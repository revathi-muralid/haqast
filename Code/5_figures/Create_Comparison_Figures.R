
# Created by: Revathi Muralidharan
# Last updated: 4/11/22

rm(list=ls())

library(plyr)
library(dplyr)
library(ggplot2)
library(data.table)
library(janitor)
library(tidyr)

setwd("/nas/longleaf/home/revathi/chaq/revathi/mortality_results/ACM/")

myfiles<-list.files()[grep("Drivers.csv",list.files())]
data1<-fread(myfiles[1])
data1<-data1[which(data1$Dataset=="Total"),]
data1$Dataset<-c("EPA")
#data1$Dataset<-c("EPA - MDA8")
data2<-fread(myfiles[2])
data2<-data2[which(data2$Dataset=="Total"),]
data2$Dataset<-c("FAQSD")
#data2$Dataset<-c("EPA - MDA1")
data4<-fread(myfiles[3])
data4<-data4[which(data4$Dataset=="Total"),]
data4$Dataset<-c("NACR")
#data4$Dataset<-c("FAQSD")
data5<-fread(myfiles[4])
data5<-data5[which(data5$Dataset=="Total"),]
data5$Dataset<-c("SAT")
#data5$Dataset<-c("NACR")

data1<-data1[,c(1:3)]
data2<-data2[,c(1:3)]
data4<-data4[,c(1:3)]
data5<-data5[,c(1:3)]

data3<-read.csv("Mort_study_comp_sums.csv")
data3<-data3[which(data3$Pollutant=="O3"),]
data6<-read.csv("GBD_mortality_sums.csv")
data6<-data6[which(data6$Pollutant=="O3"),]
data3<-data3[,c(2,6,3)]
data6<-data6[,c(2,4,3)]

#data6<-fread(myfiles[6])
names(data3)[3]<-c("Excess_Deaths")
names(data6)[3]<-c("Excess_Deaths")
#names(data3)[4]<-c("Deaths Low")
#names(data3)[5]<-c("Deaths Up")

data<-rbindlist(mget(ls()[grep("data",ls())]),fill=TRUE)

data<-data[which(data$Dataset!="Zhang et al."),]

data$Dataset <- factor(data$Dataset, 
                       levels = c("EPA","NACR","FAQSD","SAT"
                                  #,"Cohen17",
                                  #"EPA10","Fann11","Fann17","GBD","Punger13",
                                  #"Zhang18"
                                  ))


data$Dataset <- factor(data$Dataset, 
                       levels = c("EPA - MDA1","EPA - MDA8","NACR","FAQSD"
                                  #,"Zhang18","GBD","Cohen17",
                                  #"EPA10","Fann11","Fann17","Punger13"
                                  ))

data$linetype<-1
data[which(data$Dataset=="GBD"),]$linetype<-2
data[which(data$Dataset=="Zhang18"),]$linetype<-2
data[which(data$Dataset=="Cohen17"),]$linetype<-2
data[which(data$Dataset=="Punger13"),]$linetype<-2
data[which(data$Dataset=="Fann11"),]$linetype<-2
data[which(data$Dataset=="Fann17"),]$linetype<-2
data[which(data$Dataset=="EPA10"),]$linetype<-2
data$linetype<-as.factor(data$linetype)

colors <- c("EPA" = "blue", "NACR" = "red", "SAT" = "orange","FAQSD" = "gray"
            #, "GBD" = "green", "Zhang18" = "magenta",
            #"Punger13" = "#00FFFF","Cohen17" = "black", "Fann17" = "brown", "EPA10" = "#66CC99",
            #"Fann11" = "#009E73"
            )
data$colour<-c("")
data[which(data$Dataset=="EPA"),]$colour<-1
data[which(data$Dataset=="NACR"),]$colour<-2
data[which(data$Dataset=="SAT"),]$colour<-3
data[which(data$Dataset=="FAQSD"),]$colour<-4

data[which(data$Dataset=="GBD"),]$colour<-5
data[which(data$Dataset=="Zhang18"),]$colour<-6
data[which(data$Dataset=="Punger13"),]$colour<-7
data[which(data$Dataset=="Cohen17"),]$colour<-8
data[which(data$Dataset=="Fann17"),]$colour<-9
data[which(data$Dataset=="EPA10"),]$colour<-10
data[which(data$Dataset=="Fann11"),]$colour<-11
data$variable<-as.factor(data$colour)
#data$`Excess Deaths`<-data$`Excess Deaths`/1000

names(data)[3]<-c("Excess Deaths")

