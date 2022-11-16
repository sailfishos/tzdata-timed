#!/bin/bash

# Quick'n'dirty script to help identify pain points in the MCC file.
# Use like this:
# cat data/MCC | grep ^[0-9] | sort -k1 -k2 | ./find_overlaps.sh
#
# This will give you a list of things that you can then further investigate
# (i.e. grep for and compare to the stuff already in MCC-unsupported-zones)

old=""
while read LINE ; do
  new=`echo $LINE | cut -d ' ' -f1,2`
  if [[ "$old" == "$new" ]] ; then
    echo $LINE
  fi
  old=$new
done < /dev/stdin
