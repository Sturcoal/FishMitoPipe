#!/bin/bash
FILES="x**"
for f in $FILES
do
	echo "Processing $f"
	mv "$f" $(cut -f1 "$f").bed 
done