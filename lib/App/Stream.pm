package Stream;

use strict;
use warnings;

use CouchDB::Client;
use LWP::UserAgent;
use JSON::PP;
use URI::Escape;

sub show_stream {
    my $tmp_hash    = shift;
    my $creation_type = shift; # if equals "private", then called from Post.pm and done so to cache home page.

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

1;
