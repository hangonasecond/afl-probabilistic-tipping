# Author: https://github.com/bennywee/afl_probabilistic_model
library(future)
library(arrow)
library(fitzRoy)

source("R/01-load-data/data_scrape.R")

config <- yaml::read_yaml("config/data_config.yaml")
tables <- config[["raw_data_scrape"]][["tables"]]

available_cores = parallel::detectCores()-1
future::plan(future::sequential)

scrape_table_data <- function(config, table_name) {
  config_tables <-  config[["raw_data_scrape"]][[table_name]]
  years <- config_tables[["year_lb"]]:config_tables[["year_ub"]]
  # Optionally, call specific rounds by setting in the yaml
  # If you want to do this, uncomment the lines in config/data_config.yaml
  # rounds <- config_tables[["round_lb"]]:config_tables[["round_ub"]]
  # As per the docs for fitzRoy, settings rounds NULL will fetch data for all
  # rounds instead. See data_scrape.R
  data_output_loc <- paste0("data/", config_tables[["data_loc"]])

  if(!dir.exists(data_output_loc)){
    dir.create(data_output_loc, recursive = TRUE)
  }

  Map(function(season_vector)
    write_raw_data(table_type = table_name,
                   season = season_vector,
                   output_path = data_output_loc),
    season_vector = years
  )
}

Map(function(t)
  scrape_table_data(config = config, table_name = t),
  t = tables)

# Get 2025 fixture data
fixture_loc <- paste0("data/raw/fixture")

if(!dir.exists(fixture_loc)){
  dir.create(fixture_loc, recursive = TRUE)
}

fitzRoy::fetch_fixture_footywire(
  season = 2026
) |>
  arrow::write_dataset(format = "parquet",
                       path = fixture_loc)