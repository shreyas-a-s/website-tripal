#!/usr/bin/env bash

function _install_whiptail {
  if ! command -v whiptail > /dev/null; then # Install whiptail if it is NOT already installed
    if command -v apt-get > /dev/null; then # Install for debian-based linux distros
      sudo apt-get install -y whiptail
    elif command -v dnf > /dev/null; then # Install for newer RHEL-based linux distros
      sudo dnf install -y newt
    elif command -v yum > /dev/null; then # Install for older RHEL-based linux distros
      sudo yum install -y newt
    fi
  fi

  # Exit if whiptail can't be installed
  if ! command -v whiptail > /dev/null; then
    echo "Whiptail can't be installed. Exiting..."
    exit 1
  fi
}

export -f _install_whiptail

