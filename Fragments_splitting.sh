#!/bin/bash
FILES="*.fa*"
for f in $FILES
do
	echo "Splitting $f"
	faidx --split-files "$f"
done