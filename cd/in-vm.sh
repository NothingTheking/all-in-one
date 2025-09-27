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

# Placeholder obfuscation (not used anywhere)
x9zq=$(echo "ZG9ub3RoaW5n" | base64 -d 2>/dev/null)

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
            exit 1
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
    printf "%b\n" "${CYAN}${line}${RESET}"
    sleep 0.05
  done
  printf "\n"
}

# -------------------------
# System info
# -------------------------
system_info() {
    echo -e "${BOLD}SYSTEM INFORMATION${RESET}"
    echo "Hostname: $(hostname)"
    echo "User: $(whoami)"
    echo "Directory: $(pwd)"
    echo "System: $(uname -srm)"
    echo "Uptime: $(uptime -p)"
    echo "Memory: $(free -h | awk '/Mem:/ {print $3\"/\"$2}')"
    echo "Disk: $(df -h / | awk 'NR==2 {print $3\"/\"$2 \" (\"$5\")\"}')"
    echo
    read -rp "Press Enter to continue..."
}

# -------------------------
# Menu
# -------------------------
show_menu() {
    clear
    cat <<EOF
${CYAN}${BOLD}========== MAIN MENU ==========${RESET}
${BOLD}1. Pterodactyl Panel${RESET}
${BOLD}2. Pterodactyl Wing${RESET}
${BOLD}3. Jexactyl Panel${RESET}
${BOLD}4. Blueprint${RESET}
${BOLD}5. Cloudflare${RESET}
${BOLD}6. System Info${RESET}
${BOLD}7. Exit${RESET}
${CYAN}${BOLD}===============================${RESET}
EOF
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
            echo -e "${GREEN}You selected: Pterodactyl Panel${RESET}"
            check_curl
            bash <(curl -s https://raw.githubusercontent.com/NothingTheking/all-in-one/refs/heads/main/cd/ptero-panel.sh)
            read -rp "Press Enter to continue..."
            ;;
        2)
            echo -e "${YELLOW}You selected: Pterodactyl Wing${RESET}"
            check_curl
            bash <(curl -s https://raw.githubusercontent.com/NothingTheking/all-in-one/refs/heads/main/cd/wings.sh)
            read -rp "Press Enter to continue..."
            ;;
        3)
            echo -e "${CYAN}You selected: Jexactyl Panel${RESET}"
            check_curl
            bash <(curl -s https://raw.githubusercontent.com/NothingTheking/all-in-one/refs/heads/main/cd/jex-installer.sh)
            read -rp "Press Enter to continue..."
            ;;
        4)
            echo -e "${BLUE}You selected: Blueprint${RESET}"
            check_curl
            bash <(curl -s https://raw.githubusercontent.com/NothingTheKing/blueprint/main/blueprint.sh)
            read -rp "Press Enter to continue..."
            ;;
        5)
            echo -e "${CYAN}You selected: Cloudflare${RESET}"
            if check_wget; then
                wget -q --show-progress https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
                sudo dpkg -i cloudflared-linux-amd64.deb || true
                rm -f cloudflared-linux-amd64.deb
            fi
            read -rp "Press Enter to continue..."
            ;;
        6)
            if command -v neofetch &>/dev/null; then
                clear
                neofetch
            else
                echo -e "${YELLOW}neofetch not found. Installing...${RESET}"
                if command -v apt-get &>/dev/null; then
                    sudo apt-get update && sudo apt-get install -y neofetch
                    clear; neofetch
                elif command -v dnf &>/dev/null; then
                    sudo dnf install -y neofetch || system_info
                elif command -v yum &>/dev/null; then
                    sudo yum install -y epel-release && sudo yum install -y neofetch || system_info
                else
                    system_info
                fi
            fi
            read -rp "Press Enter to continue..."
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
