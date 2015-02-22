## run_analysis.R
## This script downloads the UCI HAR Dataset then does the following: 
## 1. Merge the training and test sets to create one data set. 
## 2. Extract only the measurements on the mean and std deviation for each measurement. 
## 3. Use descriptive activity names to name the activities in the data set. 
## 4. Appropriatlely label the data set with descriptive variable names. 
## 5. From the data in step 4, create a second, independent tidy data set with the average
##    of each variable for each activity and each subject. 

date()
print("run_analysis.R starting")
print("Loading data.table, dplyr, tidyr")
library(data.table)
##library(plyr)
library(dplyr)
library(tidyr)

download_files <- function () {
    ## download the zip file; delete first if it already exists. 
    if (file.exists(zipFile)) {
        file.remove(zipFile)
    }
    print("do")
    download.file(fileURL, destfile=zipFile, quiet=TRUE, method="curl")
    
    ## unzip the file to the data directory & rename
    unzip(zipFile, overwrite=TRUE)
    ## rename the directory; delete first if it already exists
    if (file.exists(dataDirectory)) {
        unlink(dataDirectory, recursive=TRUE)
    } 
    file.rename(unzipDir, dataDirectory)
}


#### MAIN

get_files="N"
## set up directory and file name variables
downloadDate    = format(Sys.Date(), "%Y%m%d")
baseDirectory   = getwd()


## location of the input data set
fileURL="https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"

## name the local copy of the input data set
zipFile=paste(baseDirectory, "getdata-projectfiles-UCI-HAR-Dataset.zip", sep="/")
unzipDir=paste(baseDirectory, "UCI HAR Dataset", sep="/")

## name the tidy data files
tidyAvgsFile=paste(baseDirectory, "Tidy_AVG_UCI_HAR_Data.csv", sep="/")

## get_files = Y, we want to get latest remote copy of the data and use today's date in the directory name
if (get_files == "Y" || length(list.files(baseDirectory, "UCI_HAR_Dataset_????????")) == 0) {
    print("Downloading dataset...")
    dataDirectory   = paste(baseDirectory, "UCI_HAR_Dataset", sep="/")
    dataDirectory   = paste(dataDirectory, downloadDate, sep="_")
    download_files()
## get_files != Y, we want to use the latest local copy    
} else {
    fileDetails <- file.info(list.files(baseDirectory, "UCI_HAR_Dataset_????????"))
    fileDetails <- fileDetails[with(fileDetails, order(as.POSIXct(mtime))), ]
    lastDir <- tail(rownames(fileDetails), 1L)
    dataDirectory <- paste(baseDirectory, lastDir, sep="/")
}

## fread v1.9.4 producing buffer overflow on X_test and X_train
## fread v1.9.5 producing error Error in fread("X_train.txt") : 
## Not positioned correctly after testing format of header row. ch=' '
## So.....
## Read files into data frames
print("Reading data files...")
activityLabels  <- read.table(paste(dataDirectory,"activity_labels.txt",sep="/"), stringsAsFactors=F)
features        <- read.table(paste(dataDirectory,"features.txt", sep="/"), stringsAsFactors=F)

testData        <- read.table(paste(dataDirectory, "test/X_test.txt", sep="/"), stringsAsFactors=F)
testIDs         <- read.table(paste(dataDirectory, "test/y_test.txt", sep="/"), stringsAsFactors=F)
testSubject     <- read.table(paste(dataDirectory, "test/subject_test.txt", sep="/"), stringsAsFactors=F)

trainData       <- read.table(paste(dataDirectory, "train/X_train.txt", sep="/"), stringsAsFactors=F)
trainIDs        <- read.table(paste(dataDirectory, "train/y_train.txt", sep="/"), stringsAsFactors=F)
trainSubject    <- read.table(paste(dataDirectory, "train/subject_train.txt", sep="/"), stringsAsFactors=F)

## Then....
## convert data frames to data tables
print("Converting to data.tables...")
activityLabels  <- data.table(activityLabels)
features        <- data.table(features)
testData        <- data.table(testData)
testIDs         <- data.table(testIDs)
testSubject     <- data.table(testSubject)
trainData       <- data.table(trainData)
trainIDs        <- data.table(trainIDs)
trainSubject    <- data.table(trainSubject)

## Add column names
print("Adding column names...")
names(activityLabels) <- c("activityID", "activityName")
names(features) <- c("featureID","featureName")
names(testData) <- features$featureName
names(testIDs)  <- "activityID"
names(testSubject) <- "subjectID"
names(trainData) <- features$featureName
names(trainIDs)  <- "activityID"
names(trainSubject) <- "subjectID"

## merge train data; add activity names
print("Merging train data...")
trainActivity <- merge(activityLabels, trainIDs, by="activityID", all=T)
trainCombined <- cbind(trainSubject, trainActivity, trainData)

## merge test data; add activity names
print("Merging test data...")
testActivity <- merge(activityLabels, testIDs, by="activityID", all=T)
testCombined <- cbind(testSubject, testActivity, testData)

## merge train and test data
print("Combining train and test data...")
allCombined <- rbind(trainCombined, testCombined, fill=T) 


## subset columns 
print("Subsetting to mean and std deviation columns...")
meansNstds <- allCombined %>%
    select(subjectID, activityID, activityName, contains("mean()"), contains("std()"))

## modify column names
names(meansNstds) <- gsub("^t", "time", names(meansNstds))              ## t at the start of the line = time
names(meansNstds) <- gsub("^f", "frequency", names(meansNstds))         ## f at the start of the line = frequency
names(meansNstds) <- gsub("-mean\\(\\)", "Mean", names(meansNstds))     ## -mean() = Mean
names(meansNstds) <- gsub("-std\\(\\)", "StdDev", names(meansNstds))    ## -std() = StdDev
names(meansNstds) <- gsub("-", "", names(meansNstds))                   ## remove other -
names(meansNstds) <- gsub("BodyBody", "Body", names(meansNstds))        ## if Body repeated = just one Body

write.table(meansNstds, tidyFile)

## column averages -- tidyFileAvg
## which columns will be the ids; which will be measures?
ids <- names(meansNstds)[c(1:3)]
measures <- names(meansNstds)[c(4:ncol(meansNstds))]

## melt to one row per subject/activity/feature measurement
print("Melting data...")
meltedData <- melt(meansNstds, id=ids, measure.vars=measures)

## dcast to get means for each feature measurement 
## will have one row per subject/activity
print("Calculating averages...")
tidyAvgs <- dcast(meltedData, subjectID + activityName ~ variable, mean)

## write the tidy averages file
print("Writing the tidy file...")
write.table(tidyAvgs, tidyAvgsFile, sep=",")

print("run_analysis.R complete...")
date()