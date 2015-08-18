package Image;

use strict;
use warnings;
use diagnostics;

use Image::Magick;
use URI::Escape::JavaScript qw(escape unescape);
use MIME::Base64;
use Data::Dumper;
use JSON::PP;
use CouchDB::Client;
use HTML::Entities;

use App::User;

use constant UPLOAD_DIR  => Config::get_value_for("images_home");
use constant BUFFER_SIZE => 16_384;
use constant MAX_FILE_SIZE => 4_194_304;

# client-side javascript sends json with an application/json post request
sub add_image_json {

#    Error::report_error("400", "debug", "test");

    my $q = new CGI;

    # my $input_json = $q->param('POSTDATA');

    my $input_json = $q->param("json_str");

    if ( !$input_json ) {
        Error::report_error("400", "Unable to process request.", "No information was provided.");
    }


    my $input_hash_ref = decode_json $input_json;

    my $logged_in_author_name  = $input_hash_ref->{'author'};
    my $session_id             = $input_hash_ref->{'session_id'};
    if ( !User::is_valid_login($logged_in_author_name, $session_id) ) { 
        Error::report_error("400", "Unable to peform action.", "You are not logged in.");
    }

    my $imagetext = $input_hash_ref->{"imagetext"};
    my $imagename = $input_hash_ref->{"imagename"};
    my $imagetype = $input_hash_ref->{"imagetype"};
    my $imageorientation = $input_hash_ref->{"imageorientation"};
    my $imagedata = $input_hash_ref->{"imagedata"};

    $imagedata = URI::Escape::JavaScript::unescape($imagedata);

    if ( $imagedata =~ m|^(.*),(.*)$|s ) {
        $imagedata = $2;
    }

    my $file_name;
    if ( $imagetype eq "image/jpeg" ) {
        $file_name = time() . "-" . $imagename;
    } else {
        $file_name = time() . "-" . $imagename . ".jpg";
    }

    my $local_image_filename = UPLOAD_DIR . "/" . $file_name;
    if ( $local_image_filename =~  m/^([a-zA-Z0-9\/\.\-_]+)$/ ) {
        $local_image_filename = $1;
    } else {
        Error::report_error("400", "Bad file name.", "Could not save image $imagename to $local_image_filename");
    }

    my $decoded= MIME::Base64::decode_base64($imagedata); 

    open my $fh, '>', $local_image_filename or Error::report_error("500", "Problem writing image file : $local_image_filename", $!);
    binmode $fh;
    print $fh $decoded;
    close $fh;


    if ( $imageorientation == 6 ) {
        my $image = new Image::Magick;
        my $err = $image->Read($local_image_filename); # camera - Exif data : orientation = 1
        Error::report_error("500", "Problem reading image file.", $local_image_filename) if $err;

        # orientation = 6 means photo taken in portrait mode as 0 Row = right side and 0 Column = top  

        # flip image in the vertical direction and rotate 90 degrees
        # $image->Transpose();

        $image->Rotate(90);

        unlink($local_image_filename) || Error::report_error("500", "Unable to delete old image file.", $local_image_filename);

        if ( $local_image_filename =~  m/^([a-zA-Z0-9\/\.\-_]+)$/ ) {
            $local_image_filename = $1;
        } else {
            Error::report_error("500", "Bad file name.", "Could not write image for filename: $local_image_filename");
        }

        $image->Write($local_image_filename);
        Error::report_error("user", "Could not write new file to drive.", $local_image_filename) if $err;
    }

    $imagetext = URI::Escape::JavaScript::unescape($imagetext);
    $imagetext = HTML::Entities::encode($imagetext, '^\n\x20-\x25\x27-\x7e');

    my @tags            = Utils::create_tag_array($imagetext);
    my $created_at      = Utils::create_datetime_stamp();
    my $updated_at      = $created_at;
    my $formatted_updated_at = Utils::format_date_time($updated_at);

    my $html = "";

    if ( $imagetext ) {
        $html = Utils::url_to_link($imagetext);
        $html = Utils::hashtag_to_link($html);
    }  else {
        $imagetext = "";
    }

    my $image_url = Config::get_value_for("images_home_url") . $file_name;
    # $html = '<p><a href="' . $image_url . '"><img src="' . $image_url . '"></a><br /><div class="imagetext">' . $html . '</div></p><br />';

    my $cdb_hash = {
        'author'               => Config::get_value_for("author_name"),
        'created_at'           => $created_at,
        'updated_at'           => $updated_at,
        'formatted_updated_at' => $formatted_updated_at,
        'markup'               => $imagetext,
        'html'                 => $html,
        'tags'                 => \@tags,
        'image_url'            => $image_url,
        'orientation'          => $imageorientation,
        'post_status'          => 'public'
    };


    my $db                     = Config::get_value_for("database_name");
    my $c = CouchDB::Client->new();
    $c->testConnection or Error::report_error("500", "Database error.", "The server cannot be reached.");
    my $rc = $c->req('POST', $db, $cdb_hash);
    if ( $rc->{status} >= 300 ) {
        Error::report_error("400", "Unable to create post.", $rc->{msg});
    }

    my $output_hash_ref;

    $output_hash_ref->{status}          = 200;
    $output_hash_ref->{description}     = "OK";
    $output_hash_ref->{user_message}    = "Uploaded image $imagename.";
    $output_hash_ref->{system_message}  = "Image saved to file system.";
    $output_hash_ref->{image_url}       = $image_url;
    $output_hash_ref->{html}            = $html;
    $output_hash_ref->{formatted_updated_at} = $formatted_updated_at;
    $output_hash_ref->{id}              = $rc->{'json'}->{'id'};

    my $output_json = encode_json $output_hash_ref;

    print CGI::header('application/json', '200 Accepted');
    print $output_json;
    exit;
 
}

