@echo off
type merge*.tsv |sort.bat > merge_sort.tsv
call tsv2htm.bat
