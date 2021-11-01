#!/usr/bin/env bash

if [ ! -f ".response.json.gpg" ]; then
  if [ ! -f ".auth.json.gpg" ]; then
    # ask for credentials
    ./scripts/logs/info.sh "Enter email, or name for lagacy accounts:"
    read -r username

    ./scripts/logs/info.sh "Enter account password:"
    read -r -s password
  else
    ./scripts/logs/info.sh "Decrypting credentials... (May prompt for password)"
    gpg .auth.json.gpg
    # get username
    username=$(jq -r '.username' .auth.json)
    # get password
    password=$(jq -r '.password' .auth.json)
    rm .auth.json
    ./scripts/logs/info.sh "Authenticating..."
  fi
  # Authenticate and save the password and username
  response=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"agent\":{\"name\":\"Minecraft\",\"version\":1},\"username\":\"$username\",\"password\":\"$password\"}" https://authserver.mojang.com/authenticate)
  # test if response has no content
  if [ -z "$response" ]; then
    ./scripts/logs/error.sh "Request to mojang auth server failed."
    exit 1
  fi
  if [[ $response == *"errorMessage"* ]]; then
    ./scripts/logs/error.sh "$(jq '.errorMessage' <<<"$response")"
    exit 1
  else
    ./scripts/logs/success.sh "Authentication successful."
    if [ ! -f ".auth.json.gpg" ]; then
      echo "Saving username and password to file... (May prompt for password)"
      echo "{\"username\":\"$username\", \"password\": \"$password\"}" >.auth.json
      gpg -c .auth.json
      rm .auth.json
      ./scripts/logs/success.sh "Saved."
    fi
    ./scripts/logs/info.sh "Saving auth response to file... (May prompt for password)"
    echo "$response" >.response.json
    gpg -c .response.json
    rm .response.json
    ./scripts/logs/success.sh "Saved."
    unset response
    unset password
    unset username
  fi
else
  ./scripts/logs/info.sh "Decrypting credentials... (May prompt for password)"
  gpg .response.json.gpg
  ./scripts/logs/info.sh "Refreshing token..."
  response=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"accessToken\": \"$(jq -r '.accessToken' .response.json)\", \"clientToken\": \"$(jq -r '.clientToken' .response.json)\", \"selectedProfile\": {\"id\": \"$(jq -r '.selectedProfile | .id' .response.json)\", \"name\": \"$(jq -r '.selectedProfile | .name' .response.json)\"}}" https://authserver.mojang.com/refresh)
  if [ -z "$response" ]; then
    ./scripts/logs/error.sh "Request to mojang auth server failed."
    exit 1
  fi
  rm .response.json
  if [[ $response == *"errorMessage"* ]]; then
    ./scripts/logs/error.sh "$(jq '.errorMessage' <<<"$response")"
    exit 1
  else
    ./scripts/logs/success.sh "Refresh successful."
    ./scripts/logs/info.sh "Saving response to file... (May prompt for password)"
    echo "$response" >.response.json
    gpg -c .response.json
    rm .response.json
    ./scripts/logs/success.sh "Saved."
    unset response
    unset password
    unset username
  fi
fi
