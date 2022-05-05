# Created on: 3/9/22 by RM
# Last edited: 4/7/22 by RM

rm(list=ls())

library(data.table)
library(ggplot2)
library(ggpubr)
library(tidyverse)
library(broom)

setwd("/nas/longleaf/home/revathi/chaq/revathi/mortality_results/ACM/")

dat<-read.csv("PM25_RateChangeCalc.csv")

dat<-read.csv("O3_RateChangeCalc.csv")

# weight based on # of years
# for given curve multiply value by weight

dat2<-dat[which(dat$Dataset=="EPA"),]
dat5<-dat[which(dat$Dataset=="SAT"),]

dat5<-dat[which(dat$Dataset=="EPA - MDA8"),]
dat2<-dat[which(dat$Dataset=="EPA - MDA1"),]

dat3<-dat[which(dat$Dataset=="NACR"),]
dat4<-dat[which(dat$Dataset=="FAQSD"),]

plot(dat2$Year,dat2$Excess.Deaths,type='l',col='red',main='Linear relationship')
mylm<-lm(Excess.Deaths~poly(Year,2,raw=T), data=dat5)
summary(mylm)

plot(dat2$Year,dat2$Excess.Deaths,
     main='Linear Regression for EPA PM2.5',
     xlab='Year',ylab='Excess Deaths')
lines(dat2$Year,dat2$Excess.Deaths,col='green',lwd=3)
lm(Excess.Deaths~poly(Year,2), data=dat2)

pollname=c("O3")
year1=1990
yearlast=2010

for(i in year1:yearlast){
  fname<-c(paste("RESP/EPA/Drivers/CDC_EPA_grid_mort_drivers_",i,".csv",sep=""))
  d1<-read.csv(fname)
  names(d1)<-c('Lon', 'Lat', 'BLDeaths', 'Pop', 'Mrate', pollname, 
                         paste('d',pollname,sep=""), 'AF',
                         'AF_low', 'AF_up', 'deaths', 'deaths_RRlow', 'deaths_RRup',
                         'BLDeaths_1990', 'Pop_1990', 'Mrate_1990', 
                         paste(pollname,'_1990',sep=""), paste('d',pollname,'_1990',sep=""),
                         'AF_1990', 'AF_low_1990', 'AF_up_1990', 'deaths_1990',
                         'deaths_RRlow_1990', 'deaths_RRup_1990', 'deaths_P', 'deaths_M',
                         'deaths_noC', 'deaths_C')
  assign(paste("dat",i,sep=""),d1)
}
rm(d1)
dat<-rbindlist(mget(ls()[grep("dat",ls())]),fill=TRUE)

#fit regression model
d2<-dat
d2$y<-d2$O3*d2$deaths
plot(d2$O3,d2$deaths,type='l',col='red',main='Linear relationship')
summary(lm(deaths~O3, data=d2))
