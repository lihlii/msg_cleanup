#!/bin/perl -w
# Convert JSON format Twitter message archive to TSV.
# v130219

#if ($ARGV[0] eq "-?") {
#    print "Convert JSON format Twitter message archive to TSV.\nUsage: $0 <input json file> > <output tsv file>\ninput file charset should be UTF8.\n";
#    exit;
#}

use HTML::Entities;
use JSON;
use utf8;
use Data::Dump;
binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");

<>;
$json_text = do {local $/; <>};
$data = decode_json $json_text;
# dd $data;

for ($i = 0; $i <= $#{$data}; $i ++) {
    if ($data->[$i]{retweeted_status}) {
	%entry = %{$data->[$i]{retweeted_status}};
    } else {
	%entry = %{$data->[$i]};
    }
    $tweetid = $entry{id};
    $fullname = $entry{user}{name};
    $fullname =~ s/[\n\r\t]//g;
    $username = $entry{user}{screen_name};
    $time = $entry{created_at};
    $text = $entry{text};
    $text =~ s/[\n\r\t]//g;
#    decode_entities($text); # in case some html tags appear in text.
    $convers = "";
    $convers = "C" if $entry{in_reply_to_status_id};
    $t_url = "https://twitter.com/$username/status/$tweetid";
    if ($entry{entities}{media}) {
        @media = @{$entry{entities}{media}};
	for ($j = 0; $j <= $#media; $j ++) {
	    $m_url = $media[$j]{url};
	    $m_d_url = $media[$j]{display_url};
	    $text =~ s/$m_url/<a href="$m_url">$m_d_url<\/a>/;
	    $m_img_url = $media[$j]{media_url};
	    $text .= "<br /><img src=\"$m_img_url\">";
	}
    }
    if ($entry{entities}{urls}) {
        @urls = @{$entry{entities}{urls}};
	for ($j = 0; $j <= $#urls; $j ++) {
	    $s_url = $urls[$j]{url};
	    $l_url = $urls[$j]{expanded_url};
	    $text =~ s/$s_url/<a href="$s_url">$l_url<\/a>/;
	}
    }
    print "$tweetid\t$t_url\t$time\t$convers\t$username\t$fullname\t$text\n";
}

# vi:sw=4
