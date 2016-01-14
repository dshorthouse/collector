#!/bin/sh

./bin/populate_occurrences.rb --truncate
./bin/populate_agents.rb --truncate
./bin/populate_taxa.rb --truncate
./bin/populate_genders.rb
./bin/disambiguate_agents.rb --reassign
./bin/populate_orcids.rb --reset
./bin/populate_profiles.rb --reset
./bin/populate_citations.rb --reset
./bin/populate_barcodes.rb --truncate
./bin/populate_datasets.rb --truncate
./bin/populate_search.rb --rebuild-all
./bin/agent_network.rb --all-agents --type dot