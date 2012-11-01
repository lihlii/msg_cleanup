@echo off
type twitter_merge*.tsv |msg_sort_twitter.bat > merge_sort.tsv
call tsv2htm.bat
