#!/usr/bin/env bash

./scripts/logs/warning.sh "Instances folder is empty, please choose a version to download:"
# Download versions list if it doesn't exist
if [ ! -f "data/version_manifest.json" ]; then
  if curl -s -o ./data/version_manifest.json https://launchermeta.mojang.com/mc/game/version_manifest.json; then
    ./scripts/logs/success.sh "Version manifest downloaded."
  else
    ./scripts/logs/error.sh "Version manifest download failed."
    exit 1
  fi
fi

# jq -r '.versions[] | .type' <<<"$(cat ./data/version_manifest.json)" | xargs -I {} echo "{} - {}"
select version in $(jq -r '.versions[] | .id' <<<"$(cat ./data/version_manifest.json)"); do
  if [ -z "$version" ]; then
    ./scripts/logs/error.sh "Invalid version. The program will now quit."
    exit 1
  fi
  ./scripts/logs/info.sh "Downloading $version..."
  mkdir -p "./data/$version"
  curl -s "$(jq -r ".versions[] | select(.id == \"$version\") | .url" ./data/version_manifest.json <<<cat)" >"./data/$version/version.json"
  mkdir -p "./instances/$version"
  curl -s "$(jq -r '.downloads | .client | .url' "./data/$version/version.json" <<<cat)" -o "./instances/$version/client.jar"
  ./scripts/logs/success.sh "Downloaded."
  break
done
