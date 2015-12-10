### Read in Data ################################
setwd('~/Homework/') # andrew's wd
library(caret)
load("cleaned_data.rdata")

### REMOVE REDUNDANT VARIABLES ######################################

# Split the data back into training/test data sets. This will 
# prevent us from making any variable selection decisions
# from the test set.

cleaned_training <- cleaned_data[cleaned_data$data_inj == 0,]
cleaned_test <- cleaned_data[cleaned_data$data_inj == 1,]
rm(cleaned_data)

cleaned_training$data_inj <- NULL
cleaned_test$data_inj <- NULL
# split into X and y
cleaned_training_X <- cleaned_training
cleaned_training_X$target <- NULL
cleaned_training_y <- cleaned_training$target


# Grab numeric variables
dtypes <- sapply(cleaned_training_X, class)
unique(dtypes)
factor_ind <- unname(which(sapply(cleaned_training_X, class) == "factor"))
numeric_data <- cleaned_training_X[,-factor_ind]


# Construct correlation matrix
corr_matrix <- cor(numeric_data)
save(corr_matrix,file="corr_matrix.rdata")

# Use findCorrelation function to retrieve the correlated variable indices
# and then remove them from the data set
corr_vars <- findCorrelation(corr_matrix,.9)
rm(corr_matrix)
numeric_data <- numeric_data[,-corr_vars]

# Join numeric data back with factor data
reduced_data_train <- cbind(numeric_data,cleaned_training_X[,factor_ind])
rm(cleaned_training_X)
rm(numeric_data)
reduced_data_train$target <- cleaned_training_y


# remove the variables from test that we removed from training
reduced_data_test <- cleaned_test[,colnames(reduced_data_train)]
reduced_data_test$target <- NULL



### write the reduced training and test to disk

save(reduced_data_test, file='reduced_data_test.rdata')
save(reduced_data_train, file='reduced_data_train.rdata')
rm(reduced_data_train)
rm(reduced_data_test)
gc()


### PRINCIPAL COMPONENTS ############################################

cleaned_data_X <- cleaned_training
cleaned_data_X$target <- NULL
cleaned_data_y <- cleaned_training$target

# If we want to reduce dimensions further, we can use princ comps
# but we can only use them on numeric variables
factor_ind <- unname(which(sapply(cleaned_data_X, class) == "factor"))
numeric_data <- cleaned_data_X[,-factor_ind]


pcs <- prcomp(numeric_data, scale=TRUE, center=TRUE)


# select the M prin comps that explain 95% of the variance
total.var = sum(pcs$sdev^2)
pct.var = pcs$sdev^2/total.var
n.95 <- which(cumsum(pct.var)>= .95)[1]


# recompose the data frame
transformed_data_train <- cbind(pcs$x[,1:n.95], cleaned_data_X[,factor_ind])
transformed_data_train$target <- cleaned_data_y
save(transformed_data_train,file="PCA_data_train.rdata")
rm(transformed_data_train)


# do it to the test set too
cleaned_data_X_test <- cleaned_test
cleaned_data_X_test$target <- NULL

factor_ind_test <- unname(which(sapply(cleaned_data_X_test, class) == "factor"))
numeric_data_test <- cleaned_data_X_test[,-factor_ind_test]

pcs_test <- predict(pcs,numeric_data_test)
pcs_test <- as.data.frame(pcs_test)[,1:n.95]

transformed_data_test <- cbind(pcs_test, cleaned_data_X_test[,factor_ind_test])


# PCA data set we want to work with:

save(transformed_data_test,file="PCA_data_test.rdata")
rm(list=ls())


