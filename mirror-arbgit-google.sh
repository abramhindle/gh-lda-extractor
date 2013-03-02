cd data
mkdir $1
cd $1 && \
git clone $2 $1.git && \
perl ~/projects/google-code-bug-tracker-downloader/google-code.pl -project $1 && \
mv $1 issues
