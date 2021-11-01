#!/usr/bin/env bash

# Check dependencies
if ! [ -x "$(command -v jq)" ]; then
  ./scripts/logs/error.sh 'Error: jq is not installed.'
  exit 1
fi
if ! [ -x "$(command -v gpg)" ]; then
  ./scripts/logs/error.sh 'Error: gpg is not installed.'
  exit 1
fi

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
  ./scripts/logs/success.sh "Saving auth response to file..."
  echo "$response" >.response.json
fi

# Check services
./scripts/statusCheck.sh

if [ ! -d "instances" ]; then
  mkdir instances
fi

if [ ! -d "data" ]; then
  mkdir -p data
fi

if [ "$(ls -A instances)" ]; then
  ./scripts/logs/success.sh "Instances folder is not empty."
else
  ./scripts/logs/warning.sh "Instances folder is empty, please choose a version to download:"
  # Download versions list if it doesn't exist
  if [ ! -f "data/version_manifest.json" ]; then
    curl -s -o data/version_manifest.json https://launchermeta.mojang.com/mc/game/version_manifest.json
  fi
  
  # jq -r '.versions[] | .type' <<<"$(cat ./data/version_manifest.json)" | xargs -I {} echo "{} - {}"
  select version in $(jq -r '.versions[] | .id' <<<"$(cat ./data/version_manifest.json)"); do
    if [ -z "$version" ]; then
      ./scripts/logs/error.sh "Invalid version. The program will now quit."
      exit 1
    fi
    ./scripts/logs/info.sh "Downloading $version..."
    mkdir -p "./data/$version"
    curl -s "$(jq -r ".versions[] | select(.id == \"$version\") | .url" <<< cat ./data/version_manifest.json)" > "./data/$version/version.json"
    mkdir -p "./instances/$version"
    curl -s "$(jq -r '.downloads | .client | .url' <<< cat "./data/$version/version.json")" -o "./instances/$version/client.jar"
    ./scripts/logs/success.sh "Downloaded."
    break
  done
fi
