set.seed(1738)
library(foreach)
library(randomForest)
library(doParallel)

cl <- makeCluster(2)
registerDoParallel(cl)
getDoParName()

setwd("~/UIUC/STAT542")
load("~/UIUC/STAT542/reduced_data_train.rdata")


reduced_data_train$target <- as.factor(reduced_data_train$target)

s_1 = reduced_data_train[sample(nrow(reduced_data_train),15000), ]

s_half = reduced_data_train[sample(nrow(reduced_data_train),72615), ]

rm(reduced_data_train)

# Start the clock!
ptm <- proc.time()

rf1 <- foreach(ntree=rep(400, 2), .combine=combine, .packages='randomForest', .multicombine=TRUE) %dopar% randomForest(s_1[,1:1021], s_1$target, ntree=ntree, mtry=28);

# Stop the clock
time1.p = proc.time() - ptm
time1.p

# Start the clock!
ptm <- proc.time()

rfhalf <- foreach(ntree=rep(400, 2), .combine=combine, .packages='randomForest', .multicombine=TRUE) %dopar% randomForest(s_half[,1:1021], s_half$target, ntree=ntree, mtry=28);

# Stop the clock
timehalf.p = proc.time() - ptm
timehalf.p



getConfusionMatrix <- function(rf) {
  
  tbl = table(predict(rf), rf$y)
  class.error = vector()
  
  for (i in 1:nrow(tbl)) {
    rowSum = sum(tbl[i,])
    accurate = diag(tbl)[i]
    error = rowSum - accurate
    
    class.error[i] = error / rowSum
  }   
  return(cbind(tbl, class.error))
}


rf1$confusion <- getConfusionMatrix(rf1)
rfhalf$confusion <- getConfusionMatrix(rfhalf)

save(list = ls(all.names = TRUE), file = "red_bench.RData", envir = .GlobalEnv)

load("~/UIUC/STAT542/reduced_data_test.rdata")

pred_red_10 = predict(rf1, reduced_data_test, type="prob")
red_10 <- as.data.frame(pred_red_10[,2])
write.csv(red_10,"red_10.csv")

pred_red_50 = predict(rfhalf, reduced_data_test, type="prob")
red_50 <- as.data.frame(pred_red_50[,2])
write.csv(red_50,"red_50.csv")

#note the columns need to be labeled ID and target in the csv
