#!/bin/bash

# Script for reporting unused language keys in the project

# Get a list of all keys in Language.properties
key_file_path=`find ./src/main -name "Language.properties"`;

keys=`awk -F= '{print $1}' $key_file_path | sort -u`;

# Would need to check if the key is used in any java clause operator files before deletion
# This is in src/mainjava/com/liferay/osb/far/web/internal/clause/operator
java_keys_path='./src/main/java/com/liferay/osb/faro/web/internal/clause/operator';

# Keys used for java clause operators
keys_in_java_source=`find $java_keys_path -name "*Operator.java" -exec grep -oh '_NAME = "[a-z-]*";' {} \; | \
grep -oh \".*\" | tr -d \"`;
# echo "$keys_in_java_source";

# Keys found in project js
keys_in_js_source=`find ./src/main/js -name "*.js" -exec egrep -A1 'Liferay.Language.get\(' {} \; | \
grep -oh \'.*\' | tr -d \'`;
# echo "$keys_in_js_source";

keys_in_all_sources=`echo "$keys_in_java_source"; echo "$keys_in_js_source" | sed '/^\s*$/d' | sort -u`;

# Diff the two outputs and print line numbers only non-matches present in File2,
# which represents language-keys that are not actually used anywwhere in the project.
unused_line_nums=$(diff --new-line-format='>%dn:%L' <(echo "$keys_in_all_sources") <(echo "$keys") | \
	 grep '^>.*$' | \
	 awk -F: '{print $1}' | \
	 tr -d '>');

# Format line numbers for use in sed to delete each line
sed_delete_str=`echo "$unused_line_nums" | awk '{print $0 "d;" }' | tr -d '\n' `;

# Remove unused keys in $key_file_path
sed -i '' $sed_delete_str $key_file_path;

# also need to trim newline at end of edited file