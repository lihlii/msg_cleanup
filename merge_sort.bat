@echo off
call merge.bat
call convert.bat |sort.bat > merge_sort.tsv
