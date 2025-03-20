#!/usr/bin/env bash

###########################
# Gitlab Runner Installer #
###########################

# Pre Steps
# 1. Install Mac OS
# 2. Run the following command in a terminal:
# /bin/bash -c "$(curl -fsSL https://gitlab.com/toptracer/toptracer-community-client/mac-gitlab-runner/install.sh)"


link_volume() {
    # Get the list of external disk identifiers
    external_disks=($(diskutil list external | awk '/disk[0-9]/{print $NF}' | grep 'disk' | sort -u))

    # Initialize an array to store external volume names
    volumes=()

    # Loop through each external disk and get its volume name
    for disk in "${external_disks[@]}"; do
        vol_name=$(diskutil info "$disk" | awk -F': ' '/Volume Name/{print $2}' | sed 's/^ *//')
        if [[ -n "$vol_name" && -d "/Volumes/$vol_name" ]]; then
            volumes+=("$vol_name")
        fi
    done

    # Check if any external volumes were found
    if [[ ${#volumes[@]} -ne 0 ]]; then
        # Display external volume options
        echo "Choose a external volume to store the tart images."
        for i in "${!volumes[@]}"; do
            echo "$((i+1))) ${volumes[$i]}"
        done

        # Ensure output is flushed before prompting
        echo ""

        # Prompt user for selection
        printf "Enter the number of the volume to choose (or press Enter to skip): "
        read choice

        # Default to no selection if Enter is pressed
        if [[ -z "$choice" ]]; then
            echo "No volume selected."
        elif ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#volumes[@]} )); then
            echo "Invalid selection."
        else
            # Get the selected external volume
            selected_volume="${volumes[$((choice-1))]}"
            mkdir /Volumes/$selected_volume/tart
            ln -s /Volumes/$selected_volume/tart ~/.tart
        fi
    fi
}

CURRENT_USER=$(logname)

# Prompt user for the GitLab token
read -p "Enter your GitLab registration token: " GITLAB_TOKEN

link_volume

# Install homebrew
echo "Install homebrew"
/bin/bash -c "$(curl -fsSL https://raw.githubusercon<tent.com/Homebrew/install/HEAD/install.sh)"

# Install Gitlab Runner, Tart and Gitlab Tart Executor
echo "Install gitlab-runner, tart and gitlab-tart-executor, iTerm"
brew install gitlab-runner cirruslabs/cli/tart gitlab-tart-executor iterm2

echo "Disable sleep and display sleep"
sudo pmset -a sleep 0 displaysleep 0 networkoversleep 0 tcpkeepalive 1 autorestart 1

# set DHCP Lease Time
echo "Set DHCP lease time"
defaults write /Library/Preferences/SystemConfiguration/com.apple.InternetSharing.default.plist bootpd -dict DHCPLeaseTimeSecs -int 600

echo "Enable Remote Login"
sudo systemsetup -setremotelogin on

echo "Register gitlab-runner"
sudo gitlab-runner register --non-interactive --name "$(scutil --get ComputerName)" --url "https://gitlab.com" --token "$GITLAB_TOKEN" --executor "custom" --request-concurrency 1 --feature-flags "FF_RESOLVE_FULL_TLS_CHAIN:false" --custom-config-exec "gitlab-tart-executor" --custom-config-args "config" --custom-prepare-exec "gitlab-tart-executor" --custom-prepare-args "prepare" --custom-prepare-args "--concurrency" --custom-prepare-args "1" --custom-prepare-args "--cpu" --custom-prepare-args "auto" --custom-prepare-args "--memory" --custom-prepare-args "auto" --custom-run-exec "gitlab-tart-executor" --custom-run-args "run" --custom-cleanup-exec "gitlab-tart-executor" --custom-cleanup-args "cleanup"

sudo brew services start gitlab-runner

echo "Setup system-updates"
sudo sh -c "cat <<EOF > /Library/Scripts/mac-update.sh
#!usr/bin/env sh
sudo -u $CURRENT_USER brew update
sudo -u $CURRENT_USER brew upgrade
sudo -u $CURRENT_USER brew cleanup
sudo -u $CURRENT_USER tart pull ghcr.io/cirruslabs/macos-sequoia-xcode:latest
softwareupdate -ia 
shutdown -r now
EOF"

sudo chmod 755 /Library/Scripts/mac-update.sh

sudo sh -c 'cat <<EOF > /Library/LaunchDaemons/com.toptracer.mac-update.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>com.toptracer.mac-update</string>

        <key>ProgramArguments</key>
        <array>
            <string>/Library/Scripts/mac-update.sh</string>
        </array>

        <key>StartCalendarInterval</key>
        <dict>
            <key>Hour</key>
            <integer>2</integer>  <!-- Run at 2 AM -->
            <key>Minute</key>
            <integer>0</integer>
        </dict>

        <key>RunAtLoad</key>
        <false/>

        <key>StandardOutPath</key>
        <string>/var/log/mac-update.log</string>
        <key>StandardErrorPath</key>
        <string>/var/log/mac-update.log</string>
    </dict>
</plist>
EOF'

sudo launchctl load /Library/LaunchDaemons/com.toptracer.mac-update.plist
