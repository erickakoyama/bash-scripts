#!/bin/bash

# Script for reporting unused language keys in the project

# Get a list of all keys in Language.properties
key_file_path=`find ./src/main -name "Language.properties"`

unused_keys=

# Diff the two outputs and print line numbers only non-matches present in File2,
# which represents language-keys that are not actually used anywwhere in the project.
unused_line_nums=$(diff --new-line-format='>%dn:%L' <(find ./src/main/js -name "*.js" -exec egrep -A1 'Liferay.Language.get\(' {} \; | grep -oh \'.*\' | tr -d \' | sort -u) \
     <(awk -F= '{print $1}' $key_file_path | sort -u) | \
	 grep '^>.*$' | \
	 awk -F: '{print $1}' | \
	 tr -d '>');

# Would need to check if the key is used on the java side before deletion
# This is in src/mainjava/com/liferay/osb/far/web/internal/clause/operator
# java_keys=""	

# Format line numbers for use in sed to delete each line
sed_delete_str=`echo "$unused_line_nums" | awk '{print $0 "d;" }' | tr -d '\n' `;

# Remove unused keys in $key_file_path
sed -i '' $sed_delete_str $key_file_path;

# also need to trim newline at end of edited file