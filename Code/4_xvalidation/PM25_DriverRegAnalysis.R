# Created on: 4/9/22 by RM
# Last edited: 5/2/22 by RM

rm(list=ls())

library(data.table)
library(ggplot2)
library(ggpubr)
library(tidyverse)
library(broom)

# write code at which there is a step where you calculate slope
# delta T step of 0.5 years; calc slope at 0.5 yr increment

setwd("/nas/longleaf/home/revathi/chaq/revathi/mortality_results/ACM/")

dat<-read.csv("PM25_ACM_MortDrivers.csv")

dat2<-dat[which(dat$Dataset=="EPA"),]
dat5<-dat[which(dat$Dataset=="SAT"),]
dat3<-dat[which(dat$Dataset=="NACR"),]
dat4<-dat[which(dat$Dataset=="FAQSD"),]

#Regression for each of the 4 datasets - get avg of 2009 and 2010 reg. values

wm9<-127156.1935

dx=0.5

# Calculate slope using available datasets
# Average slopes for each year
x0=1990
slopes9<-c()
for(j in -1:1){
  x=x0+(dx*j)
  mylm<-lm(Excess_Deaths~poly(Year,2,raw=T), dat2)
  m1=mylm$coefficients[2][[1]] + mylm$coefficients[3][[1]]*2*x
  slopes9[[length(slopes9)+1]]<-m1
}

m1=mean(unlist(slopes9))

#forward
myyears<-c()
tot_deaths<-c()
m=m1
y=wm9 
x=1990
tot_deaths[[length(tot_deaths)+1]]<-y
myyears[[length(myyears)+1]]<-x
print(paste(y," deaths in ",x,sep=""))
for(j in 1:56){
  y=m*dx+y # get y at +dx years using old y value
  x=1990+(dx*j) #get next x value
  tot_deaths[[length(tot_deaths)+1]]<-y
  myyears[[length(myyears)+1]]<-x
  print(paste(y," deaths in ",x+dx,sep=""))
  if(x>1990 & x<2000){
    for(s in -1:1){
      mylm<-lm(Excess_Deaths~poly(Year,2,raw=T), dat2)
      m=mylm$coefficients[2][[1]] + mylm$coefficients[3][[1]]*2*x
      slopes9[[length(slopes9)+1]]<-m
    }
  } else if(x>1999.5 & x<2002){
    for(s in -1:1){
      slopes9<-c()
      for(i in c(2,5)){
        dfn<-paste("dat",i,sep="")
        if(get(dfn)$Dataset[1]=="EPA"|get(dfn)$Dataset[1]=="SAT"){
          mylm<-lm(Excess_Deaths~poly(Year,2,raw=T), get(dfn))
          m=mylm$coefficients[2][[1]] + mylm$coefficients[3][[1]]*2*x
          slopes9[[length(slopes9)+1]]<-m
        } else{
          mylm<-lm(Excess_Deaths~poly(Year,1,raw=T), get(dfn))
          m=mylm$coefficients[2][[1]]
          slopes9[[length(slopes9)+1]]<-m
        }
      }
    }
  } else if(x>2001.5 & x<2009){
    for(s in -1:1){
      slopes9<-c()
      for(i in c(2,4,5)){
        dfn<-paste("dat",i,sep="")
        if(get(dfn)$Dataset[1]=="EPA"|get(dfn)$Dataset[1]=="SAT"){
          mylm<-lm(Excess_Deaths~poly(Year,2,raw=T), get(dfn))
          m=mylm$coefficients[2][[1]] + mylm$coefficients[3][[1]]*2*x
          slopes9[[length(slopes9)+1]]<-m
        } else{
          mylm<-lm(Excess_Deaths~poly(Year,1,raw=T), get(dfn))
          m=mylm$coefficients[2][[1]]
          slopes9[[length(slopes9)+1]]<-m
        }
      }
    }
  } else if(x>2008.5 & x<2010.5){
    slopes9<-c()
    for(s in -1:1){
      for(i in 2:5){
        dfn<-paste("dat",i,sep="")
        if(get(dfn)$Dataset[1]=="EPA"|get(dfn)$Dataset[1]=="SAT"){
          mylm<-lm(Excess_Deaths~poly(Year,2,raw=T), get(dfn))
          m=mylm$coefficients[2][[1]] + mylm$coefficients[3][[1]]*2*x
          slopes9[[length(slopes9)+1]]<-m
        } else{
          mylm<-lm(Excess_Deaths~poly(Year,1,raw=T), get(dfn))
          m=mylm$coefficients[2][[1]]
          slopes9[[length(slopes9)+1]]<-m
        }
      }
    }
    m=mean(unlist(slopes9))
  } else if(x>2010 & x<2015.5){
    for(s in -1:1){
      slopes9<-c()
      for(i in 3:5){
        dfn<-paste("dat",i,sep="")
        if(get(dfn)$Dataset[1]=="EPA"|get(dfn)$Dataset[1]=="SAT"){
          mylm<-lm(Excess_Deaths~poly(Year,2,raw=T), get(dfn))
          m=mylm$coefficients[2][[1]] + mylm$coefficients[3][[1]]*2*x
          slopes9[[length(slopes9)+1]]<-m
        } else{
          mylm<-lm(Excess_Deaths~poly(Year,1,raw=T), get(dfn))
          m=mylm$coefficients[2][[1]]
          slopes9[[length(slopes9)+1]]<-m
        }
      }
    }
    m=mean(unlist(slopes9))
  } else if(x>2015 & x<2017.5){
    for(s in -1:1){
      slopes9<-c()
      for(i in 4:5){
        dfn<-paste("dat",i,sep="")
        if(get(dfn)$Dataset[1]=="EPA"|get(dfn)$Dataset[1]=="SAT"){
          mylm<-lm(Excess_Deaths~poly(Year,2,raw=T), get(dfn))
          m=mylm$coefficients[2][[1]] + mylm$coefficients[3][[1]]*2*x
          slopes9[[length(slopes9)+1]]<-m
        } else{
          mylm<-lm(Excess_Deaths~poly(Year,1,raw=T), get(dfn))
          m=mylm$coefficients[2][[1]]
          slopes9[[length(slopes9)+1]]<-m
        }
      }
    }
    m=mean(unlist(slopes9))
  } else if(x>2017){
    for(s in -1:1){
      slopes9<-c()
      mylm<-lm(Excess_Deaths~poly(Year,2,raw=T), dat5)
      m=mylm$coefficients[2][[1]] + mylm$coefficients[3][[1]]*2*x
      slopes9[[length(slopes9)+1]]<-m
    }# slope at next x value, +1dx years
  }
  m=mean(unlist(slopes9))
}

