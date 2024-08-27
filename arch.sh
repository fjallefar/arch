#!/bin/bash

# Title: Arch Linux Post-Install Setup Script
# Author: Your Name
# Description: This script sets up a basic environment for an Arch Linux system, allowing users to choose which features and applications to install.

# Ensure the script is run as root for system configurations
if [ "$EUID" -eq 0 ]; then
  echo "This script should not be run as root. Please run it as a normal user."
  exit
fi

# Function to install dialog if not installed
install_dialog() {
    if ! command -v dialog &> /dev/null; then
        echo "Dialog is not installed. Installing dialog..."
        sudo pacman -Syu --noconfirm dialog
    fi
}

# Function to install git if not installed
install_git() {
    if ! command -v git &> /dev/null; then
        echo "Git is not installed. Installing git..."
        sudo pacman -Syu --noconfirm git
    fi
}

# Function to install go if not installed
install_go() {
    if ! command -v go &> /dev/null; then
        echo "Go is not installed. Installing go..."
        sudo pacman -Syu --noconfirm go
    fi
}

# Function to install yay if not installed
install_yay() {
    if ! command -v yay &> /dev/null; then
        echo "Yay is not installed. Installing yay..."
        install_git
        install_go
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd ..
        rm -rf yay
    fi
}

# Function to enable nvidia-drm in grub
enable_nvidia_drm() {
    echo "Checking and enabling nvidia-drm in grub..."
    if grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
        echo "nvidia-drm.modeset=1 is already enabled in GRUB."
    else
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&nvidia-drm.modeset=1 /' /etc/default/grub
        apply_grub_changes
    fi
}

# Function to update mkinitcpio.conf with NVIDIA modules
update_mkinitcpio() {
    echo "Checking and updating mkinitcpio.conf with nvidia modules..."
    nvidia_modules=("nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm")
    modules_to_add=()

    for module in "${nvidia_modules[@]}"; do
        if ! grep -q "$module" /etc/mkinitcpio.conf; then
            modules_to_add+=("$module")
        fi
    done

    if [ ${#modules_to_add[@]} -eq 0 ]; then
        echo "All NVIDIA modules are already present in mkinitcpio.conf."
    else
        echo "Adding NVIDIA modules: ${modules_to_add[@]}"
        sudo sed -i "s/^MODULES=\"/&${modules_to_add[*]} /" /etc/mkinitcpio.conf
        regenerate_initramfs
    fi
}

# Function to apply GRUB changes (if user enabled nvidia-drm)
apply_grub_changes() {
    echo "Applying GRUB configuration changes..."
    sudo grub-mkconfig -o /boot/grub/grub.cfg
}

# Function to regenerate initramfs (if user updated mkinitcpio.conf)
regenerate_initramfs() {
    echo "Regenerating initramfs..."
    sudo mkinitcpio -P
}

# Function to update makepkg.conf to use all cores except 2
update_makepkg_conf() {
    echo "Updating makepkg.conf to use all cores except 2..."
    total_cores=$(nproc)
    cores_to_use=$((total_cores - 2))

    if [ $cores_to_use -lt 1 ]; then
        cores_to_use=1
    fi

    desired_makeflags="-j$cores_to_use"

    if grep -q "^MAKEFLAGS=\"-j$cores_to_use\"" /etc/makepkg.conf; then
        echo "MAKEFLAGS is already set to use $cores_to_use cores."
    else
        if grep -q "^MAKEFLAGS=" /etc/makepkg.conf; then
            sudo sed -i "s/^MAKEFLAGS=.*/MAKEFLAGS=\"$desired_makeflags\"/" /etc/makepkg.conf
        elif grep -q "#MAKEFLAGS=" /etc/makepkg.conf; then
            sudo sed -i "s/#MAKEFLAGS=.*/MAKEFLAGS=\"$desired_makeflags\"/" /etc/makepkg.conf
        else
            echo "MAKEFLAGS=\"$desired_makeflags\"" | sudo tee -a /etc/makepkg.conf
        fi
    fi
}

# Function to show the menu for system settings
show_system_menu() {
    dialog --msgbox "You are now entering the system configuration setup. Select the options you want to configure and then click 'Next' to proceed." 10 50
    cmd=(dialog --separate-output --checklist "Select system settings options:" 22 76 16)
    options=(
        1 "Enable nvidia-drm in grub" off
        2 "Update mkinitcpio.conf with nvidia modules" off
        3 "Update makepkg.conf to use all cores except 2" off
    )
    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

    if [ $? -ne 0 ]; then
        echo "User cancelled the system configuration menu. Exiting script."
        exit
    fi

    clear

    system_configurations=()
    for choice in $choices; do
        case $choice in
            1)
                system_configurations+=("enable_nvidia_drm")
                ;;
            2)
                system_configurations+=("update_mkinitcpio")
                ;;
            3)
                system_configurations+=("update_makepkg_conf")
                ;;
        esac
    done
}

