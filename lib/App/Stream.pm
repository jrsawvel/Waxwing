package Stream;

use strict;
use warnings;
use diagnostics;

use CouchDB::Client;
use LWP::UserAgent;
use JSON::PP;
use URI::Escape;

use App::User;

sub show_search_form {
    my $t = Page->new("searchform");
    $t->display_page("Search form");
}

sub show_stream {
    my $tmp_hash    = shift;

    my $page_num = 1;
    if ( Utils::is_numeric($tmp_hash->{one}) ) {
        $page_num = $tmp_hash->{one};
    }

    my $rc;

    my $db = Config::get_value_for("database_name");

    my $c = CouchDB::Client->new();
    $c->testConnection or Page->report_error("system", "Database error.", "The server cannot be reached.");

    my $max_entries = Config::get_value_for("max_entries_on_page");

    my $skip_count = ($max_entries * $page_num) - $max_entries;

    my $couchdb_uri = $db . '/_design/views/_view/stream/?descending=true&limit=' . ($max_entries + 1) . '&skip=' . $skip_count;

    $rc = $c->req('GET', $couchdb_uri);

    my $stream = $rc->{'json'}->{'rows'};

    if ( !$stream ) {
        Page->report_error("user", "No images.", "Upload something.");
    }

    my $next_link_bool = 0;
    my $len = @$stream;
    if ( $len > $max_entries ) {
        $next_link_bool = 1;
    }

    my @posts;
    my $ctr=0;
    foreach my $hash_ref ( @$stream ) {
        delete($hash_ref->{'value'}->{'tags'});
        push(@posts, $hash_ref->{'value'});
        last if ++$ctr == $max_entries;
    }

    my $t = Page->new("stream");

# todo    $t->set_template_variable("loggedin", User::get_logged_in_flag());

    $t->set_template_loop_data("stream_loop",  \@posts);

    if ( $page_num == 1 ) {
        $t->set_template_variable("not_page_one", 0);
    } else {
        $t->set_template_variable("not_page_one", 1);
    }

    if ( $len >= $max_entries && $next_link_bool ) {
        $t->set_template_variable("not_last_page", 1);
    } else {
        $t->set_template_variable("not_last_page", 0);
    }
    my $previous_page_num = $page_num - 1;
    my $next_page_num = $page_num + 1;
    my $next_page_url = "/stream/$next_page_num";
    my $previous_page_url = "/stream/$previous_page_num";
    $t->set_template_variable("next_page_url", $next_page_url);
    $t->set_template_variable("previous_page_url", $previous_page_url);

    $t->display_page("Stream of Images");
}

sub tag_search {
    my $tmp_hash    = shift;

    my $keyword = $tmp_hash->{one};

    my $page_num = 1;
    if ( Utils::is_numeric($tmp_hash->{two}) ) {
        $page_num = $tmp_hash->{two};
    }

    my $rc;

    my $db = Config::get_value_for("database_name");

    my $c = CouchDB::Client->new();
    $c->testConnection or Page->report_error("system", "Database error.", "The server cannot be reached.");

    my $max_entries = Config::get_value_for("max_entries_on_page");

    my $skip_count = ($max_entries * $page_num) - $max_entries;

    my $couchdb_uri = $db . "/_design/views/_view/tag_search?descending=true&limit=" . ($max_entries + 1) . "&skip=" . $skip_count;
    $couchdb_uri = $couchdb_uri . "&startkey=[\"$keyword\", {}]&endkey=[\"$keyword\"]";

#    my $couchdb_uri = $db . "/_design/views/_view/tag_search?reduce=false&startkey=[\"$keyword\", {}]&endkey=[\"$keyword\"]&descending=true&limit=" . ($max_entries + 1) . '&skip=' . $skip_count;

    $rc = $c->req('GET', $couchdb_uri);

    my $stream = $rc->{'json'}->{'rows'};

    if ( !$stream ) {
        Page->success("Search results for $keyword", "No matches found.", "");
    }

    my $number_of_matches = @$stream;
    if ( $number_of_matches < 1 ) {
        Page->success("Search results for $keyword", "No matches found.", "");
    }

    my $next_link_bool = 0;
    my $len = @$stream;
    if ( $len > $max_entries ) {
        $next_link_bool = 1;
    }

    my @posts;
    my $ctr=0;
    foreach my $hash_ref ( @$stream ) {
        delete($hash_ref->{'value'}->{'tags'});
        push(@posts, $hash_ref->{'value'});
        last if ++$ctr == $max_entries;
    }

    my $t = Page->new("stream");

# todo    $t->set_template_variable("loggedin", User::get_logged_in_flag());

    $t->set_template_loop_data("stream_loop",  \@posts);

    if ( $page_num == 1 ) {
        $t->set_template_variable("not_page_one", 0);
    } else {
        $t->set_template_variable("not_page_one", 1);
    }

    if ( $len >= $max_entries && $next_link_bool ) {
        $t->set_template_variable("not_last_page", 1);
    } else {
        $t->set_template_variable("not_last_page", 0);
    }
    my $previous_page_num = $page_num - 1;
    my $next_page_num = $page_num + 1;
    my $next_page_url = "/tag/$keyword/$next_page_num";
    my $previous_page_url = "/tag/$keyword/$previous_page_num";
    $t->set_template_variable("next_page_url", $next_page_url);
    $t->set_template_variable("previous_page_url", $previous_page_url);
    $t->set_template_variable("search", 1);
    $t->set_template_variable("keyword", $keyword);
    $t->set_template_variable("search_uri_str", $keyword);
    $t->set_template_variable("search_type_text", "Tag search");
    $t->set_template_variable("search_type", "tag");
    $t->display_page("Tag search results for $keyword");
}

