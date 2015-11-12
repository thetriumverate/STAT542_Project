start.time <- proc.time()

#reading in training data
train <- read.csv("train.csv")

#getting row indices of samples
#this is sampling without replacement, used 17 folds because dim(train)[1] is divisible by 17
#could create "replicate" folds using createMultiFolds()
set.seed(12345)
library(caret)
train.resample.in <- createFolds(train$target, k=17, list=TRUE)

#or create replicate folds by just changing the seed:
#set.seed(54321)
#train.resample.in2 <- createFolds(train$target, k=17, list=TRUE)

train.resample.out = list(0)

#applying row indices to get separate data sets
for(i in 1:(length(train.resample.in)))
{
  tmp <- train.resample.in[[i]]
  train.resample.out[[i]] <- train[tmp,]
}

end.time <-proc.time() - start.time

end.time #2 minutes total... was run on computer with 8GB RAM and i7 processor

#train.resample.out is a list of 17 matrices, all of equal dimensions...

# It is faster to just store the data set as a .rdata file than to keep reading in
# the .csv. It is also roughly 1/4th of the size. 
#save(train,file="train.rdata")
#test <-read.csv(file="test.csv",header=TRUE)
#save(test,file="test.rdata")

# To read the data in
load("train.rdata")
