#!/bin/bash

output(){
    echo -e '\e[35m'$1'\e[0m';
}

warn(){
    echo -e '\e[31m'$1'\e[0m';
}

PANEL=latest
WINGS=latest

preflight(){
    output "Jexactyl Installation & Upgrade Script"
    output ""

    output "Please note that this script is meant to be installed on a fresh OS. Installing it on a non-fresh OS may cause problems."
    output "Automatic operating system detection initialized..."

    os_check

    if [ "$EUID" -ne 0 ]; then
        output "Please run as root."
        exit 3
    fi

    output "Automatic architecture detection initialized..."
    MACHINE_TYPE=$(uname -m)
    if [ "${MACHINE_TYPE}" == 'x86_64' ]; then
        output "64-bit server detected! Good to go."
        output ""
    else
        output "Unsupported architecture detected! Please switch to 64-bit (x86_64)."
        exit 4
    fi

    output "Automatic virtualization detection initialized..."
    if [ "$lsb_dist" = "ubuntu" ]; then
        apt-get update --fix-missing
        apt-get -y install software-properties-common
        add-apt-repository -y universe
        apt-get -y install virt-what curl
    elif [ "$lsb_dist" = "debian" ]; then
        apt update --fix-missing
        apt-get -y install software-properties-common virt-what wget curl dnsutils
    elif [ "$lsb_dist" = "fedora" ] || [ "$lsb_dist" = "centos" ] || [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
        yum -y install virt-what wget bind-utils
    fi
    virt_serv=$(virt-what)
    if [ "$virt_serv" = "" ]; then
        output "Virtualization: Bare Metal detected."
    elif [ "$virt_serv" = "openvz lxc" ]; then
        output "Virtualization: OpenVZ 7 detected."
    elif [ "$virt_serv" = "xen xen-hvm" ]; then
        output "Virtualization: Xen-HVM detected."
    elif [ "$virt_serv" = "xen xen-hvm aws" ]; then
        output "Virtualization: Xen-HVM on AWS detected."
        warn "When creating allocations for this node, please use the internal IP as Google Cloud uses NAT routing."
        warn "Resuming in 10 seconds..."
        sleep 10
    else
        output "Virtualization: $virt_serv detected."
    fi
    output ""
    if [ "$virt_serv" != "" ] && [ "$virt_serv" != "kvm" ] && [ "$virt_serv" != "vmware" ] && [ "$virt_serv" != "hyperv" ] && [ "$virt_serv" != "openvz lxc" ] && [ "$virt_serv" != "xen xen-hvm" ] && [ "$virt_serv" != "xen xen-hvm aws" ]; then
        warn "Unsupported virtualization detected. Proceed at your own risk."
        warn "Proceed?\n[1] Yes.\n[2] No."
        read choice
        case $choice in 
            1)  output "Proceeding...";;
            2)  output "Cancelling installation..."; exit 5;;
        esac
        output ""
    fi
}

os_check(){
    if [ -r /etc/os-release ]; then
        lsb_dist="$(. /etc/os-release && echo "$ID")"
        dist_version="$(. /etc/os-release && echo "$VERSION_ID")"
        if [ "$lsb_dist" = "rhel" ] || [ "$lsb_dist" = "rocky" ] || [ "$lsb_dist" = "almalinux" ]; then
            dist_version="$(echo $dist_version | awk -F. '{print $1}')"
        fi
    else
        exit 1
    fi
    
    if [ "$lsb_dist" = "ubuntu" ]; then
        if [ "$dist_version" != "20.04" ]; then
            output "Unsupported Ubuntu version. Only Ubuntu 20.04 is supported."
            exit 2
        fi
    elif [ "$lsb_dist" = "debian" ]; then
        if [ "$dist_version" != "11" ]; then
            output "Unsupported Debian version. Only Debian 11 is supported."
            exit 2
        fi
    elif [ "$lsb_dist" = "fedora" ]; then
        if [ "$dist_version" != "35" ]; then
            output "Unsupported Fedora version. Only Fedora 35 is supported."
            exit 2
        fi
    elif [ "$lsb_dist" = "centos" ]; then
        if [ "$dist_version" != "8" ]; then
            output "Unsupported CentOS version. Only CentOS Stream 8 is supported."
            exit 2
        fi
    elif [ "$lsb_dist" = "rhel" ]; then
        if [ "$dist_version" != "8" ]; then
            output "Unsupported RHEL version. Only RHEL 8 is supported."
            exit 2
        fi
    elif [ "$lsb_dist" = "rocky" ]; then
        if [ "$dist_version" != "8" ]; then
            output "Unsupported Rocky Linux version. Only Rocky Linux 8 is supported."
            exit 2
        fi
    elif [ "$lsb_dist" = "almalinux" ]; then
        if [ "$dist_version" != "8" ]; then
            output "Unsupported AlmaLinux version. Only AlmaLinux 8 is supported."
            exit 2
        fi
    else
        output "Unsupported operating system."
        exit 2
    fi
}

install_options(){
    output "Please select your installation option:"
    output "[1] Install the panel ${PANEL}."
    output "[2] Install the wings ${WINGS}."
    output "[3] Install the panel ${PANEL} and wings ${WINGS}."
    output "[4] Upgrade panel to ${PANEL}."
    output "[5] Upgrade wings to ${WINGS}."
    output "[6] Upgrade panel to ${PANEL} and wings to ${WINGS}."
    output "[7] Install phpMyAdmin (only use this after you have installed the panel)."
    output "[8] Emergency MariaDB root password reset."
    output "[9] Emergency database host information reset."
    read -r choice
    case $choice in
        1 ) installoption=1
            output "You have selected ${PANEL} panel installation only.";;
        2 ) installoption=2
            output "You have selected wings ${WINGS} installation only.";;
        3 ) installoption=3
            output "You have selected ${PANEL} panel and wings ${WINGS} installation.";;
        4 ) installoption=4
            output "You have selected to upgrade the panel to ${PANEL}.";;
        5 ) installoption=5
            output "You have selected to upgrade the wings to ${WINGS}.";;
        6 ) installoption=6
            output "You have selected to upgrade panel to ${PANEL} and wings to ${WINGS}.";;
        7 ) installoption=7
            output "You have selected to install phpMyAdmin.";;
        8 ) installoption=8
            output "You have selected MariaDB root password reset.";;
        9 ) installoption=9
            output "You have selected Database Host information reset.";;
        * ) output "You did not enter a valid selection."; install_options;;
    esac
}

ssl_certs(){
    output "Setting up SSL certificates with Let's Encrypt..."
    apt -y install certbot python3-certbot-nginx || dnf -y install certbot python3-certbot-nginx
    certbot --nginx -d $FQDN --non-interactive --agree-tos -m $email
}
