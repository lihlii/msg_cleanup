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

use URI::Escape;
use HTML::TokeParser;
use HTML::Entities;
use POSIX qw(strftime);
use Encode;
use Encode::Locale;
use Getopt::Std;

my $html_mode = 0;
my $tsv_mode = 0;
my $mobile_input = 0;
my $infile = "index.htm";
my %opts;

getopt('', \%opts);

if ($opts{'?'} == 1) {
    print "Usage: $0 [-h|-t] [-m] <input html file> > <output file>\n-h: Output HTML format, otherwise text format.\n-t: Output Tab seperated value format with HTML data fields for further processing like sorting.\n-m: input file is mobile.twitter.com page.\n";
    exit;
}

if ($opts{'h'} == 1) {
    $html_mode = 1;
} elsif ($opts{'t'} == 1) {
    $tsv_mode = 1;
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
my $fullname = "";
my $username = "";
my $url = "";
my $tweetid = "";
my ($time, $time_string);

sub print_tweet {
    if ($text_line) {
	if ($html_mode) {
	    $text_line = "$fullname \@$username <a href=\"$url\">$time_string</a><br />\n$text_line<br />\n<br />\n";
	} elsif ($tsv_mode) {
	    $text_line = "$tweetid\t$url\t$time_string\t\@$username\t$fullname\t$text_line\n";
	} else {
	    $text_line = "$fullname \@$username $time_string $url\n$text_line\n\n";
	}
	print $text_line;
	$text_line = "";
	$img ="";
    }
}

while (my $token = $p->get_token) {

    if ($token->[0] eq "S" && $token->[1] eq "link" && $token->[2]{"rel"} =~ /icon/) {
	$mobile_input = 0 if $token->[2]{"href"} =~ m|//twitter.com/|;
	$mobile_input = 1 if $token->[2]{"href"} =~ m|/twitter-mobile/|; # mobile twitter page.
	next;
    }

    # Handle mobile page.
    if ($mobile_input) {
        next if $token->[0] ne "S"; # Find start tag.
        if ($token->[1] eq "div") {
	    my $class = $token->[2]{"class"}; 

	    if ($class eq "fullname" || $class eq "full-name") { # Chrome and Firefox saved pages differ.
		print_tweet;
		$fullname = $p->get_trimmed_text("/div");
		next;
	    } elsif ($class =~ /tweet-text/) {
		while (my $token = $p->get_token) {
		    if ($token->[0] eq "E" && $token->[1] eq "div") { # end of tweet text.
			$text_line =~ s/^\s+//; # trim beginning blank chars including \n
			$text_line =~ s/\s+$//; # trim ending blank chars including \n
			$text_line =~ y/\n/ /; # remove in-between newline chars.
			last;
		    } elsif ($token->[0] eq "T") {
			my $text = $token->[1];
			decode_entities($text);
			$text_line .= $text;
		    } elsif ($token->[0] eq "S" && $token->[1] eq "a" && ($token->[2]{"class"} eq "twitter_external_link" || $token->[2]{"class"} =~ /twitter-timeline-link/)) {
			my $link = $token->[2]{"href"};
			my $link_expanded = $token->[2]{"data-url"};
			$text = $p->get_text("/a");
			$text_line .= ($link_expanded ? ("<a href=\"$link\">$link_expanded</a>" ) : "<a href=\"$link\">$text</a>");
			$p->get_tag("/a");
		    }
		}
		next;
	    } elsif ($class eq "metadata") {
		my $token = $p->get_tag("a");
		$url = $token->[1]{"href"};
		$url =~ m|^(.+)/([^/]+)/status/(\d+).*$|;
		$url = "$1/$2/status/$3";
		$username = $2;
		$tweetid = $3;
		$time_string = $p->get_text("/a");
		next;
	    } elsif ($class eq "timestamp-row") { # Firefox saved apple mobile twitter page.
		my $token = $p->get_tag("a");
		$url = $token->[1]{"href"};
		$url =~ m|^(.+)/([^/]+)/status/(\d+).*$|;
		$url = "$1/$2/status/$3";
		$username = $2;
		$tweetid = $3;
		$time = $token->[1]{"timestamp"};
		$time /= 1000 if length($time) > 12; # data-time is in miliseconds if 13 digits long.
		$time_string = strftime "%Y-%m-%d %H:%M:%S UTC", gmtime($time);
		next;
	    } elsif ($class eq "card-photo") {
		my $token = $p->get_tag("img");
		$img = $token->[1]{"src"};
		next if !$img;
		$img = uri_escape($img, "#");
		if ($html_mode) {
		    $text_line .= "<br /><img src=\"$img\">";
		} elsif ($tsv_mode) {
		    $text_line .= "<br /><img src=\"$img\">";
		} else {
		    $text_line .= "IMG=$img";
		}
		next;
	    }

	    next;
	} elsif ($token->[1] eq "strong") {
	    my $class = $token->[2]{"class"}; 
	    if ($class eq "fullname") {
		print_tweet;
		$fullname = $p->get_trimmed_text("/strong");
	    }
	    next;
	} elsif ($token->[1] eq "span") {
	    my $class = $token->[2]{"class"}; 
	    if ($class eq "full-name") {
		$fullname = $p->get_trimmed_text("/span");
	    }
	    next;
	} elsif ($token->[1] eq "td") {
	    my $class = $token->[2]{"class"}; 
	    if ($class eq "timestamp") {
		my $token = $p->get_tag("a");
		$url = $token->[1]{"href"};
		$url =~ m|^(.+)/([^/]+)/status/(\d+).*$|;
		$url = "$1/$2/status/$3";
		$username = $2;
		$tweetid = $3;
		$time_string = $p->get_text("/a");
	    }
	    next;
	} elsif ($token->[1] eq "li") {
	    my $screen_name = $token->[2]{"screen_name"}; 
	    next if !$screen_name;
	    print_tweet;

	    $username = $screen_name;
	    $tweetid = $token->[2]{"data_id"}; 
	    $time = $token->[2]{"timestamp"}; 
	    $time /= 1000 if length($time) > 12; # data-time is in miliseconds if 13 digits long.
	    $time_string = strftime "%Y-%m-%d %H:%M:%S UTC", gmtime($time);
	    $url = "https://twitter.com/$username/status/$tweetid";
	}
    }

    # Handle non-mobile page.  Search for "div" tag.
    next if $token->[0] ne "S"; # Find start tag.
    next if ($token->[1] ne "div");

    my $has_photo_card = 0;
    my $has_media_iframe = 0;
    my $is_opened = 0;

# Parse the following line to construct the tweet URL, since <a href> tag not always reliable in saved html page for all tweets.
# <div class="tweet permalink-tweet js-actionable-user js-hover js-actionable-tweet opened-tweet" data-associated-tweet-id="252421276851920899" data-tweet-id="252421276851920899" data-item-id="252421276851920899" data-screen-name="lihlii" data-name="lihlii" data-user-id="16526760" data-is-reply-to="false" data-mentions="yujie89 awfan">

    my $class = $token->[2]{"class"}; 
    if ($class =~ /proxy-tweet-container/) {
        $p->get_tag("div"); # skip duplicate entry without photo.
	next;
    }

    if ($class eq "media-instance-container") { # media card, photo embedded.
	my $t = $p->get_tag("iframe");
	my $iframe = $t->[1]{"src"};
        $iframe = uri_unescape($iframe);
	my $iframe_path = $iframe;
	$iframe_path =~ s|[^/]+$||;
	my $fn = encode(locale_fs => $iframe); # Translate utf8 string to locale language filesystem file name.
	my $c = HTML::TokeParser->new($fn);
	while ($t = $c->get_tag("div")) {
	    $class = $t->[1]{"class"}; 
	    last if $class eq "tweet-media";
	}
	$t = $c->get_tag("img");
	$img = $iframe_path . $t->[1]{"src"} if $t;

	if ($img) {
            $img = uri_escape($img, "#");
	    if ($html_mode) {
		$text_line .= "<br /><img src=\"$img\">";
	    } elsif ($tsv_mode) {
		$text_line .= "<br /><img src=\"$img\">";
	    } else {
		$text_line .= "IMG=$img";
	    }
	}
    }

    my $t = $token->[2]{"data-tweet-id"}; # tweet message entry start.
    next if !$t;

# has last tweet extracted but not printed.
    print_tweet;
    $tweetid = $t;

    $username = $token->[2]{"data-screen-name"};
    next if !$username;
    $fullname = $token->[2]{"data-name"};
    $fullname =~ s/\s+$//; # trim ending blank chars including \n
    next if !$fullname;
    my $cardtype = $token->[2]{"data-card-type"}; 
    $has_photo_card = 1 if $cardtype eq "photo";
    my $footer = $token->[2]{"data-expanded-footer"}; # The photo URL in collapsed card footer.
    if ($footer) {
    	$is_opened = 1 if $class =~ /opened-tweet/;
	$has_media_iframe = 1 if $is_opened && $footer =~ /js-tweet-media-container/;
    }
    
    $url = "https://twitter.com/$username/status/$tweetid";

# find next <a> and <span> tag, with timestamp.
# <a href="https://twitter.com/awfan/status/252419939175120896" class="tweet-timestamp js-permalink js-nav" title="7:49 AM - 30 Sep 12"><span class="_timestamp js-short-timestamp js-relative-timestamp" data-time="1349016577" data-long-form="true">10m</span></a>

    while ($token = $p->get_tag("small")) {
	$class = $token->[1]{"class"};
	last if $class eq "time";
    }
    $token = $p->get_tag("span");
    $time = $token->[1]{"data-time"};
    $time /= 1000 if length($time) > 12; # data-time is in miliseconds if 13 digits long.
    $time_string = strftime "%Y-%m-%d %H:%M:%S UTC", gmtime($time);

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
	} elsif ($token->[0] eq "T") {
	    my $text = $token->[1];
	    decode_entities($text);
	    $text_line .= $text;
	} elsif ($token->[0] eq "S" && $token->[1] eq "a" && $token->[2]{class} eq "twitter-timeline-link") {
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
            $img = uri_escape($img, "#");
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

# has last tweet extracted but not printed.
print_tweet;

print "</body>\n</html>\n" if $html_mode;

# vi:sw=4
