#!/usr/bin/perl
use strict;
use LWP::Simple qw(get);
use LWP::UserAgent;
use Getopt::Long;
use XML::XPath; 
use XML::XPath::XMLParser;
use XML::DOM;
use JSON;
use HTML::TreeBuilder;
use HTML::FormatText;
use File::Basename;


sub html2text {
	my $html = shift;
	my $tree = HTML::TreeBuilder->new->parse($html);

	my $formatter = HTML::FormatText->new(leftmargin => 0, rightmargin => 50);
	return $formatter->format($tree);
}

use Fatal qw(open close);

my $ua = LWP::UserAgent->new();

my $filename = undef;
my $outfile = "large.json";
my $comments = 1;
my  $result = GetOptions ("file=s" => \$filename,
                          "o=s" => \$outfile,
                          "c=s" => \$comments);

die "Need -file <filename> -o <outfilename>" unless $filename;

my $issuesfilename = $filename;
my $xml = load($issuesfilename);
my $xp = XML::XPath->new( xml => $xml );
my @ids = find_issue_ids( $xp );
my $parser = new XML::DOM::Parser;
my $doc = $parser->parse( $xml );
my @nodes = $doc->getElementsByTagName ("entry");
my @jnodes = map {  { doc => parse_node($_, $comments) } } @nodes;
my $json = {rows=>\@jnodes};

open(my $fd,">",$outfile);
print $fd to_json( $json, { ascii => 1, pretty => 1 } );
close($fd);

sub nav {
    my ($node,@l) = @_;
    while (@l) {
        my $name = shift @l;
        return "" if !$node;
        ($node) = $node->getElementsByTagName($name);
    }
    return text($node);
}

sub get_comment_xml {
    my ($path, $id) = @_;
    warn "Comments of $id";
    my $filename = sprintf('%s/comments-%06d.xml', $path, $id);
    my $xml = load($filename);
    return $parser->parse( $xml );
}

sub parse_node {
	my ($node, $comments) = @_;
	my $json_node = {
		comments => [],
	};
	for my $child ($node->getChildNodes) {
		#print $child->getTagName()."\t".$child->getAttribute("#text").$/;
		my $tag = tag($child);
		my $text = text($child);
		$json_node->{$tag} = $text;
		print $child->getTagName()."\t".text($child).$/;
	}
        my $author = nav($node,qw(author name));
        my $author_uri = nav($node,qw(author uri));
        $json_node->{owner} ||=    nav($node,qw(issues:owner issues:username));
        $json_node->{owneruri} ||= nav($node,qw(issues:owner issues:uri));
        $json_node->{author} ||= $author;
        $json_node->{authoruri} ||= $author_uri;
	$json_node->{_id} ||= $json_node->{"issues:id"} || $json_node->{id};
	$json_node->{html} ||= $json_node->{content};
	$json_node->{content} = html2text($json_node->{content});

        if ($comments) {
            my $doc = get_comment_xml(dirname($filename), $json_node->{_id});
            my @nodes = $doc->getElementsByTagName ("entry");
            my @jnodes = map {   parse_node($_) } @nodes;
            $json_node->{comments} = \@jnodes;
        }

	return $json_node;
}
sub tag {
	my ($node) = @_;
	return $node->getTagName();
}
sub text {
	my ($node) = @_;
        return "" unless $node;
	my $child = $node->getFirstChild();
	if (!$child) {
		return "";
	}
	return $child->getNodeValue();
}

sub save {
    my ($file,@rest) = @_;
    open(my $fd, ">", $file);
    print $fd @rest;
    close($fd);
}

sub find_issue_ids {
    my ($xp) = @_;
    my $nodeset = $xp->find('/feed/entry/issues:id/text()'); # find all subject
    my @ids = map { my $node = $_; $node->XML::XPath::XMLParser::as_string($node) } ($nodeset->get_nodelist);
    return @ids;
}

sub load {
    my ($filename) = @_;
    open(my $fd, $filename);
    my @lines = <$fd>;
    close($fd);
    return join("",@lines);
}
sub retrieve_issues {
    my ($project,$n,@xmls) = @_;
    $n = (defined($n)?$n:0);
    my $url = issues_url($project,$n);
    my $issuesfilename = "./$project/issues.xml";
    my $tmpissuesfilename = "./$project/.issues.$n.xml";
    my $xml;
    if (-e $tmpissuesfilename) {
        $xml = load($tmpissuesfilename);
    } else {
        $xml = GET( $url );
    }
    save($tmpissuesfilename, $xml);
    push @xmls, $xml;
    
    # get the number of elements
    my $xp = XML::XPath->new( xml => $xml );
    my @ids = find_issue_ids( $xp );
    if (@ids == 1000) {
        # ok so we need to add more issues :(
        return retrieve_issues($project,$n+1,@xmls);
    }

    $xml = shift @xmls;
    if (@xmls >= 1) {
        my $parser = new XML::DOM::Parser;
        my $maindoc = $parser->parse( $xml );
        my @docs = map { $parser->parse( $_ ) } @xmls;
        my @nodes = ();
        foreach my $doc (@docs) {
            my @newnodes = $doc->getElementsByTagName ("entry");
            push @nodes, @newnodes;
            warn "have nodes:".scalar(@nodes);
        }
        my $feed = $maindoc->getElementsByTagName ("feed")->[0];
        foreach my $node (@nodes) {
            #$feed->appendChild( $node );
            #$maindoc->importNode($node);
            my $cnode = $node->cloneNode(1);
            $cnode->setOwnerDocument( $maindoc );
            $feed->appendChild( $cnode );
        }
        warn "Serializing xml";
        $xml = $maindoc->toString();
        save($issuesfilename,$xml);
        return $xml;

    }
    save($issuesfilename,$xml);
    return $xml;
}
