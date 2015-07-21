
# Simple Image Uploader and Stream View


Client-side JavaScript reduces the image size to a max of 640 pixels on either the width and/or the length, depending upon which one is the longest. The resolution is reduced some.

The user can optionally add some text to the post, including hashtags and raw URLs.

The images are stored on the server's file system.

Other info related to the image post is stored in CouchDB.

Hashtag search exists, using a view that's added to CouchDB.

Elasticsearch provides the string searching.

It's very minimal. The main purpose is to permit easy upload of a photo from a phone and then be able to grab the URL to the image, so that the image can be embedded into one of my web publishing apps.

It's annoying to do this or it cannot be done using Instagram or Flickr on the phone. Sometimes, I don't need a giant, high-res image to embed into a post.

Test site at [http://image.soupmode.com](http://image.soupmode.com)

One huge problem: A bug exists within iOS7, which prevents the JavaScript from processing the image correctly. The bug existed in iOS6 too. But it's fixed with iOS8.


