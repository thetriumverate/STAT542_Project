setwd("~/Homework/")
set.seed(1738)
library(gdata)

### Read in Data ################################

train <- read.csv("train.csv",row.names=1)

### inspect datatypes ###########################

dtypes <- sapply(train, class)
unique(dtypes)

### FACTOR VARIABLES ############################

str(train[,which(sapply(train, class) == "factor")])

# lots of the variables have 1 label plus missing
# in fact, thats every var with 2 classes
# so we can remove them 

bad.vars <- which(sapply(train,nlevels) ==2)
train <- train[,-bad.vars]
gc()

# we also notice the missing values are
# represented by "", -1, or []
# so replace with NA

train_fact <- train[,which(sapply(train, class) == "factor")]
train_fact[train_fact == -1] = NA
train_fact[train_fact == "[]"] = NA
train_fact[train_fact == ""] = NA
train[,which(sapply(train, class) == "factor")] <- drop.levels(train_fact)
gc()

### Parse Dates ###
### Parse Dates ###
### Parse Dates ###
### Parse Dates ###
### Parse Dates ###
### Parse Dates ###


### Parse Locations ###
### Parse Locations ###
### Parse Locations ###
### Parse Locations ###
### Parse Locations ###
### Parse Locations ###



### LOGICAL VARIABLES ###########################

str(train[,which(sapply(train, class) == "logical")])

# looks like we can drop them all too

bad.vars <- which(sapply(train,class) =='logical')
train <- train[,-bad.vars]
gc()


### INTEGER VARIABLES ###########################

str(lapply(train[,which(sapply(train, class) == "integer")], unique))

### remove unreasonable values ###
### remove unreasonable values ###
### remove unreasonable values ###
### remove unreasonable values ###
### remove unreasonable values ###


### impute NAs ###
### impute NAs ###
### impute NAs ###
### impute NAs ###
### impute NAs ###
### impute NAs ###


### NUMERIC VARIABLES ########################### 

str(lapply(train[,which(sapply(train, class) == "numeric")], unique))

### impute NAs ###
### impute NAs ###
### impute NAs ###
### impute NAs ###
### impute NAs ###
### impute NAs ###



### REMOVE CONSTANTS ############################

col_ct = sapply(train, function(x) length(unique(x)))
bad.vars <- which(col_ct ==1)
train <- train[,-bad.vars]
gc()

### REMOVE REDUNDANT VARIABLES ##################



### WRITE TO DISK ###############################

save(train,file="train_clean.csv")


