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
# We can later try with dummy codes
target <- unlist(transformed_data_train["target"])

# The numeric data stops at variables 538 so we will subset the input to
# the DMatrix
dmatrix <- xgb.DMatrix(as.matrix(transformed_data_train[,1:537]), 
            label=target)
rm(transformed_data_train)
dmatrix_test <- xgb.DMatrix(as.matrix(transformed_data_test[,1:537]))
rm(transformed_data_test)

# Save the matrix files to avoid conversion again (Don't think I need this)
#save(pca_training,file="pca_training_matrix.rdata")
#save(pca_test,file="pca_test_matrix.rdata")

#load("pca_training_matrix.rdata")
#load("pca_test_matrix.rdata")

# Now we can go ahead and fit the xgboost tree
# We will also calculate runtime because why not
start_time <- proc.time()
pca_xgboost <- xgboost(data = dmatrix, # dmatrix object, should contain all info
                     max.depth = 10, # depth of each tree. Too high = overfit 
                     eta = .01, # step size of each boosting step
                              # smaller results in slower training
                              # larger may have less accuracy
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
write_csv(predictions,path="Submission3.csv")

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
# cleaned_training <- cleaned_training[,-factor_ind]
# cleaned_test <- cleaned_test[,-factor_ind]

# Convert factor data into numeric
# cleaned_training[,factor_ind] <- lapply(cleaned_training[,factor_ind],as.integer)
# cleaned_test[,factor_ind] <- lapply(cleaned_test[,factor_ind],as.integer)

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

##### Below will run a loop that will iterate through N bagged xgboost trees
# and average the results for an ensemble prediction. The goal is to
# potentially overfit some of the individual trees but then average
# results to generalize better.

# Specify how many iterations to perform
N <- 10
# Specify in bag fraction
j <- 0.4

# Initialize the prediction vector
total_prediction <- rep(0,145232)
# Now run the XGBoost on the full numeric data set
start_time <- proc.time()
for(n in 1:N){
  
  in_bag <- sample(x=(1:dim(training)[1]),size=j*dim(training)[1])
  bagged_training <- training[in_bag,]
  bagged_target <- unname(target[in_bag])
  bag_xgboost <- xgboost(data = bagged_training, # data training matrix
                       label = bagged_target, # target variable
                       max.depth = 15, # depth of each tree. Too high = overfit 
                       eta = .5, # step size of each boosting step
                       # smaller results in slower training
                       # larger may have less accuracy
                       nthread = 2, # can run on multiple threads 
                       nround = 3, # how many times do we want to 
                       # pass through the data
                       objective = "binary:logistic") # specify we want classification

  # We can create our predictions now
  current_prediction <- predict(bag_xgboost, testing)
  # Increment the total predicted values
  total_prediction <- total_prediction + current_prediction
}
# Now average the predictions
average_prediction <- total_prediction/N
run_time <- proc.time() - start_time

# Load in original test data to grab ID numbers
load("test.rdata")
# Combine IDs and predictions, name the columns
predictions <- cbind(as.character(test$ID),average_prediction)
colnames(predictions) <- c("ID","target")
# Write CSV in order to submit
predictions <- as.data.frame(predictions,row.names=FALSE)
write_csv(predictions,path="Avg_Submission5.csv")
