@echo off
path d:\Perl\bin
perl tsv_filter.pl < merge_sort.tsv > merge_sort_filter.tsv
perl tsv_filter.pl -o < merge_sort.tsv > merge_sort_filter-o.tsv
