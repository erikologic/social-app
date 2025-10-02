#!/bin/sh
set -e

echo "Waiting for feedgen publisher DID..."

DID_FILE="/shared/publisher-did.txt"
TIMEOUT=60
ELAPSED=0

while [ ! -f "$DID_FILE" ]; do
  if [ $ELAPSED -ge $TIMEOUT ]; then
    echo "ERROR: Timeout waiting for feedgen DID. Proceeding with default..."
    break
  fi
  sleep 2
  ELAPSED=$((ELAPSED + 2))
done

if [ -f "$DID_FILE" ]; then
  PUBLISHER_DID=$(cat "$DID_FILE" | tr -d '\n\r ')
  if [ -n "$PUBLISHER_DID" ]; then
    echo "Using feedgen publisher DID: $PUBLISHER_DID"
    export FEED_OWNER_DID="$PUBLISHER_DID"
  else
    echo "WARNING: DID file is empty. Using default from env..."
  fi
else
  echo "WARNING: DID file not found. Using default from env..."
fi

echo "Starting bskyweb..."
exec /usr/bin/bskyweb serve
