#!/bin/bash
FILES="*.fa*"
for f in $FILES
do
	echo "Renaming $f" 
	awk '/^>/ {gsub(/.fa(sta)?$/,"",FILENAME);printf(">%s\n",FILENAME);next;} {print}' "$f" > tmp && mv tmp "$f"
done