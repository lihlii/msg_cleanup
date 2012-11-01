@echo off
call msg_merge_twitter.bat |msg_sort_twitter.bat > merge_sort.tsv
