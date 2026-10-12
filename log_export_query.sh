#!/bin/bash

# Define the start and end times
START_TIME="2025-05-05T00:00:01"
END_TIME="2025-05-05T05:00:00"

# Convert times to seconds since epoch
start_epoch=$(date -d "$START_TIME IST" +%s)
end_epoch=$(date -d "$END_TIME IST" +%s)

# Loop over each hour
while [ "$start_epoch" -lt "$end_epoch" ]; do
  # Calculate end of the current 1-hour window
  next_epoch=$((start_epoch + 240))
  
  # Ensure next_epoch doesn't go beyond the original END_TIME
  if [ "$next_epoch" -gt "$end_epoch" ]; then
    next_epoch=$end_epoch
  fi

  # Format times in required format
  start_time_str=$(date -d "@$start_epoch" "+%Y-%m-%dT%H:%M:%S")
  end_time_str=$(date -d "@$next_epoch" "+%Y-%m-%dT%H:%M:%S")

  echo "Running export from $start_time_str to $end_time_str"
  python3 log_export.py -q "_fetch * from event where \$Stream=AUTHENTICATION AND \$Devsrcip=64.227.165.211 AND \$StartTime=$start_time_str AND \$EndTime=$end_time_str limit 100" -sid training  -ft csv

  # Move to next interval
  start_epoch=$next_epoch
done




