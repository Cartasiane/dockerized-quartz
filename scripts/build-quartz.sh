#!/bin/bash
set -euo pipefail

QUARTZ_DIR="/usr/src/app/quartz"
VAULT_DIR="/vault"

# Set defaults for optional environment variables
VAULT_DO_GIT_PULL_ON_UPDATE=${VAULT_DO_GIT_PULL_ON_UPDATE:-false}
NOTIFY_TARGET=${NOTIFY_TARGET:-}
CONTENT_FOLDER=${CONTENT_FOLDER:-}

# Determine the content directory (supports subfolder like "wiki" or "public")
if [ -n "$CONTENT_FOLDER" ]; then
  CONTENT_DIR="${VAULT_DIR}/${CONTENT_FOLDER}"
  echo "Building from subfolder: $CONTENT_DIR"
else
  CONTENT_DIR="$VAULT_DIR"
fi

if [ "$VAULT_DO_GIT_PULL_ON_UPDATE" = true ]; then
  echo "Executing git pull in /vault directory"
  cd $VAULT_DIR
  git pull
fi

cd $QUARTZ_DIR

echo "Running Quartz build..."
if [ -n "$NOTIFY_TARGET" ]; then
  apprise -vv --title="Dockerized Quartz" --body="Quartz build has been started." "$NOTIFY_TARGET"
fi

npx quartz build --directory "$CONTENT_DIR" --output /usr/share/nginx/html
BUILD_EXIT_CODE=$?

if [ $BUILD_EXIT_CODE -eq 0 ]; then
  echo "Quartz build completed successfully."
  if [ -n "$NOTIFY_TARGET" ]; then
    apprise -vv --title="Dockerized Quartz" --body="Quartz build completed successfully." "$NOTIFY_TARGET"
  fi
else
  echo "Quartz build failed."
  if [ -n "$NOTIFY_TARGET" ]; then
    apprise -vv --title="Dockerized Quartz" --body="Quartz build failed!" "$NOTIFY_TARGET"
  fi
  exit 1
fi