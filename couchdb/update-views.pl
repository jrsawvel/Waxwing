#!/usr/bin/perl -wT

use CouchDB::Client;
use Data::Dumper;


my $db = "waxwing";

my $view_js;

my $c = CouchDB::Client->new();
$c->testConnection or die "The server cannot be reached";

$rc = $c->req('GET', $db . '/_design/views');

my $perl_hash = $rc->{'json'};


##############################################

# javascript view code to add

my $view_js =  <<VIEWJS1;
function(doc) {
    if( doc.post_status === 'public' ) {
        emit(doc.updated_at, {slug: doc._id, html: doc.html, image_url: doc.image_url, orientation: doc.orientation, tags: doc.tags, author: doc.author, formatted_updated_at: doc.formatted_updated_at});
    }
}
VIEWJS1
$perl_hash->{'views'}->{'stream'}->{'map'} = $view_js;

##############################################



# update the view doc entry
$rc = $c->req('PUT', $db . '/_design/views', $perl_hash);
print Dumper $rc;

