#!/usr/bin/perl
use strict;
use FileHandle;
#use Text::CSV;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use Getopt::Long;
use Term::ANSIColor;
use JSON;
# $|=1;
my $case_sensitive = 1;
use VCI; #to install: cpan VCI; cpan -f VCI

my $repo = undef;
my $outfile = "commits.json";
my  $result = GetOptions ("repo=s" => \$repo,
			"o=s" => \$outfile,
);

my $repo = VCI->connect(
                              type => 'Git', 
                              repo => ($repo || die "Provide a repo path!"),
);
bluewarn("Connected to git");
my $projects = $repo->projects;
my $project = $repo->get_project( name=>'');
my $history = $project->get_history_by_time( start => 0, end => time());
my $commits = $history->commits();
bluewarn("Got History");

my %last = ();
my %content = (); # store refs to scalars!
my @rows = ();
foreach my $commit (@$commits) {
    #my $contents = $commit->contents();
    my $cid   = $commit->revision();
    my $author = $commit->author();
    my $committer = $commit->committer();
    my $comment = $commit->message();    
    my $time = "".$commit->time(); #coerce to string
    push @rows, {
	doc => {
	        _id => $cid,
        	author => $author || $committer,
		commiter => $committer,
		owner => $author || $committer,
		title =>"",
		time => $time,
		published => $time,
		content => $comment,
		comment => $comment,
	},
    };
    warn color("bold red"), join("\t",$cid,$author), color("reset");
}
my $json = {rows=>\@rows};
use JSON;
open(my $fd,">",$outfile);
print $fd to_json( $json, { ascii => 1, pretty => 1 } );
close($fd);

sub bluewarn {
    warn color("blue"),@_,color("reset");
}
sub yellowwarn {
    warn color("yellow"),@_,color("reset");
}
