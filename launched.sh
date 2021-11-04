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
    rm .auth.json.gpg
    exit 1
  else
    ./scripts/logs/success.sh "Authentication successful."
    if [ ! -f ".auth.json.gpg" ]; then
      echo "Saving username and password to file... (May prompt for password)"
      echo "{\"username\":\"$username\", \"password\": \"$password\"}" > .auth.json
      gpg -c .auth.json
      rm .auth.json
      ./scripts/logs/success.sh "Saved."
    fi
    ./scripts/logs/info.sh "Saving auth response to file... (May prompt for password)"
    echo "$response" >.response.json
    gpg -c .response.json
    rm .response.json
    ./scripts/logs/success.sh "Saved."
  fi
else
  ./scripts/logs/info.sh "Decrypting credentials... (May prompt for password)"
  gpg .response.json.gpg
  ./scripts/logs/info.sh "Refreshing token..."
  response=$(curl -s -X POST -H "Content-Type: application/json" -d "{\"accessToken\": \"$(jq -r '.accessToken' .response.json)\", \"clientToken\": \"$(jq -r '.clientToken' .response.json)\", \"selectedProfile\": {\"id\": \"$(jq -r '.selectedProfile | .id' .response.json)\", \"name\": \"$(jq -r '.selectedProfile | .name' .response.json)\"}}" https://authserver.mojang.com/refresh)
  if [ -z "$response" ]; then
    ./scripts/logs/error.sh "Request to mojang auth server failed."
    rm .response.json
    exit 1
  fi
  if [[ $response == *"errorMessage"* ]]; then
    ./scripts/logs/error.sh "$(jq '.errorMessage' <<<"$response")"
    curl -s -X POST -H "Content-Type: application/json" -d "{\"accessToken\": \"$(jq -r '.accessToken' .response.json)\", \"clientToken\": \"$(jq -r '.clientToken' .response.json)\"}" https://authserver.mojang.com/invalidate
    rm .response.json
    rm .response.json.gpg
    exit 1
  else
    ./scripts/logs/success.sh "Refresh successful."
    ./scripts/logs/info.sh "Saving response to file... (May prompt for password)"
    echo "$response" >.response.json
    gpg -c .response.json
    rm .response.json
    ./scripts/logs/success.sh "Saved."
  fi
fi

if [ "$(ls -A instances)" ]; then
  ./scripts/logs/success.sh "Instances folder is not empty."
else
  if [[ $(uname) == "Darwin" ]]; then
    system="natives-osx"
  else
    system="natives-linux"
  fi

  ./scripts/logs/warning.sh "Instances folder is empty, please choose a version to download:"
  # Download versions list if it doesn't exist
  ./scripts/logs/info.sh "Downloading version manifest..."
  if [ ! -f "data/version_manifest.json" ]; then
    if curl --progress-bar -o ./data/version_manifest.json https://launchermeta.mojang.com/mc/game/version_manifest.json; then
      ./scripts/logs/success.sh "Version manifest downloaded."
    else
      ./scripts/logs/error.sh "Version manifest download failed."
      exit 1
    fi
  fi

  select version in $(jq -r '.versions[] | .id' <<<"$(cat ./data/version_manifest.json)"); do
    if [ -z "$version" ]; then
      ./scripts/logs/error.sh "Invalid version. The program will now quit."
      exit 1
    fi
    ./scripts/logs/info.sh "Input name of the instance:"
    read -r name
    if [ -d "./instances/$name" ]; then
      ./scripts/logs/error.sh "Directory with the same name already exists."
      exit 1
    fi
    ./scripts/logs/info.sh "Downloading $version jar..."
    mkdir -p "./data/$name"
    mkdir -p "./instances/$name/libraries"
    if [ ! -f "./data/$version/version.json" ]; then
      curl --progress-bar "$(jq -r ".versions[] | select(.id == \"$version\") | .url" ./data/version_manifest.json <<<cat)" > "./data/$version/version.json"
    fi
    curl --progress-bar "$(jq -r '.downloads | .client | .url' "./data/$version/version.json" <<<cat)" -o "./instances/$name/client.jar"
    ./scripts/logs/info.sh "Downloading $version libraries..."
    # TODO: Verify sha1 which is '.libraries[] | .downloads | .artifact | .sha1' or '.libraries[] | .downloads | .classifiers | $system | .sha1'
    jq -r '.libraries[] | .downloads | .artifact | .url' "./data/$version/version.json" <<<cat | sed -r 's/null//' | while read -r line; do
      if [ -z "$line" ]; then
        continue
      fi
      ./scripts/logs/info.sh "Downloading $line..."
      curl --progress-bar "$line" -o "./instances/$name/libraries/$(basename "$line")"
    done
    jq -r ".libraries[] | .downloads | .classifiers | .[\"$system\"] | .url" "./data/$version/version.json" <<<cat | sed -r 's/null//' | while read -r line; do
      if [ -z "$line" ]; then
        continue
      fi
      ./scripts/logs/info.sh "Downloading $line..."
      curl --progress-bar "$line" -o "./instances/$name/libraries/$(basename "$line")"
    done
    ./scripts/logs/success.sh "Downloaded."
    break
  done
fi

# list the files present in the instances folder and save it to an array
files=()
while IFS='' read -r line; do files+=("$(pwd)/instances/1point8/libraries/$line"); done < <(ls instances/1point8/libraries)
classpath=$(IFS=: ; echo "${files[*]}") 

# cd ./instances/$name
# java -Djava.library.path="$(pwd)/instances/$name/libraries" -cp "$classpath:$(pwd)/instances/$name/client.jar" "$(jq -r '.mainClass' "../../data/$version/version.json" <<<cat)"
# Exception in thread "main" java.lang.UnsatisfiedLinkError: no lwjgl in java.library.path: /Users/sourtaste000/Developer/launched/instances/1point8/libraries/
#         at java.base/java.lang.ClassLoader.loadLibrary(ClassLoader.java:2429)
#         at java.base/java.lang.Runtime.loadLibrary0(Runtime.java:818)
#         at java.base/java.lang.System.loadLibrary(System.java:1989)
#         at org.lwjgl.Sys$1.run(Sys.java:73)
#         at java.base/java.security.AccessController.doPrivileged(AccessController.java:318)
#         at org.lwjgl.Sys.doLoadLibrary(Sys.java:66)
#         at org.lwjgl.Sys.loadLibrary(Sys.java:95)
#         at org.lwjgl.Sys.<clinit>(Sys.java:112)
#         at bsu.I(SourceFile:2462)
#         at net.minecraft.client.main.Main.main(SourceFile:40)
# LETS GOOOO ONE STEP