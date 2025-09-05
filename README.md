macOS NTFS Read/Write Mounter Script
====================================

A simple, interactive Bash script to mount external NTFS-formatted drives on macOS with full read and write capabilities, making them completely accessible in Finder.

The Problem
-----------

A common macOS limitation: it can **read** from NTFS-formatted drives, but it **cannot write** to them. In my case, I had a bootable Windows HDD that I needed to access and modify files on. I also needed to use it for extra storage so reformatting the drive wasn't an option.

There are software solutions available that solve this, but I wanted a free and minimal way to handle this.

The Solution
------------

This script automates the entire process of setting up and mounting an NTFS drive for full read/write access. It uses a combination of trusted, open-source tools:

*   **Homebrew**: Your good ol' standard package manager for macOS.
    
*   **MacFUSE**: The underlying framework that allows new filesystems to be used on macOS.
    
*   **NTFS-3G**: A safe, open-source driver that enables read/write access for NTFS partitions.
    

The script handles dependency checks, installation, and guides you through the necessary one-time security approvals required by modern macOS versions.
    

How to Use
----------

Follow these simple steps to get your NTFS drive working in minutes.

- Go to your Downloads folder
cd ~/Downloads

- Download the script (replace URL with the raw link from GitHub)
curl -o mount_ntfs.sh https://raw.githubusercontent.com/yorkzap/mount-ntfs-macos-read-write/main/mount_ntfs.sh

- Make it executable
chmod +x mount_ntfs.sh

- Run it
./mount_ntfs.sh
    

Once finished, your drive will be mounted and a Finder window will open automatically, ready for you to read and write files!

Prerequisites
-------------

*   **Xcode Command Line Tools**: Homebrew requires this. If you don't have them, macOS will likely prompt you to install them automatically the first time you run the script. You can also install them manually at any time by running xcode-select --install in the Terminal.
    

Disclaimer
----------

This script automates the installation and execution of system-level tools. Please use it at your own risk. It has been tested and works well, but every system configuration is unique.
