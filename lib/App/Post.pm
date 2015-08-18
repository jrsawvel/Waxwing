package Post;

use strict;
use warnings;

use CouchDB::Client;
use LWP::UserAgent;
use JSON::PP;

use App::User;

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
    $t->set_template_variable("loggedin", User::get_logged_in_flag());
    $t->display_page($post_id);
}

sub delete {
    my $tmp_hash = shift; # ref to hash
    my $post_id = $tmp_hash->{one};

    my $author_name  = User::get_logged_in_author_name(); 
    my $session_id   = User::get_logged_in_session_id(); 

    if ( !User::is_valid_login($author_name, $session_id) ) { 
        Page->report_error("user", "Unable to peform action.", "You are not logged in.");
    }

    my $db = Config::get_value_for("database_name");

    my $rc;

    my $c = CouchDB::Client->new();
    $c->testConnection or Page->report_error("system", "Database error.", "The server cannot be reached.");

    $rc = $c->req('GET', $db . "/$post_id");

    if ( !$rc->{'json'} ) {
        Page->report_error("user", "Unable to delete post.", "Post ID \"$post_id\" was not found.");
    }

    my $perl_hash = $rc->{'json'};
    
    if ( !$perl_hash ) {
        Page->report_error("user", "Unable to delete post.", "Post ID \"$post_id\" was not found.");
    }

    $perl_hash->{'post_status'} = "deleted";

    $rc = $c->req('PUT', $db . "/$post_id", $perl_hash);

    my $url = Config::get_value_for("home_page");
    my $q = new CGI;
    print $q->redirect( -url => $url);

}

sub undelete {
    my $tmp_hash = shift; # ref to hash
    my $post_id = $tmp_hash->{one};

    my $author_name  = User::get_logged_in_author_name(); 
    my $session_id   = User::get_logged_in_session_id(); 

    if ( !User::is_valid_login($author_name, $session_id) ) { 
        Page->report_error("user", "Unable to peform action.", "You are not logged in.");
    }

    my $db = Config::get_value_for("database_name");

    my $rc;

    my $c = CouchDB::Client->new();
    $c->testConnection or Page->report_error("system", "Database error.", "The server cannot be reached.");

    $rc = $c->req('GET', $db . "/$post_id");

    if ( !$rc->{'json'} ) {
        Page->report_error("user", "Unable to delete post.", "Post ID \"$post_id\" was not found.");
    }

    my $perl_hash = $rc->{'json'};
    
    if ( !$perl_hash ) {
        Page->report_error("user", "Unable to delete post.", "Post ID \"$post_id\" was not found.");
    }

    $perl_hash->{'post_status'} = "public";

    $rc = $c->req('PUT', $db . "/$post_id", $perl_hash);

    my $url = Config::get_value_for("home_page") . "/deleted";
    my $q = new CGI;
    print $q->redirect( -url => $url);

}

1;
