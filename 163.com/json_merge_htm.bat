@echo off
call json2tsv.bat
type *.tsv > merge.tsv
perl tsv2htm.pl < merge.tsv > merge.htm 2>> TSV2HTM.ERR