# Function to show the menu for application categories
show_app_categories_menu() {
    while true; do
        cmd=(dialog --menu "Select application category:" 15 50 8)
        options=(
            1 "Browsers"
            2 "Common Programs"
            3 "Extras"
            4 "Development"
            5 "Games"
            6 " "
            7 "Install Selected Options"
        )
        choice=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

        if [ $? -ne 0 ]; then
            echo "User cancelled the application categories menu. Exiting script."
            exit
        fi

        clear

        case $choice in
            1) show_browser_menu ;;
            2) show_common_programs_menu ;;
            3) show_extras_menu ;;
            4) show_development_menu ;;
            5) show_games_menu ;;
            7) confirm_and_install ;;
        esac
    done
}

# Function to show the menu for browsers
show_browser_menu() {
    cmd=(dialog --separate-output --checklist "Select Browsers:" 22 76 16)
    options=(
        1 "Google Chrome" off
        2 "Mozilla Firefox" off
        3 "Brave" off
        4 "Chromium" off
        5 "Vivaldi" off
        6 "Falkon" off
    )
    selected_indices=($(dialog --separate-output --checklist "Select Browsers:" 22 76 16 "${options[@]}" 2>&1 >/dev/tty))

    if [ $? -ne 0 ]; then
        echo "User cancelled the browser menu. Returning to the application categories menu."
        return
    fi

    clear

    browser_map=(
        [1]="google-chrome"
        [2]="firefox"
        [3]="brave-bin"
        [4]="chromium"
        [5]="vivaldi"
        [6]="falkon"
    )

    for index in "${selected_indices[@]}"; do
        selected_apps+=("${browser_map[$index]}")
    done
}

# Function to show the menu for common programs
show_common_programs_menu() {
    cmd=(dialog --separate-output --checklist "Select Common Programs:" 22 76 16)
    options=(
        1 "Discord" off
        2 "Steam" off
        3 "VLC Media Player" off
        4 "GIMP" off
        5 "LibreOffice" off
        6 "Timeshift" off
        7 "Audacity" off
        8 "Thunderbird" off
        9 "Signal" off
        10 "Spotify" off
        11 "Flameshot" off
        12 "Neofetch" off
        13 "Simplenote" off
    )
    selected_indices=($(dialog --separate-output --checklist "Select Common Programs:" 22 76 16 "${options[@]}" 2>&1 >/dev/tty))

    if [ $? -ne 0 ]; then
        echo "User cancelled the common programs menu. Returning to the application categories menu."
        return
    fi

    clear

    common_programs_map=(
        [1]="discord"
        [2]="steam"
        [3]="vlc"
        [4]="gimp"
        [5]="libreoffice-fresh"
        [6]="timeshift"
        [7]="audacity"
        [8]="thunderbird"
        [9]="signal-desktop"
        [10]="spotify"
        [11]="flameshot"
        [12]="neofetch"
        [13]="simplenote"
    )

    for index in "${selected_indices[@]}"; do
        selected_apps+=("${common_programs_map[$index]}")
    done
}

