##### This script will perform the xgboost procedure

setwd("~/Git/Stat542") # Zach's wd
library(xgboost)
library(readr)
library(psych)
set.seed(1848)

# First let's run xgboost on the pca data since that should run fastest

# Load in data and create a matrix for the function input
# WARNING: Making the matrix takes FOREVER
load("PCA_data_train.rdata")
load("PCA_data_test.rdata")
pca_training <- as.matrix(transformed_data_train)
pca_test <- as.matrix(transformed_data_test)
 
# Xgboost only works on numeric data. To just get an initial tree fit,
# let's ignore the factor variables and work with the numeric.
target <- unlist(transformed_data_train["target"])

# The numeric data stops at variables 538 so we will subset the input to
# the DMatrix
dmatrix <- xgb.DMatrix(as.matrix(transformed_data_train[,1:537]), 
            label=target)
rm(transformed_data_train)
dmatrix_test <- xgb.DMatrix(as.matrix(transformed_data_test[,1:537]))
rm(transformed_data_test)

#load("pca_training_matrix.rdata")
#load("pca_test_matrix.rdata")

# Now we can go ahead and fit the xgboost tree
start_time <- proc.time()
pca_xgboost <- xgboost(data = dmatrix, # dmatrix object, should contain all info
                     max.depth = 10, # depth of each tree. Too high = overfit 
                     eta = .01, # step size of each boosting step
                              # smaller can help prevent overfitting
                     nthread = 2, # can run on multiple threads 
                     nround = 3, # how many times do we want to 
                                 # pass through the data
                     objective = "binary:logistic") # specify we want classification
run_time <- proc.time() - start_time

# We can create our predictions now
predictions <- predict(pca_xgboost, dmatrix_test)
# Load in original test data to grab ID numbers
load("test.rdata")
# Combine IDs and predictions, name the columns
predictions <- cbind(as.character(test$ID),predictions)
colnames(predictions) <- c("ID","target")
# Write CSV in order to submit
predictions <- as.data.frame(predictions,row.names=FALSE)
#write_csv(predictions,path="Submission3.csv")

####################################################################
# Let's run this on the non-reduced data set
# This will be ran on data chunks

# Clear workspace and load in original data
rm(list=objects())
load("cleaned_data.rdata")

# Split data into training and test sets
cleaned_training <- cleaned_data[cleaned_data$data_inj == 0,]
cleaned_test <- cleaned_data[cleaned_data$data_inj == 1,]
rm(cleaned_data)

# Create factor indicator so we can remove them before running xgboost
factor_ind <- unname(which(sapply(cleaned_training, class) == "factor"))
cleaned_training <- cleaned_training[,-factor_ind]
cleaned_test <- cleaned_test[,-factor_ind]

# Store target in its own list
target <- unlist(cleaned_training["target"])

# We will subset out two variables from the data set
# since they are just the target and training/test indicator variables
remove_ind <- which(names(cleaned_training)=="target")
remove_ind <- c(remove_ind,which(names(cleaned_training)=="data_inj"))
training <- as.matrix(cleaned_training[,-remove_ind]) 
rm(cleaned_training)

testing <- as.matrix(cleaned_test[,-remove_ind])
rm(cleaned_test)

# Load in original test data to grab ID numbers
load("test.rdata")
ID <- test$ID
rm(test)

# These files were just saved and loaded for convenience to avoid
# having to re-run the data preparation

# save(training,file="xgboost_training.rdata")
# save(testing,file="xgboost_testing.rdata")
# save(ID,target,file="xgboost_other.rdata")
# load("xgboost_training.rdata")
# load("xgboost_testing.rdata")
# save(training,testing,target,ID,file="xgboost.rdata")

# This is another data file that is just saved for convenience.
# It contains the XGboost training/test data, the test set ID numbers,
# and the target variable.
#load("xgboost.rdata")

##### Below will run a loop that will iterate through N chunked xgboost trees
# and average the results for an ensemble prediction. The goal is to
# potentially overfit some of the individual trees but then average
# results to generalize better.

# Specify how many iterations to perform
N <- 10
# Specify chunk fraction
j <- .4

# Initialize the prediction vector
total_prediction <- rep(0,145232)
# Now run the XGBoost on the full numeric data set
start_time <- proc.time()
for(n in 1:N){
  
  # Chunked
  chunks <- sample(x=(1:dim(training)[1]),size=j*dim(training)[1])
  chunked_training <- training[chunks,]
  chunked_target <- unname(target[chunks])
  chunked_xgboost <- xgboost(data = chunked_training, # data training matrix
                       label = chunked_target, # target variable
                       max.depth = 10, # depth of each tree. Too high = overfit 
                       eta = .5, # step size of each boosting step
                       # smaller results in slower training
                       # larger may have less accuracy
                       nthread = 2, # can run on multiple threads 
                       nround = 3, # how many times do we want to 
                       # pass through the data
                       eval_metric = "auc", # return AUC info
                       verbose=2, #print more info
                       objective = "binary:logistic") # specify we want classification

  # We can create our predictions now
  current_prediction <- predict(chunked_xgboost, testing)
  # Increment the total predicted values
  total_prediction <- total_prediction + current_prediction
}
# Now average the predictions
average_prediction <- total_prediction/N
run_time <- proc.time() - start_time


# Combine IDs and predictions, name the columns
predictions <- cbind(as.character(ID),average_prediction)
colnames(predictions) <- c("ID","target")
# Write CSV in order to submit
predictions <- as.data.frame(predictions,row.names=FALSE)
#write_csv(predictions,path="Avg_Submission10.csv")
