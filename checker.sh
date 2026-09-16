#!/bin/sh

# Værdierne kan gives af Docker Compose.
# Teksten efter :- er en standardværdi, hvis variablen ikke er sat.
URL="${CHECK_URL:-http://web/}"
INTERVAL="${CHECK_INTERVAL:-5}"
TIMEOUT="${CHECK_TIMEOUT:-3}"
SLOW_THRESHOLD="${SLOW_THRESHOLD:-1.0}"
LOG_FILE="${LOG_FILE:-/logs/checker.log}"

# Sørg for, at mappen til logfilen findes.
mkdir -p "$(dirname "$LOG_FILE")"

echo "Starting checker: url=$URL interval=${INTERVAL}s timeout=${TIMEOUT}s slow>${SLOW_THRESHOLD}s"

while true; do
  timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

  # Send requestet, men gem ikke HTML-indholdet.
  # curl udskriver kun statuskode og samlet svartid.
  result=$(curl \
    --silent \
    --show-error \
    --output /dev/null \
    --connect-timeout "$TIMEOUT" \
    --max-time "$TIMEOUT" \
    --write-out '%{http_code} %{time_total}' \
    "$URL" 2>/tmp/curl-error)

  curl_exit=$?

  if [ "$curl_exit" -ne 0 ]; then
    error=$(tr '\n' ' ' </tmp/curl-error)
    line="$timestamp DOWN curl_exit=$curl_exit error=\"$error\""
  else
    status_code=$(printf '%s\n' "$result" | cut -d' ' -f1)
    response_time=$(printf '%s\n' "$result" | cut -d' ' -f2)

    if [ "$status_code" != "200" ]; then
      line="$timestamp ERROR status=$status_code time=${response_time}s"
    elif awk "BEGIN { exit !($response_time > $SLOW_THRESHOLD) }"; then
      line="$timestamp SLOW status=$status_code time=${response_time}s threshold=${SLOW_THRESHOLD}s"
    else
      line="$timestamp OK status=$status_code time=${response_time}s"
    fi
  fi

  # tee viser linjen på skærmen og føjer den til logfilen.
  echo "$line" | tee -a "$LOG_FILE"

  sleep "$INTERVAL"
done