### Read in the Data ############################
## too make a smaller code testing dataset, run
## head -500 train.csv > train_500.csv
## in the console in the directory where 
## train.csv lives

setwd("~/Homework/")
train <- read.csv("train_500.csv",row.names=1)

### Clean up the data ###########################

## remove the logical columns
log.cols <- which(sapply(train, class) == 'logical')
train <- train[,-log.cols]

## remove the columns with too many factor levels
bad.cols <- which(sapply(train,nlevels) > 32)
train <- train[,-bad.cols]

## rough fix the na values
library(randomForest)
train <- na.roughfix(train)

## in total we drop 18 columns
length(c(bad.cols,log.cols)) 

### split_data ##################################

## function that takes the data file and splits
## bootstrap samples with parameters

# n -- number of samples
# m -- size of samples
# p -- number of features 


split_data <- function(n, m, p){
  for (i in 1:n){
    fname = sprintf('bs_sample_%04.0f.csv', i)
    rows = sample(1:nrow(train), m, replace=T)
    cols = c(sample(1:(ncol(train)-1), p, replace=T),ncol(train))
    tmp = train[rows,cols]
    write.csv(tmp,file=fname)
  }
  rm(tmp); gc();
  cat('the current working directory is ', getwd(),'\n')
  cat('check there for the',n, 'bootstrap samples \n')
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

library(tree)

get_trees <- function(n){
  tree.list <- lapply(1:n, function(x){
    fname = sprintf('bs_sample_%04.0f.csv', x)
    test <- read.csv(fname,row.names = 1)
    test$target <- as.factor(test$target)
    tree(target~., test)
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

big_rf <- function(ntree, mtry, samp.size){
  split_data(n=ntree, m=samp.size, p=mtry)
  
  get_trees(ntree)
}

trees <- big_rf(10,200,500) # call the actual FUN

trees[[1]]

## the idea now is that we have contructed a
## pseudo random forest with only loading 
## one small data set into memory at a time.
## instead of randomizing vars at each split,
## we randomize for each tree



