#!/bin/bash

# Variables
DRUPAL_HOME=/var/www/html

# Test site maintenance username
function checkSMAUsername {
    titleSMA="Site Maintenance Account"
    while ! ( { drush user-information "$smausername" --root="$DRUPAL_HOME"/"$drupalsitedir" | grep -q administrator; } &> /dev/null ); do
        smausername=$(whiptail --title "$titleSMA" --inputbox "\nEnter the site maintenance account username that you've given to the website: " 10 48 3>&1 1>&2 2>&3)
        titleSMA="Wrong Username"
    done
}

# Change directory
SCRIPT_DIR=$(dirname -- "$( readlink -f -- "$0"; )") && cd "$SCRIPT_DIR" || exit

# Display task name
echo -e '\n+-------------------------+'
echo '|   Tripal Installation   |'
echo '+-------------------------+'

# Get user input
if [[ -z ${drupalsitedir} ]]; then
	read -r -p "Enter the name of the directory in which drupal website was installed: " drupalsitedir
fi

# Install dependencies
cd "$DRUPAL_HOME"/"$drupalsitedir"/sites/all/modules/ || exit
drush pm-download -y entity views ctools ds field_group field_group_table field_formatter_class field_formatter_settings ckeditor jquery_update
drush pm-enable -y entity views views_ui ctools ds field_group field_group_table field_formatter_class field_formatter_settings ckeditor jquery_update

# Tripal installation
drush pm-download tripal -y
cd "$DRUPAL_HOME"/"$drupalsitedir"/ || exit
drush pm-enable -y tripal tripal_chado tripal_ds tripal_ws

# Check site maintenance username before proceeding
checkSMAUsername

# Chado installation
echo -e '\n+----------------------+'
echo '|   Installing Chado   |'
echo '+----------------------+'
while [[ $(drush variable-get --root="$DRUPAL_HOME"/"$drupalsitedir" | grep chado_schema_exists | awk '{print $2}') == "true" ]]; do
  whiptail --title "Install Chado" --msgbox --ok-button "OK" --notags "1. Go to http://localhost/""$drupalsitedir""/admin/tripal/storage/chado/install\n2. Click the drop-down menu under Installation/Upgrade.\n3. Select 'New Install of Chado v1.3'.\n4. Click 'Install/Upgrade Chado'.\n-  NOTE: THERE IS NO NEED TO RUN THE DRUSH COMMAND.\n5. Hit 'OK' after completing these steps." 13 65
  drush trp-run-jobs --username="$smausername" --root="$DRUPAL_HOME"/"$drupalsitedir"
done

# Prompt user if raw.githubusercontent.com is inaccessible
while true; do
  ping -c 1 -w 2 raw.githubusercontent.com &> /dev/null
  if [ $? -eq 1 ]; then
    # Ask the user if they want to try different network setup
    if (whiptail --title "Unable to proceed" --yesno --yes-button "Retry" --no-button "Continue" "\n- Unable to connect to raw.githubusercontent.com.\n- For preparing website with chado, connecting to it\n  is necessary.\n- You can 'Continue' if you want but it is advisable\n  to change network configuration and 'Retry'." 13 57) then
        continue
    else
        break
    fi
  fi
done

# Chado preparation
echo -e '\n+---------------------+'
echo '|   Preparing Chado   |'
echo '+---------------------+'
drush trp-prepare-chado --user="$smausername" --root="$DRUPAL_HOME"/"$drupalsitedir"
drush cache-clear all --root="$DRUPAL_HOME"/"$drupalsitedir"

# Ask user if they want to switch back to previous network setup
whiptail --title "Just a Pause" --msgbox "\n- We've noticed that you've switched network before.\n- This would be agood time to change it back if you wish.\n- Do that and click 'Ok'." 11 61
whiptail --title "Just checking" --msgbox --ok-button "Yes" "         Are you sure?" 8 35
while ! ({ ping -c 1 -w 2 example.org; } &> /dev/null); do :; done

# Fix for "Trying to access array offset on value of type null" error that gets displayed
# when we refresh home page after adding some menu links
sed -i "s/return \$defaults/return \$defaults = NULL/" sites/all/modules/field_formatter_settings/field_formatter_settings.module
