# Collector
Sinatra app to parse people names from biodiversity occurrence data

[![Continuous Integration Status][1]][2]

##Make ElasticSearch Snapshot

See http://www.elastic.co/guide/en/elasticsearch/reference/1.4/modules-snapshots.html

    $ curl -XPUT 'http://127.0.0.1:9200/_snapshot/es_backup' -d '{
        "type": "fs",
        "settings": {
            "location": "/Users/dshorthouse/Documents/es_backup",
            "compress": true
        }
    }'

    $ curl -XPUT "http://127.0.0.1:9200/_snapshot/es_backup/all?wait_for_completion=true"

##Restore ElasticSearch Snapshot

To discover where snapshots are located:

    $ curl -XGET "http://localhost:9200/_snapshot/"

To restore:

    $ curl -XPOST 'http://localhost:9200/collector/_close'
    $ curl -XPOST "http://localhost:9200/_snapshot/es_backup/all/_restore" -d '{ "indices": "collector" }'
    $ curl -XPOST 'http://localhost:9200/collector/_open'
