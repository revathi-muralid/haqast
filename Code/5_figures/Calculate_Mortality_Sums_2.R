
# Created by: Revathi Muralidharan
# Last updated: 3/7/22

rm(list=ls())

library(plyr)
library(dplyr)
library(ggplot2)
library(data.table)
library(janitor)
library(tidyr)

# Set working directory
setwd('/nas/longleaf/home/revathi/chaq/revathi/mortality_results/ACM/')

ifiles<-grep("ACM_Drivers.csv",list.files())
myfiles<-list.files()[ifiles]

for(i in 1:length(myfiles)){
  dat<-read.csv(myfiles[i])
  dat$Dname<-sub("_.*", "", myfiles[i])  
  assign(paste('data',i,sep=""),dat)
}

rm(dat)
data1$Dname<-c("EPA_MDA8")
data<-rbindlist(mget(ls()[grep("data",ls())]))
#data<-data %>% mutate_if(is.character,as.numeric)
data<-data[which(data$Dataset=="Total"),]
data<-data[,c(1,3:8)]

colors <- c("EPA - 6mMDA1" = "blue", "EPA - 6mMDA8" = "#00FFFF","NACR - 6mMDA1" = "red","FAQSD - 6mMDA8" = "gray")
names(data)[7]<-c("Dataset")
data[which(data$Dataset=="EPA_MDA8"),]$Dataset<-c("EPA - 6mMDA8")
data[which(data$Dataset=="EPA"),]$Dataset<-c("EPA - 6mMDA1")
data[which(data$Dataset=="FAQSD"),]$Dataset<-c("FAQSD - 6mMDA8")
data[which(data$Dataset=="NACR"),]$Dataset<-c("NACR - 6mMDA1")
data$colour<-c("")
data[which(data$Dataset=="EPA - 6mMDA1"),]$colour<-1
data[which(data$Dataset=="EPA - 6mMDA8"),]$colour<-2
data[which(data$Dataset=="NACR - 6mMDA1"),]$colour<-3
data[which(data$Dataset=="FAQSD - 6mMDA8"),]$colour<-4
data$variable<-as.factor(data$colour)
data$Dataset<-as.factor(data$Dataset)
#d3$Year<-as.factor(d3$Year)

p<-ggplot(data,aes(x=Year,y=`Excess_Deaths`,group=`Dataset`,color=`Dataset`))

p + theme(panel.background = element_rect(fill="white",colour="white"),
          panel.grid.major = element_line(linetype="blank"),
          panel.grid.minor = element_line(linetype="blank"),
          plot.title = element_text(hjust = 0.5,face="bold"),
          axis.line = element_line(colour = "black"),
          plot.background = element_rect(color = "black", size = 0.5),
          panel.border = element_rect(colour = "black", fill=NA, size=0.5))+
  geom_line()+geom_point()+guides(linetype=F)+
  scale_color_manual(values=colors)+
  scale_fill_manual(values=colors)+
  ylab("Ozone Deaths")

p<-ggplot(d4_long[which(d4_long$`Age Group`=="Total"),],aes(x=Year,y=`Excess Deaths`,
                                                            group=`Age Group`,color=`Age Group`))+
  ggtitle(paste(pollname,"-Associated Respiratory Mortality from ",year1,"-",yearlast,"(",dname,")",sep=""))+geom_line()+
  guides(color=F)+
  geom_errorbar(aes(ymin=`Deaths Low`, ymax=`Deaths Up`), width=.2,
                position=position_dodge(0.05))
p + theme(panel.background = element_rect(fill="white",colour="white"),
          panel.grid.major = element_line(linetype="blank"),
          panel.grid.minor = element_line(linetype="blank"),
          axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1)) 
d4_long$'Dataset'<-dname
d4_long$'Pollutant'<-pollname
#write.csv(d4_long,paste(dname,'_',pollname,'_',year1,'-',yearlast,'_sums.csv',sep=""),na="",row.names=F)
