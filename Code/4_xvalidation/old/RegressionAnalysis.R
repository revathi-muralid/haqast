# Created on: 4/7/22 by RM
# Last edited: 4/8/22 by RM

rm(list=ls())

library(data.table)
library(ggplot2)
library(ggpubr)
library(tidyverse)
library(broom)

# write code at which there is a step where you calculate slope
# delta T step of 0.5 years; calc slope at 0.5 yr increment

setwd("/nas/longleaf/home/revathi/chaq/revathi/mortality_results/ACM/")

dat<-read.csv("PM25_RateChangeCalc.csv")

# weight based on # of years
# for given curve multiply value by weight

dat2<-dat[which(dat$Dataset=="EPA"),]
dat5<-dat[which(dat$Dataset=="SAT"),]

dat5<-dat[which(dat$Dataset=="EPA - MDA8"),]
dat2<-dat[which(dat$Dataset=="EPA - MDA1"),]

dat3<-dat[which(dat$Dataset=="NACR"),]
dat4<-dat[which(dat$Dataset=="FAQSD"),]

dat9<-dat[which(dat$Year==2009),]
dat9$nyear<-c(21,21,16,8)
dat9$nyear<-c(21,16,7,19)
sd(dat9$Excess.Deaths)/mean(dat9$Excess.Deaths)

wm9<-weighted.mean(dat9$Excess.Deaths,dat9$nyear/sum(dat9$nyear))
wm9<-mean(dat9$Excess.Deaths)

dat10<-dat[which(dat$Year==2010),]
dat10$nyear<-c(21,21,16,8)
dat10$nyear<-c(21,16,7,19)

wm10<-weighted.mean(dat10$Excess.Deaths,dat10$nyear/sum(dat10$nyear))
wm10<-mean(dat10$Excess.Deaths)

dx=0.5

# Calculate weighted slope using available datasets
# Apply weighted slope for each year
x=2009
slopes9<-c()
for(i in 2:5){
  dfn<-paste("dat",i,sep="")
  if(get(dfn)$Dataset[1]=="EPA"|get(dfn)$Dataset[1]=="SAT"){
    mylm<-lm(Excess.Deaths~poly(Year,2,raw=T), get(dfn))
    m1=mylm$coefficients[2][[1]] + mylm$coefficients[3][[1]]*2*x
    slopes9[[length(slopes9)+1]]<-m1
  } else{
    mylm<-lm(Excess.Deaths~poly(Year,1,raw=T), get(dfn))
    m1=mylm$coefficients[2][[1]]
    slopes9[[length(slopes9)+1]]<-m1
  }
}

###OZONE
for(i in c(2,5,4,3)){
  dfn<-paste("dat",i,sep="")
  if(get(dfn)$Dataset[1]=="EPA - MDA1"|get(dfn)$Dataset[1]=="EPA - MDA8"){
    mylm<-lm(Excess.Deaths~poly(Year,2,raw=T), get(dfn))
    m1=mylm$coefficients[2][[1]] + mylm$coefficients[3][[1]]*2*x
    slopes9[[length(slopes9)+1]]<-m1
  } else{
    mylm<-lm(Excess.Deaths~poly(Year,1,raw=T), get(dfn))
    m1=mylm$coefficients[2][[1]]
    slopes9[[length(slopes9)+1]]<-m1
  }
}

m1=weighted.mean(unlist(slopes9),dat9$nyear/sum(dat9$nyear))

