#!/bin/bash
FILES=$(cat Fragments_list.txt)

for f in $FILES
do
	echo "Assembling $f matrix"
	cat *"$f".* | cut -d "-" -f1 > "$f".fasta
done