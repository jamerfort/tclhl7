#!/bin/bash

#export SHOW_QUERY_RESULTS=1
export SHOW_QUERY_RESULTS=0

if [ "$1" = "-v" ]
then
	export SHOW_QUERY_RESULTS=1
fi

# build first
./build.sh

find tests -name \*.test -type f | xargs ls -tr | while read F
do
	tclsh "$F" -verbose "pe"
done | perl -ne '
	if (/FAIL/) {
		# red
		print "\033[01;38;5;160m$_\033[39m";
	} elsif (/PASS/) {
		# green
		print "\033[0;32m$_\033[39m";
	} else {
		print "$_";
	}
'
