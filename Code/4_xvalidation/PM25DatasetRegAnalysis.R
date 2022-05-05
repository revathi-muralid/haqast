# Created on: 4/19/22 by RM
# Last edited: 5/3/22 by RM

rm(list=ls())

library(data.table)
library(ggplot2)
library(tidyverse)
library(broom)

# write code at which there is a step where you calculate slope
# delta T step of 0.5 years; calc slope at 0.5 yr increment

setwd("/nas/longleaf/home/revathi/chaq/revathi/mortality_results/ACM/")

dat<-read.csv("PM25_RateChangeCalc.csv")

###Drivers Analysis

#dat<-read.csv("PM25_ACM_ConcExcDrivers.csv")

dat2<-dat[which(dat$Dataset=="EPA"),]
dat5<-dat[which(dat$Dataset=="SAT"),]
dat3<-dat[which(dat$Dataset=="NACR"),]
dat4<-dat[which(dat$Dataset=="FAQSD"),]

#Regression for each of the 4 datasets

mylm<-lm(Excess.Deaths~poly(Year,2,raw=T), dat2)

mort=c()
for(i in 0:20){
  myyr=1990+i
  y=predict(mylm,data.frame(Year=myyr))
  mort[[length(mort)+1]]<-y
}

mylm<-lm(Excess_Deaths~poly(Year,2,raw=T), dat5)
EPAmort<-mort

mort=c()
for(i in 0:18){
  myyr=2000+i
  y=predict(mylm,data.frame(Year=myyr))
  mort[[length(mort)+1]]<-y
}

SATmort<-mort

mylm<-lm(Excess.Deaths~poly(Year,1,raw=T), dat3)

mort=c()
for(i in 0:6){
  myyr=2009+i
  y=predict(mylm,data.frame(Year=myyr))
  mort[[length(mort)+1]]<-y
}

NACRmort<-mort

mylm<-lm(Excess.Deaths~poly(Year,1,raw=T), dat4)

mort=c()
for(i in 0:15){
  myyr=2002+i
  y=predict(mylm,data.frame(Year=myyr))
  mort[[length(mort)+1]]<-y
}

FAQSDmort<-mort

out_mort<-do.call(rbind, Map(data.frame, EPA=EPAmort, SAT=SATmort,NACR=NACRmort,
                             FAQSD=FAQSDmort),fill=TRUE)
      
df_death<-unlist(tot_deaths)
df_yr<-unlist(myyears)
out<-do.call(rbind, Map(data.frame, Year=df_yr, Excess.Deaths=df_death))

#out<-read.csv("PM25_ACM_Regression_Results_2009.csv")

#write.csv(out,'PM25_ACM_Regression_Results_2009.csv',na="",row.names=F, quote=FALSE)

colors <- c("EPA"="blue","NACR"="red",
            "FAQSD"="gray","SAT"="orange","Composite"="purple")

##### Figures

ggplot() +
  geom_smooth(aes(x=Year, y=Excess.Deaths, color = "blue"), data = dat2, 
              method = "lm", formula = y ~ poly(x,2), se = FALSE, color = "blue") + 
  geom_smooth(aes(x=Year, y=Excess.Deaths, color = "red"), data = dat3, 
              method = "lm", se = FALSE, color = "red") + 
  geom_smooth(aes(x=Year, y=Excess.Deaths, color = "gray"), data = dat4, 
              method = "lm", formula = y ~ poly(x,1),se = FALSE) +
  geom_smooth(aes(x=Year, y=Excess.Deaths, color = "orange"), data = dat5, 
              method = "lm", formula = y ~ poly(x,2),se = FALSE, color = "orange") +
  geom_point(aes(x=Year, y=Excess.Deaths, color = "blue"), data = dat2, color = "blue") + 
  geom_point(aes(x=Year, y=Excess.Deaths, color = "red"), data = dat3, color = "red")+
  geom_point(aes(x=Year, y=Excess.Deaths, color = "gray"), data = dat4, color = "gray")+
  geom_point(aes(x=Year, y=Excess.Deaths, color = "orange"), data = dat5, color = "orange")+
  xlab('Year') +
  ylab('Excess Deaths') +
  xlim(1990,2020)+
  ylim(0,150000)+
  guides(linetype="none",
         color=guide_legend(nrow=5))+ 
  scale_colour_manual(values = colors)+
  #scale_fill_manual(values = colors)+
  labs(color = "Dataset") +
  #ggtitle('Regression for PM2.5-Related Deaths')+
  theme(panel.background = element_rect(fill="white",colour="white"),
        panel.grid.major = element_line(linetype="blank"),
        panel.grid.minor = element_line(linetype="blank"),
        plot.title = element_text(hjust = 0.5,face="bold"),
        axis.line = element_line(colour = "black"),
        plot.background = element_rect(color = "black", size = 0.5),
        panel.border = element_rect(colour = "black", fill=NA, size=0.5))

