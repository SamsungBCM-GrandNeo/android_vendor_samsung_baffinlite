#!/system/bin/sh

#00100000==2048*512==1048576
apanic_on="00100000: a5 c3 s 168
sum 168"

#dd if=/dev/block/platform/sdhci.1/by-name/kpanic of=/data/dontpanic/cp_crash.bin skip=2048 bs=512
#00100000=2048*512=1048576
data=`hd -b1048576 -c2 /dev/block/platform/sdhci.1/by-name/kpanic`

echo "$data" > /dev/kmsg

case "$data" in
	$apanic_on)
	echo "do copy" > /dev/kmsg
	dd if=/dev/block/platform/sdhci.1/by-name/kpanic of=/data/dontpanic/cp_crash.bin skip=2048
	mv /data/dontpanic/cp_crash.bin /data/dontpanic/cp_crash_`date +%d%m%y_%H%M%S`.bin
esac
rm /data/dontpanic/cp_crash.bin

apanic_console_name=console_`date +%d%m%y_%H%M%S`
apanic_threads_name=threads_`date +%d%m%y_%H%M%S`

mv /data/dontpanic/apanic_console /data/dontpanic/$apanic_console_name
mv /data/dontpanic/apanic_threads /data/dontpanic/$apanic_threads_name

panic_copyed=false

check_sdcard_copyed()
{
panic_copyed=false
panic=`ls /sdcard/`
for i in $panic; do
	case $i in $apanic_threads_name)
		panic_copyed=true
	esac
done
}

ap_sdcard=`cat /sys/class/bcm_log/bcm_log/ap_crash`
for i in $ap_sdcard; do
	case $i in sdcard)
		sleep 40.
		dd if=/data/dontpanic/$apanic_console_name  of=/sdcard/$apanic_console_name
		dd if=/data/dontpanic/$apanic_threads_name  of=/sdcard/$apanic_threads_name
		check_sdcard_copyed
		if ($panic_copyed == false); then
			sleep 10.
			dd if=/data/dontpanic/$apanic_console_name  of=/sdcard/$apanic_console_name
			dd if=/data/dontpanic/$apanic_threads_name  of=/sdcard/$apanic_threads_name
		fi
	esac
done



