
#test<-fread('/nas/longleaf/home/revathi/chaq/revathi/mortality_results/RESP/CMAQ/CDC_EPA_grid_mort_results_1990.csv')

rm(list=ls())

library(plyr)
library(dplyr)
library(tidyr)

# Set working directory
setwd('/nas/longleaf/home/revathi/HAQAST/thesis/mortality/CDC_RESP/')

# Get state lookup table
states<-read.csv('/nas/longleaf/home/revathi/HAQAST/thesis/population/stateLookup.csv')
names(states)[3]<-c("State.Abbrev")

for (iyear in 2021:2021){
  mort_file = paste('CDCWonder_RESP_',iyear,'.csv',sep="")
  
  # Read in CDC county-level mortality data
  base_mort=read.csv(mort_file)
  
  #base_mort$State.Abbrev=strsplit(base_mort$County,",")
  base_mort$State.Abbrev=gsub(" ","",base_mort$State)
  #base_mort$County<-gsub(", ",",",base_mort$County)
  
  #for(i in 1:nrow(base_mort)){
  #  base_mort$State.Abbrev[i]<-base_mort$State.Abbrev[[i]][2]
  #}
  base_mort$State.Abbrev<-gsub(" ","",base_mort$State.Abbrev)
  base_mort<-base_mort[which(base_mort$State.Abbrev!="1979-1988)"),]
  
  base_mort$State.Code<-floor(base_mort$County.Code/1000) # GET FIRST TWO DIGIT
  base_mort<-merge(base_mort,states[,c(1,3)],by=c("State.Abbrev"))
  
  base_mort$Year<-iyear
  base_mort$`Year Code`<-iyear
  
  if(iyear<1999){
    base_mort<-base_mort[,c(2,9,8,3,4,10,11,5:7)]
    names(base_mort)[3]<-c("State Code")
    names(base_mort)[5]<-c("County Code")
    names(base_mort)[7]<-c("Year Code")
    names(base_mort)[10]<-c("Crude Rate")
  } else{
    base_mort<-base_mort[,c(2,9,8,3,4,10,11,5:7)]
  }
  
  write.csv(base_mort,paste("CDCWonder_RESP_",iyear,"_NEW.csv",sep=""),na="",row.names=F,quote=FALSE)
}

##### FIX NEGATIVE VALUES AND SUM BY COUNTY IN PROCESSED DATA

rm(list=ls())

library(plyr)
library(dplyr)
library(tidyr)

# Set working directory
setwd('/nas/longleaf/home/revathi/HAQAST/thesis/mortality/CDC_RESP_Processed/')

# Get state lookup table
states<-read.csv('/nas/longleaf/home/revathi/HAQAST/thesis/population/stateLookup.csv')
names(states)[3]<-c("State.Abbrev")

for (iyear in 2021:2021){
  mort_file = paste('Processed_RESP_CDC_',iyear,'.csv',sep="")
  
  # Read in CDC county-level mortality data
  base_mort=read.csv(mort_file)
  
  base_mort$State.Code<-floor(base_mort$County.Code/1000)
  
  pop_mort<-base_mort
  
  pop_mort$Mortality.Rates<-pop_mort$Deaths/pop_mort$Population
  
  pop_mort<-base_mort
  
  write.csv(pop_mort,paste("Processed_RESP_CDC_",iyear,"_NEW.csv",sep=""),na="",row.names=F,quote=FALSE)
}
