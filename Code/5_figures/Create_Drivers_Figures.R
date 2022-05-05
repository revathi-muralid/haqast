
# Created by: Revathi Muralidharan
# Last updated: 2/3/22

rm(list=ls())

library(plyr)
library(dplyr)
library(ggplot2)
library(data.table)
library(janitor)
library(tidyr)
#/nas/longleaf/home/revathi/HAQAST/thesis/mortality/Drivers/RESP/

dname=c("NACR")
pollname=c("O3")
healthname=c("RESP")
setwd(paste("/nas02/depts/ese/chaq/revathi/mortality_results/",healthname,"/",dname,"/Drivers",sep=""))
year1=2009
yearlast=2016
dat_name=c(paste("/nas/longleaf/home/revathi/chaq/revathi/mortality_results/",healthname,"/",dname,"_",pollname,"_",year1,"-",yearlast,"_sums.csv",sep=""))
cdat_name=c(paste(dname,"_",pollname,"_",year1,"-",yearlast,"_Conconlysums.csv",sep=""))
pdat_name=c(paste(dname,"_",pollname,"_",year1,"-",yearlast,"_ConcExcSums.csv",sep=""))

dat<-fread(dat_name)
dat<-dat[,c(1:3,6,7)]
cdat<-fread(cdat_name)
cdat$Dataset=c("Conc Only")
pdat<-fread(pdat_name)
pdat$Dataset=c("Conc Exc")

driver_data<-rbindlist(list(dat,cdat,pdat))
#driver_data[which(driver_data$Dataset=="CMAQ")]$Dataset=c("EPA")

driver_colors <- c("NACR" = "black", "Conc Only" = "red", "Conc Exc" = "blue")
driver_data$colour<-c("")
driver_data[which(driver_data$Dataset==dname),]$colour<-1
driver_data[which(driver_data$Dataset=="Conc Only"),]$colour<-2
driver_data[which(driver_data$Dataset=="Conc Exc"),]$colour<-3
driver_data$variable<-as.factor(driver_data$colour)

t<-ggplot(driver_data[which(driver_data$'Age Group'=="Total" & driver_data$Pollutant==pollname),],aes(x=Year,y=`Excess Deaths`,group=Dataset,colour=Dataset))+
  #ggtitle(paste("Drivers of ",pollname,"-Associated Mortality from 2009-2015 (NACR)",sep=""))+
  geom_line()+
  geom_point()+
  guides()+ 
  theme(panel.background = element_rect(fill="white",colour="white"),
        panel.grid.major = element_line(linetype="blank"),
        panel.grid.minor = element_line(linetype="blank"))+ 
  ylim(0,10000)+
  scale_color_manual(values = driver_colors)+
  scale_fill_manual(values=driver_colors)
t
