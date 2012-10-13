# sort twitter messages according to status serial number (thus time).
# v120706
# 1. Install perl, eg. ActivePerl http://www.activestate.com/activeperl
# 2. Preprocess twitter message web page using msg_cleanup_twitter.bat.
# 3. Save this script as msg_sort_twitter.pl, in the same folder as in step 2.
# 4. Open a command window, cd to the folder where the files are stored.
# 5. Input command: msg_sort_twitter.pl -h index.htm > index-o.htm
# 6. Open index-o.htm in browser to check the result.

use HTML::TokeParser;
use HTML::Entities qw(decode_entities);
$html_mode = 0;
$infile = "index.htm";

if ($ARGV[0] eq "-?") {
    print "Usage: $0 [-h] <input html file> > <output file>\n-h: Output HTML format, otherwise text format.\n";
    exit;
}

if ($ARGV[0] eq "-h") {
    $html_mode = 1;
    shift;
}

open(my $fh, "<:utf8", (shift || $infile)) || die "Can't open file: $!";

$head=<<EOF;
<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=UTF-8">
</head>
<body>
EOF

print $head if $html_mode;

while (<$fh>) {
    if (m#^(.+) (@\S+) <a href="(\S+)">(.+)</a><br />$#) {
	$name = $1;
	$id = $2;
	$url = $3;
	$date = $4;

	$_ = <$fh>;
	if (m#^$#) {
	    print "here\n";
	    $_ = <$fn>;
	    $_ =~ m#^\s*(\S.*)$#;
	    $text = $1;
	} elsif (m#^\s*(\S.*)<br />$#) {
	    $text = $1;
	}

	print "name=$name; id=$id; url=$url; date=$date; text=$text<br />\n";
    }
}

print "</body>\n</html>\n" if $html_mode;

