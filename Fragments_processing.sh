#!/bin/bash
FILES="*.fa*"
for f in $FILES
do
	echo "Processing $f" 
	awk '/>/{sub(">","&"FILENAME"-");sub(/\.fa/,x)}1' "$f" > tmp && mv tmp "$f" 
	awk '/^>/ { if(NR>1) print "";  printf("%s\n",$0); next; } { printf("%s",$0);}  END {printf("\n");}' "$f" > tmp && mv tmp "$f" 
	sed -i 's/.[0-9]*..[0-9]*([+-])/ /g' "$f" 
	sed -i 's/[[:space:]]//g' "$f" 
	awk '(/^>/ && s[$0]++){$0=$0""s[$0]}1;' "$f" > tmp && mv tmp "$f"
done