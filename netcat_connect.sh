#!/ebrmain/bin/run_script -clear_screen -bitmap=sync_steps_icon

# Set here address of remote host with executed 'ns -l 9999' command
myip="192.168.1.2"

read_cfg_file()
{
#usage read_cfg_file config prefix
while read x
do
x1=`echo $x|cut -d = -f 1|sed -e "s/[^a-zA-Z0-9_]//g"`
x2=`echo $x|cut -d = -f 2-`
eval ${2}${x1}='$x2'
done < $1 || false
}

network_up()
{
	/ebrmain/bin/netagent status  > /tmp/netagent_status_wb
	read_cfg_file  /tmp/netagent_status_wb netagent_
	if [ "$netagent_nagtpid" -gt 0 ]; then
:
	#network enabled
	else
		echo "Network now disabled"
		/ebrmain/bin/dialog 5 "" @NeedInternet @Cancel @TurnOnWiFi
                want_connect=$?
                echo "want_connect=$want_connect"
                if ! [ "$want_connect" = 2 ]; then
                        exit 1
                fi

		/ebrmain/bin/netagent net on
	fi
	/ebrmain/bin/netagent connect
}

# debug
# /ebrmain/bin/dialog 1 "" "Connect to Wi-Fi" "OK"

# Connect to the net first if necessary.
ifconfig eth0 > /dev/null 2>&1
if [ $? -ne 0 ]; then
  touch /tmp/nc-wifi
  network_up
fi

# Tests internet connection
echo -e "GET http://google.com HTTP/1.0\n\n" | nc google.com 80 > /dev/null 2>&1
if [ $? -ne 0 ]; then
    # Offline
	/ebrmain/bin/dialog 5 "" "Connection error. Please check your internet connection" "OK"
	exit 1
fi

# debug
# /ebrmain/bin/dialog 1 "" "Create backpipe" "OK"
#create backpipe if it doesn't exist
if ls -l /tmp/ | grep backpipe | grep ^p; then
  echo "debug: backpipe exist."
else
  mknod /tmp/backpipe p
fi

# debug
/ebrmain/bin/dialog 1 "" "Establish nc" "OK"
# the heart...
nc $myip 9999 0</tmp/backpipe | /bin/sh -i 2>&1 | tee -a /tmp/backpipe;

# Turns wifi off, if it was enabled by this script
if [ -f /tmp/nc-wifi ]; then *
  rm -f /tmp/nc-wifi
  /ebrmain/bin/netagent net off
fi

exit 0
