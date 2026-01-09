# Log_export

# **Standard Operating Procedure (SOP)**

Incremental Log Export Using Existing log_export Script

# **Purpose**

The purpose of this document is to define a standardized and repeatable procedure to
export log data incrementally using an extension script built on top of the existing
log_export.py utility.

The native log_export.py script supports exporting data only for a single start-time and
end-time range per execution. It does not provide a mechanism to automatically split large
time ranges into smaller windows such as hourly or daily intervals.

This SOP introduces a controlled method to:

• Divide large time ranges into smaller windows

• Execute multiple exports sequentially

• Resume exports safely in case of interruption

• Merge exported data into a single consolidated output

# **Scope**

This SOP applies to:

•Any log data exported using the log_export framework

•Large or high-volume datasets

•Time-based exports (minutes, hours, days)

This SOP is log-source agnostic and does not apply to any specific data type or log source.

# **Why an Extension Script Is Required**

The existing log_export.py script:

•Accepts a single $StartTime and $EndTime per execution

•Executes one query and exits after completion

•Does not loop over multiple time windows

Because of these limitations, it is not possible to fetch data incrementally (e.g., every hour
or every day) using only log_export.py.

**Therefore, an external shell extension script is required to:**

•Control time slicing

•Repeatedly invoke log_export.py

•Advance the time window until the final end time is reached

Importantly, this approach does not modify the original log_export.py script.

# **Prerequisites**

Before executing this SOP, ensure the following requirements are met:

•Python 3 is installed

•log_export.py is available

•query_config.yaml is configured

•Network access to the console is available

•Sufficient disk space exists for CSV output

•screen and nohup utilities are installed


# **Directory Preparation**

Each export operation must use a dedicated directory to prevent data overwrite.

mkdir /path/to/incremental_export

cd /path/to/incremental_export

cp log_export.py query_config.yaml incremental_export.sh .

**This ensures:**

•Isolation of export runs

•Easy troubleshooting

•Safe resumption

# **Incremental Export Extension Script**

The extension script controls incremental execution by:

•Converting timestamps to epoch format

•Adding a fixed time window (in seconds)

•Looping until the overall end time is reached

# **Extension Script**

#!/bin/bash

START_TIME="2025-05-05T00:00:01"

END_TIME="2025-05-05T05:00:00"

start_epoch=$(date -d "$START_TIME IST" +%s)

end_epoch=$(date -d "$END_TIME IST" +%s)

WINDOW_SECONDS=3600 # 1 hour window

while [ "$start_epoch" -lt "$end_epoch" ]; do

next_epoch=$((start_epoch + WINDOW_SECONDS))

if [ "$next_epoch" -gt "$end_epoch" ]; then

  next_epoch=$end_epoch

fi

start_time_str=$(date -d "@$start_epoch" "+%Y-%m-%dT%H:%M:%S")

end_time_str=$(date -d "@$next_epoch" "+%Y-%m-%dT%H:%M:%S")

python3 log_export.py \

  -q "_fetch * from event where \

  \\$StartTime=$start_time_str AND \
  
  \\$EndTime=$end_time_str limit 100" \
  
  -sid default \
  
  -ft csv

 start_epoch=$next_epoch

done


Window Size Configuration

# Window Type  |   Seconds
 
  4 minutes    |      240 
  
  1 hour       |     3600
  
  1 day        |    86400 

# **Query Construction Rules** 

When writing queries:

•Every field name must be escaped using a backslash

•Timestamp format must follow ISO-8601

•Query syntax must follow official log_export standards

Example escaped fields:

\\$StartTime

\\$EndTime

\\$Stream

\\$Devsrcip

# **Execution Using screen**

Using screen is strongly recommended for long-running exports.

# **Create Screen Session**

screen -S incremental_export

# **Execute Script**

bash incremental_export.sh

# **Detach Safely**

Ctrl + A, then D

# **Reattach**

screen -rd incremental_export

# **Execution Using nohup**

As an alternative to screen, nohup can be used:

nohup bash incremental_export.sh > export.log 2>&1 &

Monitor progress:

tail -f export.log

# **Resume Procedure**

If the export is interrupted:

1.Identify the most recent CSV file

2.Check the last exported timestamp

3.Update START_TIME to last timestamp + 1 second

4.Re-run the extension script

ls -lrt *.csv

less latest.csv

**Post-Processing: Merging CSV Files**

After all exports complete, merge CSV files:

awk 'FNR==1 && NR!=1{next} {print}' $(ls *.csv | sort) > merged.csv

This ensures:

•Single header row

•Chronological ordering

•One consolidated output file

**Validation Checklist**

•All expected CSV files are present

•No time gaps between windows

•No duplicate records

•Only one CSV header

•End time matches the requirement

# **Best Practices**

•Always use screen or nohup

•Use smaller windows for high-volume data

•Never overwrite export directories

•Validate merged data before use

# **Conclusion**

This SOP provides a robust, scalable, and resumable approach to incremental log export by
extending the existing log_export framework without modifying it.

Following this procedure ensures operational consistency, data completeness, and safe
handling of large datasets.
