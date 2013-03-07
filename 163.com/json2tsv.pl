#!/bin/perl -w
# Convert 163.com JSON format comment data to TSV.
# v130306

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

$json_text = do {local $/; <>};
$json_text =~ s/^var newPostList=//;
$json_text =~ s/;$//;
$data = decode_json $json_text;
@posts = @{$data->{newPosts}};
for ($i = 0; $i <= $#posts; $i ++) {
    delete $posts[$i]{d};
    foreach $item (sort {$a <=> $b} (keys %{$posts[$i]})) {
	$text = $posts[$i]{$item}{b};
	$from = $posts[$i]{$item}{f};
	$from =~ s/<a href=''>//;
	$from =~ s|</a>||;
	print "$i\t$item\t", $posts[$i]{$item}{t} ? $posts[$i]{$item}{t} : "", "\t", $posts[$i]{$item}{n} ? $posts[$i]{$item}{n} : "", "\t$from\t$text\n";
    }
}

# vi:sw=4
