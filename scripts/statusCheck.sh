#!/usr/bin/env bash

echo "========== Server Status =========="
# test if mojang.com is online
if ! curl -s -o /dev/null -w "%{http_code}" https://mojang.com/ > /dev/null; then
    ./scripts/logs/error.sh "https://mojang.com is offline"
else
    ./scripts/logs/success.sh "https://mojang.com is online"
fi

# test if minecraft.net is online
if ! curl -s -o /dev/null -w "%{http_code}" https://minecraft.net/ > /dev/null; then
    echo "Minecraft.net is offline"
else 
    ./scripts/logs/success.sh "https://minecraft.net is online"
fi

# test if account.mojang.com is online
if ! curl -s -o /dev/null -w "%{http_code}" https://account.mojang.com/ > /dev/null; then
    ./scripts/logs/error.sh "https://account.mojang.com is offline"
else
    ./scripts/logs/success.sh "https://account.mojang.com is online"
fi

# test if authserver.mojang.com is online
if ! curl -s -o /dev/null -w "%{http_code}" https://authserver.mojang.com/ > /dev/null; then
    ./scripts/logs/error.sh "https://authserver.mojang.com is offline"
else
    ./scripts/logs/success.sh "https://authserver.mojang.com is online"
fi

# test if sessionserver.mojang.com is online
if ! curl -s -o /dev/null -w "%{http_code}" https://sessionserver.mojang.com/ > /dev/null; then
    ./scripts/logs/error.sh "https://sessionserver.mojang.com is offline"
else
    ./scripts/logs/success.sh "https://sessionserver.mojang.com is online"
fi

# test if api.mojang.com is online
if ! curl -s -o /dev/null -w "%{http_code}" https://api.mojang.com/ > /dev/null; then
    ./scripts/logs/error.sh "https://api.mojang.com is offline"
else
    ./scripts/logs/success.sh "https://api.mojang.com is online"
fi

# test if textures.minecraft.net is online
if ! curl -s -o /dev/null -w "%{http_code}" https://textures.minecraft.net/ > /dev/null; then
    ./scripts/logs/error.sh "https://textures.minecraft.net is offline"
else
    ./scripts/logs/success.sh "https://textures.minecraft.net is online"
fi