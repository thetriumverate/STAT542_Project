start.time <- proc.time()
### Read in the Data ############################
## too make a smaller code testing dataset, run
## head -500 train.csv > train_500.csv
## in the console in the directory where 
## train.csv lives

setwd("~/Homework/")
data <- read.csv("train_10000.csv",row.names=1)
data$target <- as.factor(data$target)


### Clean up the data ###########################

## remove the logical columns
log.cols <- which(sapply(data, class) == 'logical')
data <- data[,-log.cols]

## remove the columns with too many factor levels
bad.cols <- which(sapply(data,nlevels) > 32)
data <- data[,-bad.cols]

## rough fix the na values
library(randomForest)
data <- na.roughfix(data)

## in total we drop 25 columns
length(c(bad.cols,log.cols)) 


train.ids <- sample(nrow(data),nrow(data)*.8,replace=F)
train <- data[train.ids,]
test <- data[-train.ids,]
rm(data)
class_freqs = 1/(table(train[,ncol(train)])/nrow(train))

### split_data ##################################

## function that takes the data file and splits
## bootstrap samples with parameters

# n -- number of samples
# m -- size of samples
# p -- number of features 

## operates on a dataset called 'train'

split_data <- function(ntree, samp.size,mtry){
  for (i in 1:ntree){
    fname = sprintf('bs_sample_%04.0f.Rdata', i)
    rows = sample(1:nrow(train), samp.size, replace=T)
    cols = c(sample(1:(ncol(train)-1), mtry, replace=F),ncol(train))
    tmp = train[rows,cols]
    save(tmp,file=fname)
  }
  rm(tmp); gc();
  cat('the current working directory is ', getwd(),'\n')
  cat('check there for the',ntree, 'bootstrap samples \n')
}

# you might notice that sometimes this results in
# non-integer rownames. This is because when the
# bootstrapping selects two of the same
# observation, it doesn't want to store them with
# the same index. This is or is not a bug


### big_random_forest ###########################

## function that reads in n data files, one at a
## time, and constructs a random forest with no
## bootstrapping or variable selection as this
## is done in the split_data function.


## helper function get_trees



get_trees <- function(ntree,ds){
  tree.list <- lapply(1:ntree, function(x){
    fname = sprintf('bs_sample_%04.0f.Rdata', x)
    load(fname)
    #wts=ifelse(tmp[,ncol(tmp)]==0,class_freqs[1],class_freqs[2])
    #tree(target~., tmp,weights=wts)
    
    sampsize <- round(table(tmp$target)*c(ds,1))
    randomForest(target~., data=tmp,
                 ntree=1,mtry=ncol(tmp)-1,
                 replace=F,sampsize=sampsize,
                 strata=tmp$target)
  })
  gc()
  cat('') # keeps the gc from printing anything
  return(tree.list)
}

## tree.list is the list of trees in the forest


## main function big_rf
# ntree -- number of trees
# mtry -- number of variables in each tree
# samp.size -- size of bootstrap samples
# ds -- how much to downsample class 0

big_rf <- function(ntree, mtry, samp.size, ds ){
  split_data(ntree, samp.size, mtry)
  Sys.sleep(1)
  get_trees(ntree,ds)
}

trees <- big_rf(501,500,5000, .4) # call the actual FUN
#trees <- get_trees(101,.4)

## the idea now is that we have contructed a
## pseudo random forest with only loading 
## one small data set into memory at a time.
## instead of randomizing vars at each split,
## we randomize for each tree


### get test error ##############################

vec = rep(0,nrow(test))
for (i in 1:length(trees)){
  tmp = as.numeric(predict(trees[[i]],test[,-ncol(test)],type='class')) - 1
  tmp[is.na(tmp)] <- sample(c(0,1),1) # replace na's with 0 or 1
  vec = vec + tmp
}
probs = vec/length(trees)
preds = ifelse(probs>.5,1,0)

test.err <- 1 - sum(preds == test[,ncol(test)]) / length(preds)
test.err

table(preds)
table(test[,ncol(test)])

### get train error #############################
vec = rep(0,nrow(train))
for (i in 1:length(trees)){
  tmp = as.numeric(predict(trees[[i]],train[,-ncol(train)],type='class')) - 1
  tmp[is.na(tmp)] <- sample(c(0,1),1) # replace na's with 0 or 1
  vec = vec + tmp
}
probs = vec/length(trees)
preds = ifelse(probs>.5,1,0)

train.err <- 1 - sum(preds == train[,ncol(train)]) / length(preds)
train.err

table(preds)

end.time <-proc.time() - start.time
end.time 


## We're gonna have to write each tree to disk
## and load them one at a time...