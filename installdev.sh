#! /bin/sh

script=`readlink -f $0`
script_dir=`dirname $script`


run_cmd()
{
	$@
	if [ $? -ne 0 ]
		then
		echo "run [$@] error"
		exit 4
	else
		echo "run [$@] succ"
	fi
}


hddev=/dev/nvme0n1
bootdev=/dev/nvme0n1p1
rootdev=/dev/nvme0n1p5

bootdir=/mnt/root/boot
rootdir=/mnt/root/

hasrootdir=`mount | grep -e "^$rootdev"`
if [ -z "$hasrootdir" ]
	then
	if [ ! -d $rootdir ]
		then
		run_cmd mkdir -p $rootdir
	fi

	run_cmd mount $rootdev $rootdir
fi

if [ $bootdev != $rootdev ]
	then
	hasbootdir=`mount | grep -e "^$bootdev"`
	if [ -z "$hasbootdir" ]
		then
		if [ ! -d $bootdir ]
			then
			run_cmd mkdir -p "$bootdir"
		fi
		run_cmd mount $bootdev $bootdir
	fi
fi



instdir=$script_dir/i386-pc
if [ $# -gt 0 ]
	then
	instdir=$1
	shift
fi

run_cmd $instdir/grub-install --boot-directory $bootdir --root-directory $rootdir --locale-directory $instdir --directory $instdir $hddev