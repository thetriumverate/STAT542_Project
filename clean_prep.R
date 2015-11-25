setwd("~/Homework/")
#setwd("~/UIUC/STAT542") Noah's wd
set.seed(1738)
library(gdata)
library(lubridate)

### Read in Data ################################

train <- read.csv("train.csv",row.names=1)
train$data_inj = 0; #this indicator tells us which data set the row belongs to (0 for train, 1 for test)

test <- read.csv("test.csv",row.names=1)
test$target = NA;
test$data_inj = 1;

#combining data sets
all_data <- rbind(train, test)

### inspect datatypes ###########################

dtypes <- sapply(all_data, class)
unique(dtypes)

### FACTOR VARIABLES ############################

str(all_data[,which(sapply(all_data, class) == "factor")])

# lots of the variables have 1 label plus missing
# in fact, thats every var with 2 classes
# so we can remove them 

bad.vars <- which(sapply(all_data,nlevels) ==2)
all_data <- all_data[,-bad.vars]
gc()

# we also notice the missing values are
# represented by "", -1, or []
# so replace with NA

train_fact <- all_data[,which(sapply(all_data, class) == "factor")]
train_fact[train_fact == -1] = NA
train_fact[train_fact == "[]"] = NA
train_fact[train_fact == ""] = NA
all_data[,which(sapply(all_data, class) == "factor")] <- drop.levels(train_fact)
gc()

### PARSING DATE VARIABLES ############################

train_fact <- as.data.frame(train_fact)

#getting date variables from train_fact
train_date = Filter(function(u) any(grepl('JAN1|FEB1|APR1',u)), train_fact)

#taking date variables out of train_fact, don't know if needed
train_fact = train_fact[, !colnames(train_fact) %in% colnames(train_date)]
dim(train_fact)

#intermediate conversion step
train_date = sapply(train_date, function(x) strptime(x, "%d%B%y:%H:%M:%S"))

#recommend saving objects here
#save(list = ls(all.names = TRUE), file = "date_vars_objects.RData", envir = .GlobalEnv)

train_date = do.call(cbind.data.frame, train_date) #converts train_date to df

#initializing matrices
train_date_month <- data.frame(matrix(0,nrow=dim(train_date)[1],ncol=dim(train_date)[2]))
train_date_year <- data.frame(matrix(0,nrow=dim(train_date)[1],ncol=dim(train_date)[2]))

#getting months and year variables, right now they are numeric
for(i in 1:(dim(train_date)[2]))
{
  train_date_month[,i] = as.factor(month(as.POSIXlt(train_date[,i], format="%d%B%y:%H:%M:%S")))
  train_date_year[,i] = as.factor(year(as.POSIXlt(train_date[,i], format="%d%B%y:%H:%M:%S")))
}

#taking old date variables out of all_data 
all_data = all_data[, !colnames(all_data) %in% colnames(train_date)]
dim(all_data)

#renaming new date variables
names(train_date_month) <- paste(names(train_date),"m", sep = "_")
names(train_date_year) <- paste(names(train_date),"y", sep = "_")


### PARSING STATE VARIABLES ############################

#getting states variables
state_vars <- Filter(function(u) any(grepl('TX|WV|AZ',u)), train_fact)
dim(state_vars)
state_vars <- state_vars[,2:3]

#taking state variables out of train_fact, dont know if needed
train_fact = train_fact[, !colnames(train_fact) %in% colnames(state_vars)]
dim(train_fact)

#taking state variables out of all_data
all_data = all_data[, !colnames(all_data) %in% colnames(state_vars)]
dim(all_data)

#states broken up into regions according to census: http://www2.census.gov/geo/pdfs/maps-data/maps/reference/us_regdiv.pdf

