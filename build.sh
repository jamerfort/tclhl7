#!/bin/bash

# search for all .tcli files and run them through include.tcl
find . -name \*.tcli -type f | while read F
do
	OUTPUT=$(echo "$F" | sed 's/\.tcli$/.tcl/g')
	echo tclsh include.tcl "$F" "$OUTPUT"
	tclsh include.tcl "$F" "$OUTPUT"
done
