# System Status Script

A Bash script for monitoring system health metrics such as CPU utilization, memory usage, and disk usage. It can also generate and email a detailed system report.

## Features

- Check CPU utilization and compare against a threshold.
- Check percentage of free memory.
- Check disk usage across mounted partitions.
- Generate a summary report and email it to a specified address.


## Files

- `system_status.sh` – Main Bash script for system health monitoring.

## Requirements

- Linux-based operating system
- `mail` command-line utility (usually available via `mailutils` or `mailx`)
- `top`, `awk`, `free`, `df`, `bc` commands (commonly pre-installed on most Linux distributions)

## Usage

Clone the repository and make the script executable:

```bash
git clone https://github.com/yourusername/system-status-script.git
cd system-status-script
chmod +x system_status.sh


