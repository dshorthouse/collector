#!/bin/sh

./bin/populate_agents.rb --truncate
./bin/populate_genders.rb --reset
./bin/populate_taxa.rb --truncate
./bin/disambiguate_agents.rb --reset

./bin/populate_orcids.rb --reset
./bin/populate_profiles.rb --truncate
./bin/populate_citations.rb --reset
./bin/populate_barcodes.rb --truncate
./bin/populate_datasets.rb --truncate

./bin/update_agents.rb --all
./bin/populate_search.rb --rebuild-all