cd data
mkdir $1
cd $1 && \
hg clone https://code.google.com/p/$1 $1.hg && \
mkdir $1.git && \
cd $1.git && \
git init && \
~/src/fast-export/hg-fast-export.sh -r ../$1.hg
git checkout HEAD && \
perl ~/projects/google-code-bug-tracker-downloader/google-code.pl -project $1 && \
mv $1 issues
