#!/bin/perl -w
# Convert TSV twitter messages to simple HTML.
# v120929

#if ($ARGV[0] eq "-?") {
#    print "Convert TSV twitter messages to simple HTML.\nUsage: $0 <input TSV file> > <output file>\ninput file charset should be UTF8.\n";
#    exit;
#}

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
    ($sn, $url, $time, $username, $fullname, $text) = split/\t/;
    print "$fullname $username <a href=\"$url\">$time</a><br />\n$text<br />\n<br />\n";
}

print "</body>\n</html>\n";

# vi:sw=4
