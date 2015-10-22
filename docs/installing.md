# Installing Waxwing

Make appropriate DNS changes for the domain name or subdomain name.

Then on the server:

* cd /home
* mkdir 'dirname'
* cd 'dirname'
* git clone http:// (waxwing repo)
* cd Waxwing/couchdb
* vim create-db.sh  [change db name]
* ./create-db.sh
* vim create-author.sh [make appropriate changes]
* ./create-author.sh
* vim create-views.pl [change db name]
* ./create-views.pl
* cd ../elasticsearch
* vim connect-elasticsearch-to-couchdb.sh [change db name]
* ./connect-elasticsearch-to-couchdb.sh
* cd ../tmpl
* vim addimageform.tmpl [change URLs]
* vim stream.tmpl [change URL]
* cd ../yaml
* vim waxwing.yml [make appropriate changes]
* cd ../lib/App
* vim Config.pm [edit waxwing.yml location]
* vim /etc/hosts [add domain]
* cd /home/'dirname'/Waxwing/root
* mkdir images
* if necessary:
 * cd /home
 * chown -R user:group 'dirname'
* cd /etc/nginx/sites-available
* [create nginx config file]
* ln -s /etc/nginx/sites-available/config-file /etc/nginx/sites-enabled/config-file
* service nginx restart
* access URL

