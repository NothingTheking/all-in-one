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
# Helper Functions
# -------------------------
check_curl() {
  if ! command -v curl >/dev/null 2>&1; then
    echo -e "${YELLOW}Installing curl...${RESET}"
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get update -y && sudo apt-get install -y curl
    elif command -v yum >/dev/null 2>&1; then
      sudo yum install -y curl
    else
      echo -e "${RED}Error: package manager not found, install curl manually.${RESET}"
      exit 1
    fi
  fi
}

# -------------------------
# Show Logo
# -------------------------
animate_logo

# -------------------------
# Main Menu
# -------------------------
echo -e "${YELLOW}Main Menu:${RESET}"
echo -e "${GREEN}1) IN VM Command${RESET}"
echo -e "${BLUE}2) IDX Setup${RESET}"
echo -e "${CYAN}3) VM Manager (External Script)${RESET}"
echo -e "${RED}4) Exit${RESET}"
echo -ne "${YELLOW}Enter your choice (1-4): ${RESET}"
read -r main_choice

case $main_choice in
  1)
    echo -e "${GREEN}You selected: Inside VM${RESET}"
    echo "Running Inside VM Commands"
    check_curl
    bash <(curl -s https://raw.githubusercontent.com/NothingTheking/all-in-one/refs/heads/main/cd/in-vm.sh)
    ;;

  2)
    echo -e "${BLUE}You selected: IDX Setup${RESET}"
    echo -e "${CYAN}Preparing IDX environment...${RESET}"
    cd ~ || exit 1
    rm -rf myapp flutter
    mkdir -p vps
    cd vps || exit 1
    if [ ! -d ".idx" ]; then
      mkdir .idx
      cd .idx || exit 1
      cat <<'EOF' > dev.nix
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
    echo -e "${GREEN}IDX setup complete.${RESET}"
    read -p "Press Enter to continue..."
    ;;

  3)
    echo -e "${CYAN}Launching VM Manager...${RESET}"
    check_curl
    bash <(curl -fsSL https://raw.githubusercontent.com/hopingboyz/vms/main/vm.sh)
    ;;

  4)
    echo -e "${RED}Exiting...${RESET}"
    exit 0
    ;;

  *)
    echo -e "${RED}Invalid choice! Please select 1, 2, 3, or 4.${RESET}"
    exit 1
    ;;
esac

# -------------------------
# Footer
# -------------------------
echo -e "${CYAN}Made by NothingTheKing${RESET}"
