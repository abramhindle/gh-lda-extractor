PROJECT=$1
export PROJECT
rm -rf out
mkdir out
cp data/$1/large.json . || perl bug-tracker-to-json.pl -file data/$1/issues/issues.xml && \
perl git-grep.pl -repo data/$1/$1.git && \
python lda_from_json.py && \
perl lda-to-csv.pl && \
time R --vanilla  -f plots.R
for file in out/run-surveys-*sh
do
	bash -x $file 
done
cp out.csv  topicsummary.csv out
mv out out.$PROJECT
