@echo off
type *.tsv |sort.bat > merge_sort.tsv
call merged_tsv2htm.bat
