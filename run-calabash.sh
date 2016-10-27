#!/bin/bash

BASEDIR=$(dirname $0)
FEATURE=""
DEBUG=0
DEVICE=""
REPORT="no"
NO_BUILD="no"

usage() {
  cat <<-EOF
  Usage: run-calabash [options] 
  Options:
    -f <feature>      ie: -f activity_completion.feature , executes only single <feature> , you can get a list of available features using -l option
    -l,               list all available features in the 'features' directory
    -t,               list all available devices, you can look it up and then use device with -s , ie -s "iPhone 6 (9.0)"
    -r                generates html report in build/calabash-report.html
    -s <device>       specifies which device to use for testing ie -s "iPhone 6 (9.0)"
    -x                skips building of cal target
    -h                output help information
EOF
}


log() {
  echo "  ○ $@"
}

build() {
  Calabash/build_cal_target.sh
}

runCalabash() {
  cmd="RESET_BETWEEN_SCENARIOS=1"
  if [ $DEBUG == 1 ]; then
   cmd="$cmd DEBUG=1"
  fi
  if [ ! "$DEVICE" == "" ]; then
   cmd="$cmd DEVICE_TARGET=\"$DEVICE\""
  fi
  cmd="$cmd APP=build/Asthma-cal.app bundle exec cucumber"
  if [ ! "$FEATURE" == "" ]; then
   cmd="$cmd features/"$FEATURE
  fi
  if [ "$REPORT" == "yes" ]; then
   cmd="$cmd --format html --out build/calabash-report.html"
  fi

  log "Running calabash: $cmd"
  eval $cmd
}

listFeatures() {
  ls features | grep .feature
}

listDevices() {
  xcrun instruments -s devices
}

run() {
  if [ $NO_BUILD == "yes" ]; then
    echo "Using -x, no .app build triggered"
  else 
    echo "Building cal target"
    build
  fi
  runCalabash
}
while getopts “hltdxrf:s:” OPTION
do
     case $OPTION in
         d)
             DEBUG=1
             ;;
         f)
             FEATURE=$OPTARG
             ;;
         h)
             usage
             exit 1
             ;;
         l)
	     listFeatures
	     exit 1
             ;;
         r)
	     REPORT="yes"
             ;;
         s)
	     DEVICE=$OPTARG
             ;;
         t)
	     listDevices
	     exit 1
             ;;
         x)
             NO_BUILD="yes"
             ;;
         ?)
             usage
             exit
             ;;
     esac
done

run
