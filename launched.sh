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

stty sane

# Init folders
if [ ! -d "instances" ]; then
  mkdir instances
fi

if [ ! -d "data" ]; then
  mkdir -p data
fi

./scripts/authenticateUser.sh

./scripts/statusCheck.sh

if [ "$(ls -A instances)" ]; then
  ./scripts/logs/success.sh "Instances folder is not empty."
else
  ./scripts/downloadJar.sh
fi
