#!/bin/bash
set -euo pipefail

# -------------------------
# Colors
# -------------------------
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
# Show Logo
# -------------------------
animate_logo

# -------------------------
# Main Menu
# -------------------------
echo -e "${YELLOW}Main Menu:${RESET}"
echo -e "${GREEN}1) Are you inside VM?${RESET}"
echo -e "${BLUE}2) Are you IN IDX?${RESET}"
echo -e "${RED}3) Exit${RESET}"
echo -ne "${YELLOW}Enter your choice (1-3): ${RESET}"
read main_choice

case $main_choice in
  1)
    echo -e "${GREEN}You selected: Inside IDX${RESET}"
    echo "👉 Put your Inside VM actions here..."
    ;;

  2)
    echo -e "${BLUE}You selected: Outside IDX${RESET}"
    echo -e "${CYAN}Preparing IDX environment...${RESET}"
    cd
    rm -rf myapp flutter
    cd vps
    if [ ! -d ".idx" ]; then
      mkdir .idx
      cd .idx
      cat <<EOF > dev.nix
{ pkgs, ... }: {
  channel = "stable-24.05";

  packages = with pkgs; [
    unzip
    openssh
    git
    qemu_kvm
    sudo
    cdrkit
    cloud-utils
    qemu
  ];

  env = {
    EDITOR = "nano";
  };

  idx = {
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
    ];

    workspace = {
      onCreate = { };
      onStart = { };
    };

    previews = {
      enable = false;
    };
  };
}
EOF
      cd ..
    fi

    echo -ne "${YELLOW}Do you want to continue? (y/n): ${RESET}"
    read confirm
    case "$confirm" in
      [yY]*)
        echo -e "${GREEN}Running external setup script...${RESET}"
        bash <(curl -fsSL https://raw.githubusercontent.com/hopingboyz/vms/main/vm.sh)
        ;;
      [nN]*)
        echo -e "${RED}Operation cancelled.${RESET}"
        exit 0
        ;;
      *)
        echo -e "${RED}Invalid input! Operation cancelled.${RESET}"
        exit 1
        ;;
    esac
    ;;

  3)
    echo -e "${RED}Exiting...${RESET}"
    exit 0
    ;;

  *)
    echo -e "${RED}Invalid choice! Please select 1, 2, or 3.${RESET}"
    exit 1
    ;;
esac

# -------------------------
# Footer
# -------------------------
echo -e "${CYAN}Made by AYUSH VPS Panel${RESET}"
