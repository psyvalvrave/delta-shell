#!/bin/sh
#while read in; do sh test.sh "$in"; done < test.sql 
echo "$1" | curl telnet://localhost:$2
