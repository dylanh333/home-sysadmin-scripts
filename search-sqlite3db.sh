#!/bin/bash

LICENSE='
MIT License

Copyright (c) 2017 Dylan Hicks (github.com/dylanh333)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
'

COPYRIGHT=$(echo "$LICENSE" | grep -E "^Copyright")

function usage(){
	printf "Scours ALL columns from ALL tables of <database>, checks if\n"
	printf "they're LIKE <string>, and then returns a set of newline\n"
	printf "delimited queries that will return these matches, suitable for\n"
	printf "piping directly into sqlite3.\n\n"
	printf "Usage: $0 <database> <string>\n"
	printf " <database>\tAn sqlite3 .db file\n"
	printf " <string>\tA string that is matched against each cell\n"
	printf "\t\tof each table using the LIKE operator.\n"
	printf "\t\tProtip: wrap string in %% symbols.\n\n"
	printf '%s\n' "$COPYRIGHT"
}

function getTables(){
	database=$1

	echo "select name from sqlite_master where type='table';" \
	| sqlite3 "$database"
}

function getColumns(){
	database=$1
	table=$2

	sql=$(
		echo "
			select sql from sqlite_master
			where type='table' and name='$table';
		" | sqlite3 "$database"
	)

	cols=$(
		echo "$sql" \
		| sed -r "
			s/create( |\t)+table[^(]+//gi;
			s/^\(//; s/\)$//;
			s/('([^']|'')+'|\"([^\"]|\"\")+\"|[^ \t,$]+)[^,$]*/\1/g;
			s/,( |\t)*/\n/g;
		"
	)

	echo "$cols"
}

function buildMatchQuery(){
	table=$1
	columns=$2
	string=$3

	printf 'SELECT * FROM \"%s\" WHERE ' "$table"
	set notFirstRow=""
	echo "$columns" | while read column; do
		if [ -n "$notFirstRow" ]; then
			printf " OR "
		fi
	
		printf '%s LIKE "%s"' "$column" "$string"
		notFirstRow="true"
	done
	printf ";\n"
}

function main(){
	database="$1"
	string="$2"

	if [ -z "$database" -o -z "$string" ]; then
		usage
		return 1	
	fi

# This is how it used to work:
#	tables=$(
#		getTables "$database" | while read table; do
#			echo "select * from [$table];" \
#			| sqlite3 "$database" \
#			| grep -q "$string" \
#			&& echo "$table"
#		done
#	)

	getTables "$database" | while read table; do
		columns=$(getColumns "$database" "$table")
			
		matchingColumns=$(
			echo "$columns" | while read column; do
				query="
					select $column from \"$table\"
					where $column like \"$string\";
				"
				matches=$(echo "$query" | sqlite3 "$database")
				if [ -n "$matches" ]; then
					echo "$column"
				fi
			done
		)
		
		if [ -n "$matchingColumns" ]; then
			buildMatchQuery "$table" "$matchingColumns" "$string"
		fi
	done		
}

main "$1" "$2"
