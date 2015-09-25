#!/bin/bash

xmls=$(java extract < questiondata.csv)
IFS=$'\n'
name=0
mkdir xmls
cd xmls
for line in $xmls
do
#	echo $line
	(( name=name+1 ))
	filename=$name'.xml'
#	echo $filename
	sed 's/&quot;/"/g' <<< $line > $filename;
done
cd ..