# testing with the client-side javascript making an application/x-www-form-urlencoded post request
# html text is returned
sub do_test {

    my $q = new CGI;

    my $imagetext = $q->param("imagetext");
    my $imagename = $q->param("imagename");
    my $imageData = $q->param("imageData");

    $imageData = URI::Escape::JavaScript::unescape($imageData);

    if ( $imageData =~ m|^(.*),(.*)$|s ) {
        $imageData = $2;
    }

    my $epochsecs = time();

    my $local_image_filename = UPLOAD_DIR . "/" . $epochsecs . "-" . $imagename;
    if ( $local_image_filename =~  m/^([a-zA-Z0-9\/\.\-_]+)$/ ) {
        $local_image_filename = $1;
    } else {
        Page->report_error("user", "Bad file name.", "Could not write image for filename: $local_image_filename");
    }

    my $decoded= MIME::Base64::decode_base64($imageData); 

    open my $fh, '>', $local_image_filename or Page->report_error("system", "Problem writing image file : $local_image_filename", $!);
    binmode $fh;
    print $fh $decoded;
    close $fh;

    Page->report_error("user", "debug", "imagetext = $imagetext<br> imagename = $imagename");
 
}

sub display_add_image_form {

    my $logged_in_author_name  = User::get_logged_in_author_name(); 
    my $session_id             = User::get_logged_in_session_id(); 
    if ( !User::is_valid_login($logged_in_author_name, $session_id) ) { 
        Page->report_error("user", "Unable to peform action.", "You are not logged in.");
    }

    my $t = Page->new("addimageform");
    $t->display_page("Upload new image with JS");
}

sub display_upload_image_form {

    my $logged_in_author_name  = User::get_logged_in_author_name(); 
    my $session_id             = User::get_logged_in_session_id(); 
    if ( !User::is_valid_login($logged_in_author_name, $session_id) ) { 
        Page->report_error("user", "Unable to peform action.", "You are not logged in.");
    }

    my $t = Page->new("uploadimageform");
    $t->display_page("Upload new image");
}

