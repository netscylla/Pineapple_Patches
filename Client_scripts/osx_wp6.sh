#!/bin/bash

#Nano Internet Connection Sharing for Apple
#v1.7
SCVER="1.7"
#By TGYK
#Special thanks to Bl1tz3dShad0w for testing and feedback for me
#This script is distributed without any warranty, and is not guarenteed to work. Feel free to modify and redistribute, but please give credit to the original author.

#####CHANGELOG####
#1.4.3:
#	Added changelog
#	Added functionality to detect lock and click if not unlocked
#1.5:
#	Attempt to make compatible for OSX yosemite 10.10.1, test results on my machine are successful, need more results to push stable.
#	Fixed some typos
#	Moved to use of functions
#1.6:
#	Added configurability, bugfixes, and command-line options
#1.7:
#	Made applescript more robust, interactive, will maintain settings after first run, bugfixes
##################

##TODO##
#Eliminate Applescript completely 

#Functions

function validateIP()
{
	local  ip=$1
	local  stat=1
	if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		OIFS=$IFS
		IFS='.'
		ip=($ip)
		IFS=$OIFS
		[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
			&& ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
		stat=$?
	fi
	return $stat
}

function disableICS {
osascript << 'END'
tell application "System Preferences"
	activate
	set current pane to pane "com.apple.preferences.sharing"
end tell
tell application "System Events" to tell process "System Preferences"
	--Find lock and click if not unlocked
	repeat with x in buttons of window "Sharing"
		try
			if (value of attribute "AXTitle" of x) is equal to "Click the lock to make changes." then
				click x
			end if
		end try
	end repeat
	delay 2

	--disable Internet Sharing
	repeat with r in rows of table 1 of scroll area 1 of group 1 of window "Sharing"
		if (value of static text of r as text) starts with "Internet" then
			set sharingBool to value of checkbox of r as boolean
			select r
			if sharingBool is true then click checkbox of r
		end if
	end repeat
	delay 2
end tell
ignoring application responses
	tell application "System Preferences" to quit
end ignoring
END
}

function enableICS {
osascript << 'END2'
tell application "System Events"
	set rootName to name of startup disk
end tell

set paramFile to rootName & ":wpplist:interfaces.txt"
set fileLoc to "/wpplist/interfaces.txt"

on genNew()
	set fileLoc to "/wpplist/interfaces"
	tell application "System Events" to tell process "System Preferences"
		--Select WiFi from dropdown
		click (pop up buttons of group 1 of window "Sharing")
		set doubleNested to name of menu item of menu of (pop up button of group 1 of window "Sharing")
		click menu item "Wi-Fi" of menu of (pop up button of group 1 of window "Sharing")
		set singleNested to item 1 of doubleNested
		set interfaceList to item 1 of singleNested
		display dialog "This only appears to prevent hangups of the choose window" buttons {"Ok"}
		choose from list interfaceList with prompt "Please choose interface to share from"
		set shareFrom to the result as text
		if shareFrom is equal to "false" then
			display dialog "No value selected!" with title "Error" buttons {"Close"} default button 1
			ignoring application responses
				tell application "System Preferences" to quit
			end ignoring
			return
		end if
		
		click (pop up buttons of group 1 of window "Sharing")
		click menu item shareFrom of menu of (pop up button of group 1 of window "Sharing")
		
		set interfaceList to value of text field of rows of table 0 of scroll area 2 of group 1 of window "Sharing"
		display dialog "This only appears to prevent hangups of the choose window" buttons {"Ok"}
		choose from list interfaceList with prompt "Please choose interface to share to"
		set shareTo to the result as text
		
		repeat with r2 in rows of table 0 of scroll area 2 of group 1 of window "Sharing"
			if (value of text field of r2 as text) is equal to shareTo then
				set enetBool to value of checkbox of r2 as boolean
				select r2
				if enetBool is false then click checkbox of r2
			end if
		end repeat
		delay 2
		
		--enable Internet Sharing
		repeat with r in rows of table 1 of scroll area 1 of group 1 of window "Sharing"
			if (value of static text of r as text) starts with "Internet" then
				set sharingBool to value of checkbox of r as boolean
				select r
				if sharingBool is false then
					click checkbox of r
					delay 2
					if (exists sheet 1 of window "Sharing") then
						click button "Start" of sheet 1 of window "Sharing"
					end if
				end if
			end if
		end repeat
		
		
		do shell script "echo " & shareFrom & " >> " & fileLoc
		do shell script "echo " & shareTo & " >> " & fileLoc
	end tell
end genNew

tell application "Finder"
	if exists file paramFile then
		set readParams to true
	else
		set readParams to false
	end if
end tell

tell application "System Preferences"
	activate
	set current pane to pane "com.apple.preferences.sharing"
end tell
tell application "System Events" to tell process "System Preferences"
	--find lock and click it if it is not unlocked
	repeat with x in buttons of window "Sharing"
		try
			if (value of attribute "AXTitle" of x) is equal to "Click the lock to make changes." then
				click x
			end if
		end try
	end repeat
	delay 5
	--find the checkbox for Internet Sharing and select the row so script can enable sharing through ethernet
	repeat with r in rows of table 1 of scroll area 1 of group 1 of window "Sharing"
		if (value of static text of r as text) starts with "Internet" then
			select r
		end if
	end repeat
	delay 2
	
	if (readParams) then
		try
			set paramList to every paragraph of (read fileLoc)
			set shareFrom to item 1 of paramList
			set shareTo to item 2 of paramList
			
			click (pop up buttons of group 1 of window "Sharing")
			click menu item shareFrom of menu of (pop up button of group 1 of window "Sharing")
			
			repeat with r2 in rows of table 0 of scroll area 2 of group 1 of window "Sharing"
				if (value of text field of r2 as text) is equal to shareTo then
					set enetBool to value of checkbox of r2 as boolean
					select r2
					if enetBool is false then click checkbox of r2
				end if
			end repeat
			delay 2
			
			--enable Internet Sharing
			repeat with r in rows of table 1 of scroll area 1 of group 1 of window "Sharing"
				if (value of static text of r as text) starts with "Internet" then
					set sharingBool to value of checkbox of r as boolean
					select r
					if sharingBool is false then
						click checkbox of r
						delay 2
						if (exists sheet 1 of window "Sharing") then
							click button "Start" of sheet 1 of window "Sharing"
						end if
					end if
				end if
			end repeat
			
			
			
		on error
			display dialog "Error reading param file, generating new parameters" buttons "Ok"
			tell me to genNew()
		end try
	else
		tell me to genNew()
	end if
end tell
ignoring application responses
	tell application "System Preferences" to quit
end ignoring
END2
}

function toggleICS {
osascript << 'END3'
tell application "System Events"
	set rootName to name of startup disk
end tell

set paramFile to rootName & ":wpplist:interfaces.txt"
set fileLoc to "/wpplist/interfaces.txt"

on genNew()
	set fileLoc to "/wpplist/interfaces"
	tell application "System Events" to tell process "System Preferences"
		--Select WiFi from dropdown
		click (pop up buttons of group 1 of window "Sharing")
		set doubleNested to name of menu item of menu of (pop up button of group 1 of window "Sharing")
		click menu item "Wi-Fi" of menu of (pop up button of group 1 of window "Sharing")
		set singleNested to item 1 of doubleNested
		set interfaceList to item 1 of singleNested
		display dialog "This only appears to prevent hangups of the choose window" buttons {"Ok"}
		choose from list interfaceList with prompt "Please choose interface to share from"
		set shareFrom to the result as text
		if shareFrom is equal to "false" then
			display dialog "No value selected!" with title "Error" buttons {"Close"} default button 1
			ignoring application responses
				tell application "System Preferences" to quit
			end ignoring
			return
		end if
		
		click (pop up buttons of group 1 of window "Sharing")
		click menu item shareFrom of menu of (pop up button of group 1 of window "Sharing")
		
		set interfaceList to value of text field of rows of table 0 of scroll area 2 of group 1 of window "Sharing"
		display dialog "This only appears to prevent hangups of the choose window" buttons {"Ok"}
		choose from list interfaceList with prompt "Please choose interface to share to"
		set shareTo to the result as text
		
		repeat with r2 in rows of table 0 of scroll area 2 of group 1 of window "Sharing"
			if (value of text field of r2 as text) is equal to shareTo then
				set enetBool to value of checkbox of r2 as boolean
				select r2
				if enetBool is false then click checkbox of r2
			end if
		end repeat
		delay 2
		
		--enable Internet Sharing
		repeat with r in rows of table 1 of scroll area 1 of group 1 of window "Sharing"
			if (value of static text of r as text) starts with "Internet" then
				set sharingBool to value of checkbox of r as boolean
				select r
				if sharingBool is false then
					click checkbox of r
					delay 2
					if (exists sheet 1 of window "Sharing") then
						click button "Start" of sheet 1 of window "Sharing"
					end if
					delay 2
					click checkbox of r
				end if
			end if
		end repeat
		
		
		do shell script "echo " & shareFrom & " >> " & fileLoc
		do shell script "echo " & shareTo & " >> " & fileLoc
	end tell
end genNew

tell application "Finder"
	if exists file paramFile then
		set readParams to true
	else
		set readParams to false
	end if
end tell

tell application "System Preferences"
	activate
	set current pane to pane "com.apple.preferences.sharing"
end tell
tell application "System Events" to tell process "System Preferences"
	--find lock and click it if it is not unlocked
	repeat with x in buttons of window "Sharing"
		try
			if (value of attribute "AXTitle" of x) is equal to "Click the lock to make changes." then
				click x
			end if
		end try
	end repeat
	delay 5
	--find the checkbox for Internet Sharing and select the row so script can enable sharing through ethernet
	repeat with r in rows of table 1 of scroll area 1 of group 1 of window "Sharing"
		if (value of static text of r as text) starts with "Internet" then
			select r
		end if
	end repeat
	delay 2
	
	if (readParams) then
		try
			set paramList to every paragraph of (read fileLoc)
			set shareFrom to item 1 of paramList
			set shareTo to item 2 of paramList
			
			click (pop up buttons of group 1 of window "Sharing")
			click menu item shareFrom of menu of (pop up button of group 1 of window "Sharing")
			
			repeat with r2 in rows of table 0 of scroll area 2 of group 1 of window "Sharing"
				if (value of text field of r2 as text) is equal to shareTo then
					set enetBool to value of checkbox of r2 as boolean
					select r2
					if enetBool is false then click checkbox of r2
				end if
			end repeat
			delay 2
			
			--enable Internet Sharing
			repeat with r in rows of table 1 of scroll area 1 of group 1 of window "Sharing"
				if (value of static text of r as text) starts with "Internet" then
					set sharingBool to value of checkbox of r as boolean
					select r
					if sharingBool is false then
						click checkbox of r
						delay 2
						if (exists sheet 1 of window "Sharing") then
							click button "Start" of sheet 1 of window "Sharing"
						end if
						delay 2
						click checkbox of r
					end if
				end if
			end repeat
			
			
			
		on error
			display dialog "Error reading param file, generating new parameters" buttons "Ok"
			tell me to genNew()
		end try
	else
		tell me to genNew()
	end if
end tell
ignoring application responses
	tell application "System Preferences" to quit
end ignoring
END3
}

#Check for root
if [ "$(id -u)" != "0" ]; then
	echo "This script must be run as root" 1>&2
	exit 1
fi

#Set Version variable, periods removed for easy comparing.
VERSION=$(sw_vers -productVersion | tr -d '.')

#Check for versions less than 10.7.5
if [[ $VERSION == "106"* ]]; then
	echo "This script is unsupported on your OS version"
	exit 2
fi

touch /wpplist/interfaces
chmod -R 777 /wpplist

GATEWAYIP="172.16.42.2"
NETWORKIP="172.16.42.0"
NETWORKEND="172.16.42.254"
DNSIP="8.8.8.8"
DNSALT="8.8.4.4"
USEWPP=true

while getopts ":rhvng:d:a:" opt; do
	case $opt in
		h)
			echo "Options:"
			echo "-g		Specify gateway"
			echo "-d		Specify DNS"
			echo "-a		Specify alternate DNS"
			echo "-h		Display brief help"
			echo "-v		Display version info and exit"
			echo "-n		Do not use completed configs (Generate new)"
			echo "-r		Removes modified files, attempt to restore from backups"
			exit 0			
			;;
		v)
			echo "System version code: $VERSION"
			echo "Script version: $SCVER"
			exit 0
			;;
		n)
			USEWPP=false
			;;
		g)
			if validateIP $OPTARG; then 
				GATEWAYIP=$OPTARG
			else
				echo "Invallid gateway IP... EXITING!"
				exit 1
			fi
			temp=`echo $GATEWAYIP | cut -d"." -f1-3`
			NETWORKIP=`echo $temp".0"`
			NETWORKEND=`echo $temp".254"`
			;;
		d)
			if validateIP $OPTARG; then 
				DNSIP=$OPTARG
			else
				echo "Invallid DNS IP... EXITING!"
				exit 1
			fi
			;;
		a)
			if validateIP $OPTARG; then 
				DNSALT=$OPTARG
			else
				echo "Invallid Alternate DNS IP... EXITING!"
				exit 1
			fi
			;;
		r)
			ICSPID=$(pgrep InternetSharing)
			if [ $? == "0" ]; then
				echo "Killing ICS"
				disableICS
				sleep 2
			fi
			if [ -e /Library/Preferences/SystemConfiguration/com.apple.nat.plist ]; then
				rm /Library/Preferences/SystemConfiguration/com.apple.nat.plist
				echo "Removed old NAT file"
			fi
			if [ -e /Library/Preferences/SystemConfiguration/com.apple.nat.lockfile ]; then
				rm /Library/Preferences/SystemConfiguration/com.apple.nat.lockfile
				echo "Removed old NAT lock file"
			fi
			if [ -e /etc/bootpd.plist ]; then
				rm /etc/bootpd.plist
				echo "Removed old bootpd file"
			fi
			if [ -d /wpplist/ ]; then
				rm -r /wpplist/
				echo "Removed completed configs directory"
			fi
			if [ -d /plistbackups/ ]; then
				if [ -e /plistbackups/com.apple.nat.plist ]; then
					cp /plistbackups/com.apple.nat.plist /Library/Preferences/SystemConfiguration/
					echo "Restored NAT file from backup"
				fi
				if [ -e /plistbackups/com.apple.nat.plist.lockfile ]; then
					cp /plistbackups/com.apple.nat.plist.lockfile /Library/Preferences/SystemConfiguration/
					echo "Restored NAT lockfile from backup"
				fi
				if [ -e /plistbackups/bootpd.plist ]; then
					cp /plistbackups/bootpd.plist /etc/
					echo "Restored bootpd file from backup"
				fi
			else
				echo "No plist backups found to restore from, this is usually not an issue, as enabling ICS manually or running this script usually generates them."
			fi
			exit 0
			;;
	  	\?)
			echo "Invalid option: -$OPTARG" >&2
			;;
	esac
