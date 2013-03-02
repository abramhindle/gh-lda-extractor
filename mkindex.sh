cat <<EOF
<html>
<body>
EOF
for file in $*
do
	echo "<img src=\"$file\"/><br/>" 
done
cat <<EOF
</body>
</html>
EOF
