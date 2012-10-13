# clean up mobile.twitter messages
# v120612
# 1. Save twitter message web page as complete html, eg. 01.htm
# NOTE: Chrome browser can't save twitter message in HTML only mode.
#
# 2. Install perl, eg. ActivePerl http://www.activestate.com/activeperl
# 3. Save this script as mobile.twitter_msg_cleanup.pl, in the same folder as in step 1.
# 4. Open a command window, cd to the folder where the files are stored.
# 5. Input command: mobile.twitter_msg_cleanup.pl -h 01.htm > 01o.htm
# 6. Open 01o.htm in browser to check the result.

use HTML::TokeParser;
use HTML::Entities qw(decode_entities);
$html_mode = 0;

if ($ARGV[0] eq "-?") {
    print "Usage: $0 [-h] <input html file> > <output file>\n-h: Output HTML format, otherwise text format.\n";
    exit;
}

if ($ARGV[0] eq "-h") {
    $html_mode = 1;
    shift;
}

open(my $fh, "<:utf8", (shift || "index.htm")) || die "Can't open file: $!";
$p = HTML::TokeParser->new($fh);

$head=<<EOF;
<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=UTF-8">
</head>
<body>
EOF

print $head if $html_mode;

while (my $token = $p->get_tag("td")) {
    my $class = $token->[1]{class};
    next if $class ne "user-info";
    $token = $p->get_tag("strong");
    $class = $token->[1]{class};
    next if $class ne "fullname";
    my $fullname = $p->get_text("/strong");
    $token = $p->get_tag("span");
    $class = $token->[1]{class};
    next if $class ne "username";
    $p->get_tag("/span");
    my $username = $p->get_trimmed_text("/span");
    $token = $p->get_tag("td");
    $class = $token->[1]{class};
    next if $class ne "timestamp";
    $token = $p->get_tag("a");
    my $url = $token->[1]{href};
    my $time = $p->get_text("/a");
    if ($html_mode) {
	print "<a href=\"$url\">$fullname $username $time</a><br />\n";
    } else {
	print "$fullname $username $time $url\n";
    }

    $token = $p->get_tag("div");
    $class = $token->[1]{class};
    next if $class ne "tweet-text";
    while ($token = $p->get_token) {
	if ($token->[0] eq "E" && $token->[1] eq "div") {
	    if ($html_mode) {
		print "<br />\n<br />\n";
	    } else {
		print "\n\n";
	    }
	    last;
	}
	if ($token->[0] eq "T") {
	    my $text = $token->[1];
	    decode_entities($text);
	    print $text;
	}
	if ($token->[0] eq "S" && $token->[1] eq "a" && $token->[2]{class} eq "twitter_external_link") {
	    $link = $token->[2]{"href"};
	    $link_text = $p->get_text("/a");
	    if ($html_mode) {
		print "<a href=\"$link\">$link_text</a>";
	    } else {
		print " $link = $link_text ";
	    }
	}
    }
}

print "</body>\n</html>\n" if $html_mode;

