#!/usr/bin/env bash

# Check dependencies
if ! [ -x "$(command -v jq)" ]; then
  ./scripts/logs/error.sh 'Error: jq is not installed.'
  exit 1
fi

# ask for credentials
echo "Enter email, or name for lagacy accounts:"
read -r username

echo "Enter account password:"
read -r -s password

# Authenticate and save the password and username
response=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"agent\":{\"name\":\"Minecraft\",\"version\":1},\"username\":\"$username\",\"password\":\"$password\"}" https://authserver.mojang.com/authenticate)
if [[ $response == *"errorMessage"* ]]; then
  ./scripts/logs/error.sh "$(jq '.errorMessage' <<<"$response")"
  exit 1
else
  ./scripts/logs/success.sh "Authentication successful."
  ./scripts/logs/success.sh "Saving username and password to file... (May prompt for password)"
  echo "$username:$password" >.auth.json
  gpg --batch --yes --passphrase-file .auth.json --symmetric .auth.json
  rm .auth.json
  ./scripts/logs/success.sh "Saved."
fi

# Check services
./scripts/statusCheck.sh

if [ ! -d "instances" ]; then
  mkdir instances
fi

if [ "$(ls -A instances)" ]; then
  ./scripts/logs/success.sh "Instances folder is not empty."
else
  ./scripts/logs/success.sh "Instances folder is empty, please choose a version:"

fi

# jq -r '.total_visits' <<< "$response"