done

#Get netrange from GWIP
IFS=. read ip1 ip2 ip3 ip4 <<< "$GATEWAYIP"
temp=`echo $GATEWAYIP | cut -d"." -f1-3`
temp2=`expr $ip4 + 1`
NETRANGE=`echo $temp"."$temp2`


#Check for and kill ICS if it's already running
ICSPID=$(pgrep InternetSharing)
if [ $? == "0" ]; then
	echo "Killing ICS"
	disableICS
	sleep 2
fi

#Check for plist backup dir and if not there, create it and backup default configs, but do not overwrite them
if [ ! -d /plistbackups ]; then
	echo "Backing up default plists"
	mkdir /plistbackups
	ICSPID=$(pgrep InternetSharing)
	if [ $? == "0" ]; then
		echo "Killing ICS"
		disableICS
		sleep 2
	fi
	if [ -e /Library/Preferences/SystemConfiguration/com.apple.nat.plist ]; then
		cp /Library/Preferences/SystemConfiguration/com.apple.nat.plist /plistbackups/
		echo "Backed up old NAT file"
	fi
	if [ -e /Library/Preferences/SystemConfiguration/com.apple.nat.lockfile ]; then
		cp /Library/Preferences/SystemConfiguration/com.apple.nat.lockfile /plistbackups/
		echo "Backed up old NAT lock file"
	fi
	if [ -e /etc/bootpd.plist ]; then
		cp /etc/bootpd.plist /plistbackups/
		echo "Backed up old bootpd file"
	fi
	sleep 2
