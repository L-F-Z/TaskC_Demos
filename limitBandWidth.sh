#!/bin/bash

# Check if the bandwidth parameter is provided
if [ -z "$1" ]; then
  echo "Please provide a bandwidth limit in Mbit, e.g., ./limitbandwidth 500"
  exit 1
fi

# Get the bandwidth value from the command-line argument
BANDWIDTH=$1

# Delete existing qdisc (ignore the error if it doesn't exist)
tc qdisc del dev eth0 root 2>/dev/null

# Add a new qdisc
if ! tc qdisc add dev eth0 root handle 1: htb default 10; then
  echo "Failed to add qdisc"
  exit 1
fi

# Add class 1:1 with a rate of 1Gbit
if ! tc class add dev eth0 parent 1: classid 1:1 htb rate 1gbit; then
  echo "Failed to add class 1:1"
  exit 1
fi

# Add subclass 1:10 with a rate limit provided by the command-line argument
if ! tc class add dev eth0 parent 1:1 classid 1:10 htb rate ${BANDWIDTH}mbit ceil ${BANDWIDTH}mbit; then
  echo "Failed to add subclass 1:10"
  exit 1
fi

# Add a filter
if ! tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dst 0.0.0.0/0 flowid 1:10; then
  echo "Failed to add filter"
  exit 1
fi

echo "OUT Bandwidth limit successfully set to ${BANDWIDTH} Mbit/s"

