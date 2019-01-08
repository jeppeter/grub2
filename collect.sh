#! /bin/bash

run_cmd()
{
	$@
	if [ $? -ne 0 ]
		then
		echo "run [$@] error"
		exit 4
	fi
}

script=`readlink -f $0`
script_dir=`dirname $script`


outdir=$script_dir/i386-pc
if [ $# -gt 0 ]
	then
	outdir=shift
fi

if [ ! -d "$outdir" ]
	then
	run_cmd mkdir -p "$outdir"
fi

for _l in $(find $script_dir/grub-core/ -name '*.mod')
do
	_b=`basename $_l`
	run_cmd cp "$_l"  "$outdir/$_b"
done

for _l in $(find $script_dir/grub-core/ -name '*.img')
do
	_b=`basename $_l`
	run_cmd cp "$_l"  "$outdir/$_b"
done