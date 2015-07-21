#!/usr/bin/perl -wT

use strict;
use warnings;
use diagnostics;

use Image::Magick;

my $max_image_size = 640; # pixels
my $err;
my $image = new Image::Magick;

# $err = $image->Read("radar.gif"); 

# $err = $image->Read("aug2005.jpg"); # camera - Exif data : orientation = 1
 $err = $image->Read("rivp.jpg"); # camera - Exif data : orientation = 1
# $err = $image->Read("yard.jpg"); # iphone - landscape mode with hope button at right side - Exif data : orientation = 1

# $err = $image->Read("tree.jpg");# iphone - portrait mode - Exif data : orientation = 6
# $err = $image->Read("garden.jpg"); # iphone - portrait mode - Exif data : orientation = 6
die "$err" if "$err";

# get image attribute methods
my $h = $image->Get('height');
my $w = $image->Get('width');

my $format = $image->Get('format');
print "format = $format\n";

my $mime = $image->Get('mime');
print "mime = $mime\n";

############
#my %exif = map { s/\s+\z//; $_ }
#           map { split /=/, $_  }
#           split /exif:/, $image->Get('format', '%[EXIF:*]');
#my $h =  $exif{'ExifImageLength'}; 
#my $w =  $exif{'ExifImageWidth'};
#my $o = $exif{'Orientation'};

# this block is unneeded
#if ( $o == 6 ) {
#    my $tmp = $h;
#    $h = $w;
#    $w = $tmp;
#}
############


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
die "$err" if "$err";

# if orientation = 6 then transpose (flip image in the vertical direction and rotate 90 degrees)
# $image->Transpose();

$image->Write("jr.jpg");
die "$err" if "$err";


