#! /bin/sh

sudo launchctl unload /Library/LaunchDaemons/com.lyq1996.X-Monitor.Helper.plist
sudo rm /Library/LaunchDaemons/com.lyq1996.X-Monitor.Helper.plist
sudo rm /Library/PrivilegedHelperTools/com.lyq1996.X-Monitor.Helper

sudo launchctl unload /Library/LaunchDaemons/com.lyq1996.X-Service.plist
sudo rm /Library/LaunchDaemons/com.lyq1996.X-Service.plist
sudo rm /Library/PrivilegedHelperTools/com.lyq1996.X-Service