df_death<-unlist(tot_deaths)
df_yr<-unlist(myyears)
out<-do.call(rbind, Map(data.frame, Year=df_yr, Excess.Deaths=df_death))

write.csv(out,'PM25_MortOnly_Regression_Results.csv',na="",row.names=F, quote=FALSE)


##### Figures

ggplot() +
  geom_smooth(aes(x=Year, y=Excess_Deaths), data = dat2, 
              method = "lm", formula = y ~ poly(x,2), se = FALSE, color = "blue") + 
  geom_smooth(aes(x=Year, y=Excess_Deaths), data = dat3, 
              method = "lm", se = FALSE, color = "red") + 
  geom_smooth(aes(x=Year, y=Excess_Deaths), data = dat4, 
              method = "lm", formula = y ~ poly(x,1),se = FALSE, color = "gray") +
  geom_smooth(aes(x=Year, y=Excess_Deaths), data = dat5, 
              method = "lm", formula = y ~ poly(x,2),se = FALSE, color = "orange") +
  geom_smooth(aes(x=Year, y=Excess.Deaths), data = out, 
              se = FALSE, color = "purple") +
  geom_point(aes(x=Year, y=Excess_Deaths), data = dat2, color = "blue") + 
  geom_point(aes(x=Year, y=Excess_Deaths), data = dat3, color = "red")+
  geom_point(aes(x=Year, y=Excess_Deaths), data = dat4, color = "gray")+
  geom_point(aes(x=Year, y=Excess_Deaths), data = dat5, color = "orange")+
  geom_point(aes(x=Year, y=Excess.Deaths), data = out, color = "purple")+
  xlab('Year') +
  ylab('Excess Deaths') +
  xlim(1990,2020)+
  ggtitle('Regression for PM2.5-Related Deaths')+
  theme(panel.background = element_rect(fill="white",colour="white"),
        panel.grid.major = element_line(linetype="blank"),
        panel.grid.minor = element_line(linetype="blank"),
        plot.title = element_text(hjust = 0.5,face="bold"),
        axis.line = element_line(colour = "black"),
        plot.background = element_rect(color = "black", size = 0.5),
        panel.border = element_rect(colour = "black", fill=NA, size=0.5))
