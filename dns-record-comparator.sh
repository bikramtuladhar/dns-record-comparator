#!/bin/bash

# Set up colours
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RESET=$(tput sgr0)

# Function to display help text
display_help() {
    echo "Usage: $0 ZONE Target_Server_1 Target_Server_2 zone_file"
    echo
    echo "This script extracts DNS records from a zone file and compares them against two DNS servers."
    echo
    echo "Arguments:"
    echo "  ZONE              The domain zone to query (e.g., example.com)"
    echo "  Target_Server_1   The first DNS server to query"
    echo "  Target_Server_2   The second DNS server to query"
    echo "  zone_file         Path to the zone file to extract records from"
    echo
    echo "Example:"
    echo "  $0 example.com 1.2.3.4 5.6.7.8 /path/to/zonefile.txt"
    exit 1
}

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    display_help
fi

# Set inputs
ZONE=$1
T1=$2
T2=$3
ZONEFILE=$4

# Input check
if [[ -z $T1 ]] || [[ -z $T2 ]] || [[ -z $ZONE ]] || [[ -z $ZONEFILE ]]; then
    echo "Error: Missing required arguments."
    display_help
fi

# Set counters
ERROR_COUNT=0
WARN_COUNT=0

# Function to extract DNS records from a zone file
extract_dns_records() {
    local zonefile=$1
    awk -v zone="$ZONE" '
    BEGIN { OFS=" " }
    /^[^;]/ {
        gsub(/;.*$/, "")
        if (NF > 0 && !/^\$/) {
            domain = $1
            if (domain == "IN") {
                domain = zone "."
            } else if (domain == "@") {
                domain = zone "."
            } else if (domain !~ /\.$/) {
                domain = domain "." zone "."
            }
            for (i=1; i<=NF; i++) {
                if ($i ~ /^(A|AAAA|CNAME|MX|NS|SOA|TXT|PTR|SRV|CAA|NAPTR|SPF|DNSKEY|DS|RRSIG|NSEC|TLSA)$/) {
                    type = $i
                    print type, domain
                    break
                }
            }
        }
    }
    ' "$zonefile" | sort -u
}

# Function to compare a single record against both servers
compare_record() {
    local record_type=$1
    local domain=$2
    local server1=$3
    local server2=$4

    RESULT_T1=$(dig +short $record_type $domain @$server1 | sort | tr '\n' ',' | sed 's/,$//')
    RESULT_T2=$(dig +short $record_type $domain @$server2 | sort | tr '\n' ',' | sed 's/,$//')

    if [[ $RESULT_T1 != $RESULT_T2 ]]; then
        case "${record_type}" in
            SOA|NS)
                STATUS="${YELLOW}WARN${RESET}"
                WARN_COUNT=$((WARN_COUNT+1))
                ;;
            *)
                STATUS="${RED}ERROR${RESET}"
                ERROR_COUNT=$((ERROR_COUNT+1))
                ;;
        esac
    else
        STATUS="${GREEN}OK${RESET}"
    fi

    printf "| %-5s | %-40s | %-40s | %-40s | %s |\n" \
           "$record_type" \
           "${domain:0:40}" \
           "${RESULT_T1:0:40}" \
           "${RESULT_T2:0:40}" \
           "$STATUS"
}

# Extract records from zone file
echo -e "${BLUE}Extracting DNS records from zone file:${RESET}"
RECORDS=($(extract_dns_records "$ZONEFILE"))

# Print table header
echo -e "\n${BLUE}Comparing extracted records against both servers:${RESET}"
printf "+-------+------------------------------------------+------------------------------------------+------------------------------------------+--------+\n"
printf "| %-5s | %-40s | %-40s | %-40s | %-6s |\n" "Type" "Domain" "Server 1 ($T1)" "Server 2 ($T2)" "Status"
printf "+-------+------------------------------------------+------------------------------------------+------------------------------------------+--------+\n"

# Compare extracted records against both servers
for ((i=0; i<${#RECORDS[@]}; i+=2)); do
    RECORD_TYPE=${RECORDS[i]}
    DOMAIN=${RECORDS[i+1]}
    compare_record "$RECORD_TYPE" "$DOMAIN" "$T1" "$T2"
done

# Print table footer
printf "+-------+------------------------------------------+------------------------------------------+------------------------------------------+--------+\n"

# Output counts
echo -e "\n${RED}ERRORS:${RESET} $ERROR_COUNT\n${YELLOW}WARNINGS:${RESET} $WARN_COUNT"

if [[ $ERROR_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi