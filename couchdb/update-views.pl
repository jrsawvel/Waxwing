#!/usr/bin/perl -wT

use CouchDB::Client;
use Data::Dumper;


my $db = "waxwingdvlp";

my $view_js;

my $c = CouchDB::Client->new();
$c->testConnection or die "The server cannot be reached";

$rc = $c->req('GET', $db . '/_design/views');

my $perl_hash = $rc->{'json'};


##############################################

# javascript view code to add


# get a stream of deleted posts executed by the logged-in author

$view_js =  <<VIEWJS5;
function(doc) {
    if( doc.post_status === 'deleted' ) {
        emit(doc.updated_at, {slug: doc._id, html: doc.html, image_url: doc.image_url});
    }
}
VIEWJS5

$perl_hash->{'views'}->{'deleted_posts'}->{'map'} = $view_js;

##############################################



# update the view doc entry
$rc = $c->req('PUT', $db . '/_design/views', $perl_hash);
print Dumper $rc;

