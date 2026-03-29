#!/bin/bash

set -e

source "$(dirname "$0")/config.env"

mkdir -p "$(dirname "$REPORT_LOG")"

trap 'echo "ERROR : SCRIPT FAILED....." >> "$ALERT_LOG"' ERR


timestamp() {
	date "+%Y-%m-%d %H:%M:%S"
}

log() {
	echo "$timestamp $1" >> "$REPORT_LOG"
}

alert() {
	echo "$timestamp ALERT: $1" >> "$ALERT_LOG"
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



