#!/usr/bin/env bash

# Display title of script
if type _printtitle &> /dev/null; then
  _printtitle "INSTALLING - DRUPAL"
fi

# Install Drupal
sudo chown -R "$USER" "$WEB_ROOT"
cd "$WEB_ROOT" || exit
[ -f index.html ] && mv index.html index.html.orig
drush dl drupal --drupal-project-rename="$DRUPAL_HOME"

# Setup Drupal
cd "$DRUPAL_HOME" || exit
cp sites/default/default.settings.php sites/default/settings.php
mkdir sites/default/files/
sudo chgrp -R www-data sites/default/files/
sudo chmod g+rw sites/default/files/

drush site-install standard --db-url=pgsql://"$psqluser":"$PGPASSWORD"@localhost:5432/"$psqldb" --account-mail="$drupal_mail" --account-name="$drupal_user" --account-pass="$drupal_pass" --site-mail="$drupal_mail" --site-name="$drupal_site_name" install_configure_form.site_default_country="$drupal_country_code" -y

# Set temp-path for drupal to prevent issues in future
mkdir -p "$WEB_ROOT"/"$DRUPAL_HOME"/sites/default/files/tmp/
sudo chgrp www-data "$WEB_ROOT"/"$DRUPAL_HOME"/sites/default/files/tmp/
chmod g+w "$WEB_ROOT"/"$DRUPAL_HOME"/sites/default/files/tmp/
drush variable-set file_temporary_path "$WEB_ROOT"/"$DRUPAL_HOME"/sites/default/files/tmp --root="$WEB_ROOT"/"$DRUPAL_HOME"

# Prompt user to login to Drupal
whiptail --title "DRUPAL SETUP" --msgbox \
  --ok-button "OK" \
  --notags \
  "Drupal is installed and setup.\
  \n\n1. Now you can go to http://localhost/""$DRUPAL_HOME"" and test out your site by logging in with your drupal username and password.\
  \n2. Press ENTER to continue." 13 56

# Unset PGPASSWORD
unset PGPASSWORD
