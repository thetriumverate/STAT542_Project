### Read in Data ################################

load("cleaned_data.rdata")

### REMOVE REDUNDANT VARIABLES ##################

# Split the data back into training/test data sets. This will 
# prevent us from making any variable selection decisions
# from the test set.
train_ind <- ifelse(cleaned_data$target!=999999,TRUE,FALSE)
cleaned_training <- cleaned_data[train_ind,]

# Grab numeric variables
dtypes <- sapply(cleaned_training, class)
unique(dtypes)
factor_ind <- unname(which(sapply(cleaned_training, class) == "factor"))
numeric_data <- cleaned_training[,-factor_ind]

# There appear to be some constant variables that came through. Remove them.
standard_dev <- apply(numeric_data,MARGIN=2,sd)
zero_variance <- unname(which(standard_dev==0))
numeric_data <- numeric_data[,-zero_variance]

# Construct correlation matrix
corr_matrix <- cor(numeric_data)
save(corr_matrix,file="corr_matrix.rdata")

# Use findCorrelation function to retrieve the correlated variable indices
# and then remove them from the data set
corr_vars <- findCorrelation(corr_matrix,0.9)
uncorr_vars <- numeric_data[,-corr_vars]

# Join numeric data back with factor data
reduced_data <- cbind(uncorr_vars,cleaned_training[,factor_ind])


#### Principal Component Test
# If we want to reduce dimensions further, we can use princ comps
pcs <- princomp(x=uncorr_vars)

# Feng has code to select the M princ comps that explain X% of the data.
# We can dig this up if deemed necessary.

# Final data set we want to work with:
save(reduced_data,file="reduced_data.rdata")

### WRITE TO DISK ###############################

rm(list=setdiff(ls(), "all_data")) #remove all objects but data set containing modified train & test sets
save(list = ls(all.names = TRUE), file = "name_yo_object.RData", envir = .GlobalEnv) #save all_data to rdata file, I feel like this is faster to load in
#save(all_data,file="data_clean.csv")


