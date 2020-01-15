#!/bin/bash

# Script for finding and deleting unused language keys in the project

# Get a sorted list of all keys in Language.properties
key_file_path=`find ./src/main/resources/content -name "Language.properties"`;
keys=`awk -F= '{print $1}' $key_file_path`;

# Keys found in project js
# -- multiline for capturing language keys that might be broken to the next line, -o to only print part of line that matches pattern
keys_in_source=`find ./src/main/js \( -name "*.jsx" -o -name "*.js" -o -name "*.ts" -o -name "*.tsx" \) -exec pcregrep -o --multiline 'Liferay.Language.get\((\n|.)*?\)' {} \; | \
# get only the part between quotations in Liferay.Language.get('...')
grep -oh \'.*\' | \
# delete any lines that contain capitals since they are probably not language keys
sed "/[A-Z]/d" | \
# delete the quotations surrounding the key '...'
tr -d \' | \
# sorted
sort -u
`;

# Diff the two outputs and print line numbers only non-matches present in File2,
# which represents language-keys that are not actually used anywwhere in the project.
#
# If we reverse the diff order, we should be able to find language keys in the source code that have no language key.
unused_line_nums=$(diff --new-line-format='>%dn:%L' <(echo "$keys_in_source") <(echo "$keys") | \
	 grep '^>.*$' | \
	 awk -F: '{print $1}' | \
	 tr -d '>');

for key in $unused_line_nums; do
	# go through each line num and replace that line with a blank line
	sed -i '' -e "$key s/.*//" $key_file_path;
done

# delete all the blank lines
sed -i '' -e '/^$/d' $key_file_path;