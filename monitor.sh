#!/bin/bash

set -e

source "$(dirname "$0")/config.env"

mkdir -p "$(dirname "$REPORT_LOG")"

trap 'echo "ERROR : SCRIPT FAILED....." >> "$ALERT_LOG"' ERR


timestamp() {
	date "+%Y-%m-%d %H:%M:%S"
}


log() {
	echo "$(timestamp) $1" >> "$REPORT_LOG"
}


alert() {
	echo "$(timestamp) ALERT: $1" >> "$ALERT_LOG"
	log "ALERT TRIGGERED: $1"
}


check_disk() {
	local usage 
	usage=$( df / | awk ' NR==2 {gsub("%",""); print $5 } ' )

	log "Disk usage: ${usage}%"
		if [ $usage -ge $DISK_THRESHOLD ];
then
	alert "Disk usage is ${usage}% - exceeds disk threshold of  ${DISK_THRESHOLD}% "

fi
}


check_service() {

	if systemctl is-active --quiet nginx; 
       	then
		log "Service $SERVICE_NAME is running"
	else
		log "Service $SERVICE_NAME is not running"
fi
}


check_cpu() {
	local usage idle
	idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d"." -f1)
	usage=$((100-$idle))
	
	log "CPU usage is ${usage}%"

	if [ $usage -ge $CPU_THRESHOLD ]; then
		alert "CPU usage is ${usage}% - exceeds CPU thresold of ${CPU_THRESHOLD}%"
fi
}

check_memory() {
	local total used percentage
	used=$(free | awk 'NR==2 {print $3}')
	total=$(free | awk 'NR==2 {print $2}')
	percentage=$((($used * 100)/$total))

	log "Memory usage ${percentage}% - (Used $used KBs out of $total KBs)"

	if [ $percentage -ge $MEM_THRESHOLD ]; then
		alert "Memory usage is ${percentage}% - exceeds threshold of ${MEM_THRESHOLD}%"
fi
}

check_url() {
	local status

	status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$CHECK_URL" || echo "000")

	log "URL checked : HTTP $status"

	if [ "$status" != "200" ]; then
		alert "URL $CHECK_URL return HTTP $status - expected 200"
fi
}

check_network() {
	local status
	
	status=$(nslookup google.com | awk 'NR==6 {print $2}' )

	if [ "$status" == "" ]; then
		alert "DNS resolution error - google.com not resolved"
	else 
		log "DNS resolution checked - google.com resolved"
fi
}


main() {
	echo "" >> $REPORT_LOG
	log "============================================="
	log "Health check started on $(hostname)"
	log "============================================="

	check_disk
	check_service
	check_cpu
	check_memory
	check_url
	check_network

	log "============================================="
	log "Health check completed"
	log "============================================="
}

main


	