# jrs - 24apr2015 - uses elasticsearch
sub search {
    my $tmp_hash = shift;  

    my $keyword = $tmp_hash->{one};

    my $page_num = 1;

    if ( Utils::is_numeric($tmp_hash->{two}) ) {
        $page_num = $tmp_hash->{two};
    }

    if ( !defined($keyword) ) {
        my $q = new CGI;
        $keyword = $q->param("keywords");

        if ( !defined($keyword) ) {
            Page->report_error("user", "Missing data.", "Enter keyword(s) to search on.");
        }
        
        $keyword = Utils::trim_spaces($keyword);
        if ( length($keyword) < 1 ) {
            Page->report_error("user", "Missing data.", "Enter keyword(s) to search on.");
        }
    } else { 
        $keyword = uri_unescape($keyword);
          # CGI.pm will deal with escaped blanks in query string that contain %20.
          # if the more friendly + signs are used for spaces in query string, deal with it here.
          #        $search_string =~ s/\+/ /g;
    }

    my $search_uri_str = $keyword;
    $search_uri_str =~ s/ /\+/g;
    $search_uri_str = uri_escape($search_uri_str);

    my $db = Config::get_value_for("database_name");

    my $max_entries = Config::get_value_for("max_entries_on_page");

    my $skip_count = ($max_entries * $page_num) - $max_entries;

    my $url = 'http://127.0.0.1:9200/' . $db . '/' . $db . '/_search?size=' . $max_entries . '&q=%2Bpost_status%3Apublic+%2Bmarkup%3A' . uri_escape($keyword) . '&from=' . $skip_count;

    my $ua = LWP::UserAgent->new;

    my $response = $ua->get($url);
    if ( !$response->is_success ) {
        Page->report_error("user", "Unable to complete request.", "$url");
    }

    my $rc = decode_json $response->content;

    my $total_hits = $rc->{'hits'}->{'total'};

    my $stream = $rc->{'hits'}->{'hits'};

    if ( !$stream ) {
        Page->success("Search results for $keyword", "No matches found.", "");
    }

    my $len = @$stream;
    if ( $len < 1 ) {
        Page->success("Search results for $keyword", "No matches found.", "");
    }

    my $next_link_bool = 0;
    if ( ($len == $max_entries) && ($total_hits > $max_entries) ) {
        $next_link_bool = 1;
    }

    my @posts;

    foreach my $hash_ref ( @$stream ) {
        $hash_ref->{'_source'}->{'slug'} = $hash_ref->{'_source'}->{'_id'};

        delete($hash_ref->{'_source'}->{'_id'});
        delete($hash_ref->{'_source'}->{'_rev'});
        delete($hash_ref->{'_source'}->{'created_at'});
        delete($hash_ref->{'_source'}->{'markup'});
        delete($hash_ref->{'_source'}->{'tags'});
        delete($hash_ref->{'_source'}->{'post_status'});

        push(@posts, $hash_ref->{'_source'});
    }

    my $t = Page->new("stream");
    $t->set_template_loop_data("stream_loop", \@posts);
    $t->set_template_variable("search", 1);
    $t->set_template_variable("keyword", $keyword);
    $t->set_template_variable("search_uri_str", $search_uri_str);
    $t->set_template_variable("search_type_text", "Search");
    $t->set_template_variable("search_type", "search");

    if ( $page_num == 1 ) {
        $t->set_template_variable("not_page_one", 0);
    } else {
        $t->set_template_variable("not_page_one", 1);
    }

    if ( $total_hits > $max_entries && $next_link_bool ) {
        $t->set_template_variable("not_last_page", 1);
    } else {
        $t->set_template_variable("not_last_page", 0);
    }
    my $previous_page_num = $page_num - 1;
    my $next_page_num = $page_num + 1;
    my $next_page_url = "/search/$search_uri_str/$next_page_num";
    my $previous_page_url = "/search/$search_uri_str/$previous_page_num";
    $t->set_template_variable("next_page_url", $next_page_url);
    $t->set_template_variable("previous_page_url", $previous_page_url);

    $t->display_page("Search results for $keyword");
}

sub show_deleted_posts {

    my $author_name  = User::get_logged_in_author_name(); 
    my $session_id   = User::get_logged_in_session_id(); 
    if ( !User::is_valid_login($author_name, $session_id) ) { 
        Page->report_error("user", "Unable to peform action.", "You are not logged in.");
    }

    my $rc;

    my $db = Config::get_value_for("database_name");

    my $c = CouchDB::Client->new();
    $c->testConnection or Page->report_error("system", "Database error.", "The server cannot be reached.");

    $rc = $c->req('GET', $db . '/_design/views/_view/deleted_posts/?descending=true');

    my $deleted = $rc->{'json'}->{'rows'};

    my @posts;

    foreach my $hash_ref ( @$deleted ) {
        push(@posts, $hash_ref->{'value'});
    }

    my $t = Page->new("deleted");
    $t->set_template_loop_data("deleted_loop", \@posts);
    $t->display_page("Deleted Posts");

}

1;
