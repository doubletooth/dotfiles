#!/usr/bin/env bash

RED="\033[1;31m"
GREEN="\033[1;32m"
WARNING="\033[93m"
NOCOLOR="\033[0m"

function print_red() {
  echo "${RED}$1${NOCOLOR}"
}

function print_green() {
  echo "${GREEN}$1${NOCOLOR}"
}

function print_warning() {
  echo "${WARNING}$1${NOCOLOR}"
}

print_green "Exiting cleanly"
exit 0
