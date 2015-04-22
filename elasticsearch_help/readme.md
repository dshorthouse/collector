#Make ElasticSearch Snapshot

See http://www.elastic.co/guide/en/elasticsearch/reference/1.4/modules-snapshots.html

    $ curl -XPUT "127.0.0.1:9200/_snapshot/es_backup/all?wait_for_completion=true"

#Restore ElasticSearch Snapshot

To discover where snapshots are located:

    $ curl -XPUT 'http://localhost:9200/_snapshot/

To restore:

    $ curl -XPOST "localhost:9200/_snapshot/es_backup/all/_restore" -d '{ "indices": "collector,canent" }'