fi

#If completed configs exist, use them
if [ -d /wpplist ] && [ $USEWPP == true ]; then
	if [ ! -e /wpplist/params ]; then
		echo "No /wpplist/params file... EXITING!"
		exit 1
	fi
	i="0"
	while read line; do
		file[$i]=$line
		i=`expr $i + 1`
	done < /wpplist/params
	WPGATEWAY=${file[0]}
	WPDNS=${file[1]}
	WPALT=${file[2]}
	if ! validateIP $WPGATEWAY; then 
		echo "Invallid gateway IP from wpparams... EXITING!"
		exit 1
	fi
	if ! validateIP $WPDNS; then 
		echo "Invallid DNS IP from wpparams... EXITING!"
		exit 1
	fi
	if ! validateIP $WPALT; then 
		echo "Invallid Alternate DNS IP from wpparams... EXITING!"
		exit 1
	fi

	#Copy nat config
	cp /wpplist/com.apple.nat.plist /Library/Preferences/SystemConfiguration/com.apple.nat.plist
	echo "Restored from previous completed configs"

	#Start ICS
	enableICS
	sleep 2
	echo "ICS started"

	#Check for existence of bridge100 and if it's there, use it, otherwise, use en9
	junk=$(ifconfig bridge100 2>&1)
	if [ $? == 0 ]; then
		ifconfig bridge100 $WPGATEWAY netmask 255.255.255.0 up
		echo "IP on bridge100 set to $WPGATEWAY"
		sleep 2
	else
		ifconfig en9 $WPGATEWAY netmask 255.255.255.0 up
		echo "IP on en9 set to $WPGATEWAY"
		sleep 2
	fi

	#Set DNS
	networksetup -setdnsservers Ethernet $WPDNS $WPALT
	echo "Set Primary DNS to $WPDNS Alternate to $WPALT"
	sleep 2

	#Copy bootpd
	if [ -e /wpplist/bootpd.plist ]; then
		cp /wpplist/bootpd.plist /etc/bootpd.plist
		#Reload bootpd
		if [[ $VERSION != "1010"* ]]; then
			kill -HUP $(pgrep bootpd)
			sleep 2
			echo "Reloaded bootpd file for DHCP"
		fi
	fi
	exit
