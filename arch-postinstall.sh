#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

echo "Starting Arch Linux post-install script..."

# Automatically detect the non-root username
NON_ROOT_USER=$(logname)

if [ -z "$NON_ROOT_USER" ]; then
  echo "Could not automatically detect non-root username. Please enter your username:"
  read -p "Non-root username for AUR installations: " NON_ROOT_USER
else
  echo "Detected non-root username: $NON_ROOT_USER"
fi

# User choices
read -p "Do you want to configure GRUB for NVIDIA DRM? (y/n): " configure_grub
read -p "Do you want to configure mkinitcpio for NVIDIA modules? (y/n): " configure_mkinitcpio
read -p "Do you want to enable multicore support for makepkg? (y/n): " configure_makepkg
read -p "Do you want to install the yay AUR helper? (y/n): " install_yay
read -p "Do you want to install the Brave browser? (y/n): " install_brave

# Individual application prompts
read -p "Do you want to install Discord? (y/n): " install_discord
read -p "Do you want to install Spectacle (screenshot tool)? (y/n): " install_spectacle
read -p "Do you want to install Neofetch (system information tool)? (y/n): " install_neofetch
read -p "Do you want to install Teamspeak3? (y/n): " install_teamspeak3
read -p "Do you want to install Steam? (y/n): " install_steam

read -p "Do you want to install EasyEffects and related plugins? (y/n): " install_easyeffects
read -p "Do you want to install 32-bit Pipewire? (y/n): " install_pipewire

# Function to check user's yes/no response
function user_choice() {
    [[ "$1" == "y" || "$1" == "Y" ]]
}

# Calculate number of cores to use for makepkg
TOTAL_CORES=$(nproc)
CORES_FOR_MAKEPKG=$((TOTAL_CORES - 2))

# Configure GRUB for NVIDIA DRM
if user_choice "$configure_grub"; then
  echo "Checking GRUB configuration for nvidia-drm..."
  if grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
    echo "nvidia-drm.modeset=1 is already present in GRUB_CMDLINE_LINUX_DEFAULT, skipping GRUB update."
  else
    echo "Adding nvidia-drm.modeset=1 to GRUB_CMDLINE_LINUX_DEFAULT"
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/&nvidia-drm.modeset=1 /' /etc/default/grub
    echo "Updating GRUB configuration..."
    grub-mkconfig -o /boot/grub/grub.cfg
  fi
else
  echo "Skipping GRUB configuration for NVIDIA DRM."
fi

# Configure mkinitcpio for NVIDIA modules
if user_choice "$configure_mkinitcpio"; then
  echo "Checking mkinitcpio.conf for NVIDIA modules..."
  NVIDIA_MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
  MODULES_LINE=$(grep "^MODULES=" /etc/mkinitcpio.conf)

  # Append NVIDIA modules if they are not already present
  if echo "$MODULES_LINE" | grep -qE "nvidia|nvidia_modeset|nvidia_uvm|nvidia_drm"; then
    echo "NVIDIA modules are already present in MODULES, skipping mkinitcpio update."
  else
    echo "Appending NVIDIA modules to mkinitcpio.conf..."
    # Extract existing modules and append NVIDIA modules
    EXISTING_MODULES=$(sed -n 's/^MODULES=\(.*\)/\1/p' /etc/mkinitcpio.conf)
    # Remove leading and trailing parentheses
    EXISTING_MODULES=$(echo "$EXISTING_MODULES" | sed 's/^[()]//;s/[()]$//')
    # Combine existing modules with NVIDIA modules
    UPDATED_MODULES="($EXISTING_MODULES nvidia nvidia_modeset nvidia_uvm nvidia_drm)"
    sed -i "s/^MODULES=.*/MODULES=$UPDATED_MODULES/" /etc/mkinitcpio.conf
    echo "Rebuilding initramfs..."
    mkinitcpio -P
  fi
else
  echo "Skipping mkinitcpio configuration for NVIDIA modules."
fi

# Enable multicore support for makepkg
if user_choice "$configure_makepkg"; then
  echo "Configuring multicore support for makepkg to use ${CORES_FOR_MAKEPKG} cores..."
  # Uncomment the line if it's commented and set the value
  if grep -q '^#MAKEFLAGS=' /etc/makepkg.conf; then
    sed -i "s/^#MAKEFLAGS=\".*\"/MAKEFLAGS=\"-j${CORES_FOR_MAKEPKG}\"/" /etc/makepkg.conf
  else
    # Ensure the line is present and correctly set
    grep -q '^MAKEFLAGS=' /etc/makepkg.conf || echo "MAKEFLAGS=\"-j${CORES_FOR_MAKEPKG}\"" >> /etc/makepkg.conf
  fi
else
  echo "Skipping multicore support configuration for makepkg."
fi

# Install yay AUR helper
if user_choice "$install_yay"; then
  echo "Installing yay AUR helper..."
  sudo -u "$NON_ROOT_USER" bash << EOF
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
EOF
else
  echo "Skipping yay AUR helper installation."
fi

# Install AUR packages as the non-root user
if user_choice "$install_yay"; then
  echo "Installing AUR packages..."

  # Install AUR packages
  sudo -u "$NON_ROOT_USER" bash << EOF
yay -S --noconfirm $(if user_choice "$install_brave"; then echo "brave-bin"; fi) $(if user_choice "$install_discord"; then echo "discord"; fi) $(if user_choice "$install_spectacle"; then echo "spectacle"; fi) $(if user_choice "$install_neofetch"; then echo "neofetch"; fi) $(if user_choice "$install_teamspeak3"; then echo "teamspeak3"; fi) $(if user_choice "$install_steam"; then echo "steam"; fi) $(if user_choice "$install_easyeffects"; then echo "calf lsp-plugins easyeffects"; fi) $(if user_choice "$install_pipewire"; then echo "lib32-pipewire"; fi)
EOF
else
  echo "Skipping AUR package installations."
fi

# Clean up /tmp folder
echo "Cleaning up /tmp folder..."
rm -rf /tmp/*

echo "Arch Linux post-install script completed!"
