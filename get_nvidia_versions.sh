#!/bin/bash

URL="https://www.nvidia.com/en-us/drivers/unix/"

# Fetch the page content and strip newlines
CONTENT=$(curl -s "$URL" | tr '\n' ' ')

# Extract Linux x86_64/AMD64/EM64T Latest Production Branch Version
PRODUCTION_VERSION=$(echo "$CONTENT" | grep -oP 'Linux x86_64/AMD64/EM64T.*?Latest Production Branch Version:<\/span> <a href="[^"]+">\K[^<]+')

# Output only the version for command substitution
echo "$PRODUCTION_VERSION"
