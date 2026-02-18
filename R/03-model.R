source("R/02-tidy-data.R")

library(tidyverse)
library(rsample)
library(caret)
library(vip)
library(ROCR)

results_long <- results_long |>
  select(-Round.Type, -Margin) |>
  filter(Result != "Draw") |>
  mutate(Result = factor(Result, labels = c("Win", "Lose")))

df <- results_long |>
  mutate(across(where(is.ordered), ~ factor(., ordered = FALSE)))

set.seed(2026)
win_split <- initial_split(df, prop = .75, strata = Result)
win_train <- training(win_split)
win_test <- testing(win_split)

# basic glms
model1 <- glm(Result ~ Points.For, family = "binomial", data = win_train)
model2 <- glm(Result ~ Points.Against, family = "binomial", data = win_train)
model3 <- glm(Result ~ Home, family = "binomial", data = win_train)
model4 <- glm(
  Result ~ Points.For + Points.Against + Home,
  family = "binomial",
  data = win_train
  )

cv_model1 <- train(
  Result ~ Points.For,
  data = win_train,
  method = "glm",
  family = "binomial",
  trControl = trainControl(method = "cv", number = 10)
)

cv_model2 <- train(
  Result ~ Points.Against,
  data = win_train,
  method = "glm",
  family = "binomial",
  trControl = trainControl(method = "cv", number = 10)
)

cv_model3 <- train(
  Result ~ Home,
  data = win_train,
  method = "glm",
  family = "binomial",
  trControl = trainControl(method = "cv", number = 10)
)

cv_model4 <- train(
  Result ~ .,
  data = win_train,
  method = "glm",
  family = "binomial",
  trControl = trainControl(method = "cv", number = 10)
)

summary(
  resamples(
    list(
      model1 = cv_model1,
      model2 = cv_model2,
      model3 = cv_model3,
      model4 = cv_model4
    )
  )
)

pred_class <- predict(cv_model4, win_test)

confusionMatrix(
  data = relevel(pred_class, ref = "Win"),
  reference = relevel(win_test$Result, ref = "Win")
)

m1_prob <- predict(cv_model1, win_test, type = "prob")$Win
m4_prob <- predict(cv_model4, win_test, type = "prob")$Win

perf1 <- prediction(m1_prob, win_test$Result) |>
  performance(measure = "tpr", x.measure = "fpr")
perf4 <- prediction(m4_prob, win_test$Result) |>
  performance(measure = "tpr", x.measure = "fpr")

plot(perf1, col = "black", lty = 2)
plot(perf4, add = TRUE, col = "blue")
legend(
  0.8, 0.2, legend = c(
    "cv_model1", "cv_model4"
  ),
  col = c("black", "blue"),
  lty = 2:1,
  cex = 0.6
)
