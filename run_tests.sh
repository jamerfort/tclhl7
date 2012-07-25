#!/bin/bash

# build first
./build.sh

find tests -name \*.test -type f | while read F
do
	tclsh "$F" -verbose "pe"
done
