
# Created by: Revathi Muralidharan
# Last updated: 3/2/22

rm(list=ls())

library(plyr)
library(dplyr)
library(tidyr)

# Set working directory
setwd('/nas/longleaf/home/revathi/HAQAST/thesis')

# Get state lookup table
states<-read.csv('population/stateLookup.csv')

####################################################################################################

for (iyear in 1990:1998){
  
  #### County-level mortality data location
  mort_fold = 'mortality/CDC_RESP'
  #### County-level mortality data file
  mort_path = paste('CDCWonder_RESP_',iyear,'.csv',sep="")
  #### Set name of base mortality file
  base_mort_file = paste(mort_fold,'/',mort_path,sep="")
  
  # Read in CDC county-level mortality data
  base_mort=read.csv(base_mort_file)
  # Remove last two rows with totals
  base_mort = base_mort[c(1:22030),]
  base_mort$County.Code<-as.numeric(base_mort$County.Code)
  base_mort$State.Abbrev=strsplit(base_mort$County,",")
  for(i in 1:nrow(base_mort)){
    base_mort$County[i]<-base_mort$State.Abbrev[[i]][1]
    base_mort$State.Abbrev[i]<-base_mort$State.Abbrev[[i]][2]
  }
  base_mort$State.Abbrev<-gsub(" ","",base_mort$State.Abbrev)
  
  #suppressed
  state_mort<-read.csv(paste("mortality/CDC_RESP/statemort/StateMort_",iyear,".csv",sep=""))
  state_mort<-state_mort[c(1:365),]
  base_mort2<-base_mort
  sumdat<-base_mort2[which(base_mort2$Deaths=="Suppressed"|base_mort2$Deaths=="Missing"),]
  sumdat$Population<-as.numeric(sumdat$Population)
  sumdat2<-sumdat%>%group_by(State.Abbrev)%>%summarise_at(vars(Population),sum,na.rm=T)
  names(sumdat2)[2]<-c("SuppPop")
  for(i in 1:nrow(base_mort2)){
    if(base_mort2$Deaths[i]=="Suppressed"|base_mort2$Deaths[i]=="Missing"){
      base_mort2$Deaths[i]<-NA
    }
  }
  
  base_mort2<-base_mort2[which(is.na(base_mort2$State.Abbrev)==F),]
  base_mort2$Deaths<-as.numeric(base_mort2$Deaths)
  base_mort3<-base_mort2%>%group_by(State.Abbrev)%>%
    summarise_at(vars(Deaths),sum,na.rm=T)
  names(states)[3]<-c("State.Abbrev")
  state_mort<-merge(state_mort,states,by=c("State"))
  state_mort2<-state_mort
  for(i in 1:nrow(state_mort2)){
    if(state_mort2$Deaths[i]=="Suppressed"|state_mort2$Deaths[i]=="Missing"){
      state_mort2$Deaths[i]<-NA
    }
  }
  state_mort2<-state_mort2[which(state_mort2$State.Abbrev!="AK"),]
  state_mort2<-state_mort2[which(state_mort2$State.Abbrev!="HI"),]
  state_mort2$Deaths<-as.numeric(state_mort2$Deaths)
  state_mort2$Population<-as.numeric(state_mort2$Population)
  state_mort2<-state_mort2%>%group_by(State.Abbrev)%>%
    summarise_at(vars(Deaths,Population),sum,na.rm=T)
  names(base_mort3)[2]<-c("KnownDeaths")
  state_mort2<-merge(state_mort2,base_mort3,by=c("State.Abbrev"))
  state_mort2$SuppDeaths<-state_mort2$Deaths-state_mort2$KnownDeaths
  state_mort2<-merge(state_mort2,sumdat2,by=c("State.Abbrev"))
  state_mort2$SuppMort<-state_mort2$SuppDeaths/state_mort2$SuppPop
  
  base_mort<-base_mort[which(base_mort$State.Abbrev!="AK"),]
  base_mort<-base_mort[which(base_mort$State.Abbrev!="HI"),]
  base_mort<-base_mort[which(base_mort$State.Abbrev!="1979-1988)"),]
  
  #base_mort<-merge(base_mort,state_mort[,c(1,11)],by=c("State.Abbrev"))
  for(i in 1:nrow(base_mort)){
    if(base_mort$Deaths[i]=="Suppressed"|base_mort$Deaths[i]=="Missing"){
      base_mort$Mrate[i]<-state_mort2[which(state_mort2$State.Abbrev==base_mort$State.Abbrev[i]),]$SuppMort
    } else{
      base_mort$Mrate[i]<-as.numeric(base_mort$Deaths[i])/as.numeric(base_mort$Population[i])
    }
  }
  
  # Long to wide
  dat<-base_mort[,c(2,4,5,9,10)]
  pop_mort<-spread(dat,key=Age.Group,value=Mrate)
  names(pop_mort)[4:10]<-c("Mortality Rates_25-34","Mortality Rates_35-44",
                           "Mortality Rates_45-54","Mortality Rates_55-64",
                           "Mortality Rates_65-74","Mortality Rates_75-84",
                           "Mortality Rates_85+")
  dat<-base_mort[,c(2,4,5,9,7)]
  pop_mort2<-spread(dat,key=Age.Group,value=Population)
  names(pop_mort2)[4:10]<-c("Pops_25-34","Pops_35-44","Pops_45-54","Pops_55-64",
                           "Pops_65-74","Pops_75-84","Pops_85+")
  pop_mort3<-merge(pop_mort,pop_mort2,by=c("County","County.Code","State.Abbrev"))
  pop_mort3<-merge(pop_mort3,states[,c(1,3)],by=c("State.Abbrev"))
  # Divide state code by 1000 
  pop_mort3$State.Code<-round(pop_mort$County.Code/1000,0) # GET FIRST TWO DIGITS
  pop_mort3<-pop_mort3[,c(18,19,3,11,4,12,5,13,6,14,7,15,8,16,9,17,10)]
  
  names(pop_mort3)<-c("State","State Code","County Code","Pops_25-34","Mortality Rates_25-34",
                      "Pops_35-44","Mortality Rates_35-44","Pops_45-54","Mortality Rates_45-54",
                      "Pops_55-64","Mortality Rates_55-64","Pops_65-74","Mortality Rates_65-74",
                      "Pops_75-84","Mortality Rates_75-84","Pops_85+","Mortality Rates_85+")
  assign(paste("pop_mort_",iyear,sep=""),pop_mort3)
  write.csv(pop_mort3,paste('mortality/CDC_RESP_Processed/Processed_RESP_CDC_',iyear,"_NEW.csv",sep=""),row.names=F,na="")
}
  

