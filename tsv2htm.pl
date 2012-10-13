#!/bin/perl -w
# Convert TSV twitter messages to simple HTML.
# v120929

my $infile = "msg_merge_twitter.txt";
my $outfile = "tsv2htm.htm";

if ($ARGV[0] eq "-?") {
    print "Convert TSV twitter messages to simple HTML.\nUsage: $0 <input TSV file> > <output file>\ninput file charset should be UTF8.\n";
    exit;
}

open(my $fh, "<:utf8", (shift || $infile)) || die "Can't open file: $!";
open(my $fo, ">$outfile") || die "Can't open file: $!";

$head=<<EOF;
<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=UTF-8">
</head>
<body>
EOF

print $fo $head;

while (<$fh>) {
    ($sn, $url, $time, $username, $fullname, $text) = split/\t/;
    print $fo "$fullname $username <a href=\"$url\">$time</a><br />\n$text<br />\n<br />\n";
}

print $fo "</body>\n</html>\n";

# vi:sw=4