p<-ggplot(data,aes(x=Year,y=`Excess Deaths`,group=Dataset,colour=Dataset))+
  #ggtitle("PM2.5-Associated Mortality from 1990-2019")+
  geom_line(show.legend=FALSE)+
  #geom_line(linetype=1,data=soliddat)+geom_line(linetype=2,data=dashdat)+
  geom_point(show.legend=FALSE)+
  #geom_errorbar(aes(ymin=`Deaths Low`, ymax=`Deaths Up`), width=.2,
  #              position=position_dodge(0.05))+
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

colors <- c("EPA - MDA1" = "blue", "EPA - MDA8" = "#00FFFF","NACR" = "red","FAQSD" = "gray"
            #, "GBD" = "green", "Zhang18" = "magenta",
            #"Punger13" = "#ffa200","Cohen17" = "black", "Fann17" = "brown", "EPA10" = "#66CC99",
            #"Fann11" = "#009E73"
            )
data$colour<-c("")
data[which(data$Dataset=="EPA - MDA1"),]$colour<-1
data[which(data$Dataset=="EPA - MDA8"),]$colour<-2
data[which(data$Dataset=="NACR"),]$colour<-3
data[which(data$Dataset=="FAQSD"),]$colour<-4

data[which(data$Dataset=="GBD"),]$colour<-5
data[which(data$Dataset=="Zhang18"),]$colour<-6
data[which(data$Dataset=="Punger13"),]$colour<-7
data[which(data$Dataset=="Cohen17"),]$colour<-8
data[which(data$Dataset=="Fann17"),]$colour<-9
data[which(data$Dataset=="EPA10"),]$colour<-10
data[which(data$Dataset=="Fann11"),]$colour<-11

data$variable<-as.factor(data$colour)

names(data)[3]<-c("Excess Deaths")

#data$`Excess Deaths`<-data$`Excess Deaths`/1000

q<-ggplot(data,aes(x=Year,y=`Excess Deaths`,group=`Dataset`,color=`Dataset`))+
  #ggtitle("Ozone-Associated Mortality from 1990-2019")+
  geom_line(show.legend=FALSE)+
  geom_point(show.legend=FALSE)+
  #geom_errorbar(aes(ymin=`Deaths Low`, ymax=`Deaths Up`), width=.2,
  #              position=position_dodge(0.05))+
  guides(linetype=FALSE,colour=guide_legend(nrow=6))+
  theme(panel.background = element_rect(fill="white",colour="white"),
        panel.grid.major = element_line(linetype="blank"),
        panel.grid.minor = element_line(linetype="blank"),
        plot.title = element_text(hjust = 0.5,face="bold"),
        axis.line = element_line(colour = "black"),
        plot.background = element_rect(color = "black", size = 0.5),
        panel.border = element_rect(colour = "black", fill=NA, size=0.5))+
  scale_color_manual(values = colors)+
  scale_fill_manual(values=colors)+
  ylab("Ozone Deaths")+xlim(1990,2020)
q


######################RATE OF CHANGE ANALYSIS#######################################

rdat<-read.csv("O3_RateChanges.csv")
rdat<-read.csv("PM25_RateChanges.csv")

rdat2<-read.csv("PM25_3YrRateChanges.csv")
rdat2<-read.csv("O3_3YrRateChangeCalc.csv")
#rdat$perc_change<-(rdat$Excess.Deaths-rdat$Year1_Deaths)/rdat$Year1_Deaths
#rdat$`Percent Change (%)`<-rdat$perc_change*100
#rdat2<-rdat[which(rdat$Year!=1990),]
#rdat2[which(rdat2$Dataset=="EPA_MDA8"),]$Dataset<-c("EPA - MDA8")
names(rdat)[4]<-c("Percent Change (%)")
names(rdat2)[4]<-c("Percent Change (%)")

z<-ggplot(rdat2,aes(x=Year,y=`Percent Change (%)`,group=`Dataset`,color=`Dataset`))+
  geom_line()+
  geom_point()+
  guides()+
  theme(panel.background = element_rect(fill="white",colour="white"),
        panel.grid.major = element_line(linetype="blank"),
        panel.grid.minor = element_line(linetype="blank"),
        plot.title = element_text(hjust = 0.5,face="bold"),
        axis.line = element_line(colour = "black"),
        plot.background = element_rect(color = "black", size = 0.5),
        panel.border = element_rect(colour = "black", fill=NA, size=0.5))+
  scale_color_manual(values = colors)+
  scale_fill_manual(values=colors)+xlim(1990,2020)
z
