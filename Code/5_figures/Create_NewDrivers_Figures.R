
# Created by: Revathi Muralidharan
# Last updated: 2/27/22

rm(list=ls())

library(plyr)
library(dplyr)
library(ggplot2)
library(data.table)
library(janitor)
library(tidyr)
#/nas/longleaf/home/revathi/HAQAST/thesis/mortality/Drivers/RESP/

dname=c("SAT")
pollname=c("PM25")
healthname=c("ACM")
setwd(paste("/nas02/depts/ese/chaq/revathi/mortality_results/",healthname,"/",dname,"/Drivers",sep=""))
year1=2000
yearlast=2018
dat_name=c(paste("/nas/longleaf/home/revathi/chaq/revathi/mortality_results/",healthname,"/",dname,"_",pollname,"_",year1,"-",yearlast,"_sums.csv",sep=""))
cdat_name=c(paste(dname,"_",pollname,"_",year1,"-",yearlast,"_Conconlysums.csv",sep=""))
ncdat_name=c(paste(dname,"_",pollname,"_",year1,"-",yearlast,"_ConcExcSums.csv",sep=""))
mdat_name=c(paste(dname,"_",pollname,"_",year1,"-",yearlast,"_Mortonlysums.csv",sep=""))
pdat_name=c(paste(dname,"_",pollname,"_",year1,"-",yearlast,"_Poponlysums.csv",sep=""))

dat<-fread(dat_name)
dat<-dat[,c(1:3,6,7)]
dat$Dataset=c("Total")
cdat<-fread(cdat_name)
cdat$Dataset=c("Conc Only")
ncdat<-fread(ncdat_name)
ncdat$Dataset=c("Conc Exc")
mdat<-fread(mdat_name)
mdat$Dataset=c("Mort Only")
pdat<-fread(pdat_name)
pdat$Dataset=c("Pop Only")

driver_data<-rbindlist(list(dat,cdat,ncdat,mdat,pdat))
driver_data[which(driver_data$Dataset=="CMAQ")]$Dataset=c("EPA")

driver_data$Dataset <- factor(driver_data$Dataset, 
                       levels = c("Total","Conc Exc","Conc Only","Mort Only",
                                  "Pop Only"))

driver_colors <- c("Total" = "black", "Conc Only" = "red", "Conc Exc" = "blue", "Mort Only" = "magenta", "Pop Only" = "brown")
driver_data$colour<-c("")
driver_data[which(driver_data$Dataset=="Total"),]$colour<-1
driver_data[which(driver_data$Dataset=="Conc Only"),]$colour<-2
driver_data[which(driver_data$Dataset=="Conc Exc"),]$colour<-3
driver_data[which(driver_data$Dataset=="Mort Only"),]$colour<-4
driver_data[which(driver_data$Dataset=="Pop Only"),]$colour<-5
driver_data$variable<-as.factor(driver_data$colour)

driver_data$linetype<-2
driver_data[which(driver_data$Dataset=="Total"),]$linetype<-1
driver_data$myline<-as.factor(driver_data$linetype)

options(scipen=999)
t<-ggplot(driver_data[which(driver_data$'Age Group'=="Total" & driver_data$Pollutant==pollname),],aes(x=Year,y=`Excess Deaths`,group=Dataset,colour=Dataset,linetype=myline))+
  ggtitle(dname)+
  geom_line()+
  geom_point()+
  guides(linetype=FALSE)+ 
  theme(panel.background = element_rect(fill="white",colour="white"),
        panel.grid.major = element_line(linetype="blank"),
        panel.grid.minor = element_line(linetype="blank"),
        plot.title = element_text(hjust = 0.5,face="bold"),
        axis.line = element_line(colour = "black"),
        plot.background = element_rect(color = "black", size = 0.5),
        panel.border = element_rect(colour = "black", fill=NA, size=0.5))+ 
  ylab("PM2.5 Deaths")+
  scale_color_manual(#name="Dataset",
                     #labels=c("FAQSD","Conc Only", "Conc Exc", "Mort Only", "Pop Only"),
                     values=driver_colors)+
  scale_fill_manual(values=driver_colors)
t

#test<-driver_data[which(driver_data$`Age Group`=="Total"),]
