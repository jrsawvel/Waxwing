#!/usr/bin/perl -wT

use JSON::PP;
use CouchDB::Client;
use Data::Dumper;


my $db = "waxwing";


my $views = <<VIEWS;
{
  "_id":"_design/views"
}
VIEWS

# convert json string into a perl hash
my $perl_hash = decode_json $views;


# homepage stream of posts listed by updated date
my $view_js =  <<VIEWJS1;
function(doc) {
    if( doc.post_status === 'public' ) {
        emit(doc.updated_at, {slug: doc._id, html: doc.html, image_url: doc.image_url, orientation: doc.orientation, tags: doc.tags, author: doc.author, formatted_updated_at: doc.formatted_updated_at});
    }
}
VIEWJS1
$perl_hash->{'views'}->{'stream'}->{'map'} = $view_js;



# get a single post HTML display
$view_js =  <<VIEWJS2;
function(doc) {
    if( doc.post_status === 'public' ) {
        emit(doc._id, {slug: doc._id, html: doc.html, image_url: doc.image_url, orientation: doc.orientation, tags: doc.tags, author: doc.author, formatted_updated_at: doc.formatted_updated_at});
    }
}
VIEWJS2
$perl_hash->{'views'}->{'post'}->{'map'} = $view_js;



# tag search on the tag array
$view_js = <<VIEWJS9;
function(doc) {
  if( doc.post_status === 'public' && doc.tags.length > 0) {
    doc.tags.forEach(function(i) {
      emit( [i, doc.updated_at ], {slug: doc._id, html: doc.html, image_url: doc.image_url, orientation: doc.orientation, tags: doc.tags, author: doc.author, formatted_updated_at: doc.formatted_updated_at});
    });
  }
}
_count 
VIEWJS9
$perl_hash->{'views'}->{'tag_search'}->{'map'} = $view_js;




my $c = CouchDB::Client->new();
$c->testConnection or die "The server cannot be reached";

# create the view doc entry
my $rc = $c->req('POST', $db, $perl_hash);
print Dumper $rc;

print "\n\n\n";

$rc = $c->req('GET', $db . '/_design/views');
print Dumper $rc;
print "\n";

