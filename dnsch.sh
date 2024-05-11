#!/bin/bash

# Check if the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Backup the original resolv.conf file only if a backup doesn't exist yet
if [[ ! -e /etc/resolv.conf.bak ]]; then
    cp /etc/resolv.conf /etc/resolv.conf.bak
fi

# Function to print usage instructions
usage() {
    echo "Usage: $0 {g|sh|ag|cf|403|bg|rd|el} [-c|--clear] [-s|--set]"
    exit 1
}

# Verify the number of arguments provided
if [[ $# -lt 1 ]]; then
    usage
fi

# A list of all DNSs
declare -A dnsList
dnsList["g",0]="8.8.8.8"; dnsList["g",1]="8.8.4.4"
dnsList["sh",0]="178.22.122.100"; dnsList["sh",1]="185.51.200.2"
dnsList["ag",0]="176.103.130.130"; dnsList["ag",1]="176.103.130.131"
dnsList["cf",0]="1.1.1.1"; dnsList["cf",1]="1.0.0.1"
dnsList["403",0]="10.202.10.202"; dnsList["403",1]="10.202.10.102"
dnsList["bg",0]="185.55.226.26"; dnsList["bg",1]="185.55.225.25"
dnsList["rd",0]="10.202.10.10"; dnsList["rd",1]="10.202.10.11"
dnsList["el",0]="78.157.42.100"; dnsList["el",1]="78.157.42.101"

# Parse the arguments
if [[ $1 == "-s" || $1 == "--set" ]]; then
    # Check if exactly two IP addresses are provided
    if [[ $# -ne 3 ]]; then
        usage
    fi
    # Set the nameservers based on provided IP addresses
    nameservers=("nameserver $2" "nameserver $3")
elif [[ $1 == "-c" || $1 == "--clear" ]]; then
    nameservers=()
else
    # Add the nameservers based on the previous list
    nameservers=("nameserver ${dnsList[$1,0]}" "nameserver ${dnsList[$1,1]}")
    # If the dns wasn't in the list, throw an error
    if [ "${nameservers[0]}" == "nameserver " ]; then
        echo "Invalid option: $1"
        usage
    fi
fi

# Remove all existing nameservers and add new ones atomically
# This avoids potential issues with an empty or partial file
{
    > /etc/resolv.conf.new
    for ns in "${nameservers[@]}"; do
        echo "$ns"
    done
} > /etc/resolv.conf.new

# Safely move the new file to the actual resolv.conf location
mv -f /etc/resolv.conf.new /etc/resolv.conf || { echo "Failed to update resolv.conf"; exit 1; }

# Confirm the changes
echo "The resolv.conf file has been updated:"
cat /etc/resolv.conf
