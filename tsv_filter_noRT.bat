@echo off
path d:\Perl\bin;d:\cygwin\bin
perl tsv_filter_noRT.pl < merge_sort.tsv | sort.exe -u -t"	" -k8 | sort -n > merge_sort_noRT.tsv
