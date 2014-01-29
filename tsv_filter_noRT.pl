#!/bin/perl -w
# Filter TSV twitter messages, excluding duplicate RT messages.
# TODO: Not done.
# v130306

use utf8;
use Data::Dump;
use Getopt::Std;
use List::MoreUtils qw{any none};

getopt('', \%opts);

if ($opts{'?'} && $opts{'?'} == 1) {
    print "Usage: $0 < <input html file> > <output file>\n";
    exit;
}

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

while (<STDIN>) {
    ($tweetid, $url, $time, $convers, $username, $fullname, $text) = split/\t/;
#    ($ignore, $ignore, $ignore, $ignore, $username, $ignore, $ignore) = split/\t/;
#    $ignore = $ignore; # disable warning.
    chomp $text;
    my $text_noRT = $text;
    $text_noRT =~ s/^((RT[":]?|[>"“]|&gt;)\s*(@[A-Za-z0-9_]+:?\s*)+)+//g; # text line without RT prefixes for filtering duplicate RT messages later.
    $text_noRT =~ s/<[^>]+>//g; # ignore html tags and href urls
    $text_noRT =~ s/\s+//g; # ignore space
    print "$tweetid\t$url\t$time\t$convers\t$username\t$fullname\t$text\t$text_noRT\n";
}

# vi:sw=4
