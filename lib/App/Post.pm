package Post;

use strict;
use warnings;

use CouchDB::Client;
use LWP::UserAgent;
use JSON::PP;

sub show_post {
    my $tmp_hash      = shift; 

    my $post_id = $tmp_hash->{function}; 
   
    my $ua = LWP::UserAgent->new;

    my $db = Config::get_value_for("database_name");
    my $url = "http://127.0.0.1:5984/" . $db . "/_design/views/_view/post?key=\"$post_id\"";

    my $response = $ua->get($url);

    if ( !$response->is_success ) {
        Page->report_error("user", "Unable to display post.", "Post ID \"$post_id\" was not found - 1.");
    }

    my $rc = decode_json $response->content;

    my $post = $rc->{'rows'}->[0]->{'value'};

    if ( !$post ) {
        Page->report_error("user", "Unable to display post.", "Post ID \"$post_id\" was not found - 2.");
    }

    my $slug = $rc->{'rows'}->[0]->{'id'};

    my $t = Page->new("post");

    $t->set_template_variable("html",                  $post->{'html'});
    $t->set_template_variable("image_url",             $post->{'image_url'});
    $t->set_template_variable("formatted_updated_at",  $post->{'formatted_updated_at'});
    $t->set_template_variable("slug",                  $slug);
    $t->set_template_variable("author",                $post->{'author'}); 
#    $t->set_template_variable("author_profile",        Config::get_value_for("author_profile"));

    $t->display_page($post_id);
}

1;
