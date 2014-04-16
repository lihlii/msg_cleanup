#!/usr/bin/perl

use LWP::UserAgent;
use JSON;
use Data::Dump;
use LWP::ConnCache; 
use utf8;
use Config::Tiny;

my $Config = Config::Tiny->new;
$Config = Config::Tiny->read('twitter-user-profile.ini');

my $user_string = $Config->{_}->{user_string};
my $tweet_id_begin = $Config->{_}->{tweet_id_begin}; # biggest id to start with.
my $tweet_id_end = $Config->{_}->{tweet_id_end}; # if see id smaller than this on last page, then stop.

$url_prefix_next = 'https://twitter.com/i/profiles/show/' . $user_string . '/timeline/with_replies?include_available_features=1&include_entities=1&max_id=';

$url_prefix_new = 'https://twitter.com/i/profiles/show/' . $user_string . '/timeline/with_replies?composed_count=0&include_available_features=1&include_entities=1&include_new_items_bar=true&interval=60000&latent_count=0&since_id=';

$tweet_id_max = $tweet_id_begin;
$max_id = "$tweet_id_max";
$url_prefix = $url_prefix_next;
$url = "$url_prefix$max_id";
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
	$max_id = $json_data->{max_id};
	$last_tweet_id = $tweet_id;
	$tweet_id = $max_id;
	if ($tweet_id == $last_tweet_id) {
	    $wait = 1;
	} else {
	    $wait = 0;
	}

	if ($tweet_id <= $tweet_id_end) {
	    print STDERR "\ntweet_id=$tweet_id, end.";
	    exit;
	}
	$url = "$url_prefix$tweet_id";
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
