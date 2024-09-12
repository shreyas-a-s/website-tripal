#!/usr/bin/env bash

# Display title of script
if type _printtitle &> /dev/null; then
  _printtitle "INSTALLING - TRIPAL DAEMON"
fi

# Change into drupal directory
cd "$WEB_ROOT"/"$DRUPAL_HOME"/ || exit

# Install dependencies
drush pm-download libraries -y
wget -O sites/all/libraries/PHP-Daemon.tar.gz https://github.com/shaneharter/PHP-Daemon/archive/v2.0.tar.gz
tar -zxf sites/all/libraries/PHP-Daemon.tar.gz -C sites/all/libraries/
mv sites/all/libraries/PHP-Daemon-2.0 sites/all/libraries/PHP-Daemon
rm sites/all/libraries/PHP-Daemon.tar.gz
drush pm-download drushd -y

# Enable dependencies
drush pm-enable -y libraries # Libraries needs to be enabled first otherwise drush will error out
drush pm-enable -y drushd    # saying 'Call to undefined function libraries_get_libraries()'

# Enable tripal daemon
drush pm-enable -y tripal_daemon

# Fix for "Trying to access array offset on value of type null in PHP-Daemon/Core/error_handlers.php on line 118"
sed -i "/is_array/ c\    if\ (\!is_array(\$error)\ ||\ \!isset(\$error['type']))" sites/all/libraries/PHP-Daemon/Core/error_handlers.php

# Start the Daemon
drush trpjob-daemon start

# Set daemon to autostart during boot
echo "@reboot $USER /usr/local/bin/drush trpjob-daemon start --root=$WEB_ROOT/$DRUPAL_HOME" | sudo tee /etc/cron.d/tripal-daemon-autostart > /dev/null

# Set daemon to autostart every hour in case it gets stopped
echo "0 */1 * * * $USER /usr/local/bin/drush trpjob-daemon start --root=$WEB_ROOT/$DRUPAL_HOME" | sudo tee /etc/cron.d/tripal-daemon-autostart-hourly > /dev/null
