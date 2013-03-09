#!/bin/perl -w
# Convert filter.txt to spamid.htm for easy twitter spam id reporting.
# v130309

open(IN, "filter.txt");
open(OUT, ">spamid.htm");
while (<IN>) {
    s/@(\S+)\n/$1/;
    print OUT "<a href=\"https://twitter.com/$_\" target=\"_blank\">@", $_, "</a><br/>\n";
}

# vi:sw=4
