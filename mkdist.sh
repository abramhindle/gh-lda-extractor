PROJECT=$1
cd out
DIR=`wwwpass2.pl $1`
mkdir $DIR
ln survey*odt survey*png survey*html survey*pdf 0-*png $DIR/
bash ../mkindex.sh 0-*png > $DIR/index.html
cp ../consent.* $DIR/
cp ../consent_* $DIR/
cd $DIR
echo Options -Indexes > .htaccess
cd ..
#spup $DIR
rsync -rPv ./$DIR abez@softwareprocess.es:softwareprocess.es/a/