fi


#Use applescript to reliably create NAT file
toggleICS
sleep 2
echo "NAT file created"

#Write the NAT parameters to the file using the defaults command
defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict-add SharingNetworkNumberStart $NETWORKIP
if [[ $VERSION == "1011"* ]]; then
        defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict-add SharingNetworkNumberEnd $NETWORKEND
        defaults write /Library/Preferences/SystemConfiguration/com.apple.nat NAT -dict-add SharingNetworkMask 255.255.255.0
fi

sleep 2
echo "NAT file edited"

#Start sharing again
enableICS
sleep 2
echo "ICS started"

#Check for existence of bridge100 and if it's there, use it, otherwise, use en9
	junk=$(ifconfig bridge100 2>&1)
	if [ $? == 0 ]; then
		ifconfig bridge100 $GATEWAYIP netmask 255.255.255.0 up
		echo "IP on bridge100 set to $GATEWAYIP"
		sleep 2
	else
		ifconfig en9 $GATEWAYIP netmask 255.255.255.0 up
		echo "IP on en9 set to $GATEWAYIP"
		sleep 2
	fi

#Set DNS
networksetup -setdnsservers Ethernet $DNSIP $DNSALT
echo "Set Primary DNS to $DNSIP Alternate to $DNSALT"
sleep 2

