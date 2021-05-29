#!/bin/bash
FILES=$(cat ID.list)

for f in $FILES
do
	echo "Extracting D-loop from $f"
	seqtk subseq "$f".fa "$f".bed | cut -d ":" -f1 | sed 's/>.*/&-D-loop/' | cut -d "-" -f1 >> D-loop.fasta
done