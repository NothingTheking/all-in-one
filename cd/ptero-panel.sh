#!/bin/bash

set -e

# Colors
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
CYAN='\e[36m'
RESET='\e[0m'

# -------------------------
# Logo
# -------------------------
animate_logo() {
  clear
  local logo=(
"   _   _       _   _     _          _______ _    "
"  | \ | |     | | | |   (_)        |__   __| |   "
"  |  \| | ___ | |_| |__  _ _ __   __ _| |  | | __"
"  | . \` |/ _ \| __| '_ \| | '_ \ / _\` | |  | |/ /"
"  | |\  | (_) | |_| | | | | | | | (_| | |  |   < "
"  |_| \_|\___/ \__|_| |_|_|_| |_|\__, |_|  |_|\_\\"
"                                  __/ |          "
"                                 |___/           "
  )

  for line in "${logo[@]}"; do
    echo -e "${CYAN}${line}${RESET}"
    sleep 0.05
  done
  echo ""
}

# -------------------------
# Check lib.sh
# -------------------------
fn_exists() { declare -F "$1" >/dev/null; }

if ! fn_exists lib_loaded; then
  # shellcheck source=lib/lib.sh
  source /tmp/lib.sh || source <(curl -sSL "${GITHUB_BASE_URL}/${GITHUB_SOURCE}/lib/lib.sh")
  ! fn_exists lib_loaded && echo -e "${RED}* ERROR: Could not load lib script${RESET}" && exit 1
fi

# ------------------ Variables ----------------- #
export FQDN=""
export MYSQL_DB=""
export MYSQL_USER=""
export MYSQL_PASSWORD=""

export timezone=""
export email=""

export user_email=""
export user_username=""
export user_firstname=""
export user_lastname=""
export user_password=""

export ASSUME_SSL=false
export CONFIGURE_LETSENCRYPT=false
export CONFIGURE_FIREWALL=false

# ------------ User input functions ------------ #
ask_letsencrypt() {
  if [ "$CONFIGURE_FIREWALL" == false ]; then
    warning "Let's Encrypt requires port 80/443 to be opened! You opted out of automatic firewall configuration."
  fi

  echo -n "* Do you want to automatically configure HTTPS using Let's Encrypt? (y/N): "
  read -r CONFIRM_SSL
  if [[ "$CONFIRM_SSL" =~ [Yy] ]]; then
    CONFIGURE_LETSENCRYPT=true
    ASSUME_SSL=false
  fi
}

ask_assume_ssl() {
  output "Let's Encrypt is not going to be automatically configured by this script."
  output "You can 'assume' SSL, which means the script will configure nginx for Let's Encrypt but not obtain certs."
  echo -n "* Assume SSL or not? (y/N): "
  read -r ASSUME_SSL_INPUT

  [[ "$ASSUME_SSL_INPUT" =~ [Yy] ]] && ASSUME_SSL=true
}

check_FQDN_SSL() {
  if [[ $(invalid_ip "$FQDN") == 1 && $FQDN != 'localhost' ]]; then
    SSL_AVAILABLE=true
  else
    warning "* Let's Encrypt will not be available for IP addresses."
    output "To use Let's Encrypt, you must use a valid domain name."
  fi
}

# ------------------ Main ----------------- #
main() {
  if [ -d "/var/www/pterodactyl" ]; then
    warning "Pterodactyl panel already detected!"
    echo -n "* Are you sure you want to proceed? (y/N): "
    read -r CONFIRM_PROCEED
    if [[ ! "$CONFIRM_PROCEED" =~ [Yy] ]]; then
      error "Installation aborted!"
      exit 1
    fi
  fi

  animate_logo
  welcome "panel"
  check_os_x86_64

  # DB setup
  output "Database configuration."
  MYSQL_DB="-"
  while [[ "$MYSQL_DB" == *"-"* ]]; do
    required_input MYSQL_DB "Database name (panel): " "" "panel"
    [[ "$MYSQL_DB" == *"-"* ]] && error "Database name cannot contain hyphens"
  done

  MYSQL_USER="-"
  while [[ "$MYSQL_USER" == *"-"* ]]; do
    required_input MYSQL_USER "Database username (pterodactyl): " "" "pterodactyl"
    [[ "$MYSQL_USER" == *"-"* ]] && error "Database user cannot contain hyphens"
  done

  rand_pw=$(gen_passwd 64)
  password_input MYSQL_PASSWORD "Password (press enter to use random): " "MySQL password cannot be empty" "$rand_pw"

  # Timezone
  readarray -t valid_timezones <<<"$(curl -s "$GITHUB_URL/configs/valid_timezones.txt")"
  output "List of valid timezones: https://www.php.net/manual/en/timezones.php"
  while [ -z "$timezone" ]; do
    echo -n "* Select timezone [Europe/Stockholm]: "
    read -r timezone_input
    array_contains_element "$timezone_input" "${valid_timezones[@]}" && timezone="$timezone_input"
    [ -z "$timezone_input" ] && timezone="Europe/Stockholm"
  done

  # Emails
  email_input email "Email for Let's Encrypt & panel: " "Email cannot be empty"
  email_input user_email "Admin account email: " "Email cannot be empty"
  required_input user_username "Admin username: " "Cannot be empty"
  required_input user_firstname "Admin firstname: " "Cannot be empty"
  required_input user_lastname "Admin lastname: " "Cannot be empty"
  password_input user_password "Admin password: " "Cannot be empty"

  # FQDN
  while [ -z "$FQDN" ]; do
    echo -n "* Set the FQDN (panel.example.com): "
    read -r FQDN
    [ -z "$FQDN" ] && error "FQDN cannot be empty"
  done

  # SSL
  check_FQDN_SSL
  ask_firewall CONFIGURE_FIREWALL
  if [ "$SSL_AVAILABLE" == true ]; then
    ask_letsencrypt
    [ "$CONFIGURE_LETSENCRYPT" == false ] && ask_assume_ssl
  fi

  [ "$CONFIGURE_LETSENCRYPT" == true ] || [ "$ASSUME_SSL" == true ] && \
    bash <(curl -s "$GITHUB_URL/lib/verify-fqdn.sh") "$FQDN"

  summary
  echo -n "* Continue with installation? (y/N): "
  read -r CONFIRM
  [[ "$CONFIRM" =~ [Yy] ]] && run_installer "panel" || { error "Installation aborted."; exit 1; }
}

summary() {
  print_brake 62
  output "Pterodactyl panel installation summary:"
  output "Database: $MYSQL_DB / $MYSQL_USER / (hidden)"
  output "Timezone: $timezone"
  output "Admin: $user_username <$user_email>"
  output "FQDN: $FQDN"
  output "Firewall: $CONFIGURE_FIREWALL"
  output "Let's Encrypt: $CONFIGURE_LETSENCRYPT"
  output "Assume SSL: $ASSUME_SSL"
  print_brake 62
}

goodbye() {
  print_brake 62
  output "Panel installation completed."
  [ "$CONFIGURE_LETSENCRYPT" == true ] && output "Access: https://$FQDN"
  [ "$ASSUME_SSL" == true ] && output "Assumed SSL enabled; configure certs manually."
  [ "$ASSUME_SSL" == false ] && [ "$CONFIGURE_LETSENCRYPT" == false ] && output "Access: http://$FQDN"
  print_brake 62
}

# Run
main
goodbye
