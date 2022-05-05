
# Created by: Revathi Muralidharan
# Last updated: 1/14/22

rm(list=ls())

library(plyr)
library(dplyr)
library(ggplot2)
library(data.table)
library(janitor)
library(tidyr)

setwd("/nas/longleaf/home/revathi/HAQAST/thesis/BME_Final_withGrid/raw/")

for(i in 1990:2019){
  d0<-unzip(paste("daily_44201_",i,".zip",sep=""))
  d1<-fread(d0)
  d2<-d1
  # Get dates from April to Sept
  d2$month<-month(d2$`Date Local`)
  d2<-d2[which(d2$month>3 & d2$month<10),]
  # Group by location and year to get annual avg
  
  d3<-d2 %>%                                            # the pipe operator to have dplyr chains                                      
    group_by(Latitude,Longitude,`Date Local`) %>%
    summarise_at(vars(`Arithmetic Mean`),mean)
  d3$ozone_ppb<-d3$`Arithmetic Mean`*1000
  d3$Year<-i
  assign(paste("data",i,sep=""),d3)
}

data<-rbindlist(mget(ls()[grep("data",ls())]))
#data[data==9.97e36]<-NA
data<-data %>% mutate_if(is.character,as.numeric)

out<-data%>%
  mutate(ID=group_indices_(data,.dots=c("Latitude","Longitude")))

fwrite(data,"/nas/longleaf/home/revathi/HAQAST/thesis/BME_Final_withGrid/preprocessed/BMEAnalyticAQSHardData.csv")
