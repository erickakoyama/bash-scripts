#!/bin/bash

# Script for finding and deleting unused language keys in the project

# Get a sorted list of all keys in Language.properties
key_file_path=`find ./src/main/resources/content -name "Language.properties"`;
keys=`awk -F= '{print $1}' $key_file_path | sort -u`;

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

# Diff the two outputs and print key value pairs of line_num:lang_key only non-matches present in File2,
# which represents language-keys that are not actually used anywwhere in the js code.
unused_line_key_values=$(diff --new-line-format='>%dn:%L' <(echo "$keys_in_source") <(echo "$keys") | \
	 grep '^>.*$' | \
	 tr -d '>');

# Before deleting the key, we should check if it is used in any java files
for key_value_pair in $unused_line_key_values; do
	line_num=`echo "$key_value_pair" | cut -d: -f 1`;
	key=`echo "$key_value_pair" | cut -d: -f 2`;
	# If the string is a match within 20 characters, we'll call it a match, in case the string is concatenated.
	if [ $(find ./src/main/java \( -name "*.java" \) -exec pcregrep -o --multiline \""${key:0:20}" {} \; | wc -l) -eq 0 ]
	then
		# replace line with a blank line
		sed -i '' -e "$line_num s/.*//" $key_file_path;
	else 
		echo "Woops this language key is used in the .java files: ${key}";
	fi
done

# # # delete all the blank lines
sed -i '' -e '/^$/d' $key_file_path;