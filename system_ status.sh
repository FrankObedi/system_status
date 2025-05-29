#!/bin/bash

valid_input() {
    # Function to validate the threshold input for each function
    # Arguments:
    #   $1 - Function name (to customize error message)
    #   $2 - Threshold value

    # check if threshold was given
    if [[ -z "$2" ]]; then
        echo "Usage: $1 <cpu_threshold_percentage>"
        return 1
    fi

    # check for valid threshold
    if [[ "$2" -lt 0  ]] || [[ "$2" -gt 100 ]]; then
        if [[ "$1" == "cpu_utilization" ]]; then
            echo "Enter the CPU threshold percentage between 0 to 100"

        elif [[ "$1" == "mem_free" ]]; then
            echo "Enter the free memory threshold percentage between 0 to 100"
        else
            echo "Enter the disk usage threshold percentage between 0 to 100"
        fi
        return 1
    fi

}

cpu_utilization () {
    # Function to check CPU Utilization and compare it with a threshold percentage
    # Usage: cpu_utilization <cpu_threshold_percentage>
    # Arguments:
    #   - cpu_threshold_percentage: The threshold percentage for CPU usage (between 0 and 100)
    # Returns:
    #   - "cpu ok!!" if CPU utilization is below the threshold
    #   - "cpu warning!!" if CPU utilization is above threshold

    # check for valid threshold
    valid_input "cpu_utilization" "$1" || return 1

    local threshold=$1 # get the threshold to use


    # get cpu usage from 'top' in batch mode '-b' for only 1 iteration '-n1'
    # use 'awk' get the sum of the user and system usage fields
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')

    # check if cpu usage is higher than threshold
    local cpu_overloaded=$(echo "$cpu_usage >= $threshold" | bc -l)
    echo "cpu utilization: $cpu_usage"
    if [[ "$cpu_overloaded" -eq 1 ]]; then       
        echo "cpu warning!!"
    else
        echo "cpu ok!!"
    fi
    return 0  
}

mem_free () {
    # Function to check the percentage of free memory and compare it with a threshold
    # Usage: mem_free <free_memory_threshold_percentage>
    # Arguments:
    #   - free_memory_threshold_percentage: The threshold percentage of free memory (between 0 to 100)
    # Returns:
    #   - "memory warning!!" if the memory free is below the threshold
    #   - "memory ok!!" if the memory free is above the threshold

    # validate args
    valid_input "mem_free" "$1" || return 1

    local threshold=$1

    # extract total memory and free memory from 'free' stats
    # use free/total*100 to get percentage 
    local mem_free=$(free | awk '/Mem:/ {printf "%.4f", $4/$2 * 100}')
    

    # calcualte percentage of free memory
    # local free_percent=$(echo "scale=4; 100 - ($mem_free / $mem_total * 100)" | bc -l)
    echo "percent memory free is : $mem_free%"

    local mem_overloaded=$(echo "$mem_free < $threshold" | bc -l)

    if [[ "$mem_overloaded" -eq 1 ]]; then
        echo "memory warning!!"
    else
        echo "memory ok!!"
    fi        
    return 0
}

disk_usage () {
    # Function to check disk usage and display warning if it exceeds a threshold percentage
    # Usage: disk_usage <disk_threshold_percentage>
    # Arguments:
    #   - disk_threshold_percentage: The threshold percentage for disk usage (0-100)
    # Returns:
    #   - "Disk ok!!" if disk usage is below the threshold
    #   - "Disk warning!!" if disk usage is above the threshold

    # validate args
    valid_input "disk_usage" "$1" || return 1

    local threshold=$1
    local flag=0  # flag to indicate if any disk exceeds the threshold

    # find mounted disks (not tempfs) and check each of their disk usages
    while read -r disk usage; do
        # extract the usage for each disk
        local disk_used=${usage%\%}
        if [[ "$disk_used" -gt "$threshold" ]]; then
            echo "$disk usage: $disk_used%"
            echo "Disk warning!!"
            let flag=1 # indicate disk with high usage found
            break;
        else
            echo "$disk usage: $disk_used%"
        fi
    done < <(df -h | awk '/^\/dev/ {print $1, $5}')

    if [[ "$flag" -ne 1 ]]; then
        echo "Disk ok!!"
    fi
    return 0
}

send_report () {
    # Function to send a system status report via email
    # Usage: send_report <email_address>
    # Arguments:
    #   - email_address: The email address to send the report to

    # Check if an email address was given
    if [[ -z "$1" ]]; then
        echo "Usage: send_report <email_address>"
        return 1
    fi

    local email_address=$1
    local sys_report="/tmp/system_report.txt"

    echo "##########################################" > "$sys_report"
    echo "Testing CPU utilization, free memory, disk usage status of the system on $(date)" >> "$sys_report"
    echo "##########################################" >> "$sys_report"

    # call check_all and redirect output to report file
    check_all >> "$sys_report"

    echo "##########################################" >> "$sys_report"
    echo "Capturing the system status" >> "$sys_report"
    echo "Sending email with the system status to $email_address" >> "$sys_report"
    echo "##########################################" >> "$sys_report"

    cat "$sys_report" # print the report to the console


    # Send the report via email
    cat "$sys_report" | mail -s "System Health Report" "$email_address"


    # remove the temporary file
    rm -f "$sys_report"
    return 0

}

check_all(){
    # Function to check CPU utilization, free memory, and disk usage
    # Usage: check_all

    
    cpu_utilization 10
    echo "##########################################"
    mem_free 10
    echo "##########################################"
    disk_usage 50
  
}

send_report "frankobedi6@gmail.com"
