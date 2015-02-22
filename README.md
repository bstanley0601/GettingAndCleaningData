#Getting And Cleaning Data Project
##Data 
The data linked to from the course website represent data collected from the accelerometers from the Samsung Galaxy S smartphone. A full description is available at the site where the data was obtained: 

http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones 

Here are the data for the project: 

https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip 

##Script
###run_analysis.R
This script performs the following steps: 
1. Downloads the dataset listed above to your working directory. 
    a. set get_files="Y" at line 38 if you wish to download the remote dataset
    b. set get_files="N" at line 38 if you wish to use the latest dataset already present 
       in your working directory. 
2. Unzips the dataset to a subfolder named UCI_HAR_Dataset_<yyyymmdd>.
2. Merges the training and the test sets to create one data set.
3. Extracts only the measurements on the mean and standard deviation for each measurement. 
4. Uses descriptive activity names to name the activities in the data set
5. Appropriately labels the data set with descriptive variable names. 
6. From the data set in step 5, creates a second, independent tidy data set with the average of each variable for each activity and each subject.

##Run the script
###source('./run_analysis.R')
