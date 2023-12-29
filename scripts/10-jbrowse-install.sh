#!/usr/bin/env bash

# Display task name
echo -e '\n+---------------------------------+'
echo '|   Tripal_JBrowse Installation   |'
echo '+---------------------------------+'

# Install dependencies
if command -v apt-get > /dev/null; then # Install for debian-based distros
  sudo apt-get -y install build-essential curl unzip wget zlib1g-dev
fi

# Prepare environment
cd "$DRUPAL_HOME"/"$drupalsitedir" || exit
mkdir tools/
mkdir -p sites/default/files/jbrowse/data/
sudo chgrp -R www-data sites/default/files/jbrowse/
sudo chmod -R g+w sites/default/files/jbrowse

# Install jbrowse
curl -L -O https://github.com/GMOD/jbrowse/releases/download/1.16.11-release/JBrowse-1.16.11.zip
unzip -q JBrowse-1.16.11.zip
rm JBrowse-1.16.11.zip
mv JBrowse-1.16.11 tools/jbrowse
cd tools/jbrowse/ || exit
./setup.sh

# Install tripal_jbrowse
wget https://github.com/tripal/tripal_jbrowse/archive/refs/tags/7.x-3.0.zip
unzip -q 7.x-3.0.zip
rm 7.x-3.0.zip
mv tripal_jbrowse-7.x-3.0 "$DRUPAL_HOME"/"$drupalsitedir"/sites/all/modules/tripal_jbrowse
drush pm-enable -y tripal_jbrowse_mgmt tripal_jbrowse_page

# Setup tripal_jbrowse
echo -e '\n+--------------------------+'
echo '|   Tripal_JBrowse Setup   |'
echo '+--------------------------+'
drush variable-set tripal_jbrowse_mgmt_settings "{\"data_dir\":\"$DRUPAL_HOME/$drupalsitedir/sites/default/files/jbrowse/data\",\"data_path\":\"$drupalsitedir/sites/default/files/jbrowse/data\",\"bin_path\":\"$DRUPAL_HOME\/$drupalsitedir/tools/jbrowse/bin\",\"link\":\"tools/jbrowse\",\"menu_template\":[]}" --root="$DRUPAL_HOME"/"$drupalsitedir"

# User intervention
whiptail --title "JBrowse Example Data (Volvox)" --msgbox --ok-button "OK" --notags "\nTo see JBrowse example data, go to http://localhost/""$drupalsitedir""/tools/jbrowse/index.html?data=sample_data/json/volvox\n\nTo exit, hit 'OK'." 11 86
