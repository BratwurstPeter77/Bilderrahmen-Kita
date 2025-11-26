#!/bin/bash

# protect_sd.sh
# This script prompts for the SSD path and migrates write-intensive paths to the SSD

# Check if the script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Prompt for SSD path
read -p "Enter the SSD path (e.g., /mnt/ssd): " ssd_path

# Check if the SSD path exists
if [ ! -d "$ssd_path" ]; then
    echo "The specified SSD path does not exist. Please check and try again."
    exit 1
fi

# Function to migrate a directory
migrate_directory() {
    local src_path=$1
    local dest_path=${ssd_path}${src_path}

    # Create destination directory if it doesn't exist
    mkdir -p "$dest_path"

    # Move the directory to the SSD
    mv "$src_path" "$dest_path"

    # Create a symlink from the original location to the new location
    ln -s "$dest_path" "$src_path"
}

# Migrate write-intensive paths
migrate_directory "/var/log"
migrate_directory "/var/tmp"
migrate_directory "/var/cache"

echo "Migration completed successfully!"