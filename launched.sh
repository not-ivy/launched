#!/usr/bin/env bash

# Check dependencies
if ! [ -x "$(command -v jq)" ]; then
  echo 'Error: jq is not installed.' >&2
  exit 1
fi

# Misc functions
function error() {
  echo -e "\033[31m$1\033[0m"
}

function success() {
  echo -e "\033[32m$1\033[0m"
}

function warning() {
  echo -e "\033[33m$1\033[0m"
}

# ask for credentials
echo "Enter account email, or name for lagacy accounts"
read -r username

echo "Enter account password:"
read -r -s password

# Authenticate user
response=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"agent\":{\"name\":\"Minecraft\",\"version\":1},\"username\":\"$username\",\"password\":\"$password\"}" https://authserver.mojang.com/authenticate)

# if response contains error, print errorMessage using jq and exit
if [[ $response == *"errorMessage"* ]]; then
  error "$(echo $response | jq -r '.errorMessage')"
  exit 1
fi
echo "$response"


# jq -r '.total_visits' <<< "$response"