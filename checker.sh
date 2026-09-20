#!/bin/sh


URL="${CHECK_URL:-http://web/}" #The text after :- is a default value if the variable is not set. 
INTERVAL="${CHECK_INTERVAL:-5}"
TIMEOUT="${CHECK_TIMEOUT:-3}"
SLOW_THRESHOLD="${SLOW_THRESHOLD:-1.0}"
LOG_FILE="${LOG_FILE:-/logs/checker.log}"  # This line makes sure that the data is stored within the log file, the data will not be lost even if you remove the container from docker desktop.

mkdir -p "$(dirname "$LOG_FILE")" #This line ensure s that the directory for the log file exists.

echo "Starting checker: url=$URL interval=${INTERVAL}s timeout=${TIMEOUT}s slow>${SLOW_THRESHOLD}s"

# This line of code is a loop that runs every 5 seconds. While active it checks the status of the website as well as marking down the time, date and status in our log file.
while true; do
  timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')


  # This sends the request, does doesn't save the HTML content. While the curl command only gives the status code and answer time.
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

  # tee shows the line on the screen and adds it to the log file.
  echo "$line" | tee -a "$LOG_FILE"

  sleep "$INTERVAL" #sleep prevents the loop from running faster than your computer can handle, while preventing the log file from being overloaded with data.
done