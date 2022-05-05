
# Created by: Revathi Muralidharan
# Last updated: 3/7/22

rm(list=ls())

library(plyr)
library(dplyr)
library(tidyr)

# Set working directory
setwd('/nas/longleaf/home/revathi/HAQAST/thesis')

# Get state lookup table
states<-read.csv('population/stateLookup.csv')
names(states)[3]<-c("State.Abbrev")

####################################################################################################

for (iyear in 1990:1998){
  
  #### County-level mortality data location
  mort_fold = 'mortality/CDC_ACM'
  #### County-level mortality data file
  mort_path = paste('CDCWonder_ACM_',iyear,'.csv',sep="")
  #### Set name of base mortality file
  base_mort_file = paste(mort_fold,'/',mort_path,sep="")
  
  # Read in CDC county-level mortality data
  base_mort=read.csv(base_mort_file)
  # Remove last two rows with totals
  base_mort = base_mort[c(1:22029),]
  base_mort$County.Code<-as.numeric(base_mort$County.Code)
  base_mort$State.Abbrev=strsplit(base_mort$County,",")
  for(i in 1:nrow(base_mort)){
    base_mort$State.Abbrev[i]<-base_mort$State.Abbrev[[i]][2]
  }
  base_mort$State.Abbrev<-gsub(" ","",base_mort$State.Abbrev)
  
  base_mort<-base_mort[which(base_mort$State.Abbrev!="1979-1988)"),]
  
  # Divide state code by 1000 
  base_mort$State.Code<-round(base_mort$County.Code/1000,0) # GET FIRST TWO DIGITS
  
  base_mort$Year<-iyear
  base_mort$Year.Code<-iyear
  
  base_mort<-merge(base_mort,states[,c(1,3)],by=c("State.Abbrev"))
  
  base_mort<-base_mort[,c("Notes","State","State.Code","County","County.Code",
                          "Year","Year.Code","Age.Group","Age.Group.Code",
                          "Deaths","Population","Crude.Rate")]
  
  names(base_mort)<-c("Notes","State","State Code","County","County Code",
                      "Year","Year Code","Age Group","Age Group Code",
                      "Deaths","Population","Crude Rate")
  
  base_mort2<-base_mort[order(base_mort$`County Code`,base_mort$`Age Group Code`),]
  
  write.csv(base_mort2,paste('mortality/CDC_ACM/CDCWonder_ACM_',iyear,"_NEW.csv",sep=""),row.names=F,na="",quote=FALSE)
}


for (iyear in 1999:2020){
  
  #### County-level mortality data location
  mort_fold = 'mortality/CDC_ACM'
  #### County-level mortality data file
  mort_path = paste('CDCWonder_ACM_',iyear,'.csv',sep="")
  #### Set name of base mortality file
  base_mort_file = paste(mort_fold,'/',mort_path,sep="")
  
  # Read in CDC county-level mortality data
  base_mort=read.csv(base_mort_file)
  # Remove last two rows with totals
  base_mort = base_mort[c(1:22036),]
  base_mort$County.Code<-as.numeric(base_mort$County.Code)
  base_mort$State.Abbrev=strsplit(base_mort$County,",")
  for(i in 1:nrow(base_mort)){
    base_mort$State.Abbrev[i]<-base_mort$State.Abbrev[[i]][2]
  }
  base_mort$State.Abbrev<-gsub(" ","",base_mort$State.Abbrev)
  
  base_mort<-base_mort[which(base_mort$State.Abbrev!="1979-1988)"),]
  
  # Divide state code by 1000 
  base_mort$State.Code<-round(base_mort$County.Code/1000,0) # GET FIRST TWO DIGITS
  
  base_mort$Year<-iyear
  base_mort$Year.Code<-iyear
  
  base_mort<-merge(base_mort,states[,c(1,3)],by=c("State.Abbrev"))
  
  base_mort<-base_mort[,c("Notes","State","State.Code","County","County.Code",
                          "Year","Year.Code","Age.Group","Age.Group.Code",
                          "Deaths","Population","Crude.Rate")]
  
  names(base_mort)<-c("Notes","State","State Code","County","County Code",
                      "Year","Year Code","Age Group","Age Group Code",
                      "Deaths","Population","Crude Rate")
  
  base_mort2<-base_mort[order(base_mort$`County Code`,base_mort$`Age Group Code`),]
  
  write.csv(base_mort2,paste('mortality/CDC_ACM/CDCWonder_ACM_',iyear,"_NEW.csv",sep=""),row.names=F,na="",quote=FALSE)
}


for(i in 1990:2020){
  dat<-read.csv(paste('mortality/CDC_ACM_Processed/Processed_ACM_CDC_',i,'_NEW.csv',sep=""))
  dat<-dat[,c(1:17)]
  names(dat)<-c('State', 'State Code', 'County Code', 'Pops_25-34', 
                'Mortality Rates_25-34', 'Pops_35-44', 'Mortality Rates_45-44',
                'Pops_45-54', 'Mortality Rates_45-54','Pops_55-64', 
                'Mortality Rates_55-64','Pops_65-74', 'Mortality Rates_65-74',
                'Pops_75-84', 'Mortality Rates_75-84', 'Pops_85+', 
                'Mortality Rates_85+')
  write.csv(dat,paste('mortality/CDC_ACM_Processed/Processed_ACM_CDC_',i,'_NEW2.csv',sep=""),quote=FALSE,na="",row.names=F)
}

