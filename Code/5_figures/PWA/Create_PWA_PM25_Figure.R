
# Created by: Revathi Muralidharan
# Last updated: 3/14/22

rm(list=ls())

library(plyr)
library(dplyr)
library(ggplot2)
library(data.table)
library(janitor)
library(tidyr)

# Create figure

# Set working directory
setwd('/nas/longleaf/home/revathi/HAQAST/thesis/Code/5_figures/PWA/results/')

myfiles<-list.files()[grep("PM25_",list.files())]

data1<-fread(myfiles[2])
data2<-fread(myfiles[3])
data3<-fread(myfiles[4])
data4<-fread(myfiles[5])
data5<-fread(myfiles[6])
data6<-fread(myfiles[1])
data<-rbindlist(mget(ls()[grep("data",ls())]))
colors <- c("EPA" = "blue", "NACR" = "red",  "FAQSD" = "gray","SAT" = "orange","GBD"="green")
data$colour<-c("")
data[which(data$Dataset=="EPA"),]$colour<-1
data[which(data$Dataset=="NACR"),]$colour<-2
data[which(data$Dataset=="FAQSD"),]$colour<-3
data[which(data$Dataset=="SAT"),]$colour<-4
data[which(data$Dataset=="GBD"),]$colour<-5
data$variable<-as.factor(data$colour)

data9<-data[which(data$Year==2009),]
sd(data9$PWA_PM25)/mean(data9$PWA_PM25)
data10<-data[which(data$Year==2010),]
sd(data10$PWA_PM25)/mean(data10$PWA_PM25)

data$linetype<-1
data[which(data$Dataset=="GBD"),]$linetype<-2
data[which(data$Dataset=="Zhang et al."),]$linetype<-2
data$linetype<-as.factor(data$linetype)

data$Dataset <- factor(data$Dataset, 
                       levels = c("EPA","NACR","FAQSD","SAT","GBD"))

p<-ggplot(data,aes(x=Year,y=`PWA_PM25`,group=Dataset,colour=Dataset,linetype=linetype))+
  #ggtitle("Population-Weighted Averages of PM2.5 Concentrations")+
  geom_line()+
  geom_point()+
  guides(linetype=FALSE)+ 
  theme(panel.background = element_rect(fill="white",colour="white"),
        panel.grid.major = element_line(linetype="blank"),
        panel.grid.minor = element_line(linetype="blank"),
        plot.title = element_text(hjust = 0.5),
        axis.line = element_line(colour = "black"),
        plot.background = element_rect(color = "black", size = 0.5),
        panel.border = element_rect(colour = "black", fill=NA, size=0.5))+ 
  #ylim(0,20)+
  ylab("PM2.5 (ug/m3)")+
  scale_color_manual(name="Dataset",
                     labels=c("EPA","NACR","FAQSD","SAT", "GBD"),
                     values=colors)+
  scale_fill_manual(values=colors)
p


##################################### PWA sums ##########################################

# Set working directory
setwd('/nas/longleaf/home/revathi/HAQAST/thesis/Code/5_figures/PWA/')

mynames<-c('Lon', 'Lat', 'O3', 'P_TOT', 'PWA_PM25','Year')

year1=2009
yearlast=2015
nYear=yearlast-year1

for(i in year1:yearlast){
  fname<-paste("NACR_PM25_PWA_",i,".csv",sep="")
  data<-fread(fname)
  data$Year<-i
  data[c(nrow(data)+1),]<-names(data)
  names(data)<-mynames
  assign(paste("data",i,sep=""),data)
}

rm(data)
data<-rbindlist(mget(ls()[grep("data",ls())]))
data<-data %>% mutate_if(is.character,as.numeric)

d2<-data%>%group_by(Year)%>%summarise_at(vars(PWA_PM25),sum,na.rm=T)

p<-ggplot(d2,aes(x=Year,y=`PWA_PM25`))+geom_line()+
  guides(color=F)
p + theme(panel.background = element_rect(fill="white",colour="white"),
          panel.grid.major = element_line(linetype="blank"),
          panel.grid.minor = element_line(linetype="blank")) + 
  theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1))
d2$'Dataset'<-c("NACR")
d2$'Pollutant'<-c("PM25")
#write.csv(d2,'NACR_PM25_2009-2015_PWA_results.csv',na="",row.names=F)
