#!/usr/bin/env bash

#  ██████╗ ███╗   ██╗███████╗     ██████╗██╗     ██╗ ██████╗██╗  ██╗
# ██╔═══██╗████╗  ██║██╔════╝    ██╔════╝██║     ██║██╔════╝██║ ██╔╝
# ██║   ██║██╔██╗ ██║█████╗      ██║     ██║     ██║██║     █████╔╝ 
# ██║   ██║██║╚██╗██║██╔══╝      ██║     ██║     ██║██║     ██╔═██╗ 
# ╚██████╔╝██║ ╚████║███████╗    ╚██████╗███████╗██║╚██████╗██║  ██╗
#  ╚═════╝ ╚═╝  ╚═══╝╚══════╝     ╚═════╝╚══════╝╚═╝ ╚═════╝╚═╝  ╚═╝

#      ██╗    ██╗███████╗██████╗ ███████╗██╗████████╗███████╗
#      ██║    ██║██╔════╝██╔══██╗██╔════╝██║╚══██╔══╝██╔════╝
#      ██║ █╗ ██║█████╗  ██████╔╝███████╗██║   ██║   █████╗
#      ██║███╗██║██╔══╝  ██╔══██╗╚════██║██║   ██║   ██╔══╝
#      ╚███╔███╔╝███████╗██████╔╝███████║██║   ██║   ███████╗
#       ╚══╝╚══╝ ╚══════╝╚═════╝ ╚══════╝╚═╝   ╚═╝   ╚══════╝

# ██████╗ ███████╗██████╗ ██╗      ██████╗ ██╗   ██╗███████╗██████╗ 
# ██╔══██╗██╔════╝██╔══██╗██║     ██╔═══██╗╚██╗ ██╔╝██╔════╝██╔══██╗
# ██║  ██║█████╗  ██████╔╝██║     ██║   ██║ ╚████╔╝ █████╗  ██████╔╝
# ██║  ██║██╔══╝  ██╔═══╝ ██║     ██║   ██║  ╚██╔╝  ██╔══╝  ██╔══██╗
# ██████╔╝███████╗██║     ███████╗╚██████╔╝   ██║   ███████╗██║  ██║
# ╚═════╝ ╚══════╝╚═╝     ╚══════╝ ╚═════╝    ╚═╝   ╚══════╝╚═╝  ╚═╝

# Developed for https://BharatGenomeDatabase.org by
# Shreyas A S [https://github.com/shreyas-a-s/website-tripal]
# Sastha Kumar N [https://github.com/Sastha-Kumar-N]
# Sabarinath Subramaniam [https://www.linkedin.com/in/sabarinath-subramaniam-a228014]

# Create log files and append OS info to them
if [ ! -f ~/oneclick-website-deployer.log ] || ! grep -qF 'SYS INFO' ~/oneclick-website-deployer.log; then
  printf -- "--------\
  \nSYS INFO\
  \n--------\
  \n%s\
  \n--------\
  \n" "$(grep -iv 'url' /etc/os-release)" | tee -a ~/oneclick-website-deployer.log ~/oneclick-website-deployer-errors.log > /dev/null
fi

# Append time of execution to log files
printf -- "-------------------------------\
\n%s\
\n-------------------------------\
\n" "$(date)" | tee -a ~/oneclick-website-deployer.log ~/oneclick-website-deployer-errors.log > /dev/null

# Redirect stdout to one log file and stderr to another
exec > >(tee -a ~/oneclick-website-deployer.log) 2> >(tee -a  ~/oneclick-website-deployer-errors.log >&2)

# Define web root folder
export WEB_ROOT=/var/www/html

# Change directory
SCRIPT_DIR=$(dirname -- "$( readlink -f -- "$0"; )") && cd "$SCRIPT_DIR" || exit

