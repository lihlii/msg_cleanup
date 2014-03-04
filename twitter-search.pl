#!/usr/bin/perl

use LWP::UserAgent;
use JSON;
use Data::Dump;
use LWP::ConnCache; 
use utf8;
use Config::Tiny;

my $Config = Config::Tiny->new;
$Config = Config::Tiny->read('twitter-search.ini');

my $search_string = $Config->{_}->{search_string};
my $tweet_id_begin = $Config->{_}->{tweet_id_begin}; # biggest id to start with.
my $tweet_id_end = $Config->{_}->{tweet_id_end}; # if see id smaller than this on last page, then stop.

$url_prefix_all = 'https://twitter.com/i/search/timeline?q=' . $search_string . '&src=typd&f=realtime&include_available_features=1&include_entities=1&scroll_cursor=';

$url_prefix_top = 'https://twitter.com/i/search/timeline?q=' . $search_string . '&src=typd&f=relevance&composed_count=0&include_available_features=1&include_entities=1&include_new_items_bar=true&latent_count=0&oldest_unread_id=0&refresh_cursor=';

$tweet_id_max = $tweet_id_begin;
$scroll_cursor = "TWEET-$tweet_id_begin-$tweet_id_max";
$url_prefix = $url_prefix_all;
$url = "$url_prefix$scroll_cursor";
$has_more = 1;
$retry_max = 10;
$sleep_seconds = 1;

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
STDOUT->autoflush(1);

my $ua = LWP::UserAgent->new;
$ua->conn_cache(LWP::ConnCache->new()); # keep alive.
$retry = $retry_max;

while ($retry > 0) {
    my $req = HTTP::Request->new(GET => $url );
    my $res = $ua->request($req);
    if ($res->is_success) {
	$json_text = $res->content;
	$json_data = from_json($json_text);
#       dd $json_data;
	$html = $json_data->{items_html};
	if ($html =~ /^\s+$/) {
	    print STDERR "\nNo more.";
	    exit;
	} else {
	    print $html;
	}
	$has_more = $json_data->{has_more_items};
#	print STDERR "\nhas_more=$has_more###";
	$scroll_cursor = $json_data->{scroll_cursor};
	$scroll_cursor =~ /TWEET-(\d+)-.*/;
	$last_tweet_id = $tweet_id;
	$tweet_id = $1;
	if ($tweet_id == $last_tweet_id) {
	    $wait = 1;
	} else {
	    $wait = 0;
	}

	if ($tweet_id <= $tweet_id_end) {
	    print STDERR "\ntweet_id=$tweet_id, end.";
	    exit;
	}
	$url = "$url_prefix$scroll_cursor";
	if ($wait) {
	    $retry --;
	    $sleep_seconds *= 2;
	    print STDERR "\n$tweet_id, retry $retry after $sleep_seconds seconds.";
	} else {
	    $retry = $retry_max;
	    $sleep_seconds = 1;
	    print STDERR "\n$tweet_id, next to download.";
	};
	sleep $sleep_seconds;
    } else {
	print STDERR "\nFailed: $tweet_id, ", $res->status_line;
    }
};

# vim:sw=4
