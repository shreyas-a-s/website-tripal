#!/bin/bash
echo "####################################################################"
echo "# This works only on the latest debian (currently it's version 12) #"
echo "####################################################################"

# Variables
phpversion=$(apt show php | awk 'NR==2{print $2}' | awk -F ':' '{print $2}' | awk -F '+' '{print $1}')
sed -i '$a\DRUPAL_HOME=/var/www/html' "$HOME"/.bashrc && DRUPAL_HOME=/var/www/html
sed -i '$a\PATH=./vendor/bin:$PATH' "$HOME"/.bashrc && PATH=./vendor/bin:$PATH

function continueORNot {
   read -r -p "Continue? (yes/no): " choice
   case "$choice" in 
     "yes" ) echo "Moving on to next step..";sleep 2;;
     "no" ) echo "Exiting.."; exit 1;;
     * ) echo "Invalid Choice! Keep in mind this is case-sensitive."; continueORNot;;
   esac
}

function checkSMAUsername {
    read -r -p "Enter the site maintenance account username that you've given to the website: " smausername
    echo "Testing username.."
    drush trp-run-jobs --username="$smausername"
    exitstatus=$?
    [ $exitstatus -eq 1 ] && echo "Wrong Username! " && checkSMAUsername
}

# Installing dependencies and setting up base system
sudo apt update && sudo apt upgrade -y && sudo apt install git -y
sudo apt install apache2 -y
cd /etc/apache2/mods-enabled && sudo ln -s ../mods-available/rewrite.load
sudo sed -i '$i<Directory /var/www/html>\n   Options Indexes FollowSymLinks MultiViews\n   AllowOverride All\n   Order allow,deny\n   allow from all\n</Directory>' /etc/apache2/sites-available/000-default.conf
sudo service apache2 restart
sudo apt install php php-dev php-cli libapache2-mod-php php"$phpversion"-mbstring -y
sudo apt install php-pgsql php-gd php-xml php-curl php-apcu php-uploadprogress -y
read -r -p "How much memory to allocate to the website (in MB)? " memorylimit
sudo sed -i "/memory_limit/ c\memory_limit = $memorylimit\M" /etc/php/"$phpversion"/apache2/php.ini
sudo service apache2 restart
sudo apt install postgresql composer -y

# Basic database creation
echo "___Postgres Database Creation___"
read -r -p "Enter a new username: " psqluser
echo "Enter a new password for user $psqluser: "
sudo su - postgres -c "createuser -P $psqluser"
read -r -p "Enter the name for a new database for our website: " psqldb
sudo su - postgres -c "createdb $psqldb -O $psqluser"
psql -U "$psqluser" -d "$psqldb" -h localhost -c "CREATE EXTENSION pg_trgm;"

# Drupal + Drush Installation
cd "$DRUPAL_HOME" || exit
sudo chown -R "$USER" "$DRUPAL_HOME"
read -r -p "Enter the name of new directory to which drupal website needs to be installed: " drupalsitedir
composer create-project drupal/recommended-project:^10 "$drupalsitedir"
cd "$drupalsitedir" || exit
composer require drush/drush
composer require drupal/core
cp ./web/sites/default/default.settings.php ./web/sites/default/settings.php
sudo chown www-data:www-data ./web/sites/default/settings.php
sudo chown www-data:www-data ./web/sites/default/
echo '---------------'
echo '   Site Setup   '
echo '---------------'
echo "Go to http://localhost/""$drupalsitedir""/web/install.php and complete initial setup of website by providing newly created database details, new site maintenance account details, etc"
echo "IMP NOTE: Make sure to note down site maintenance account username."
echo "After completing initial setup, come back and type 'yes' to continue."
continueORNot

# Installing and enabling dependencies of tripal
composer require drupal/entity
composer require drupal/ctools
composer require drupal/ds
composer require drupal/field_group
composer require drupal/field_group_table
composer require drupal/field_formatter_class
composer require drupal/jquery_ui_accordion
drush pm-enable -y entity views views_ui ctools ds field_group field_group_table field_formatter_class jquery_ui jquery_ui_accordion

# Installing and enabling tripal and tripal chado
git clone -b 4.x https://github.com/tripal/tripal.git ./web/modules/contrib/tripal
drush pm-enable -y tripal tripal_chado

# Chado Installation
checkSMAUsername
echo '------------------'
echo '   Install Chado   '
echo '------------------'
echo "Go to http://localhost/""$drupalsitedir""/web/admin/tripal/storage/chado/install"
echo "Click 'Install Chado 1.3'."
echo "NOTE: THERE IS NO NEED TO RUN THE DRUSH COMMAND."
echo "After completing these steps, come back and type 'yes' to continue."
continueORNot
drush trp-run-jobs --username="$smausername"

# Chado Preparation
echo '------------------'
echo '   Prepare Chado   '
echo '------------------'
echo "Go to http://localhost/""$drupalsitedir""/web/admin/tripal/storage/chado/prepare"
echo "Click 'Prepare this site'."
echo "NOTE: THERE IS NO NEED TO RUN THE DRUSH COMMAND."
echo "After completing these steps, come back and type 'yes' to continue."
continueORNot
drush trp-run-jobs --username="$smausername"

# Closing
echo "Installation completed. Press any key to update all modules using composer and exit from installation."
read -r -s -n 1
echo "Doing composer update.."
composer update
drush cache-clear drush
drush cache-clear theme-registry
drush cache-clear router
# drush cache-clear css-js FIX: Why this command errors out saying 'Permission denied in /var/www/html/dw/web/sites/default/files/css'
drush cache-clear render
drush cache-clear plugin
drush cache-clear bin default
drush cache-clear container
drush cache-clear views
echo "Exiting.."