for (iyear in 1999:2020){
  
  #### County-level mortality data location
  mort_fold = 'mortality/CDC_RESP'
  #### County-level mortality data file
  mort_path = paste('CDCWonder_RESP_',iyear,'.csv',sep="")
  #### Set name of base mortality file
  base_mort_file = paste(mort_fold,'/',mort_path,sep="")
  
  # Read in CDC county-level mortality data
  base_mort=read.csv(base_mort_file)
  # Remove last two rows with totals
  base_mort = base_mort[c(1:22030),]
  base_mort$County.Code<-as.numeric(base_mort$County.Code)
  base_mort$State.Abbrev=strsplit(base_mort$County,",")
  for(i in 1:nrow(base_mort)){
    base_mort$County[i]<-base_mort$State.Abbrev[[i]][1]
    base_mort$State.Abbrev[i]<-base_mort$State.Abbrev[[i]][2]
  }
  base_mort$State.Abbrev<-gsub(" ","",base_mort$State.Abbrev)
  
  #suppressed
  state_mort<-read.csv(paste("mortality/CDC_RESP/statemort/StateMort_",iyear,".csv",sep=""))
  state_mort<-state_mort[c(1:365),]
  base_mort2<-base_mort
  sumdat<-base_mort2[which(base_mort2$Deaths=="Suppressed"|base_mort2$Deaths=="Missing"),]
  sumdat$Population<-as.numeric(sumdat$Population)
  sumdat2<-sumdat%>%group_by(State.Abbrev)%>%summarise_at(vars(Population),sum,na.rm=T)
  names(sumdat2)[2]<-c("SuppPop")
  for(i in 1:nrow(base_mort2)){
    if(base_mort2$Deaths[i]=="Suppressed"|base_mort2$Deaths[i]=="Missing"){
      base_mort2$Deaths[i]<-NA
    }
  }
  
  base_mort2<-base_mort2[which(is.na(base_mort2$State.Abbrev)==F),]
  base_mort2$Deaths<-as.numeric(base_mort2$Deaths)
  base_mort3<-base_mort2%>%group_by(State.Abbrev)%>%
    summarise_at(vars(Deaths),sum,na.rm=T)
  names(states)[3]<-c("State.Abbrev")
  state_mort<-merge(state_mort,states,by=c("State"))
  state_mort2<-state_mort
  for(i in 1:nrow(state_mort2)){
    if(state_mort2$Deaths[i]=="Suppressed"|state_mort2$Deaths[i]=="Missing"){
      state_mort2$Deaths[i]<-NA
    }
  }
  state_mort2<-state_mort2[which(state_mort2$State.Abbrev!="AK"),]
  state_mort2<-state_mort2[which(state_mort2$State.Abbrev!="HI"),]
  state_mort2$Deaths<-as.numeric(state_mort2$Deaths)
  state_mort2$Population<-as.numeric(state_mort2$Population)
  state_mort2<-state_mort2%>%group_by(State.Abbrev)%>%
    summarise_at(vars(Deaths,Population),sum,na.rm=T)
  names(base_mort3)[2]<-c("KnownDeaths")
  state_mort2<-merge(state_mort2,base_mort3,by=c("State.Abbrev"))
  state_mort2$SuppDeaths<-state_mort2$Deaths-state_mort2$KnownDeaths
  state_mort2<-merge(state_mort2,sumdat2,by=c("State.Abbrev"))
  state_mort2$SuppMort<-state_mort2$SuppDeaths/state_mort2$SuppPop
  
  base_mort<-base_mort[which(base_mort$State.Abbrev!="AK"),]
  base_mort<-base_mort[which(base_mort$State.Abbrev!="HI"),]
  base_mort<-base_mort[which(base_mort$State.Abbrev!="1979-1988)"),]
  
  #base_mort<-merge(base_mort,state_mort[,c(1,11)],by=c("State.Abbrev"))
  for(i in 1:nrow(base_mort)){
    if(base_mort$Deaths[i]=="Suppressed"|base_mort$Deaths[i]=="Missing"){
      base_mort$Mrate[i]<-state_mort2[which(state_mort2$State.Abbrev==base_mort$State.Abbrev[i]),]$SuppMort
    } else{
      base_mort$Mrate[i]<-as.numeric(base_mort$Deaths[i])/as.numeric(base_mort$Population[i])
    }
  }
  
  # Long to wide
  dat<-base_mort[,c(2,3,4,9,10)]
  pop_mort<-spread(dat,key=Ten.Year.Age.Groups,value=Mrate)
  names(pop_mort)[4:10]<-c("Mortality Rates_25-34","Mortality Rates_35-44",
                           "Mortality Rates_45-54","Mortality Rates_55-64",
                           "Mortality Rates_65-74","Mortality Rates_75-84",
                           "Mortality Rates_85+")
  dat<-base_mort[,c(2,3,4,9,7)]
  pop_mort2<-spread(dat,key=Ten.Year.Age.Groups,value=Population)
  names(pop_mort2)[4:10]<-c("Pops_25-34","Pops_35-44","Pops_45-54","Pops_55-64",
                            "Pops_65-74","Pops_75-84","Pops_85+")
  pop_mort3<-merge(pop_mort,pop_mort2,by=c("County","County.Code","State.Abbrev"))
  pop_mort3<-merge(pop_mort3,states[,c(1,3)],by=c("State.Abbrev"))
  # Divide state code by 1000 
  pop_mort3$State.Code<-round(pop_mort$County.Code/1000,0) # GET FIRST TWO DIGITS
  pop_mort3<-pop_mort3[,c(18,19,3,11,4,12,5,13,6,14,7,15,8,16,9,17,10)]
  
  names(pop_mort3)<-c("State","State Code","County Code","Pops_25-34","Mortality Rates_25-34",
                      "Pops_35-44","Mortality Rates_35-44","Pops_45-54","Mortality Rates_45-54",
                      "Pops_55-64","Mortality Rates_55-64","Pops_65-74","Mortality Rates_65-74",
                      "Pops_75-84","Mortality Rates_75-84","Pops_85+","Mortality Rates_85+")
  assign(paste("pop_mort_",iyear,sep=""),pop_mort3)
  write.csv(pop_mort3,paste('mortality/CDC_RESP_Processed/Processed_RESP_CDC_',iyear,"_NEW.csv",sep=""),row.names=F,na="")
}

