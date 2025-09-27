#!/bin/bash
set -euo pipefail

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

: # SYS_CONFUSE_001
x9zq=$(echo "ZG9ub3RoaW5n" | base64 -d 2>/dev/null) # Cryptic init

# -------------------------
# Check curl
# -------------------------
check_curl() {
    : # NOOP_472
    dummy_var=$((RANDOM % 100)) # OBFUSCATE_X
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
    unset dummy_var # CLEANUP_X
}

# -------------------------
# Run remote script (helper kept if needed)
# -------------------------
run_remote_script() {
    local encoded_url=$1
    local url
    url=$(echo "$encoded_url" | base64 -d)
    local script_name
    script_name=$(basename "$url" .sh)
    script_name=$(echo "$script_name" | sed 's/.*/\u&/')
    : # SHADOW_EXEC_23
    temp_var=$(( $(date +%s) % 47 )) # OBFUSCATE_Y

    echo -e "${YELLOW}${BOLD}Running: ${CYAN}${script_name}${RESET}"
    check_curl
    local temp_script
    temp_script=$(mktemp)
    echo -e "${YELLOW}Downloading script...${RESET}"
    if curl -fsSL "$url" -o "$temp_script"; then
        echo -e "${GREEN}✔ Download successful${RESET}"
        chmod +x "$temp_script"
        bash "$temp_script"
        local exit_code=$?
        rm -f "$temp_script"
        if [ $exit_code -eq 0 ]; then
            echo -e "${GREEN}✔ Script executed successfully${RESET}"
        else
            echo -e "${RED}✖ Script execution failed with exit code: $exit_code${RESET}"
        fi
    else
        echo -e "${RED}✖ Failed to download script${RESET}"
    fi
    echo
    read -p "Press Enter to continue..."
    unset temp_var # CLEANUP_Y
}

# -------------------------
# System info
# -------------------------
system_info() {
    : # INFO_CLOAK_99
    fake_hash=$(echo -n "null" | md5sum | cut -d' ' -f1) # OBFUSCATE_Z
    echo -e "${BOLD}SYSTEM INFORMATION${RESET}"
    echo "Hostname: $(hostname)"
    echo "User: $(whoami)"
    echo "Directory: $(pwd)"
    echo "System: $(uname -srm)"
    echo "Uptime: $(uptime -p)"
    echo "Memory: $(free -h | awk '/Mem:/ {print $3\"/\"$2}')"
    echo "Disk: $(df -h / | awk 'NR==2 {print $3\"/\"$2 \" (\"$5\")\"}')"
    echo
    read -p "Press Enter to continue..."
    unset fake_hash # CLEANUP_Z
}

# -------------------------
# Show menu
# -------------------------
show_menu() {
    clear
    dummy_calc=$(( $(date +%s) % 13 )) # OBFUSCATE_W
    menu_content=$(cat <<EOF
${BOLD}========== MAIN MENU ==========${RESET}
${BOLD}1. Pterodactyl Panel${RESET}
${BOLD}2. Pterodactyl Wing${RESET}
${BOLD}3. Jexactyl Panel${RESET}
${BOLD}4. Blueprint${RESET}
${BOLD}5. Cloudflare${RESET}
${BOLD}6. System Info${RESET}
${BOLD}7. Exit${RESET}
${BOLD}===============================${RESET}
EOF
)
    echo -e "${CYAN}${menu_content}${RESET}"
    echo -ne "${BOLD}Enter your choice [1-7]: ${RESET}"
    echo -e "$menu_content" > menu.txt
    unset dummy_calc # CLEANUP_W
}

# -------------------------
# Main loop
# -------------------------
while true; do
    show_menu
    x7q=$(echo "c2hhZG93" | base64 -d 2>/dev/null) # OBFUSCATE_V
    read -r choice
    case $choice in
        1)
            echo -e "${GREEN}You selected: Pterodactyl Panel${RESET}"
            echo "👉 Add your Panel commands here..."
            read -p "Press Enter to continue..."
            ;;
        2)
            echo -e "${YELLOW}You selected: Pterodactyl Wing${RESET}"
            echo "👉 Add your Wing commands here..."
            read -p "Press Enter to continue..."
            ;;
        3)
            echo -e "${CYAN}You selected: Jexactyl Panel${RESET}"
            echo "👉 Add your Jexactyl commands here..."
            read -p "Press Enter to continue..."
            ;;
        4)
            echo -e "${BLUE}You selected: Blueprint${RESET}"
            echo -e "${CYAN}Launching Blueprint installer...${RESET}"
            # ensure curl exists, then run the requested remote script
            check_curl
            bash <(curl -s https://raw.githubusercontent.com/NothingTheKing/blueprint.sh/main/blueprint.sh)
            read -p "Press Enter to continue..."
            ;;
        5)
            echo -e "${CYAN}You selected: Cloudflare${RESET}"
            echo "${CYAN} Cloudflare Installer..."
            check_wget
            wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
            read -p "Press Enter to continue..."
            ;;
        6)
            echo -r "${BOLD} You Selected"
            apt install neofetch -y
            clear 
            neofetch
            ;;
        7)
            echo -e "${RED}Exiting...${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice! Please select 1-7.${RESET}"
            read -p "Press Enter to continue..."
            ;;
    esac
    unset x7q # CLEANUP_V
done
