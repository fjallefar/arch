# Arch Linux Post-Install Setup Script

Welcome to the Arch Linux Post-Install Setup Script repository! 
This script is designed to streamline the setup of a new Arch Linux installation by installing a selection of commonly used applications and configuring system settings based on user choices.

## Overview

This script provides an interactive menu-driven interface that allows you to:
- Select and install a variety of applications categorized into Browsers, Common Programs, Extras, Development Tools, and Games.
- Configure system settings such as enabling NVIDIA DRM in GRUB and updating initramfs with NVIDIA modules.

## Features

- **Interactive Menus**: Navigate through different categories of applications and system configurations using a text-based menu interface.
- **Package Management**: Installs packages using `pacman`, Arch Linux's package manager, and handles both official repositories and AUR (Arch User Repository) packages.
- **System Configuration**: Applies essential system configurations tailored for NVIDIA graphics cards.

## Installation

**Get the script:**:
wget raw.githubusercontent.com/fjallefar/arch/main/arch.sh

**Make it executeable:**:
chmod+x arch.sh

**Run the script:**:
run: ./arch.sh
