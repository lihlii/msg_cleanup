#!/bin/perl -w
# Convert 163.com comments TSV twitter messages to simple HTML.
# v130306

#if ($ARGV[0] eq "-?") {
#    print "Convert TSV twitter messages to simple HTML.\nUsage: $0 <input TSV file> > <output file>\ninput file charset should be UTF8.\n";
#    exit;
#}

use utf8;
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

$head=<<EOF;
<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=UTF-8">
</head>
<body>
EOF

print $head;

while (<STDIN>) {
    ($nr, $qnr, $time, $name, $from, $text) = split/\t/;
    print "[$nr.$qnr] $time $name $from<br />\n$text<br />\n<br />\n";
}

print "</body>\n</html>\n";

# vi:sw=4
