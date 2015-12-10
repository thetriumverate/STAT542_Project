setwd("~/Homework/") # andrew's wd
#setwd("~/UIUC/STAT542") # Noah's wd
#setwd("~/Git/Stat542") # Zach's wd

set.seed(1738)
library(gdata)
library(lubridate)
library(randomForest)


### Read in Data ################################

### Stores CSVs as Rdata for faster loading

if (!file.exists('train.rdata')){ 
  train <- read.csv("train.csv",row.names=1)
  save(train, file='train.rdata')
  rm(train)
} 

if (!file.exists('test.rdata')){
  test <- read.csv("test.csv",row.names=1)
  save(test, file='test.rdata')
  rm(test)
}

### loads in the rdata files and combines them into all_data

load("train.rdata")
train$data_inj = 0; #this indicator tells us which data set the row belongs to (0 for train, 1 for test)

load("test.rdata")
test$target = 999999; # Set to arbitrary value 
test$data_inj = 1;

#combining data sets
all_data <- rbind(train, test)
rm(list=setdiff(ls(), "all_data"))
gc()

### inspect datatypes ###########################

dtypes <- sapply(all_data, class)
unique(dtypes)
table(dtypes)
### FACTOR VARIABLES ############################

str(all_data[,which(sapply(all_data, class) == "factor")])

# we notice the missing values are
# represented by "", -1, or []
# so replace with NA

train_fact <- all_data[,which(sapply(all_data, class) == "factor")]
train_fact[train_fact == -1] = NA
train_fact[train_fact == "[]"] = NA
train_fact[train_fact == ""] = NA
all_data[,which(sapply(all_data, class) == "factor")] <- drop.levels(train_fact)
gc()

# check to make sure it worked
str(all_data[,which(sapply(all_data, class) == "factor")])
# now those look like nice factor vars

# although there are still some with only 1 level

bad.vars <- which(sapply(all_data,nlevels) ==1)
bad.vars
all_data <- all_data[,-bad.vars]
gc()

# check again to make sure it worked
str(all_data[,which(sapply(all_data, class) == "factor")])

# now they look great. we'll get the one with 0 levels
# and the NAs later

### PARSING DATE VARIABLES ############################

train_fact <- as.data.frame(train_fact)

#getting date variables from train_fact
train_date = Filter(function(u) any(grepl('JAN1|FEB1|APR1',u)), train_fact)

#intermediate conversion step
train_date = sapply(train_date, function(x) strptime(x, "%d%B%y:%H:%M:%S"))

train_date = do.call(cbind.data.frame, train_date) #converts train_date to df

#initializing matrices
train_date_month <- data.frame(matrix(0,nrow=dim(train_date)[1],ncol=dim(train_date)[2]))
train_date_year <- data.frame(matrix(0,nrow=dim(train_date)[1],ncol=dim(train_date)[2]))

#getting months and year variables
for(i in 1:(dim(train_date)[2]))
{
  train_date_month[,i] = as.factor(month(as.POSIXlt(train_date[,i], format="%d%B%y:%H:%M:%S")))
  train_date_year[,i] = as.factor(year(as.POSIXlt(train_date[,i], format="%d%B%y:%H:%M:%S")))
}

######### taking old date variables out of all_data ####################
all_data = all_data[, !colnames(all_data) %in% colnames(train_date)]
dim(all_data)

#renaming new date variables
names(train_date_month) <- paste(names(train_date),"m", sep = "_")
names(train_date_year) <- paste(names(train_date),"y", sep = "_")
rm(train_date)

### PARSING STATE VARIABLES ############################

#getting states variables
state_vars <- Filter(function(u) any(grepl('TX|WV|AZ',u)), train_fact)
rm(train_fact)
dim(state_vars)

#taking state variables out of all_data (this gets rid of the two state varaibles and the "city" variable with tons of levels)
all_data = all_data[, !colnames(all_data) %in% colnames(state_vars)]
dim(all_data)

state_vars <- state_vars[,2:3]

#states broken up into regions according to census: http://www2.census.gov/geo/pdfs/maps-data/maps/reference/us_regdiv.pdf

state_vars$VAR_0237_new <- state_vars$VAR_0237
levels(state_vars$VAR_0237_new) <- c(levels(state_vars$VAR_0237_new), "NE","MA","ENC","WNC","SA","ESC","WSC","MT","PC","Other","Missing")
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
state_vars[state_vars$VAR_0237 %in% c("-1",""), "VAR_0237_new"] <- "Missing";

state_vars$VAR_0274_new <- state_vars$VAR_0274
levels(state_vars$VAR_0274_new) <- c(levels(state_vars$VAR_0274_new), "NE","MA","ENC","WNC","SA","ESC","WSC","MT","PC","Other","Missing")
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
state_vars[state_vars$VAR_0274 %in% c("-1",""), "VAR_0274_new"] <- "Missing";