#forward
myyears<-c()
tot_deaths<-c()
m=m1
y=wm9 
x=2009
tot_deaths[[length(tot_deaths)+1]]<-y
myyears[[length(myyears)+1]]<-x
print(paste(y," deaths in ",x,sep=""))
for(j in 1:22){
  y=m*dx+y # get y at +dx years using old y value
  x=2009+(dx*j) #get next x value
  tot_deaths[[length(tot_deaths)+1]]<-y
  myyears[[length(myyears)+1]]<-x
  print(paste(y," deaths in ",x+dx,sep=""))
  if(x>2009 & x<2010.5){
    slopes9<-c()
    for(i in 2:5){
      dfn<-paste("dat",i,sep="")
      if(get(dfn)$Dataset[1]=="EPA"|get(dfn)$Dataset[1]=="SAT"){
        mylm<-lm(Excess.Deaths~poly(Year,2,raw=T), get(dfn))
        m=mylm$coefficients[2][[1]] + mylm$coefficients[3][[1]]*2*x
        slopes9[[length(slopes9)+1]]<-m
      } else{
        mylm<-lm(Excess.Deaths~poly(Year,1,raw=T), get(dfn))
        m=mylm$coefficients[2][[1]]
        slopes9[[length(slopes9)+1]]<-m
      }
    }
    weighted.mean(unlist(slopes9),dat9$nyear/sum(dat9$nyear))
    } else if(x>2010.5 & x<2015.5){
      slopes9<-c()
      for(i in 3:5){
        dfn<-paste("dat",i,sep="")
        if(get(dfn)$Dataset[1]=="EPA"|get(dfn)$Dataset[1]=="SAT"){
          mylm<-lm(Excess.Deaths~poly(Year,2,raw=T), get(dfn))
          m=mylm$coefficients[2][[1]] + mylm$coefficients[3][[1]]*2*x
          slopes9[[length(slopes9)+1]]<-m
        } else{
          mylm<-lm(Excess.Deaths~poly(Year,1,raw=T), get(dfn))
          m=mylm$coefficients[2][[1]]
          slopes9[[length(slopes9)+1]]<-m
        }
      }
      m=weighted.mean(unlist(slopes9),(dat9$nyear/sum(dat9$nyear))[2:4])
    } else if(x>2015.5 & x<2017.5){
      slopes9<-c()
      for(i in 4:5){
        dfn<-paste("dat",i,sep="")
        if(get(dfn)$Dataset[1]=="EPA"|get(dfn)$Dataset[1]=="SAT"){
          mylm<-lm(Excess.Deaths~poly(Year,2,raw=T), get(dfn))
          m=mylm$coefficients[2][[1]] + mylm$coefficients[3][[1]]*2*x
          slopes9[[length(slopes9)+1]]<-m
        } else{
          mylm<-lm(Excess.Deaths~poly(Year,1,raw=T), get(dfn))
          m=mylm$coefficients[2][[1]]
          slopes9[[length(slopes9)+1]]<-m
        }
      }
      m=weighted.mean(unlist(slopes9),(dat9$nyear/sum(dat9$nyear))[3:4])
    } else if(x>2017.5){
      mylm<-lm(Excess.Deaths~poly(Year,2,raw=T), dat5)
      m=mylm$coefficients[2][[1]] + mylm$coefficients[3][[1]]*2*x
    }# slope at next x value, +1dx years
}
#backwards
m=m1
y=wm9 
x=2009
print(paste(y," deaths in ",x,sep=""))
for(k in 1:38){
  y=m*-dx+y # get y at +dx years using old y value
  x=2009+(-dx*k) #get next x value
  tot_deaths[[length(tot_deaths)+1]]<-y
  myyears[[length(myyears)+1]]<-x
  print(paste(y," deaths in ",x+dx,sep=""))
  if(x>2001.5){
    slopes9<-c()
    for(i in c(2,4,5)){
      dfn<-paste("dat",i,sep="")
      if(get(dfn)$Dataset[1]=="EPA"|get(dfn)$Dataset[1]=="SAT"){
        mylm<-lm(Excess.Deaths~poly(Year,2,raw=T), get(dfn))
        m=mylm$coefficients[2][[1]] + mylm$coefficients[3][[1]]*2*x
        slopes9[[length(slopes9)+1]]<-m
      } else{
        mylm<-lm(Excess.Deaths~poly(Year,1,raw=T), get(dfn))
        m=mylm$coefficients[2][[1]]
        slopes9[[length(slopes9)+1]]<-m
      }
    }
    m=weighted.mean(unlist(slopes9),c(0.3333333,0.2539683,0.3015873))
  } else if(x>1999.5 & x<2002){
    slopes9<-c()
    for(i in c(2,5)){
      dfn<-paste("dat",i,sep="")
      if(get(dfn)$Dataset[1]=="EPA"|get(dfn)$Dataset[1]=="SAT"){
        mylm<-lm(Excess.Deaths~poly(Year,2,raw=T), get(dfn))
        m=mylm$coefficients[2][[1]] + mylm$coefficients[3][[1]]*2*x
        slopes9[[length(slopes9)+1]]<-m
      } else{
        mylm<-lm(Excess.Deaths~poly(Year,1,raw=T), get(dfn))
        m=mylm$coefficients[2][[1]]
        slopes9[[length(slopes9)+1]]<-m
      }
    }
    m=weighted.mean(unlist(slopes9),c(0.3333333,0.3015873))
  } else if(x<2000){
    mylm<-lm(Excess.Deaths~poly(Year,2,raw=T), dat2)
    m=mylm$coefficients[2][[1]] + mylm$coefficients[3][[1]]*2*x
  }# slope at next x value, +1dx years
}

