#!/bin/bash

set -e

echo args: $@

rcS_dir=$1
debugger=$2
program=$3
model=$4
build_path=$5

echo SITL ARGS

echo rcS_dir: $rcS_dir
echo debugger: $debugger
echo program: $program
echo model: $model
echo build_path: $build_path

src_path=$build_path/posix
working_dir=$build_path/posix
sitl_bin=$build_path/posix/px4
rootfs=$build_path/posix/rootfs

mkdir -p $build_path/posix/rootfs/fs/microsd
mkdir -p $build_path/posix/rootfs/eeprom
touch $build_path/posix/rootfs/eeprom/parameters

if [ "$chroot" == "1" ]
then
	chroot_enabled=-c
	sudo_enabled=sudo
else
	chroot_enabled=""
	sudo_enabled=""
fi

# To disable user input
if [[ -n "$NO_PXH" ]]; then
	no_pxh=-d
else
	no_pxh=""
fi

if [ "$model" == "" ] || [ "$model" == "none" ]
then
	echo "empty model, setting iris as default"
	model="iris"
fi

# if [ "$#" -lt 7 ]
# then
# 	echo usage: sitl_run.sh rc_script rcS_dir debugger program model src_path build_path
# 	echo ""
# 	exit 1
# fi

SIM_PID=0

cd $working_dir

if [ "$logfile" != "" ]
then
	cp $logfile $rootfs/replay.px4log
fi

# Do not exit on failure now from here on because we want the complete cleanup
set +e

sitl_command="$sudo_enabled $sitl_bin $no_pxh $chroot_enabled $src_path $src_path/${rcS_dir}/${model}"

echo SITL COMMAND: $sitl_command

# Start Java simulator
if [ "$debugger" == "lldb" ]
then
	lldb -- $sitl_command
elif [ "$debugger" == "gdb" ]
then
	gdb --args $sitl_command
elif [ "$debugger" == "ddd" ]
then
	ddd --debugger gdb --args $sitl_command
elif [ "$debugger" == "valgrind" ]
then
	valgrind $sitl_command
else
	$sitl_command
fi

if [ "$program" == "jmavsim" ]
then
	pkill -9 -P $SIM_PID
	kill -9 $SIM_PID
elif [ "$program" == "gazebo" ]
then
	kill -9 $SIM_PID
	if [[ ! -n "$HEADLESS" ]]; then
		kill -9 $GUI_PID
	fi
fi
