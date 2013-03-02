cd data
mkdir $1
cd $1 && \
git-svn clone http://$1.googlecode.com/svn/ $1.git && \
perl ~/projects/google-code-bug-tracker-downloader/google-code.pl -project $1 && \
mv $1 issues
