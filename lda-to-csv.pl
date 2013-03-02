#!/usr/bin/perl
use strict;
use JSON;
use Getopt::Long;
use Date::Parse;
use Text::CSV;


my $summary_json = "out/summary.txt";

my $lda_map_json = "out/document_topic_map.txt";
my $commits_json = "commits.json";
my $outcsv = "out.csv";
my $topicoutcsv = "topicsummary.csv";

my  $result = GetOptions ("lda=s" => \$lda_map_json,
                          "commits=s" => \$commits_json,
                          "o=s" => \$outcsv,
                          "summary=s" => \$summary_json,
                          "so=s" => \$topicoutcsv,

);

my $raw_commits = load_json($commits_json);
my @commits = map { $_->{doc} } @{$raw_commits->{rows}};

foreach my $commit (@commits) {
    $commit->{utime} = str2time($commit->{time});
}

my %commit_map = map { $_->{_id} => $_ } @commits;
my $lda_map = load_json($lda_map_json);

my @sorted_ids = map {$_->[1]} 
                     (sort { $a->[0] <=> $b->[0]  } 
                         (map { [$->{utime}, $_->{_id} ]  }  @commits));

my $csv = Text::CSV->new ({ binary => 1, eol => $/});

open my $fh, ">:encoding(utf8)", $outcsv or die "$outcsv : $!";
warn $sorted_ids[0];
my $n = scalar(@{$lda_map->{$sorted_ids[0]}});
warn $n;
my @topics = map { "t$_" } (1..$n);
my @header = (qw(utime id author time  ), @topics);
$csv->print($fh, \@header );
foreach my $id (@sorted_ids) {
    warn $id;
    my $commit = $commit_map{$id};
    $csv->print( $fh, [
                       $commit->{utime},
                       $commit->{_id},
                       $commit->{author},
                       $commit->{time},
                       @{$lda_map->{$id}}
                      ]);
}
close $fh or die "$outcsv: $!";

my $summary = load_json($summary_json);
open my $fh, ">:encoding(utf8)", $topicoutcsv or die "$topicoutcsv : $!";
# header
$csv->print($fh, [ map { "w$_" } (1..scalar(@{$summary->[0]})) ] );
$csv->print($fh, $_) foreach @$summary;
close $fh or die "$topicoutcsv: $!";



sub load_json {
    my $file = shift;
    local $/;
    open( my $fh, '<', $file );
    my $json_text   = <$fh>;
    my $perl_scalar = decode_json( $json_text );
    return $perl_scalar;
}