#Edit bootpd
if [[ $VERSION != "1011"* ]]; then
        /usr/libexec/PlistBuddy -c "set :Subnets:0:dhcp_domain_name_server:0 '$GATEWEAYIP'" /etc/bootpd.plist
        /usr/libexec/PlistBuddy -c "set :Subnets:0:dhcp_router '$GATEWAYIP'" /etc/bootpd.plist
        /usr/libexec/PlistBuddy -c "set :Subnets:0:net_range:0 '$NETRANGE'" /etc/bootpd.plist
sleep 2
echo "Rewritten bootpd file for DHCP"
fi


#Make backup of configured files for future use
if [ ! -d /wpplist ]; then
	mkdir /wpplist
	touch /wpplist/params
	sleep 2
	echo "Made backup directory for completed config files"
fi
cp /Library/Preferences/SystemConfiguration/com.apple.nat.plist /wpplist
cp /etc/bootpd.plist /wpplist
echo $GATEWAYIP > /wpplist/params
echo $DNSIP >> /wpplist/params
echo $DNSALT >> /wpplist/params
sleep 2
echo "Copied completed config files"

#Reload bootpd process
if [[ $VERSION != "1011"* ]]; then
	kill -HUP $(pgrep bootpd)
	sleep 2
	
	echo "Reloaded bootpd file for DHCP"
fi
