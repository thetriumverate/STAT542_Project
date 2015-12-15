## Setup

start.time <- proc.time()

library(tree)
setwd("~/Homework/")
load('reduced_data_train.rdata')

## Parameters

ntree=2001
samp.size=15000
mtry=100


### GET BS SAMPLES ##############################

for (i in 1:ntree){
  fname = sprintf('bs_sample_%04.0f.Rdata', i)
  rows = sample(1:nrow(reduced_data_train), samp.size, replace=T)
  cols = c(sample(1:(ncol(reduced_data_train)-1), mtry, replace=F),ncol(reduced_data_train))
  tmp = reduced_data_train[rows,cols]
  save(tmp,file=fname)
}
rm(tmp); rm(reduced_data_train); gc();


### GET PREDICTIONS ON TEST #####################

load('reduced_data_test.rdata')


vec = rep(0,nrow(reduced_data_test))
for (i in 1:ntree){
  fname = sprintf('bs_sample_%04.0f.Rdata', i)
  load(fname)
  tmp$target <- as.factor(tmp$target)
  tr = tree(target~., data=tmp)
  #tr = prune.tree(tr, best=5)
  tmp = as.numeric(predict(tr,reduced_data_test))
  vec = vec + tmp
}

probs = 1 - (vec/ntree)

### WRITE SUBMISSION ############################

submission = cbind(rownames(reduced_data_test), probs[1:145232])
colnames(submission) <- c('ID','target')
subname = sprintf("our_method_reduced_%03d.csv", ntree)
write.csv(submission, subname, row.names=FALSE)


end.time <-proc.time() - start.time
end.time 
