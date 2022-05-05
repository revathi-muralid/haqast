
# Created by: Revathi Muralidharan
# Last updated: 4/11/2022

rm(list=ls())

library(plyr)
library(dplyr)
library(ggplot2)
library(data.table)
library(janitor)
library(tidyr)

# Set working directory
setwd('/nas/longleaf/home/revathi/chaq/revathi/mortality_results/RESP/')

ifiles<-grep("Uncertainty.csv",list.files())
myfiles<-list.files()[ifiles]

for(i in 1:length(myfiles)){
  fname<-myfiles[i]
  data<-fread(fname)
  data$Dataset<-sub("_.*", "", fname)
  assign(paste("data",i,sep=""),data)
}
rm(data)
data1$Dataset<-c("EPA - MDA1")
data2$Dataset<-c("EPA - MDA8")
data<-rbindlist(mget(ls()[grep("data",ls())]))

data$Dataset <- factor(data$Dataset, 
                     levels = c("EPA - MDA1","EPA - MDA8","NACR","FAQSD"))
colors <- c("EPA" = "blue", "NACR" = "red", "SAT" = "orange","FAQSD" = "gray")

colors <- c("EPA - MDA1" = "blue", "EPA - MDA8" = "#00FFFF","NACR" = "red","FAQSD" = "gray"
            
)

data$colour<-c("")
data[which(data$Dataset=="EPA"),]$colour<-1
data[which(data$Dataset=="NACR"),]$colour<-2
data[which(data$Dataset=="SAT"),]$colour<-3
data[which(data$Dataset=="FAQSD"),]$colour<-4

names(data)[4]<-c("Excess Deaths")

p<-ggplot(data,aes(x=Year,y=`Excess Deaths`,group=Dataset,colour=Dataset))+
  #ggtitle("PM2.5-Associated Mortality from 1990-2019")+
  geom_line(show.legend=FALSE)+
  #geom_line(linetype=1,data=soliddat)+geom_line(linetype=2,data=dashdat)+
  geom_point(show.legend=FALSE)+
  geom_errorbar(aes(ymin=`LB`, ymax=`UB`), width=.2,
                position=position_dodge(0.05))+
  guides(linetype=FALSE,
         colour=guide_legend(nrow=7))+ 
  theme(panel.background = element_rect(fill="white",colour="white"),
        panel.grid.major = element_line(linetype="blank"),
        panel.grid.minor = element_line(linetype="blank"),
        plot.title = element_text(hjust = 0.5),
        axis.line = element_line(colour = "black"),
        plot.background = element_rect(color = "black", size = 0.5),
        panel.border = element_rect(colour = "black", fill=NA, size=0.5))+ 
  ylab("PM2.5 Deaths")+xlim(1990,2020)+
  scale_color_manual(values = colors)+
  scale_fill_manual(values=colors)
p

data$colour<-c("")
data[which(data$Dataset=="EPA - MDA1"),]$colour<-1
data[which(data$Dataset=="EPA - MDA8"),]$colour<-2
data[which(data$Dataset=="NACR"),]$colour<-3
data[which(data$Dataset=="FAQSD"),]$colour<-4

q<-ggplot(data,aes(x=Year,y=`Excess Deaths`,group=Dataset,colour=Dataset))+
  #ggtitle("PM2.5-Associated Mortality from 1990-2019")+
  geom_line(show.legend=FALSE)+
  #geom_line(linetype=1,data=soliddat)+geom_line(linetype=2,data=dashdat)+
  geom_point(show.legend=FALSE)+
  geom_errorbar(aes(ymin=`LB`, ymax=`UB`), width=.2,
                position=position_dodge(0.05))+
  guides(linetype=FALSE,
         colour=guide_legend(nrow=7))+ 
  theme(panel.background = element_rect(fill="white",colour="white"),
        panel.grid.major = element_line(linetype="blank"),
        panel.grid.minor = element_line(linetype="blank"),
        plot.title = element_text(hjust = 0.5),
        axis.line = element_line(colour = "black"),
        plot.background = element_rect(color = "black", size = 0.5),
        panel.border = element_rect(colour = "black", fill=NA, size=0.5))+ 
  ylab("Ozone Deaths")+xlim(1990,2020)+
  scale_color_manual(values = colors)+
  scale_fill_manual(values=colors)
q
