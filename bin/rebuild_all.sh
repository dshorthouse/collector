#!/bin/sh

#Following four takes approx 20min total for 2.75M occurrences
./bin/populate_agents.rb --truncate
./bin/populate_genders.rb --reset
./bin/populate_taxa.rb --truncate
./bin/disambiguate_agents.rb --reset

./bin/populate_orcids.rb --reset
./bin/populate_profiles.rb --truncate

#Can be very slow, many external calls, can be done in parallel
./bin/populate_citations.rb --reset
./bin/populate_barcodes.rb --truncate
./bin/populate_datasets.rb --truncate

./bin/update_agents.rb --all
./bin/populate_search.rb --rebuild-all