# Function to show the menu for extras
show_extras_menu() {
    cmd=(dialog --separate-output --checklist "Select Extras:" 22 76 16)
    options=(
        1 "EasyEffects (includes Calf and lsp-plugins)" off
        2 "Kdenlive" off
    )
    selected_indices=($(dialog --separate-output --checklist "Select Extras:" 22 76 16 "${options[@]}" 2>&1 >/dev/tty))

    if [ $? -ne 0 ]; then
        echo "User cancelled the extras menu. Returning to the application categories menu."
        return
    fi

    clear

    extras_map=(
        [1]="easyeffects calf-plugins lsp-plugins"
        [2]="kdenlive"
    )

    for index in "${selected_indices[@]}"; do
        selected_apps+=("${extras_map[$index]}")
    done
}

# Function to show the menu for development tools
show_development_menu() {
    cmd=(dialog --separate-output --checklist "Select Development Tools:" 22 76 16)
    options=(
        1 "Visual Studio Code" off
        2 "Lyx" off
    )
    selected_indices=($(dialog --separate-output --checklist "Select Development Tools:" 22 76 16 "${options[@]}" 2>&1 >/dev/tty))

    if [ $? -ne 0 ]; then
        echo "User cancelled the development tools menu. Returning to the application categories menu."
        return
    fi

    clear

    development_map=(
        [1]="visual-studio-code-bin"
        [2]="lyx"
    )

    for index in "${selected_indices[@]}"; do
        selected_apps+=("${development_map[$index]}")
    done
}

# Function to show the menu for games
show_games_menu() {
    cmd=(dialog --separate-output --checklist "Select Games:" 22 76 16)
    options=(
        1 "Steam" off
        2 "PlayOnLinux" off
        3 "Lutris" off
    )
    selected_indices=($(dialog --separate-output --checklist "Select Games:" 22 76 16 "${options[@]}" 2>&1 >/dev/tty))

    if [ $? -ne 0 ]; then
        echo "User cancelled the games menu. Returning to the application categories menu."
        return
    fi

    clear

    games_map=(
        [1]="steam"
        [2]="playonlinux"
        [3]="lutris"
    )

    for index in "${selected_indices[@]}"; do
        selected_apps+=("${games_map[$index]}")
    done
}

# Function to confirm and install selected applications and configurations
confirm_and_install() {
    if [ ${#selected_apps[@]} -eq 0 ] && [ ${#system_configurations[@]} -eq 0 ]; then
        dialog --msgbox "No applications or system configurations selected." 10 50
        return
    fi

    dialog --msgbox "You have selected the following options for installation:\n\nApplications:\n${selected_apps[*]}\n\nSystem Configurations:\n${system_configurations[*]}\n\nClick 'Ok' to start installation." 15 50

    if [ $? -ne 0 ]; then
        echo "User cancelled the confirmation dialog. Exiting script."
        exit
    fi

    clear

    # Apply system configurations
    for config in "${system_configurations[@]}"; do
        case $config in
            "enable_nvidia_drm")
                enable_nvidia_drm
                ;;
            "update_mkinitcpio")
                update_mkinitcpio
                ;;
            "update_makepkg_conf")
                update_makepkg_conf
                ;;
        esac
    done

    # Install selected applications
    for app in "${selected_apps[@]}"; do
        echo "Installing $app..."
        yay -S --noconfirm "$app"
    done

    # Notify user of completion
    echo "Installation completed. Closing script."
    exit
}

# Main function
main() {
    echo "Welcome to the Arch Linux Post-Install Setup Script"
    install_dialog

    # Check and install git, go, and yay if needed
    install_git
    install_go
    install_yay

    # Show system configuration menu
    show_system_menu

    # Show application categories menu
    show_app_categories_menu

    # Display summary of changes
    if [ -z "$changes_made" ]; then
        echo "No changes were made."
    else
        echo -e "Summary of changes:\n$changes_made"
    fi
}

# Call the main function
main