df_death<-unlist(tot_deaths)
df_yr<-unlist(myyears)
out<-do.call(rbind, Map(data.frame, Year=df_yr, Excess.Deaths=df_death))

mylm<-lm(Excess.Deaths~poly(Year,2,raw=T), data=dat5)
summary(mylm)
paste(mylm$coefficients[1]," + ",mylm$coefficients[2],"*x + ",mylm$coefficients[3],"*x^2",sep="")
x=2009
mylm$coefficients[2] + mylm$coefficients[3]*2*x

##### Figures


ggplot() +
  geom_smooth(aes(x=Year, y=Excess.Deaths), data = dat2, 
              method = "lm", formula = y ~ poly(x,2), se = FALSE, color = "blue") + 
  geom_smooth(aes(x=Year, y=Excess.Deaths), data = dat3, 
              method = "lm", se = FALSE, color = "red") + 
  geom_smooth(aes(x=Year, y=Excess.Deaths), data = dat4, 
              method = "lm", formula = y ~ poly(x,1),se = FALSE, color = "gray") +
  geom_smooth(aes(x=Year, y=Excess.Deaths), data = dat5, 
              method = "lm", formula = y ~ poly(x,2),se = FALSE, color = "orange") +
  geom_smooth(aes(x=Year, y=Excess.Deaths), data = out, 
              se = FALSE, color = "purple") +
  geom_point(aes(x=Year, y=Excess.Deaths), data = dat2, color = "blue") + 
  geom_point(aes(x=Year, y=Excess.Deaths), data = dat3, color = "red")+
  geom_point(aes(x=Year, y=Excess.Deaths), data = dat4, color = "gray")+
  geom_point(aes(x=Year, y=Excess.Deaths), data = dat5, color = "orange")+
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


ggplot() +
  geom_smooth(aes(x=Year, y=Excess.Deaths), data = dat2, 
              method = "lm", formula = y ~ poly(x,2), se = FALSE, color = "blue") + 
  geom_smooth(aes(x=Year, y=Excess.Deaths), data = dat3, 
              method = "lm", se = FALSE, color = "red") + 
  geom_smooth(aes(x=Year, y=Excess.Deaths), data = dat4, 
              method = "lm", formula = y ~ poly(x,1),se = FALSE, color = "gray") +
  geom_smooth(aes(x=Year, y=Excess.Deaths), data = dat5, 
              method = "lm", formula = y ~ poly(x,2),se = FALSE, color = "turquoise") +
  geom_point(aes(x=Year, y=Excess.Deaths), data = dat2, color = "blue") + 
  geom_point(aes(x=Year, y=Excess.Deaths), data = dat3, color = "red")+
  geom_point(aes(x=Year, y=Excess.Deaths), data = dat4, color = "gray")+
  geom_point(aes(x=Year, y=Excess.Deaths), data = dat5, color = "turquoise")+
  xlab('Year') +
  ylab('Excess Deaths') +
  xlim(1990,2020)+
  ggtitle('Regression for Ozone-Related Deaths')+
  theme(panel.background = element_rect(fill="white",colour="white"),
        panel.grid.major = element_line(linetype="blank"),
        panel.grid.minor = element_line(linetype="blank"),
        plot.title = element_text(hjust = 0.5,face="bold"),
        axis.line = element_line(colour = "black"),
        plot.background = element_rect(color = "black", size = 0.5),
        panel.border = element_rect(colour = "black", fill=NA, size=0.5))