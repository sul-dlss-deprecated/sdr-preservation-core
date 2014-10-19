#!/bin/bash

if [ "$1" != "" ]; then
	repo_path=$1
else
	repo_path='/services-disk/sdr2objects/druid /services-disk02/sdr2objects /services-disk03/sdr2objects /services-disk04/sdr2objects'
fi

DRUID_FOLDER_REGEX='[[:lower:]]{2}[[:digit:]]{3}[[:lower:]]{2}[[:digit:]]{4}$'

for disk in $repo_path; do
	disk_name=$(echo $disk | sed s#^/## | sed s#/#_#g)
	echo $disk_name
	# Find and save all the DRUID folders on this disk
	find $disk -type d | grep -E "${DRUID_FOLDER_REGEX}" > ${disk_name}_druid_paths.txt
	# Report the sum of all the metadata file sizes for each DRUID.
        # Exclude all the 'data/content' files.
        metaDataFileSize=${disk_name}_druid_metadata_size.txt
        rm $metaDataFileSize
        while read line; do
            files=$(find "$line" -type f | grep -v 'data.content')
            size=$(cat "$files" | xargs stat --printf="%s\t%n\n" | awk '{s+=$1} END {print s}')
            echo -e "$size\t$line" >> $metaDataFileSize
        done < ${disk_name}_druid_paths.txt
done


