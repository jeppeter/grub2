#! /bin/bash

script=`readlink -f $0`
script_dir=`dirname $script`
echo "script_dir[$script_dir]"

origdir=

run_cmd()
{
	$@
	if [ $? -ne 0 ]
		then
		echo "run [$@] error"
		if [ -n "$origdir" ]
			then
			cd $origdir
		fi
		exit 4
	else
		echo "run [$@] succ"
	fi
}

run_cmd $script_dir/init.sh 
source $script_dir/addextra.sh
run_cmd $script_dir/autogen.sh
run_cmd $script_dir/configure --enable-boot-time --enable-time-emulate --enable-chs-mode --enable-e820map-emulate
origdir=`pwd`
cd $script_dir
run_cmd make
run_cmd $script_dir/collect.sh
cd $origdir