# simple html form with enctype="multipart/form-data and the browser makes
# an application/x-www-form-urlencoded post request to send the 
# entire, original image to the server where all the processing occurs. 
# this is slow, since the image can be megs in size.
sub add_image {

#my $str = Dumper %ENV;
#Page->report_error("user", "debug", $str);

    my $logged_in_author_name  = User::get_logged_in_author_name(); 
    my $session_id             = User::get_logged_in_session_id(); 
    if ( !User::is_valid_login($logged_in_author_name, $session_id) ) { 
        Page->report_error("user", "Unable to peform action.", "You are not logged in.");
    }

    my $max_image_size = 640; # pixels

    my $q = new CGI;

    $CGI::POST_MAX = MAX_FILE_SIZE;

    if ( $ENV{CONTENT_LENGTH} > $CGI::POST_MAX ) {
        Page->report_error("user", "Upload Error", "Image too large."); 
    }

    if ( $q->cgi_error ) {
        Page->report_error("user", "Upload Error", $q->cgi_error);
    }

    my $err_msg;
    undef $err_msg;

    my $image_name     = $q->param("image");
    my $image_text     = $q->param("imagetext");
    my $image_binary;

    my $articleid = 0;

    my $tmp_image_name = Utils::trim_spaces($image_name);
#    $tmp_image_name    = Utils::clean_title($tmp_image_name);

    if ( !defined($tmp_image_name) || length($tmp_image_name) < 1 ) {
        $err_msg .= "Missing image to upload.";
    } else {
        $image_binary   = $q->upload("image");
    }

    $image_text = Utils::trim_spaces($image_text);
    if ( !defined($image_text) || length($image_text) < 1 ) {
        $image_text = " ";
    } elsif ( length($image_text) > 110) {
        $err_msg .= "Description must be less than 111 characters long.";
    }

    if ( defined($err_msg) ) {
        Page->report_error("user", "Invalid Input",  $err_msg);
    } 

    my $epochsecs = time();

    my $local_image_filename = UPLOAD_DIR . "/" . $epochsecs . "-" . $tmp_image_name;
    if ( $local_image_filename =~  m/^([a-zA-Z0-9\/\.\-_]+)$/ ) {
        $local_image_filename = $1;
    } else {
        Page->report_error("user", "Bad file name.", "Could not write image for filename: $local_image_filename");
    }

    open (fd_out, ">$local_image_filename") || Page->report_error("system", "Problem writing image file : $local_image_filename", $!);
    
    my $buffer = "";
    my $str = "";
    while ( read($image_binary, $buffer, BUFFER_SIZE ) ) {
        print fd_out $buffer;    
    }
    close fd_out;


    my $image = new Image::Magick;

    my $err = $image->Read($local_image_filename); # camera - Exif data : orientation = 1
    Page->report_error("user", "problem", "could not read $local_image_filename") if $err;

    my $h = $image->Get('height');
    my $w = $image->Get('width');
    my $format = $image->Get('format');
    my $mime = $image->Get('mime');

    my %exif = map { s/\s+\z//; $_ }
           map { split /=/, $_  }
           split /exif:/, $image->Get('format', '%[EXIF:*]');
    my $o = $exif{'Orientation'};

    unlink($local_image_filename) || Page->report_error("user", "unable to delete file.", $local_image_filename);

if ( $h > $max_image_size or $w > $max_image_size ) {
    if ( $h > $w ) {
        $w = ( $max_image_size / $h ) * $w;
        $h = $max_image_size;
    } else {
        $h = ( $max_image_size / $w ) * $h;
        $w = $max_image_size;
    }
}


$image->Resize('height' => $h, 'width' => $w); 
Page->report_error("user", "could not resize image", "") if "$err";

    if ( $local_image_filename =~  m/^([a-zA-Z0-9\/\.\-_]+)$/ ) {
        $local_image_filename = $1;
    } else {
        Page->report_error("user", "Bad file name.", "Could not write image for filename: $local_image_filename");
    }

$image->Write($local_image_filename);
Page->report_error("user", "could not write new file to drive.", $local_image_filename) if $err;


Page->report_error("user", "orientation=$o h=$h w=$w format=$format mime=$mime", "image_name = $image_name");

}

1;
