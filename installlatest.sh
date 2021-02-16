#!/bin/bash

#example usage:
#bash installlatest.sh

get_latest_release() {
	curl --silent "https://api.github.com/repos/$1/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")'
}

wget https://raw.githubusercontent.com/AquaQAnalytics/TorQ/master/installtorqapp.sh

torq_latest=`get_latest_release "AquaQAnalytics/TorQ"`

if [[  $torq_latest == *?.?.? ]] || [[  $torq_latest == *?.??.?? ]] || [[  $torq_latest == *?.?.?? ]] || [[  $torq_latest == *?.??.? ]];
then
        echo "============================================================="
	echo "Latest TorQ release"
	echo $torq_latest
	echo "Getting the latest TorQ .tar.gz file"
	echo "============================================================="

	
else
	echo "the tag for Torq release: "
        echo $torq_latest
        echo "Is not in the right format, exiting script."
	exit 1
fi

wget --content-disposition https://github.com/AquaQAnalytics/TorQ/archive/$torq_latest.tar.gz

echo $torq_latest

if [ "${torq_latest%%v*}" ]
then
  echo "tag doesn't start with v"
else
  torq_latest=${torq_latest#?}
fi

echo $torq_latest

torq_fsp_latest=`get_latest_release "AquaQAnalytics/TorQ-Finance-Starter-Pack"`

echo "============================================================="
echo "Latest TorQ-FSP release"
echo $torq_fsp_latest
echo "Getting the latest TorQ-FSP .tar.gz file"
echo "============================================================="

if [[  $torq_fsp_latest == *?.?.? ]] || [[  $torq_fsp_latest == *?.??.?? ]] || [[  $torq_fsp_latest == *?.??.? ]] || [[  $torq_fsp_latest == *?.?.?? ]];
then
	echo "============================================================="
	echo "Latest TorQ-FSP release"
	echo $torq_fsp_latest
	echo "Getting the latest TorQ-FSP .tar.gz file"
	echo "============================================================="

	
else
        echo "the tag for Torq release: "
        echo $torq_fsp_latest
        echo "Is not in the right format, exiting script."
	exit 1
fi


wget --content-disposition https://github.com/AquaQAnalytics/TorQ-Finance-Starter-Pack/archive/$torq_fsp_latest.tar.gz

echo $torq_fsp_latest

if [ "${torq_fsp_latest%%v*}" ]
then
  echo "tag doesn't start with v"
else
  torq_fsp_latest=${torq_fsp_latest#?}
fi

echo $torq_fsp_latest

echo "Files downloaded. Executing install script"

bash installtorqapp.sh --torq TorQ-$torq_latest.tar.gz --releasedir deploy --data datatemp --installfile TorQ-Finance-Starter-Pack-$torq_fsp_latest.tar.gz
