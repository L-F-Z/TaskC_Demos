#!/bin/bash  

STATUS_FILE="./flag.txt" 
CHECK_INTERVAL=3   
WAIT_BEFORE_EXIT=3
LOG_FILE="./monitor.log"

get_cpu_usage() {  
    CPU=($(grep '^cpu ' /proc/stat))  
    # idle + iowait  
    idle1=$((CPU[4] + CPU[5]))  
    total1=0  
    for value in "${CPU[@]:1}"; do  
        total1=$((total1 + value))  
    done  

    sleep "$CHECK_INTERVAL"  

    CPU=($(grep '^cpu ' /proc/stat))  
    idle2=$((CPU[4] + CPU[5]))  
    total2=0  
    for value in "${CPU[@]:1}"; do  
        total2=$((total2 + value))  
    done  

    total_diff=$((total2 - total1))  
    idle_diff=$((idle2 - idle1))  

    if [ "$total_diff" -eq 0 ]; then  
        usage="0.00"  
    else  
        usage=$(echo "scale=5; 100 * ($total_diff - $idle_diff) / $total_diff" | bc)  
    fi  

    if [[ "$usage" == .* ]]; then  
        usage="0$usage"  
    fi  

    echo "$usage"  
}  

get_mem_usage() {  
    mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')  
    mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')  
    mem_used=$((mem_total - mem_available))  
    if [ "$mem_total" -eq 0 ]; then  
        mem_usage="0.00"  
    else  
        mem_usage=$(echo "scale=5; 100 * $mem_used / $mem_total" | bc)  
    fi  

    if [[ "$mem_usage" == .* ]]; then  
        mem_usage="0$mem_usage"  
    fi  

    echo "$mem_usage"  
}  

check_taskc_test_done() {  
    if [ -f "$STATUS_FILE" ]; then  
        status=$(grep '^TASKC_TEST=' "$STATUS_FILE" | awk -F '=' '{print $2}' | tr -d '[:space:]')  
        if [ "$status" == "done" ]; then  
            return 0
        fi  
    fi  
    return 1
}  

while true; do  
    cpu_usage=$(get_cpu_usage)  
    mem_usage=$(get_mem_usage) 
    timestamp=$(date +%s) 
    # log to file
    echo "${timestamp}, ${cpu_usage}, ${mem_usage}" >> "$LOG_FILE"

    if check_taskc_test_done; then  
        sleep "$WAIT_BEFORE_EXIT"  
        echo "done" 
        exit 0  
    fi  
done