## Setup

setwd("~/Homework/")
library(randomForest)
load('reduced_data_train.rdata')

## Parameters
nsplits=10
ntree = 101


chunksize = nrow(reduced_data_train)/nsplits # rough chunk size
rmdr = chunksize %% 1 # remainder of the chunk size
tot.rmdr = rmdr*nsplits # get the total remainder
chunksize = round(chunksize) # then round the chunksize down

for (i in 1:nsplits){
  fname = sprintf('chunk_%04.0f.Rdata', i)
  firstrow = (i-1)*chunksize+1
  lastrow=i*chunksize
  if (i == nsplits){ # if it's the last one
    lastrow=lastrow+tot.rmdr # tack on the remainder
  }
  tmp = reduced_data_train[firstrow:lastrow,]
  save(tmp,file=fname)
}

rm(tmp); rm(reduced_data_train); gc();


### GET PREDICTIONS

load('reduced_data_test.rdata')


vec = rep(0,nrow(reduced_data_test))
for (i in 1:nsplits){
  fname = sprintf('chunk_%04.0f.Rdata', i)
  load(fname)
  tmp$target <- as.factor(tmp$target)
  rf = randomForest(target~., data=tmp, ntree=ntree)
  tmp = as.numeric(predict(rf,reduced_data_test,type='prob'))
  vec = vec + tmp
  cat('\nfinished forest',i)
}

probs = 1 - (vec/nsplits)

### WRITE SUBMISSION ############################

submission = cbind(rownames(reduced_data_test), probs[1:145232])
colnames(submission) <- c('ID','target')
subname = sprintf("rf_chunk_reduced_%03d.csv", ntree)
write.csv(submission, subname, row.names=FALSE)

