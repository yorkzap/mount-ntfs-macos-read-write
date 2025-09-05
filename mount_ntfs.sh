#!/bin/bash

# ==============================================================================
# Interactive NTFS Mount Script for macOS (Read/Write Support)
#
# Author: [Your Name/GitHub Handle Here]
# Version: 1.1
#
# This script automates the process of mounting external NTFS drives on macOS
# with full read and write capabilities. It handles all necessary dependencies,
# including Homebrew, macFUSE, and ntfs-3g, and provides an interactive
# menu for the user to select the desired drive.
# ==============================================================================

# 'set -e' ensures that the script will exit immediately if any command fails.
# This prevents unexpected behavior or errors from cascading.
set -e

# --- Configuration & Styling ---
# Define ANSI color codes for creating styled, easy-to-read output messages.
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color / Reset

# --- Script Header ---
# Display the initial title of the script. The -e flag enables interpretation of backslash escapes (like color codes).
echo -e "${BLUE}Interactive NTFS Mount Script${NC}"
echo "=============================="

# --- Dependency Check Section ---
echo -e "\n${BLUE}Checking for dependencies...${NC}"

# 1. Check for Homebrew (the macOS package manager).
# 'command -v brew' checks if the 'brew' executable is in the system's PATH.
# The output is redirected to /dev/null to keep the check silent.
if ! command -v brew &> /dev/null; then
    echo -e "${RED}Homebrew not found. Please install it from https://brew.sh/${NC}"
    exit 1
fi

# 2. Check for macFUSE (Filesystem in Userspace for macOS).
# macFUSE is a critical dependency for ntfs-3g to function. We check for its presence
# by looking for its filesystem bundle in the standard installation directory.
if [ ! -d "/Library/Filesystems/macfuse.fs" ]; then
    echo -e "${YELLOW}macFUSE not found. Attempting to install via Homebrew...${NC}"
    brew install --cask macfuse

    # macOS requires explicit, manual user approval for new System Extensions for security reasons.
    echo -e "\n${YELLOW}‼️ ACTION REQUIRED: Approve the System Extension${NC}"
    echo -e "macOS requires your manual approval for MacFUSE to work."
    echo -e "The 'Privacy & Security' settings will now open for you.\n"
    
    # This command uses a special URL scheme to open the System Settings app
    # directly to the 'Privacy & Security' pane.
    open "x-apple-systempreferences:com.apple.preference.security"
    
    # Provide clear instructions for the user to follow.
    echo -e "${YELLOW}Please do the following:${NC}"
    echo -e "1. In the window that opens, scroll down if needed."
    echo -e "2. Click ${GREEN}'Allow'${NC} next to the message about system software from ${GREEN}'Benjamin Fleischer'${NC}."
    echo -e "3. If your Mac asks you to restart, please do so and then run this script again."
    
    # 'read -p' pauses the script and waits for the user to press Enter. This gives them
    # time to complete the manual approval step before the script continues.
    read -p "Press [Enter] to continue after approving the extension..."
fi


# 3. Check for ntfs-3g (the driver for read/write NTFS support).
if ! command -v ntfs-3g &> /dev/null; then
    echo -e "${YELLOW}ntfs-3g not found. Attempting to install...${NC}"
    # The official Homebrew formula for ntfs-3g is outdated. This third-party "tap"
    # provides a modern, compatible version that works with the latest macFUSE.
    brew install gromgit/fuse/ntfs-3g-mac
fi

echo -e "${GREEN} All dependencies are satisfied.${NC}"
# --- End of Dependency Check ---

echo -e "\n${BLUE}🔎 Scanning for external NTFS drives...${NC}"

# --- Drive Discovery & Selection ---
# Create empty arrays to hold drive identifiers (e.g., disk3s1) and their labels (e.g., "Windows HD").
partitions=()
descriptions=()

