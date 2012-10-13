# clean up friendfeed messages
# v120612
# 1. Save friendfeed message web page as complete html, eg. 01.htm
# NOTE: Chrome browser can't save twitter message in HTML only mode.
#
# 2. Install perl, eg. ActivePerl http://www.activestate.com/activeperl
# 3. Save this script as msg_cleanup_friendfeed.pl, in the same folder as in step 1.
# 4. Open a command window, cd to the folder where the files are stored.
# 5. Input command: msg_cleanup_friendfeed.pl -h 01.htm > 01o.htm
# 6. Open 01o.htm in browser to check the result.

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
$p = HTML::TokeParser->new($fh);

$head=<<EOF;
<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=UTF-8">
</head>
<body>
EOF

print $head if $html_mode;

while (my $token = $p->get_tag("div")) {
    $class = $token->[1]{class};
    next if $class ne "name";

    $token = $p->get_tag("a");
    $class = $token->[1]{class};
    next if $class ne "l_profile";
    my $name = $p->get_text("/a");

    $token = $p->get_tag("div");
    $class = $token->[1]{class};
    next if $class ne "text";

    my $text = "";
    while ($token = $p->get_token) {
	if ($token->[0] eq "E" && $token->[1] eq "div") {
	    if ($html_mode) {
		$text .= "<br />\n<br />\n";
	    } else {
		$text .= "\n\n";
	    }
	    last;
	}
	if ($token->[0] eq "T") {
	    my $t = $token->[1];
	    decode_entities($t);
	    $text .= $t;
	}
	if ($token->[0] eq "S" && $token->[1] eq "a") {
	    my $link_expanded = $token->[2]{"title"};
	    next if !$link_expanded;
	    my $link = $token->[2]{"href"};
	    if ($html_mode) {
		$text .= "<a href=\"$link\">$link_expanded</a>";
	    } else {
		$text .= " $link = $link_expanded ";
	    }
	    $p->get_tag("/a");
	}
    }

    $token = $p->get_tag("div");
    $class = $token->[1]{class};
    next if $class ne "info";
    $token = $p->get_tag("a");
    $class = $token->[1]{class};
    next if $class ne "date";
    my $url_f = $token->[1]{href};
    my $date = $p->get_text("/a");

    $token = $p->get_tag("a");
    $class = $token->[1]{class};
    next if $class ne "service";
    my $url_s = $token->[1]{href};
    my $service = $p->get_text("/a");

    my $header;
    if ($html_mode) {
	$header = "<a href=\"$url_f\">$name</a> <a href=\"$url_s\">$date $service</a><br />\n";
    } else {
	$header = "$name $url_f $date $service $url_s\n";
    }
    print $header, $text;
}

print "</body>\n</html>\n" if $html_mode;

