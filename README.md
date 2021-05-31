# `FishMitoPipe` the pipeline for fish mitochondrial genome manipulation before phylogenetic analysis

A step-by-step guide to parsing fish mitochondrial genomes for phylogenetic reconstructions based on output from the MitoAnnotator resource (Iwasaki et al., 2013) http://mitofish.aori.u-tokyo.ac.jp/annotation/input.html

This pipeline accepts the annotated fish mitochondrial genomes as input and allows its partitioning into fragments, alignment, and making a supermatrix for subsequent phylogenetic analysis.

## Before you begin

You will need the following programs and modules:

1. The module pyfaidx for python 
```bash
sudo pip install pyfaidx
```

2.  rename
```bash
sudo apt install rename
```

3. seqtk

The installation guide can be found here: https://github.com/lh3/seqtk

Or you can install seqtk via Anaconda: https://anaconda.org/bioconda/seqtk

4. MAFFT

The installation guide is here: https://mafft.cbrc.jp/alignment/software/

5. phyutility

The source code, installation instructions, and manual can be found here: https://github.com/blackrim/phyutility


**Make sure all these programs are added to your `$PATH` environment.**


## I. To collect the sequence matrices of all genome fragments except the D-loop, we do the following:

1. We Annotate the genomes with MitoAnnotator. 
File names before uploading should be structured according to Genus_species_GNumber or Genus_species_SeqID (for example, Xiphister_atropurpureus_KY657279 or PHP2_19) and saved into a working directory. The annotation is resulted in archives.
The Pipeline is sensitive to filenames.

2. Create folders `MitProject`, `Fragments`, `Phylo` and `Aligned_Fragments`.

```bash
mkdir MitProject Fragments Phylo Aligned_Fragments
```

3. Unzip all the files into the MitProject folder.

```bash
unzip '*.zip' -d MitProject/
```

4. Go to the `MitProject` directory.

```bash
cd MitProject/
```


5. We need to unify the extensions if not only *.fa, but also *.fas and *.fasta occur.

```bash
ls *.fasta # to check
rename 's/.fasta/.fa/g' *.fa* # to rename *.fasta into *.fa
rename 's/.fas/.fa/g' *.fa* # to rename *.fas into *.fa
```

6. Next we check how many fragments there are in each of the files with fragments. The number without D-loop (MitoAnnotator does not pull out the control region) and including 2 repeating tRNAs has to be 37. Everything else are deviations. It is advisable to examine them individually.

```bash
grep -c "^>" *genes* # shows the files and the number of fragments
grep -c "^>" *genes* | grep -v "37" # outputs the files with deviations
```

7. Move all the files with fragments into the `Fragments` directory.

```bash
mv *genes* /path_to_this_directory/Fragments
```

8. Go to the `Fragments` directory.

```bash
cd /path_to_this_directory/Fragments
```

9. Rename the files (delete "_genes" from their names).

```bash
rename 's/_genes//g' *.fa*
# if you want to remove an extra '_' from the name: 
# rename 's/__/_/g' *.fa*
```

10. We add a filename to each sequence name, convert sequences to non-interleaved format, remove intervals and spaces in the name, and rename the duplicated fragments.

`Fragments_processing.sh`
```bash
#!/bin/bash
FILES="*.fa*"
for f in $FILES
do
	echo "Processing $f" 
	awk '/>/{sub(">","&"FILENAME"-");sub(/\.fa/,x)}1' "$f" > tmp && mv tmp "$f" # add a filename to each sequence name 
	awk '/^>/ { if(NR>1) print "";  printf("%s\n",$0); next; } { printf("%s",$0);}  END {printf("\n");}' "$f" > tmp && mv tmp "$f" # make the sequences non-interleaved
	sed -i 's/.[0-9]*..[0-9]*([+-])/ /g' "$f" # remove intervals
	sed -i 's/[[:space:]]//g' "$f" # remove spaces
	awk '(/^>/ && s[$0]++){$0=$0""s[$0]}1;' "$f" > tmp && mv tmp "$f" # rename the duplicated fragments
done
```
To run the script just save the above into `Fragments_processing.sh` and type:
```bash
./Fragments_processing.sh
```

11. Splitting the files into the individual fragments.

