##### This script will perform the xgboost procedure

setwd("~/Git/Stat542") # Zach's wd
library(xgboost)
library(readr)
library(psych)
set.seed(1848)

####################################################################
# Let's run this on the non-reduced data set

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

# These are just saved to make running the code more convenient
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


##### Below will run a loop that will iterate through N bagged xgboost trees
# and average the results for an ensemble prediction. The goal is to
# potentially overfit some of the individual trees but then average
# results to generalize better.

# Specify how many iterations to perform
N <- 3
# Specify in bag fraction
j <- 1

# Initialize the prediction vector
total_prediction <- rep(0,145232)
# Now run the XGBoost on the full numeric data set
start_time <- proc.time()
for(n in 1:N){
  
  # Store the indices of the bagged observations
  in_bag <- sample(x=(1:dim(training)[1]),size=j*dim(training)[1],replace=TRUE)
  # Subset the training and target according to the bagged indices
  bagged_training <- training[in_bag,]
  bagged_target <- unname(target[in_bag])
  # Fit the xgboost model
  bag_xgboost <- xgboost(data = bagged_training, # data training matrix
                       label = bagged_target, # target variable
                       max.depth = 10, # depth of each tree. Too high = overfit 
                       eta = .1, # step size of each boosting step
                       # smaller results in slower training
                       # larger may have less accuracy
                       nthread = 2, # can run on multiple threads 
                       nround = 5, # how many times do we want to 
                       # pass through the data
                       eval_metric = "auc", # return AUC info
                       verbose=2, #print more info
                       objective = "binary:logistic") # specify we want classification

  # We can create our predictions now
  current_prediction <- predict(bag_xgboost, testing)
  # Increment the total predicted values
  total_prediction <- total_prediction + current_prediction
}
# Now average the predictions
average_prediction <- total_prediction/N
run_time <- proc.time() - start_time

# Combine IDs and predictions
predictions <- cbind(as.character(ID),average_prediction)
# Name the columns
colnames(predictions) <- c("ID","target")
# Write CSV in order to submit
# predictions <- as.data.frame(predictions,row.names=FALSE)
# write_csv(predictions,path="bagged.csv")
