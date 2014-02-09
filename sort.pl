#!/bin/perl -w
# sort twitter messages TSV file according to status serial number (thus time).
# v121030
# 1. Install perl, eg. ActivePerl http://www.activestate.com/activeperl
# 2. Preprocess twitter message web page using msg_merge_twitter.bat > msg_merge_twitter.tsv
# 3. Save this script as msg_sort_twitter.pl, in the same folder as in step 2.
# 4. Open a command window, cd to the folder where the files are stored.
# 5. Input command: msg_sort_twitter.pl < msg_merge_twitter.tsv > msg_merge_twitter_sort.tsv
# When there are several copies of messages with the same status serial number, keep the one with the longest timestamp string.

#if ($ARGV[0] eq "-?") {
#    print "Usage: $0 < <input tsv file> > <output sorted file>\n";
#    exit;
#}

binmode(STDIN, ":utf8");
binmode(STDOUT, ":utf8");
my ($sn, $url, $time_string, $username, $fullname, $text, @tsv);

while (<>) {
    push @tsv, [ split /\t/ ];
}

@tsvs = sort { $a->[0] <=> $b->[0] } @tsv;

for (my $i = 0; $i < @tsvs; $i++) {
    $time_string = $tsvs[$i][2];
    $text = $tsvs[$i][6];
    while ( ($i+1 < @tsvs) && $tsvs[$i+1][0] eq $tsvs[$i][0]) { # is next line with the same serial number at first field?
	$time_string = $tsvs[$i+1][2] if length($time_string) < length($tsvs[$i+1][2]); # store the time string field if it's longer than the current one.
	$text = $tsvs[$i+1][6] if length($text) < length($tsvs[$i+1][6]); # store the text field if it's longer than the current one.
    } continue {
	$i++;
    }
    $tsvs[$i][2] = $time_string;
    $tsvs[$i][6] = $text;
    print join("\t", @{$tsvs[$i]});
}

# vi:sw=4
