# Created on: 4/9/22 by RM
# Last edited: 5/13/22 by RM

rm(list=ls())

library(data.table)
library(ggplot2)
library(ggpubr)
library(tidyverse)
library(broom)

# write code at which there is a step where you calculate slope
# delta T step of 0.5 years; calc slope at 0.5 yr increment

setwd("/nas/longleaf/home/revathi/chaq/revathi/mortality_results/RESP/")

dat<-read.csv("MDA1_O3_RESP_PopDrivers.csv")

dat2<-dat[which(dat$Dataset=="EPA"),]
dat3<-dat[which(dat$Dataset=="NACR"),]

#Regression for each of the 2 datasets - get avg of 2009 and 2010 reg. values

#wm9<-35753.6705946925 #MDA8
wm9<-13205.6606569786

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

myyears<-c()
tot_deaths<-c()
m=m1
y=wm9 
x=1990
tot_deaths[[length(tot_deaths)+1]]<-y
myyears[[length(myyears)+1]]<-x
print(paste(y," deaths in ",x,sep=""))

###MDA1 O3
for(j in 1:60){
  y=m*dx+y # get y at +dx years using old y value
  x=1990+(dx*j) #get next x value
  tot_deaths[[length(tot_deaths)+1]]<-y
  myyears[[length(myyears)+1]]<-x
  print(paste(y," deaths in ",x+dx,sep=""))
  if(x>1990 & x<2002){
    for(s in -1:1){
      mylm<-lm(Excess_Deaths~poly(Year,2,raw=T), dat2)
      m=mylm$coefficients[2][[1]] + mylm$coefficients[3][[1]]*2*x
      slopes9[[length(slopes9)+1]]<-m
    }
  } else if(x>2008.5 & x<2010.5){
    for(s in -1:1){
      slopes9<-c()
      for(i in 2:3){
        dfn<-paste("dat",i,sep="")
        if(get(dfn)$Dataset[1]=="EPA"){
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
  } else if(x>2010){
    for(s in -1:1){
      slopes9<-c()
      mylm<-lm(Excess_Deaths~poly(Year,1,raw=T), dat3)
      m=mylm$coefficients[2][[1]] 
      slopes9[[length(slopes9)+1]]<-m
    }# slope at next x value, +1dx years
  }
  m=mean(unlist(slopes9))
}

###MDA8 O3
for(j in 1:54){
  y=m*dx+y # get y at +dx years using old y value
  x=1990+(dx*j) #get next x value
  tot_deaths[[length(tot_deaths)+1]]<-y
  myyears[[length(myyears)+1]]<-x
  print(paste(y," deaths in ",x+dx,sep=""))
  if(x>1990 & x<2002){
    for(s in -1:1){
      mylm<-lm(Excess_Deaths~poly(Year,2,raw=T), dat2)
      m=mylm$coefficients[2][[1]] + mylm$coefficients[3][[1]]*2*x
      slopes9[[length(slopes9)+1]]<-m
    }
  } else if(x>2001.5 & x<2010.5){
    for(s in -1:1){
      slopes9<-c()
      for(i in 2:3){
        dfn<-paste("dat",i,sep="")
        if(get(dfn)$Dataset[1]=="EPA"){
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
  } else if(x>2010){
    for(s in -1:1){
      slopes9<-c()
      mylm<-lm(Excess_Deaths~poly(Year,1,raw=T), dat3)
      m=mylm$coefficients[2][[1]] 
      slopes9[[length(slopes9)+1]]<-m
    }# slope at next x value, +1dx years
  }
  m=mean(unlist(slopes9))
}

df_death<-unlist(tot_deaths)
df_yr<-unlist(myyears)
out<-do.call(rbind, Map(data.frame, Year=df_yr, Excess.Deaths=df_death))

#write.csv(out,'MDA1_O3_PopOnly_Regression_Results.csv',na="",row.names=F, quote=FALSE)
#out<-read.csv('MDA8_O3_RESP_Regression_Results.csv')
#out2<-read.csv('MDA1_O3_RESP_Regression_Results.csv')

##### Figures

ggplot() +
  geom_smooth(aes(x=Year, y=Excess_Deaths), data = dat2, 
              method = "lm", formula = y ~ poly(x,2), se = FALSE, color = "blue") + 
  geom_smooth(aes(x=Year, y=Excess_Deaths), data = dat3, 
              method = "lm", se = FALSE, color = "red") + 
  geom_smooth(aes(x=Year, y=Excess.Deaths), data = out, 
              se = FALSE, color = "purple") +
  geom_point(aes(x=Year, y=Excess_Deaths), data = dat2, color = "blue") + 
  geom_point(aes(x=Year, y=Excess_Deaths), data = dat3, color = "red")+
  geom_point(aes(x=Year, y=Excess.Deaths), data = out, color = "purple")+
  xlab('Year') +
  ylab('Excess Deaths') +
  xlim(1990,2020)+
  ggtitle('Regression for O3-Related Deaths')+
  theme(panel.background = element_rect(fill="white",colour="white"),
        panel.grid.major = element_line(linetype="blank"),
        panel.grid.minor = element_line(linetype="blank"),
        plot.title = element_text(hjust = 0.5,face="bold"),
        axis.line = element_line(colour = "black"),
        plot.background = element_rect(color = "black", size = 0.5),
        panel.border = element_rect(colour = "black", fill=NA, size=0.5))
