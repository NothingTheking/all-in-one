#!/bin/bash
set -euo pipefail

# -------------------------
# Colors
# -------------------------
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
CYAN="\e[36m"
WHITE="\e[37m"
RESET="\e[0m"
BOLD="\e[1m"

# -------------------------
# Helpers
# -------------------------
check_curl() {
    if ! command -v curl &>/dev/null; then
        echo -e "${RED}${BOLD}Error: curl is not installed.${RESET}"
        echo -e "${YELLOW}Installing curl...${RESET}"
        if command -v apt-get &>/dev/null; then
            sudo apt-get update && sudo apt-get install -y curl
        elif command -v yum &>/dev/null; then
            sudo yum install -y curl
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y curl
        else
            echo -e "${RED}Could not install curl automatically. Please install it manually.${RESET}"
            return 1
        fi
        echo -e "${GREEN}curl installed successfully!${RESET}"
    fi
}

check_wget() {
    if ! command -v wget &>/dev/null; then
        echo -e "${YELLOW}wget not found — attempting to install...${RESET}"
        if command -v apt-get &>/dev/null; then
            sudo apt-get update && sudo apt-get install -y wget
        elif command -v yum &>/dev/null; then
            sudo yum install -y wget
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y wget
        else
            echo -e "${RED}Could not install wget automatically. Please install it manually.${RESET}"
            return 1
        fi
        echo -e "${GREEN}wget installed successfully!${RESET}"
    fi
}

# -------------------------
# Logo animation
# -------------------------
animate_logo() {
  clear
  local logo=(
"   _   _       _   _     _          _______ _    "
"  | \\ | |     | | | |   (_)        |__   __| |   "
"  |  \\| | ___ | |_| |__  _ _ __   __ _| |  | | __"
"  | . \` |/ _ \\| __| '_ \\| | '_ \\ / _\` | |  | |/ /"
"  | |\\  | (_) | |_| | | | | | | | (_| | |  |   < "
"  |_| \\_|\\___/ \\__|_| |_|_|_| |_|\\__, |_|  |_|\_\\"
"                                  __/ |          "
"                                 |___/           "
  )
  for line in "${logo[@]}"; do
    printf "%b\n" "${CYAN}${BOLD}${line}${RESET}"
    sleep 0.03
  done
  printf "\n"
}

# -------------------------
# System info
# -------------------------
system_info() {
    echo -e "${BOLD}SYSTEM INFORMATION${RESET}"
    echo "Hostname : $(hostname)"
    echo "User     : $(whoami)"
    echo "Directory: $(pwd)"
    echo "System   : $(uname -srm)"
    echo "Uptime   : $(uptime -p)"
    echo "Memory   : $(free -h | awk '/Mem:/ {print $3\"/\"$2}')"
    echo "Disk     : $(df -h / | awk 'NR==2 {print $3\"/\"$2 \" (\"$5\")\"}')"
    echo
    read -rp "Press Enter to continue..."
}

# -------------------------
# Run script safely
# -------------------------
run_script() {
    local url="$1"
    check_curl || return
    echo -e "${YELLOW}Running script: $url${RESET}"
    if ! bash <(curl -fsSL "$url"); then
        echo -e "${RED}Script failed! Returning to menu...${RESET}"
        read -rp "Press Enter to continue..."
    else
        echo -e "${GREEN}Script completed successfully.${RESET}"
        read -rp "Press Enter to continue..."
    fi
}

# -------------------------
# Main menu
# -------------------------
show_menu() {
    clear
    echo -e "${CYAN}${BOLD}========== MAIN MENU ==========${RESET}"
    echo -e "${BOLD}1. Pterodactyl ${RESET}"
    echo -e "${BOLD}2. Jexactyl ${RESET}"
    echo -e "${BOLD}3. Blueprint${RESET}"
    echo -e "${BOLD}4. Cloudflare${RESET}"
    echo -e "${BOLD}5. System Info${RESET}"
    echo -e "${BOLD}6. Exit${RESET}"
    echo -e "${CYAN}${BOLD}===============================${RESET}"
    echo -ne "${BOLD}Enter your choice [1-7]: ${RESET}"
}

# -------------------------
# Main loop
# -------------------------
while true; do
    animate_logo
    show_menu
    read -r choice
    case $choice in
        1)
            run_script "https://pterodactyl-installer.se"
            ;;
        2)
            run_script "https://raw.githubusercontent.com/NothingTheking/all-in-one/refs/heads/main/cd/jex.sh"
            ;;
        3)
            run_script "https://raw.githubusercontent.com/NothingTheKing/blueprint/main/blueprint.sh"
            ;;
        4)
            check_wget || continue
            echo -e "${YELLOW}Downloading Cloudflare package...${RESET}"
            if wget -q --show-progress https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb; then
                sudo dpkg -i cloudflared-linux-amd64.deb || true
                rm -f cloudflared-linux-amd64.deb
                echo -e "${GREEN}Cloudflare installed successfully.${RESET}"
            else
                echo -e "${RED}Failed to download Cloudflare.${RESET}"
            fi
            read -rp "Press Enter to continue..."
            ;;
        6)
            system_info
            ;;
        7)
            echo -e "${RED}Exiting...${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice! Please select 1-7.${RESET}"
            read -rp "Press Enter to continue..."
            ;;
    esac
done
