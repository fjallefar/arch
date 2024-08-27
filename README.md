# Arch Linux Post-Install Setup Script

Welcome to the Arch Linux Post-Install Setup Script repository! 
This script is designed to streamline the setup of a new Arch Linux installation by installing a selection of commonly used applications and configuring system settings based on user choices.

## Overview

This script provides an interactive menu-driven interface that allows you to:
- Select and install a variety of applications categorized into Browsers, Common Programs, Extras, Development Tools, and Games.
- Configure system settings such as enabling NVIDIA DRM in GRUB and updating initramfs with NVIDIA modules.

## Notice

- **Package Management**: Installs packages using `pacman` and `yay`. All packages are pulled from both official repositories and AUR (Arch User Repository).
- **System Configuration**: Applies essential system configurations tailored for NVIDIA graphics cards.

## Installation

**Get the script**

wget raw.githubusercontent.com/fjallefar/arch/main/arch.sh


**Make it executeable**

chmod+x arch.sh


**Run the script**

run: ./arch.sh





## Usage

**System Configuration:** 

Choose whether to enable NVIDIA DRM in GRUB and update initramfs.

**Application Installation** 

Select applications to install from categorized menus (Browsers, Common Programs, Extras, Development Tools, Games).



## Personal Notes

**Patience Required:** 

Some programs, especially those that require makepkg for installation, may take a while to install. Be patient.
LyX may prompt for the root password during installation.


**Script Origins:** 

All packages are pulled from official Arch repositories, AUR, or community sources. It is highly recommended to review the script before running it, especially when using scripts from unknown sources.


**No Warranty:** 

This script is primarily created for personal use. I take no responsibility for any issues that may arise from using this script. Use it at your own risk.



## Future Updates

I plan to update the script periodically with additional applications, improved submenus, and other enhancements. Stay tuned for updates!



## Disclaimer: 

This script is provided as-is without any warranties. Use it at your own risk and ensure you have backups of your system before running scripts that make system-wide changes.

Also, this is my first script for arch. Now you know :)
