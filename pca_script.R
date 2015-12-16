set.seed(1738)
library(foreach)
library(randomForest)
library(doParallel)

cl <- makeCluster(2)
registerDoParallel(cl)
getDoParName()

setwd("~/UIUC/STAT542")
load("~/UIUC/STAT542/PCA_data_train.rdata")


transformed_data_train$target <- as.factor(transformed_data_train$target)

#Randomly sampling 10% of pca_data_train
s_pc_1 = transformed_data_train[sample(nrow(transformed_data_train),15000), ]

#Randomly sampling 50% of pca_data_train
s_pc_half = transformed_data_train[sample(nrow(transformed_data_train),72615), ]

rm(transformed_data_train)

# Start the clock!
ptm <- proc.time()

#Running Random Forest with its default settings and 800 trees on tenth the pca_data_train
rf1.pc <- foreach(ntree=rep(400, 2), .combine=combine, .packages='randomForest', .multicombine=TRUE) %dopar% randomForest(s_pc_1[,1:585], s_pc_1$target, ntree=ntree, mtry=28);

# Stop the clock
time1.pc = proc.time() - ptm
time1.pc

# Start the clock!
ptm <- proc.time()

#Running Random Forest with its default settings and 800 trees on half the pca_data_train
rfhalf.pc <- foreach(ntree=rep(400, 2), .combine=combine, .packages='randomForest', .multicombine=TRUE) %dopar% randomForest(s_pc_half[,1:585], s_pc_half$target, ntree=ntree, mtry=28);

# Stop the clock
timehalf.pc = proc.time() - ptm
timehalf.pc



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

#Generating confusion matrices
rf1.pc$confusion <- getConfusionMatrix(rf1.pc)
rfhalf.pc$confusion <- getConfusionMatrix(rfhalf.pc)

save(list = ls(all.names = TRUE), file = "PCA_bench.RData", envir = .GlobalEnv)

load("~/UIUC/STAT542/PCA_data_test.rdata")

#Predicting using the model built on tenth the pca_data_train
pred_pca_10 = predict(rf1.pc, transformed_data_test, type="prob")
pca_10 <- as.data.frame(pred_pca_10[,2])
write.csv(pca_10,"pca_10.csv")

#Predicting using the model built on half the pca_data_train
pred_pca_50 = predict(rfhalf.pc, transformed_data_test, type="prob")
pca_50 <- as.data.frame(pred_pca_50[,2])
write.csv(pca_50,"pca_50.csv")

#note the columns need to be labeled ID and target in the csv

