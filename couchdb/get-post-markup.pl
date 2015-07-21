#!/usr/bin/perl -wT

use lib '/home/image/Waxwing/lib';

use CouchDB::Client;
use Data::Dumper;

my $rc;
my $c = CouchDB::Client->new();
$c->testConnection or die "The server cannot be reached";

$rc = $c->req('GET', 'waxwing/_design/views/_view/post_markup?key="info"');
print Dumper $rc;
print "\n";

# my $stream = $rc->{'json'}->{'rows'};


