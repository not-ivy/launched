#!/usr/bin/env bash
auth_player_name="sourTaste000"
version_name="1.8.9"
game_directory="./instances/$version_name/.minecraft"
assets_root="./instances/$version_name/assets"
assets_index_name="indexes/1.8" #!!
auth_uuid="a9c8f9f6-f8a8-4b8f-b8b6-b8f9f6a9c8f9"
auth_access_token="abc"
user_properties=()
user_type="legacy"

java\
--username ${auth_player_name}\
--version ${version_name}\
--gameDir ${game_directory}\
--assetsDir ${assets_root}\
--assetIndex ${assets_index_name}\
--uuid ${auth_uuid}\
--accessToken ${auth_access_token}\
--userProperties ${user_properties}\
--userType ${user_type}