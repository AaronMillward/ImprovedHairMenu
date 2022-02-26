rm -rf build/
mkdir build/
cp -rf improved-hair-menu/* build/

#Replace symlinks created by git-annex with real files
find ./build/ -type l | while read line; do
	FILENAME=$(readlink -f -- "$line")
	cp --remove-destination $FILENAME $line
done