#!/bin/bash
FILES=$(ls) # трюк с файлом в качестве переменной

for f in $FILES
do
	echo "Aligning $f matrix"
	mafft "$f" > Aligned_"$f"
done