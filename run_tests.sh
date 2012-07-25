#!/bin/bash

find tests -name \*.test -type f | while read F
do
	tclsh "$F"
done