`Fragments_splitting.sh`
```bash
#!/bin/bash
FILES="*.fa*"
for f in $FILES
do
	echo "Splitting $f"
	faidx --split-files "$f"
done
```

12. Creating a list of the unique names of the fragments.
```bash
ls *-* | cut -d "." -f1 | cut -d "_" -f3 | cut -d "-" -f2,3 | sort | uniq > Fragments_list.txt
```

13. Creating the matrices based on the fragments.

`Fragments_matrix.sh`
```bash
#!/bin/bash
FILES=$(cat Fragments_list.txt)

for f in $FILES
do
	echo "Assembling $f matrix"
	cat *"$f".* | cut -d "-" -f1 > "$f".fasta
done
```

14. Moving the files with the *.fasta extension into the `Phylo` directory.

```bash
mv *.fasta /path_to_this_directory/Phylo
```

## II. To retrieve the D-loop fragment:

1. Go back to the `MitProject` folder

```bash
cd /path_to_this_directory/MitProject
# rename 's/__/_/g' *.fa* # if you need it
```

2. First, let's try to pull its intervals for each genome (located in a file with *.txt extension) and save them into separate files. The file names will consist of 3 letters, the first of which will most likely be "x".
```bash
grep "D-loop" *.txt | cut  -f1,3 | sed 's/.txt://g' | sed 's/\.\./\t/g' | split -l 1
```

3. Rename the files according to the genome identifier.

`Rename_D-loop.sh`
```bash
#!/bin/bash
FILES="x**"
for f in $FILES
do
	echo "Processing $f"
	mv "$f" $(cut -f1 "$f").bed 
done
```

4. Now you can delete unneeded files if you want to. Do not forget to save the annotations.

```bash
rm *genes* *.txt *.svg *.png *.log *.fasta
```

5. A list of IDs is required. So let's make it.

```bash
ls *[fa,bed] | cut -d "." -f1 | uniq > ID.list
```

6. Renaming the long genbank sequence names in the genome files (if such names remain).

`Rename_GB_seq.sh`
```bash
#!/bin/bash
FILES="*.fa*"
for f in $FILES
do
	echo "Renaming $f"
	awk '/^>/ {gsub(/.fa(sta)?$/,"",FILENAME);printf(">%s\n",FILENAME);next;} {print}' "$f" > tmp && mv tmp "$f"
done
```

7. Pulling sequences based on the intervals and place them into the `D-loop.fasta` file.

`D-loop_matrix.sh`
```bash
#!/bin/bash
FILES=$(cat ID.list)

for f in $FILES
do
	echo "Extracting D-loop from $f"
	seqtk subseq "$f".fa "$f".bed | cut -d ":" -f1 | sed 's/>.*/&-D-loop/' | cut -d "-" -f1 >> D-loop.fasta
done
```

8. Moving the matrix file for D-loop to the `Phylo` directory.

```bash
mv *.fasta /path_to_this_directory/Phylo
```


## III. The alignment:

1. Go to the `Phylo` directory.

```bash
cd /path_to_this_directory/Phylo
```

2. Aligning all fragments in the directory using the `MAFFT` program.

`Align_them_all.sh`
```bash
FILES=$(ls) 

for f in $FILES
do
	echo "Aligning $f matrix"
	mafft "$f" > Aligned_"$f"
done
```

3. Moving the aligned files into the `Aligned_Fragments` directory.

```bash
mv Aligned_* /path_to_this_directory/Aligned_Fragment
```

4. Go to the `Aligned_Fragment` directory.

```bash
cd /path_to_this_directory/Aligned_Fragment
```

5. Renaming the files (remove "Aligned_" as well as "tRNA-").

```bash
rename 's/Aligned_//g' *.fa*
rename 's/tRNA-//g' *.fa*
```

## IV. Assembling the matrix based on the obtained fragments in the required order (the order is given in the genome annotation):

For example, a line of code which uses phyutility to concatenate a matrix of fragments 16S.fasta, 12S.fasta, COI.fasta, ND4.fasta and D-loop.fasta into a matrix with the order of fragments D-loop-16S-12S-COI-ND4:

```bash
phyutility -concat -in D-loop.fasta 16S.fasta 12S.fasta COI.fasta ND4.fasta -out Supermatrix.nexus
```
