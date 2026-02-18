library(arrow)
library(tidyverse)

fixtures <- open_dataset("data/raw/fixture", unify_schemas = TRUE) |> collect()
ladders <- open_dataset("data/raw/ladder", unify_schemas = TRUE) |> collect()
results <- open_dataset("data/raw/results", unify_schemas = TRUE) |> collect()

# Exploration - results ---------------------------------------------------

# Lengthen results so it is suitable for modelling
# I want a df that allows me to filter for a team and see all their games,
# both home and away, with a result.
# We will create a long data set for home teams, and then for away teams,
# And then join them.
results_long_home <- results |>
  mutate(
    Team = Home.Team,
    Opponent = Away.Team,
    Home = TRUE,
    .keep = "unused"
  ) |>
  rename(
    Goals.For = Home.Goals,
    Behinds.For = Home.Behinds,
    Points.For = Home.Points,
    Goals.Against = Away.Goals,
    Behinds.Against = Away.Behinds,
    Points.Against = Away.Points,
  )

results_long_away <- results |>
  mutate(
    Team = Away.Team,
    Opponent = Home.Team,
    Home = FALSE,
    .keep = "unused"
  ) |>
  rename(
    Goals.Against = Away.Goals,
    Behinds.Against = Away.Behinds,
    Points.Against = Away.Points,
    Goals.For = Home.Goals,
    Behinds.For = Home.Behinds,
    Points.For = Home.Points,
  )

results_long <- bind_rows(results_long_home, results_long_away)

# The margin should be the margin of the team in Team
# We also want a result column for ease
results_long <- results_long |>
  filter(grepl("R", Round)) |>
  mutate(
    Margin = Home * Margin - (1 - Home) * Margin,
    Result = case_when(
      Margin > 0 ~ 1,
      Margin == 0 ~ 0,
      Margin < 0 ~ -1
    ),
    Result = factor(Result, labels = c("Win", "Draw", "Lose"))
  )
