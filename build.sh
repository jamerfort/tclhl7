#!/bin/bash

# search for all .tcli files and run them through include.tcl
find . -name \*.tcli -type f | while read F
do
	OUTPUT=$(echo "$F" | sed 's/\.tcli$/.tcl/g')
	echo tclsh include.tcl "$F" "$OUTPUT"
	tclsh include.tcl "$F" "$OUTPUT"
done

# build the README.md.html
echo "Generating HTML documentation."
perl Markdown.pl README.md | sed 's/<!-- <style>/<style>/; s!</style> -->!</style>!;' > README.md.html

# copy the hl7.tcl file to the build directory
echo "Copying the hl7.tcl file to ./build/"
cp hl7.1/hl7.tcl build/
