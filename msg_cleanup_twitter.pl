#!/bin/perl -w
# clean up twitter messages
# v120612
# 1. Save twitter message web page as complete html, eg. 01.htm
# NOTE: Chrome browser can't save twitter message in HTML only mode.
#
# 2. Install perl, eg. ActivePerl http://www.activestate.com/activeperl
# 3. Save this script as twitter_msg_cleanup.pl, in the same folder as in step 1.
# 4. Open a command window, cd to the folder where the files are stored.
# 5. Input command: twitter_msg_cleanup.pl -h 01.htm > 01o.htm
# 6. Open 01o.htm in browser to check the result.

use HTML::TokeParser;
use HTML::Entities qw(decode_entities);
use POSIX qw(strftime);
use Encode;
use Encode::Locale;

my $html_mode = 0;
my $tsv_mode = 0;
my $infile = "index.htm";

if ($ARGV[0] eq "-?") {
    print "Usage: $0 [-h | -t] <input html file> > <output file>\n-h: Output HTML format, otherwise text format.\n-t: Output Tab seperated value format with HTML data fields for further processing like sorting.\n";
    exit;
}

if ($ARGV[0] eq "-h") {
    $html_mode = 1;
    shift;
}

if ($ARGV[0] eq "-t") {
    $tsv_mode = 1;
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

my $text_line = "";
my $img = "";

while (my $token = $p->get_tag("div")) {
    my $has_photo_card = 0;
    my $has_media_iframe = 0;
    my $is_opened = 0;

# Parse the following line to construct the tweet URL, since <a href> tag not always reliable in saved html page for all tweets.
# <div class="tweet permalink-tweet js-actionable-user js-hover js-actionable-tweet opened-tweet" data-associated-tweet-id="252421276851920899" data-tweet-id="252421276851920899" data-item-id="252421276851920899" data-screen-name="lihlii" data-name="lihlii" data-user-id="16526760" data-is-reply-to="false" data-mentions="yujie89 awfan">

    my $class = $token->[1]{"class"}; 
    if ($class =~ "proxy-tweet-container") {
        $p->get_tag("div"); # skip duplicate entry without photo.
    };

    if ($class eq "media-instance-container") { # media card, photo embedded.
	$token = $p->get_tag("iframe");
	my $iframe = $token->[1]{"src"};
	my $iframe_path = $iframe;
	$iframe_path =~ s|[^/]+$||;
	my $fn = encode(locale_fs => $iframe); # Translate utf8 string to locale language filesystem file name.

	my $c = HTML::TokeParser->new($fn);
	while ($token = $c->get_tag("div")) {
	    $class = $token->[1]{"class"}; 
	    last if $class eq "tweet-media";
	}
	$token = $c->get_tag("img");
	$img = $iframe_path . $token->[1]{"src"};

	if ($img) {
	    if ($html_mode) {
		$text_line .= "<br /><img src=\"$img\">";
	    } elsif ($tsv_mode) {
		$text_line .= "<br /><img src=\"$img\">";
	    } else {
		$text_line .= "IMG=$img";
	    }
	}
    }

    my $tweetid = $token->[1]{"data-tweet-id"}; # tweet message entry start.
    next if !$tweetid;

    if ($text_line) { # has last tweet extracted but not printed.
	if ($html_mode) {
	    $text_line .= "<br />\n<br />\n";
	} elsif ($tsv_mode) {
	    $text_line .= "\n";
	} else {
	    $text_line .= "\n\n";
	}
	print $text_line;
	$text_line = "";
	$img ="";
    }

    my $username = $token->[1]{"data-screen-name"};
    next if !$username;
    my $fullname = $token->[1]{"data-name"};
    $fullname =~ s/\s+$//; # trim ending blank chars including \n
    next if !$fullname;
    my $cardtype = $token->[1]{"data-card-type"}; 
    $has_photo_card = 1 if $cardtype eq "photo";
    my $footer = $token->[1]{"data-expanded-footer"}; # The photo URL in collapsed card footer.
    if ($footer) {
    	$is_opened = 1 if $class =~ /opened-tweet/;
	$has_media_iframe = 1 if $is_opened && $footer =~ /js-tweet-media-container/;
    }
    
    my $url = "https://twitter.com/$username/status/$tweetid";

# find next <a> and <span> tag, with timestamp.
# <a href="https://twitter.com/awfan/status/252419939175120896" class="tweet-timestamp js-permalink js-nav" title="7:49 AM - 30 Sep 12"><span class="_timestamp js-short-timestamp js-relative-timestamp" data-time="1349016577" data-long-form="true">10m</span></a>

    while ($token = $p->get_tag("small")) {
	$class = $token->[1]{"class"};
	last if $class eq "time";
    }
    $token = $p->get_tag("span");
    my $time = $token->[1]{"data-time"};
    $time /= 1000 if length($time) > 12; # data-time is in miliseconds if 13 digits long.
    my $time_string = strftime "%Y-%m-%d %H:%M:%S UTC", gmtime($time);

    if ($html_mode) {
	print "$fullname \@$username <a href=\"$url\">$time_string</a><br />\n";
    } elsif ($tsv_mode) {
#		$url =~ m|.+/([^/]+)$|; # extract the serial number part for time ordered sorting.
#		$sn = $1;
	print $time, "\t", $url, "\t", $time_string, "\t@", $username, "\t", $fullname, "\t";
    } else {
	print "$fullname \@$username $time_string $url\n";
    }

    $token = $p->get_tag("p");
    $class = $token->[1]{"class"};
    next if $class !~ /^js-tweet-text/;
#    my @img, $img_c;
#    $img_c = 0;
    while ($token = $p->get_token) {
	if ($token->[0] eq "E" && $token->[1] eq "p") { # end of tweet text.
	    $text_line =~ s/^\s+//; # trim beginning blank chars including \n
	    $text_line =~ s/\s+$//; # trim ending blank chars including \n
	    $text_line =~ y/\n/ /; # remove in-between newline chars.
	    last;
	}
	if ($token->[0] eq "T") {
	    my $text = $token->[1];
	    decode_entities($text);
	    $text_line .= $text;
	}
	if ($token->[0] eq "S" && $token->[1] eq "a" && $token->[2]{class} eq "twitter-timeline-link") {
	    my $link = $token->[2]{"href"};
	    my $link_expanded = $token->[2]{"data-expanded-url"};
	    my $link_ultimate = $token->[2]{"data-ultimate-url"};
	    $text = $p->get_text("/a");
	    $text_line .= ($link_expanded ? ("<a href=\"$link\">$link_expanded</a>" ) : "<a href=\"$link\">$text</a>") . (($link_ultimate && $link_ultimate ne $link_expanded) ? " = <a href=\"$link_ultimate\">$link_ultimate</a> " : "");
	    $p->get_tag("/a");
#	    $link = $link_ultimate ? $link_ultimate : $link_expanded;
#	    $img[$img_c++] = $link if $link =~ /\.(jpg|gif|png)$/i;
#	    $img[$img_c++] = $link if $link =~ m{^https?://img.ly/}i;
	}
    }

    if ($has_photo_card) { # contains photo card.
	if ($footer) {
	    decode_entities($footer);
	    my $c = HTML::TokeParser->new(\$footer);
	    while ($token = $c->get_tag("div")) {
		$class = $token->[1]{"class"}; 
		last if $class eq "media";
	    }
	    $token = $c->get_tag("img");
	    $img = $token->[1]{"src"};
	} else {
	    while ($token = $p->get_tag("div")) {
		$class = $token->[1]{"class"};
		last if $class eq "media";
	    }
	    $token = $p->get_tag("img");
	    $img = $token->[1]{"src"};
	}

	if ($img) {
	    if ($html_mode) {
		$text_line .= "<br /><img src=\"$img\">";
	    } elsif ($tsv_mode) {
		$text_line .= "<br /><img src=\"$img\">";
	    } else {
		$text_line .= "IMG=$img";
	    }
	}
    }
}

if ($text_line) { # has last tweet extracted but not printed.
    print $text_line;
    $text_line = "";
}

print "</body>\n</html>\n" if $html_mode;

# vi:sw=4
