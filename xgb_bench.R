library(readr)
library(xgboost)
set.seed(1738)

setwd("~/UIUC/STAT542")
load("~/UIUC/STAT542/reduced_data_train.rdata")

#Randomly sampling 50% of reduced_data_train
s_xgb_half = reduced_data_train[sample(nrow(reduced_data_train),72615), ]


# Start the clock!
ptm <- proc.time()

#Running XGBoost with its default settings and 20 rounds on half of the reduced_data_train
xgb_half <- xgboost(data        = data.matrix(s_xgb_half[,1:1021]),
                    label       = s_xgb_half$target,
                    nrounds     = 20,
                    objective   = "binary:logistic",
                    eval_metric = "auc")

# Stop the clock
timehalf.xgb = proc.time() - ptm
timehalf.xgb

# Start the clock!
ptm <- proc.time()

#Running XGBoost with its default settings and 20 rounds on all of the reduced_data_train
xgb_full <- xgboost(data   = data.matrix(reduced_data_train[,1:1021]),
               label       = reduced_data_train$target,
               nrounds     = 20,
               objective   = "binary:logistic",
               eval_metric = "auc")

# Stop the clock
timefull.xgb = proc.time() - ptm
timefull.xgb


save(list = ls(all.names = TRUE), file = "xgb_bench.RData", envir = .GlobalEnv)

rm(reduced_data_train)
load("~/UIUC/STAT542/reduced_data_test.rdata")

#Predicting using the model built on half the reduced_data_train
pred_xgb_half = predict(xgb_half, data.matrix(reduced_data_test))
write.csv(pred_xgb_half,"xgb_50.csv")

#Predicting using the model built on all the reduced_data_train
pred_xgb_full = predict(xgb_full, data.matrix(reduced_data_test))
write.csv(pred_xgb_full,"xgb_full.csv")

#note the columns need to be labeled ID and target in the csv