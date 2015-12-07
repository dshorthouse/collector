This folder contains a series of command line executables that normalize tables in preparation for populating ElasticSearch.

The progression is as follows:

    ./bin/populate_occurrences [--truncate] (one-time)
    ./bin/populate_agents [--truncate]
    ./bin/populate_taxa [--truncate]
    ./bin/disambiguate_agents [--reset]
    ./bin/populate_orcids [--reset]
    ./bin/populate_profiles [--res]
    ./bin/populate_citations [--reset]
    ./bin/populate_barcodes [--truncate]
    ./bin/populate_datasets [--truncate]
    ./bin/disambiguate_agents --reassign (if deemed necessary)
    ./bin/populate_search [--flush][--rebuild-all][--rebuild-agents][--rebuild-occurrences][--rebuild-taxa][--refresh]