# This loop reads the output of the 'diskutil' command line-by-line.
# It is a robust method that is compatible with the older version of bash that ships with macOS.
# 'IFS= read -r line' ensures that lines are read exactly as they are, without trimming whitespace.
# '< <(...) ' is process substitution, feeding the output of the command into the while loop.
while IFS= read -r line; do
    # 'awk '{print $NF}'' extracts the last field of the line (the device identifier).
    partitions+=("$(echo "$line" | awk '{print $NF}')")
    # 'sed' is used to strip away the preceding text to isolate just the volume's name/label.
    descriptions+=("$(echo "$line" | sed -E 's/.*Microsoft Basic Data[[:space:]]+//; s/^[[:space:]]+|[[:space:]]+$//')")
done < <(diskutil list external | grep "Microsoft Basic Data")

# Check if the partitions array is empty. If so, no NTFS drives were found.
if [ ${#partitions[@]} -eq 0 ]; then
    echo -e "${RED}No external NTFS partitions found.${NC}"
    exit 1
fi

# --- Drive Selection Menu ---
# Display an interactive menu for the user to select a drive.
echo -e "${BLUE}Please select the drive you want to mount:${NC}"
# PS3 sets the prompt string that the 'select' command will display.
PS3="➡️ Enter a number: "

# The 'select' loop presents the items in the 'descriptions' array as a numbered menu.
select choice in "${descriptions[@]}"; do
    # Check if the user's input ($REPLY) was a valid number from the list.
    if [[ -n "$choice" ]]; then
        # The user made a valid choice. Get the corresponding partition identifier.
        # $REPLY is a special variable that holds the number the user entered. We subtract 1 for the array index.
        PARTITION=${partitions[$REPLY-1]}
        LABEL=$choice
        echo -e "${GREEN}You selected: $LABEL (/dev/$PARTITION)${NC}"
        break # Exit the select loop.
    else
        # The user entered an invalid number.
        echo -e "${RED}Invalid selection. Please try again.${NC}"
    fi
done
# --- End of Drive Selection ---

# --- Mounting Process ---
# Create a safe directory name from the drive label for the mount point.
# This 'sed' command replaces any character that is not a letter, number, dot, underscore, or hyphen with an underscore.
SAFE_LABEL=$(echo "$LABEL" | sed 's/[^a-zA-Z0-9._-]/_/g')
MOUNT_POINT="/Volumes/$SAFE_LABEL"

# Check if the drive is already mounted by macOS (likely as read-only).
# 'mount | grep -q' searches the list of mounted volumes quietly.
if mount | grep -q "/dev/$PARTITION"; then
    echo -e "${YELLOW}Unmounting current instance...${NC}"
    # Unmount the drive using its device identifier to prevent conflicts.
    sudo diskutil unmount "/dev/$PARTITION"
else
    echo -e "${BLUE}Drive is already unmounted.${NC}"
fi

# Create the mount point directory. The '-p' flag prevents errors if the directory already exists.
sudo mkdir -p "$MOUNT_POINT"

# Mount the drive using the ntfs-3g driver with read/write options.
echo -e "${BLUE}💾 Mounting with NTFS-3G...${NC}"
# `sudo` is required to perform a mount operation.
# `"$(which ntfs-3g)"` dynamically finds the path to the ntfs-3g executable.
# The '-o' flag specifies mount options:
#   rw: Mount the filesystem in read-write mode.
#   auto_xattr: Improves compatibility with Finder's extended attributes.
#   defer-permissions: Can help prevent permission issues with files on the drive.
sudo "$(which ntfs-3g)" "/dev/$PARTITION" "$MOUNT_POINT" -o rw,auto_xattr,defer-permissions

echo -e "\n${GREEN}Success! Mounted at: $MOUNT_POINT${NC}"

# Open the newly mounted drive in a Finder window for immediate access.
# '2>/dev/null' suppresses any potential error messages from the 'open' command.
# '&' runs the command in the background, so the script can finish without waiting for the Finder window to close.
open "$MOUNT_POINT" 2>/dev/null &
