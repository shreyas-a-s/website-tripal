#!/usr/bin/env bash

function _is_internet_available {
  printf "Checking internet connectivity. Please wait.."
  if ! ping -c 3 1.1.1.1 &> /dev/null; then
    printf "\nUnable to connect to internet. Check and make sure you are connected to internet before executing the script.\n"
    exit 1
  fi
}

export -f _is_internet_available
