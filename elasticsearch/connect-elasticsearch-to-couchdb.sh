curl -X PUT 'http://127.0.0.1:9200/_river/waxwing/_meta' -d '{ "type" : "couchdb", "couchdb" : { "host" : "localhost", "port" : 5984, "db" : "waxwing", "filter" : null }, "index" : { "index" : "waxwing", "type" : "waxwing", "bulk_size" : "100", "bulk_timeout" : "10ms" } }'