# Source functions
for fn in ./functions/*.sh; do
  . "$fn"
done

# Check & prepare environment
_install_whiptail                 # Install whiptail program that poweres the script
_set_whiptail_colors_default      # Apply default whiptail colors
_is_os_supported                  # Check if the OS is on the supported list
_is_internet_available            # Check if system is connected to internet
./scripts/show-about-us-page.sh   # Display the "About Us" page on the screen
./scripts/install-dependencies.sh # Install dependency programs like wget, jq, etc.

# Prompt the user to enter inputs (database creds & memory limit)
while true; do
  _input_db_name       # PostgreSQL Database name
  _input_db_username   # PostgreSQL Database username
  _input_db_pass       # PostgreSQL Database password
  _input_memory_limit  # Maximum amount of memory a PHP script can consume
  # Give user option to edit choices
  whiptail --title "USER SELECTION" --yesno \
    --defaultno \
    --yes-button "Edit" \
    --no-button "Continue" \
    "Database Name: $psqldb\
    \nDatabase User: $psqluser\
    \nDatabase Password: $HIDDEN_PGPASSWORD\
    \nMemory Limit: $memorylimit""MB\
    \n\n       You can edit the data if you want.\
    \n     (ARROW KEYS to move, ENTER to confirm)" \
    14 53
  exitstatus=$?
  if [ $exitstatus  = 0 ]; then
    continue
  else
    break
  fi
done

# Set whiptail BG color to cyan
_set_whiptail_colors_bg_cyan

# Prompt the user to enter inputs (drupal creds)
while true; do
  _input_drupal_dir       # Directory to which Drupal should be installed
  _input_drupal_site_name # Name for website
  _input_drupal_username  # Username to use for Drupal
  _input_drupal_pass      # Password for drupal user
  _input_drupal_mail      # Email to be added to Drupal
  _input_drupal_country   # Default country to be set in Drupal
  # Give user option to edit choices
  whiptail --title "DRUPAL WEBSITE DETAILS" --yesno \
    --defaultno \
    --yes-button "Edit" \
    --no-button "Continue" \
    "Drupal Website Directory: $WEB_ROOT/$DRUPAL_HOME\
    \nDrupal Site Name: $drupal_site_name\
    \nDrupal Username: $drupal_user\
    \nDrupal Password: $hidden_drupal_pass\
    \nDrupal Email: $drupal_mail\
    \nCountry: $drupal_country_name\
    \n\n       You can edit the data if you want.\
    \n     (ARROW KEYS to move, ENTER to confirm)" \
    16 53
  exitstatus=$?
  if [ $exitstatus  = 0 ]; then
    continue
  else
    break
  fi
done

# Prompt user to choose which website components to install
while true; do
  _set_whiptail_colors_bg_magenta # Set whiptail BG color to magenta for selection of components
  website_components=$(whiptail --title "COMPONENTS SELECTION" --checklist \
    "\n         Choose which website components to install\
    \n           (ARROW KEYS to move, SPACE to select,\
    \n      TAB to move between sections, ENTER to confirm):" 14 64 4 \
    "Webform" "[Drupal module used to create Forms]" ON \
    "Tripal Blast" "[Interface for using NCBI Blast+]" ON \
    "Tripal JBrowse" "[Integrate GMOD JBrowse with Tripal]" ON \
    3>&1 1>&2 2>&3)
  exitstatus=$?
  if [ $exitstatus = 1 ]; then
    exit 1
  fi

  if [[ -z $website_components ]]; then # Prompt user if they chose nothing
    _set_whiptail_colors_bg_red # Set whiptail BG color to red indicating warning
    whiptail --title 'ATTENTION PLEASE !!' --yesno \
      --defaultno \
      --yes-button "Go Back" \
      --no-button "Continue" \
      "You did not select any components to install. If this was intended, you can continue. If not, go back and choose the components by pressing SPACE.\
      \n     (ARROW KEYS to move, ENTER to confirm)" \
      11 53
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
      continue
    else
      break
    fi
  else
    break
  fi
done

# Set whiptail colors to default before proceeding
_set_whiptail_colors_default

# Custom scripts
./scripts/install-apache.sh           # Web server used to run website
./scripts/install-php.sh              # Major backend program for Drupal
./scripts/install-psql.sh             # PostgreSQL - the database backend for Drupal
./scripts/install-drush.sh            # Drush is the utility to manage Drupal from cli
./scripts/install-drupal.sh           # Drupal powers the whole website
./scripts/setup-cron.sh               # Replace drupal cron tasks with system cronjob
./scripts/install-tripal.sh           # Install Tripal
./scripts/install-chado.sh            # Install chado database
./scripts/prepare-chado.sh            # Prepare website to work with chado
./scripts/install-tripal-daemon.sh    # Tripal Daemon is used to automate execution of tripal jobs
if [[ -n $website_components ]]; then # Install tripal extensions based on user choice
  [[ $website_components == *"Webform"* ]]        &&  ./scripts/install-webform.sh
  [[ $website_components == *"Tripal Blast"* ]]   &&  ./scripts/install-tripal-blast.sh && ./scripts/setup-sample-blast-db.sh
  [[ $website_components == *"Tripal JBrowse"* ]] &&  ./scripts/install-jbrowse.sh && ./scripts/install-tripal-jbrowse.sh
fi

# Provide users the option for an automatic system reboot
./scripts/auto-system-reboot.sh

