#!/ebrmain/bin/run_script -clear_screen -bitmap=sync_steps_icon

# Set these variables...
user="user"
passwd="password"
remote_host="https://example.com"
remote_path_suffix="/my_cloud_path/remote.php/webdav/"
remote_dir_name="DirForSyncFromRemoteSide"

remote_path="$remote_path_suffix$remote_dir_name"
escaped_remote_path=$(echo $remote_path | sed "s/\//\\\\\//g")
full_url="$remote_host$remote_path"

# Special characters e.g. umlauts, whitespaces... must be URL-encoded
# https://meyerweb.com/eric/tools/dencoder/

local_dir="/mnt/ext1/NextCloud"
# /mnt/ext1 --> internal storage
# /mnt/ext2 --> SD-Card


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

url_decode() {
# Decodes URL-Encoding
	local url_encoded="${1//+/ }"
	printf '%b' "${url_encoded//%/\\x}"
}



# Connect to the net first if necessary.
ifconfig eth0 > /dev/null 2>&1
if [ $? -ne 0 ]; then
  touch /tmp/webdav-wifi
  network_up
fi

# Tests internet connection
echo -e "GET http://google.com HTTP/1.0\n\n" | nc google.com 80 > /dev/null 2>&1
if [ $? -ne 0 ]; then
    # Offline
	/ebrmain/bin/dialog 5 "" "Connection error. Please check your internet connection" "OK"
	exit 1
fi

# Saves a list of all remote files in $files
# In another world we can use "grep -oP "(?<=<d:href>)[^<]+"" instead of multiple ugly sed's
files=$(\
curl --silent --user "$user":"$passwd" "$full_url" -X PROPFIND \
--data '<?xml version="1.0"?>
<a:propfind xmlns:a="DAV:">
<a:prop>
<a:resourcetype />
</a:prop>
</a:propfind>' | grep 'href' | sed 's/<\/\?[^>]\+>//g' | sed 's/HTTP\/1.1 200 OK/\n/g' | sed "s/$escaped_remote_path\///g" | grep -v '^$')

# For sync directory recursively we can try to use follows:
# wget -r -nH -np --cut-dirs=1 --no-check-certificate -U Mozilla --user={uname} --password={pwd} https://my-host/my-webdav-dir/my-dir-in-webdav
# from here: https://askubuntu.com/questions/104046/how-do-i-recursively-copy-download-a-whole-webdav-directory
# But in this case any time will be processed full directory fetch. This is very expensive, especially for big library.

files_count=$(echo $file | wc -l)
/ebrmain/bin/dialog 1 "" "We found $files_count file(s) in remote dir "$remote_dir_name"" "OK"

# debug
# /ebrmain/bin/dialog 1 "" "Files list: "$full_url"" "OK"

# Downloads every file in $files, if the remote version is newer than the local one
echo "$files" | while IFS= read -r file
do
    # debug
    # /ebrmain/bin/dialog 1 "" "Local file: "$local_dir"/"$(url_decode "$file")"" "OK"
    # /ebrmain/bin/dialog 1 "" "Remote file: "$full_url"/"$file"" "OK"

    curl --silent --create-dirs --time-cond "$local_dir"/"$(url_decode "$file")" --user "$user":"$passwd" "$full_url"/"$file" --output "$local_dir"/"$(url_decode "$file")"
done

# Turns wifi off, if it was enabled by this script
if [ -f /tmp/webdav-wifi ]; then *
  rm -f /tmp/webdav-wifi
  /ebrmain/bin/netagent net off
fi

# Done :)
/ebrmain/bin/dialog 1 "" "Sync with $(url_decode "$full_url") finished. Hopefully ;)" "OK"
exit 0