state_vars$VAR_0237_new <- state_vars$VAR_0237
levels(state_vars$VAR_0237_new) <- c(levels(state_vars$VAR_0237_new), "NE","MA","ENC","WNC","SA","ESC","WSC","MT","PC","Other",NA)
state_vars[state_vars$VAR_0237 %in% c("CT", "ME","MA","NH","RI","VT"), "VAR_0237_new"] <- "NE"
state_vars[state_vars$VAR_0237 %in% c("NJ", "NY","PA"), "VAR_0237_new"] <- "MA"
state_vars[state_vars$VAR_0237 %in% c("IN", "IL","MI","OH","WI"), "VAR_0237_new"] <- "ENC"
state_vars[state_vars$VAR_0237 %in% c("IA", "KS","MN","MO","NE","ND","SD"), "VAR_0237_new"] <- "WNC"
state_vars[state_vars$VAR_0237 %in% c("DE", "DC","FL","GA","MD","NC","SC","VA","WV"), "VAR_0237_new"] <- "SA"
state_vars[state_vars$VAR_0237 %in% c("AL", "KY","MS","TN"), "VAR_0237_new"] <- "ESC"
state_vars[state_vars$VAR_0237 %in% c("AR", "LA","OK","TX"), "VAR_0237_new"] <- "WSC"
state_vars[state_vars$VAR_0237 %in% c("AZ", "CO","ID","NM","MT","UT","NV","WY"), "VAR_0237_new"] <- "MT"
state_vars[state_vars$VAR_0237 %in% c("AK", "CA","HI","OR","WA"), "VAR_0237_new"] <- "PC"
state_vars[state_vars$VAR_0237 %in% c("PR","EE","RR","RN","GS"), "VAR_0237_new"] <- "Other"
state_vars[state_vars$VAR_0237 %in% c("-1",""), "VAR_0237_new"] <- NA;

state_vars$VAR_0274_new <- state_vars$VAR_0274
levels(state_vars$VAR_0274_new) <- c(levels(state_vars$VAR_0274_new), "NE","MA","ENC","WNC","SA","ESC","WSC","MT","PC","Other",NA)
state_vars[state_vars$VAR_0274 %in% c("CT", "ME","MA","NH","RI","VT"), "VAR_0274_new"] <- "NE"
state_vars[state_vars$VAR_0274 %in% c("NJ", "NY","PA"), "VAR_0274_new"] <- "MA"
state_vars[state_vars$VAR_0274 %in% c("IN", "IL","MI","OH","WI"), "VAR_0274_new"] <- "ENC"
state_vars[state_vars$VAR_0274 %in% c("IA", "KS","MN","MO","NE","ND","SD"), "VAR_0274_new"] <- "WNC"
state_vars[state_vars$VAR_0274 %in% c("DE", "DC","FL","GA","MD","NC","SC","VA","WV"), "VAR_0274_new"] <- "SA"
state_vars[state_vars$VAR_0274 %in% c("AL", "KY","MS","TN"), "VAR_0274_new"] <- "ESC"
state_vars[state_vars$VAR_0274 %in% c("AR", "LA","OK","TX"), "VAR_0274_new"] <- "WSC"
state_vars[state_vars$VAR_0274 %in% c("AZ", "CO","ID","NM","MT","UT","NV","WY"), "VAR_0274_new"] <- "MT"
state_vars[state_vars$VAR_0274 %in% c("AK", "CA","HI","OR","WA"), "VAR_0274_new"] <- "PC"
state_vars[state_vars$VAR_0274 %in% c("PR","EE","RR","RN","GS"), "VAR_0274_new"] <- "Other"
state_vars[state_vars$VAR_0274 %in% c("-1",""), "VAR_0274_new"] <- NA;


#################################################

#add in new factor variables (train_date_month, train_date_year, state_vars[,3:4]) to all_data
all_data <- data.frame(all_data, train_date_month, train_date_year, state_vars[,3:4])

### LOGICAL VARIABLES ###########################

str(all_data[,which(sapply(all_data, class) == "logical")])

# looks like we can drop them all too

bad.vars <- which(sapply(all_data,class) =='logical')
all_data <- all_data[,-bad.vars]
gc()


### INTEGER VARIABLES ###########################

str(lapply(all_data[,which(sapply(all_data, class) == "integer")], unique))

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

str(lapply(all_data[,which(sapply(all_data, class) == "numeric")], unique))

### impute NAs ###
### impute NAs ###
### impute NAs ###
### impute NAs ###
### impute NAs ###
### impute NAs ###



### REMOVE CONSTANTS ############################

col_ct = sapply(all_data, function(x) length(unique(x)))
bad.vars <- which(col_ct ==1)
all_data <- all_data[,-bad.vars]
gc()

### REMOVE REDUNDANT VARIABLES ##################



### WRITE TO DISK ###############################

rm(list=setdiff(ls(), "all_data")) #remove all objects but data set containing modified train & test sets
save(list = ls(all.names = TRUE), file = "name_yo_object.RData", envir = .GlobalEnv) #save all_data to rdata file, I feel like this is faster to load in
#save(all_data,file="data_clean.csv")


