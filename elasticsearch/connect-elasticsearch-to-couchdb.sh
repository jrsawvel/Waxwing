curl -X PUT 'http://127.0.0.1:9200/_river/waxwingdvlp/_meta' -d '{ "type" : "couchdb", "couchdb" : { "host" : "localhost", "port" : 5984, "db" : "waxwingdvlp", "filter" : null }, "index" : { "index" : "waxwingdvlp", "type" : "waxwingdvlp", "bulk_size" : "100", "bulk_timeout" : "10ms" } }'

