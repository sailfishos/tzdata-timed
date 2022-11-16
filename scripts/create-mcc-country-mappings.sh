#!/bin/bash

function usage {
  cat <<EOF
Usage: ${0##*/} [DIRECTORY]

Copy-paste the english Wikipedia entries about mobile country codes in edit mode, e.g.
https://en.wikipedia.org/wiki/Mobile_network_codes_in_ITU_region_2xx_%28Europe%29
and add all the files to a directory of your choosing. Filenames don't matter,
but the directory should *only* contain any files you want to be parsed.
Then pass the directory as an argument to the script.

The output format is

  <MCC> <MNC> <ISO3166 country code> <Name of Country>

For example

  123 45 AA Kingdom of Anonymous Aardwarks
  123 46 AA Kingdom of Anonymous Aardwarks
  456 78 RB Republic of Banana
EOF
}

if [ -z $1 ]; then
  usage
  exit 1
fi

if [ "$1" == "-h" -o "$1" == "--help" ] ; then
  usage
  exit 0
fi

if [ ! -d $1 ] ; then
  echo "ERROR: $1 is not a directory" >&2
  exit 1
fi

TMPFILE=`mktemp`
for infile in $1/* ; do
  while read LINE ; do
    # Check for header line with country information, e.g.
    # ==== [[Argentina]] – AR ====
    if echo $LINE | grep -q ^==== ; then
      country=`echo $LINE | cut -d '[' -f3 | cut -d ']' -f1`
      if echo $country | grep -q '|' ; then
        country=`echo $country | cut -d '|' -f2`
      fi
      # Country codes sometimes look non-standard, e.g. Abkhazia (GE-AB)
      # or Australia (AU/CC/CX) which also has Cocos islands & Christmas island.
      # In these non-standard cases we only want the first code.
      countrycode=`echo $LINE | rev | cut -d ' ' -f2 | rev | cut -d '/' -f1 | cut -d '-' -f1`
    # Check for line with operator information, e.g.
    # | 244 || 05 || Elisa || [[Elisa Oyj]] || Operational || GSM 900 (...) || Former Radiolinja
    elif echo $LINE | grep -q '^| [0-9]\+ || [0-9]\+ ' ; then
      mcc=`echo $LINE | cut -d ' ' -f2`
      mnc=`echo $LINE | cut -d ' ' -f4`
      echo "$mcc $mnc $countrycode $country" >> $TMPFILE
    fi
  done < $infile
done
today=`date "+%Y, %b %d"`

cat <<EOF
# This file contains a list of MCC, MNC and ISO 3166-1 alpha-2
# codes. Each line contains the following fields separated by spaces:
#
#   <MCC> <MNC> <ISO 3166-1 alpha-2> <Country name>
#
# The country name is for documentational purposes only, they do
# not follow any standard. Lines starting with a "#" are comments,
# and empty lines (only white space) are ignored.
#
# The main source for this list is the Wikipedia article on mobile
# country codes: http://en.wikipedia.org/wiki/Mobile_country_code
# Updated from Wikipedia on $today with the help of
# scripts/${0##*/}

EOF
cat $TMPFILE | sort -u -k3 -k1 -k2
rm -f $TMPFILE
