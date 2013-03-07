#!/bin/perl -w
# Filter TSV twitter messages, excluding or only showing twitter IDs from filter.txt list.
# v130306

use utf8;
use Data::Dump;
use Getopt::Std;
use List::MoreUtils qw{any none};

getopt('', \%opts);

if ($opts{'?'} && $opts{'?'} == 1) {
    print "Usage: $0 [-o] < <input html file> > <output file>\n-o: Output data oOnly from Twitter IDs in the filter.txt file\nOtherwise, filter out data from Twitter IDs in the filter.txt file.\n";
    exit;
}

if ($opts{'o'} && $opts{'o'} == 1) {
    $mode_only = 1;
} else {
    $mode_only = 0;
}

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

open(FILTER, "filter.txt");
@filter = <FILTER>;
chomp @filter;
# dd @filter;

while (<STDIN>) {
    $line = $_;
#    ($tweetid, $url, $time, $convers, $username, $fullname, $text) = split/\t/;
    ($ignore, $ignore, $ignore, $ignore, $username, $ignore, $ignore) = split/\t/;
    $ignore = $ignore; # disable warning.
    if ($mode_only) {
	next if none {$username eq $_} @filter;
    } else {
	next if any {$username eq $_} @filter;
    }
    print $line;
}

# vi:sw=4
