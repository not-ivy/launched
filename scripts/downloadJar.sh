#!/usr/bin/env bash

# TODO: Extra check for windows
if [[ $(uname) == "Darwin" ]]; then
  system="natives-osx"
else
  system="natives-linux"
fi

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
  ./scripts/logs/info.sh "Downloading $version jar..."
  mkdir -p "./data/$version"
  curl -s "$(jq -r ".versions[] | select(.id == \"$version\") | .url" ./data/version_manifest.json <<<cat)" >"./data/$version/version.json"
  mkdir -p "./instances/$version/assets"
  curl -s "$(jq -r '.downloads | .client | .url' "./data/$version/version.json" <<<cat)" -o "./instances/$version/client.jar"
  ./scripts/logs/info.sh "Downloading $version assets..."
  # curl -s "$(jq -r '.libraries[] | .downloads | .artifact | .url' "./data/$version/version.json" <<<cat)" -o "./instances/$version/assets"
  # TODO: Verify sha1 which is '.libraries[] | .downloads | .artifact | .sha1' or '.libraries[] | .downloads | .classifiers | $system | .sha1'
  jq -r '.libraries[] | .downloads | .artifact | .url' "./data/$version/version.json" <<< cat | sed -r 's/null//' | while read -r line; do
    if [ -z "$line" ]; then
      continue
    fi
    ./scripts/logs/info.sh "Downloading $line..."
    curl -x "http://127.0.0.1:9080" "$line" -o "./instances/$version/assets/$(basename "$line")"
  done
  jq -r ".libraries[] | .downloads | .classifiers | .[\"$system\"] | .url" "./data/1.8.9/version.json" <<< cat | sed -r 's/null//' | while read -r line; do
    if [ -z "$line" ]; then
      continue
    fi
    ./scripts/logs/info.sh "Downloading $line..."
    curl -x "http://127.0.0.1:9080" "$line" -o "./instances/$version/assets/$(basename "$line")"
  done
  ./scripts/logs/success.sh "Downloaded."
  # java -cp client.jar net.minecraft.client.main.Main
  break
done
