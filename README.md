# Collector
Sinatra app to parse people names from biodiversity occurrence data, apply basic regular expressions and heuristics to disambiguate them, and to find candidate resources held in [ORCID](https://orcid.org), [DataCite](https://www.datacite.org/), and [BOLD](http://www.boldsystems.org/) that could be attributed to them. The front-end works entirely off an ElasticSearch index.

[![Build Status](https://travis-ci.org/dshorthouse/collector.svg?branch=master)](https://travis-ci.org/dshorthouse/collector)
