# PocketBook Scripts
Bash-scripts for PocketBook 631.

## WebDAV
Inspired with [this](https://www.e-reader-forum.de/ebook-reader/pocketbook/27169-own-cloud-webdav-synchronisation-fuer-pb-touch-hd/) and [this](https://github.com/cghdev/cloud-dl).

For now, it can do only follows:
* synchronize new files,
* update changed files based on date.

__Important restriction:__
* script synchronize only first level of directory hierarchy without nested directories;
* script doesn't remove anything from local directory.

## NetCat
Fetched from [this](http://www.trefmanic.me/ssh-na-pocketbook-626/) and [this](https://www.mobileread.com/forums/showthread.php?t=116350) places with small modifications.

## Contributing
Feel free to modify and improve these scripts. But be ware. There is BusyBox on PocketBook and most part of shell utilities has reduced functionality.
