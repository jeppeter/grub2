#! /bin/bash

get_source_file()
{
	echo "${BASH_SOURCE[1]}"
}

source_file1=$(get_source_file)
source_file=
for _path in $( echo $PATH | sed 's/:/\n/g')
do
	if [ -f "$_path/$source_file1" ]
		then
		source_file=`readlink -f $_path/source_file1`
		break
	fi
done

if [ -z "$source_file" ]
	then
	source_file=`readlink -f $source_file1`
else
	echo "source set [$source_file]"
fi

source_dir=`dirname $source_file`
export GRUB_CONTRIB=$source_dir/debian/grub-extras/