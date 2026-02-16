# Author: https://github.com/bennywee/afl_probabilistic_model
source("R/01-load-data/raw_schema.R")

data_type_lookup <- list(
  ladder = list(fitzRoy::fetch_ladder, ladder_schema),
  results = list(fitzRoy::fetch_results, results_schema)
)