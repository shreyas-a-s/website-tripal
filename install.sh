#!/bin/bash

./scripts/1-base-setup.sh
./scripts/2-drush-install.sh
./scripts/3-postgres-setup.sh
./scripts/4-drupal-install.sh
./scripts/5-tripal-install.sh
./scripts/6-blast-install.sh
./scripts/7-daemon-install.sh
./scripts/8-jbrowse-install.sh