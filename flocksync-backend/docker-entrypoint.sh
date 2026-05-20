#!/usr/bin/env bash
set -e
if [ -n "$FIREBASE_SERVICE_ACCOUNT_JSON" ]; then
  echo "$FIREBASE_SERVICE_ACCOUNT_JSON" > /app/serviceAccountKey.json
fi
exec "$@"