state_vars$VAR_0237_new <- drop.levels(state_vars$VAR_0237_new)
state_vars$VAR_0274_new <- drop.levels(state_vars$VAR_0274_new)
state_vars <- state_vars[,3:4]



#add in new factor variables (train_date_month, train_date_year, state_vars) to all_data
all_data <- data.frame(all_data, train_date_month, train_date_year, state_vars)
rm(train_date_month)
rm(train_date_year)
# check to make sure it all looks good
str(all_data[,which(sapply(all_data, class) == "factor")])

# we know we can remove the factors with 0 and 1 levels
# which are VAR_0044 and VAR_0204_y

myvars <- names(all_data) %in% c('VAR_0044', 'VAR_0204_y')
all_data <- all_data[!myvars]

# we also need to drop those with > 32 levels
bad.vars <- which(sapply(all_data,nlevels) >32)
all_data <- all_data[-bad.vars]

######## Exploring values to change to NA #############################

#little function to give missing data information, parameter should be dataframe
propmiss <- function(dataframe) {
  m <- sapply(dataframe, function(x) {
    data.frame(
      nmiss=sum(is.na(x)), 
      n=length(x), 
      propmiss=sum(is.na(x))/length(x)
    )
  })
  d <- data.frame(t(m))
  d <- sapply(d, unlist)
  d <- as.data.frame(d)
  d$variable <- row.names(d)
  row.names(d) <- NULL
  d <- cbind(d[ncol(d)],d[-ncol(d)])
  return(d[order(d$propmiss), ])
}


train_numr = all_data[, sapply(all_data, is.numeric)]

train_numr_samp = train_numr[,sample(1:ncol(train_numr),100)]
str(lapply(train_numr_samp, unique))

rm(train_numr)
rm(train_numr_samp)

# hist(all_data$VAR_1215)
# hist(all_data$VAR_0979)
# hist(all_data$VAR_1251)
# hist(all_data$VAR_1113)
# hist(all_data$VAR_1682)
# 
# 
# table(all_data$VAR_1215)
# table(all_data$VAR_0979)
# table(all_data$VAR_1251)


#it looks like 999999996 - 999999999 are some sort of other indicator. 
#These values only occur in int class variables (there's only 13 numeric variables)
#I'm also not finding -1 when -99999 is present, so these could theoretically mean missing or some other indicator from different data locations/servers.
#However NA's are present in variables with -1 as a level
# basically it is one awful mess
############## IMPUTATION ##########################################################


#I tried converting our factors to characters so that when I save to csv we don't have factors convert to numeric
##all_data[sapply(all_data, is.factor)] <- lapply(all_data[sapply(all_data, is.factor)], as.character)
#This ended up not working 

dtypes <- sapply(all_data, class)
unique(dtypes)



### WRITE CHECKPOINT ############################

# a little silly, but here we are writing the 
# data file out to a csv so we can read it back
# in with the NAs coded properly

write.csv(all_data, file="Checkpoint2.csv") #you can use the link below for this file below if you like
# here is the location of Checkpoint2.csv: https://uofi.box.com/s/qtpvgdkql1wyylvfkygz830dk2d0dr32

# We need a factor indicator to re-convert the factor variables that get 
# miscoded using read_csv
factor_ind <- which(sapply(all_data,class)=="factor")
rm(list=setdiff(ls(), "factor_ind"))


### END WRITE CHECKPOINT ########################


### Read back in the data 

all_data <- read.csv("Checkpoint2.csv",
                     na=c("","NA"," ","NULL",-1,-99999,999999999,999999998,999999997,999999996),
                     row.names=1)

# Store the names of the factors
factor_names <- names(factor_ind)

# convert back to factors
all_data[,factor_names] <- lapply(all_data[,factor_names] , factor)

# get rid of the logical variables, they are useless
bad.vars <- which(sapply(all_data,class) =='logical')
all_data <- all_data[,-bad.vars]
gc()

# We can check and see that we do have factors once again
dtypes <- sapply(all_data, class)
unique(dtypes)

str(all_data[,which(sapply(all_data, class) == "factor")])


### NA FIX (FINALLY) ############################

all_data = na.roughfix(all_data)

# checking for NAs
na_count <- sapply(all_data, function(y) sum(which(is.na(y)))) # na's by column
sum(na_count) # total na's

#removing constant variables
col_ct = sapply(all_data, function(x) length(unique(x)))
bad.vars <- which(col_ct ==1)
all_data <- all_data[,-bad.vars]
gc()

# Store cleaned data so I don't have to do this garbage again
cleaned_data <- all_data
rm(all_data)
save(cleaned_data,file="cleaned_data.rdata")
rm(list=ls())
gc()
