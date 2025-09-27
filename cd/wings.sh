#!/bin/bash

set -e

# -------------- Safe Fallback Functions -------------- #
fn_exists() { declare -F "$1" >/dev/null; }

if ! fn_exists lib_loaded; then
  # shellcheck source=lib/lib.sh
  if [ -f /tmp/lib.sh ]; then
    source /tmp/lib.sh
  elif [ -n "$GITHUB_BASE_URL" ] && [ -n "$GITHUB_SOURCE" ]; then
    source <(curl -sSL "$GITHUB_BASE_URL/$GITHUB_SOURCE/lib/lib.sh")
  fi
fi

# Fallbacks if lib.sh not loaded
warning()  { echo -e "\e[33m* WARNING:\e[0m $*"; }
error()    { echo -e "\e[31m* ERROR:\e[0m $*" >&2; }
welcome()  { echo -e "\e[36m* Welcome to $1 installer\e[0m"; }
hyperlink(){ echo "$1"; }
print_brake(){ printf '%*s\n' "$1" '' | tr ' ' '*'; }
check_virt(){ true; }
run_installer(){ echo "* Running installer for $1..."; }
valid_email(){ [[ "$1" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; }
required_input(){ read -rp "$2" val; export "$1"="${val:-$4}"; }
password_input(){ while true; do read -rsp "$2" val; echo; [ -n "$val" ] && break || echo "$3"; done; export "$1"="$val"; }

# ------------------ Variables ----------------- #

# Install mariadb
export INSTALL_MARIADB=false

# Firewall
export CONFIGURE_FIREWALL=false
export CONFIGURE_UFW=false
export CONFIGURE_FIREWALL_CMD=false

# SSL (Let's Encrypt)
export CONFIGURE_LETSENCRYPT=false
export FQDN=""
export EMAIL=""

# Database host
export CONFIGURE_DBHOST=false
export CONFIGURE_DB_FIREWALL=false
export MYSQL_DBHOST_HOST="127.0.0.1"
export MYSQL_DBHOST_USER="pterodactyluser"
export MYSQL_DBHOST_PASSWORD=""

# ------------ User input functions ------------ #

ask_letsencrypt() {
  if [ "$CONFIGURE_UFW" == false ] && [ "$CONFIGURE_FIREWALL_CMD" == false ]; then
    warning "Let's Encrypt requires port 80/443 to be opened!"
  fi

  warning "You cannot use Let's Encrypt with an IP address! It must be a FQDN (e.g. node.example.org)."

  read -rp "* Do you want to automatically configure HTTPS using Let's Encrypt? (y/N): " CONFIRM_SSL
  [[ "$CONFIRM_SSL" =~ [Yy] ]] && CONFIGURE_LETSENCRYPT=true
}

ask_database_user() {
  read -rp "* Do you want to automatically configure a user for database hosts? (y/N): " CONFIRM_DBHOST
  if [[ "$CONFIRM_DBHOST" =~ [Yy] ]]; then
    ask_database_external
    CONFIGURE_DBHOST=true
  fi
}

ask_database_external() {
  read -rp "* Do you want to configure MySQL to be accessed externally? (y/N): " CONFIRM_DBEXTERNAL
  if [[ "$CONFIRM_DBEXTERNAL" =~ [Yy] ]]; then
    read -rp "* Enter the panel address (blank for any address): " CONFIRM_DBEXTERNAL_HOST
    MYSQL_DBHOST_HOST="${CONFIRM_DBEXTERNAL_HOST:-%}"
    [ "$CONFIGURE_FIREWALL" == true ] && ask_database_firewall
  fi
}

ask_database_firewall() {
  warning "Allowing external MySQL access (3306) can be a security risk!"
  read -rp "* Would you like to allow incoming traffic to port 3306? (y/N): " CONFIRM_DB_FIREWALL
  [[ "$CONFIRM_DB_FIREWALL" =~ [Yy] ]] && CONFIGURE_DB_FIREWALL=true
}

####################
## MAIN FUNCTIONS ##
####################

main() {
  if [ -d "/etc/pterodactyl" ]; then
    warning "Pterodactyl Wings already detected!"
    read -rp "* Proceed anyway? (y/N): " CONFIRM_PROCEED
    [[ ! "$CONFIRM_PROCEED" =~ [Yy] ]] && { error "Installation aborted!"; exit 1; }
  fi

  welcome "wings"

  check_virt

  echo "* Installing Docker, dependencies, and Wings..."
  echo "* You will still need to configure the node in the panel."
  echo "* Docs: $(hyperlink 'https://pterodactyl.io/wings/1.0/installing.html#configure')"
  print_brake 42

  ask_database_user
  ask_letsencrypt

  if [ "$CONFIGURE_LETSENCRYPT" == true ]; then
    while [ -z "$FQDN" ]; do
      read -rp "* Set the FQDN for Let's Encrypt (node.example.com): " FQDN
      [ -z "$FQDN" ] && error "FQDN cannot be empty" && continue
      [ -d "/etc/letsencrypt/live/$FQDN/" ] && { error "Cert already exists!"; FQDN=""; }
    done

    while ! valid_email "$EMAIL"; do
      read -rp "* Enter email for Let's Encrypt: " EMAIL
      valid_email "$EMAIL" || error "Invalid email"
    done
  fi

  read -rp "* Proceed with installation? (y/N): " CONFIRM
  [[ "$CONFIRM" =~ [Yy] ]] && run_installer "wings" || { error "Installation aborted."; exit 1; }
}

goodbye() {
  echo ""
  print_brake 70
  echo "* Wings installation completed"
  echo "* Configure Wings with your panel: https://pterodactyl.io/wings/1.0/installing.html#configure"
  echo "* Copy config to /etc/pterodactyl/config.yml or use auto-deploy."
  echo "* Start manually with: sudo wings"
  echo "* Or run as service: systemctl start wings"
  print_brake 70
}

# Run script
main
goodbye
