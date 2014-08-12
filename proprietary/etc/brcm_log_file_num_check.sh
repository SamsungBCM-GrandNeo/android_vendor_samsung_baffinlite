#!/system/bin/sh
#
# brcm_log_file_num_check.sh
#
# Check SD card root directory for number of brcm
# log files and delete older log files if the total
# number of log files exceeds $1
#
# All these commands require root access to run

echo entering $0 ...

log_dir="/sys/class/bcm_log/bcm_log"
log_format="log-*.bin"
sleep_period=`getprop persist.brcm.log_check_period`
max_num_log=`getprop persist.brcm.log_max_num`

if [ "$sleep_period" -le 0 ]; then
	exit 1
fi

if [ "$max_num_log" -le 0 ]; then
	exit 1
fi

# funtion to delete first $num_to_del log files
function del_old_log() {
	num_to_del=$1
	del_cnt=0
	log_path=`cat $log_dir/file_base`
	log_files=$log_path$log_format
	for fd in `ls $log_files`
	do
		if [ "$del_cnt" -ge "$num_to_del" ]; then
			break
		fi

		rm -rf $fd
		echo "$fd deleted"
		((del_cnt++))
done
}

# function to check if currently in SD logging mode
function validate_sd_log {
	log_cfg=`cat $log_dir/log`
	if [[ "$log_cfg" == *sdcard* ]]; then
		return 1
		fi
	return 0
}

# function to check if SD directory path exists
function validate_sd_path {
	log_path=`cat $log_dir/file_base`
	if [ -d "$log_path" ]; then
		return 1
	fi
	return 0
}

function main_process {
	tot_num_log=0
	log_path=`cat $log_dir/file_base`
	log_files=$log_path$log_format
	for fd in `ls $log_files`
		do
		if [ -f "$fd" ]; then
			((tot_num_log++))
		fi
	done

	if [ "$tot_num_log" -gt "$max_num_log" ]; then
		num_del=$((tot_num_log - max_num_log))
		del_old_log $num_del
	fi
}

# run once every $sleep_period seconds
while [ 1 ]
do
	validate_sd_log
	if [ $? -eq 1 ]; then
		validate_sd_path
		if [ $? -eq 1 ]; then
			main_process
		fi
	fi
	sleep $sleep_period
done

echo leaving $0 ...
