
# Created by: Revathi Muralidharan
# Last updated: 4/12/22

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

myfiles<-list.files()[grep("O3",list.files())]

data1<-fread(myfiles[1])
data2<-fread(myfiles[2])
data3<-fread(myfiles[3])
data4<-fread(myfiles[4])
data5<-fread(myfiles[5])
data<-rbindlist(mget(ls()[grep("data",ls())]))
data[which(data$Dataset=="CMAQ_1hr"),]$Dataset<-c("EPA - 6mDMA1")
data[which(data$Dataset=="CMAQ_MDA8"),]$Dataset<-c("EPA - 6mMDA8")

data9<-data[which(data$Year==2009),]
sd(data9$PWA_O3)/mean(data9$PWA_O3)
data10<-data[which(data$Year==2010),]
sd(data10$PWA_O3)/mean(data10$PWA_O3)

data$linetype<-1
data[which(data$Dataset=="GBD"),]$linetype<-2
data[which(data$Dataset=="Zhang et al."),]$linetype<-2
data$myline<-as.factor(data$linetype)

data$Dataset <- factor(data$Dataset, 
                       levels = c("EPA - 6mDMA1","EPA - 6mMDA8","FAQSD","NACR","GBD"))
colors <- c("EPA - 6mDMA1" = "blue", "NACR" = "red","FAQSD" = "gray","EPA - 6mMDA8" = "#00FFFF", "GBD" = "green")
data$colour<-c("")
data[which(data$Dataset=="EPA - 6mDMA1"),]$colour<-1
data[which(data$Dataset=="NACR"),]$colour<-2
data[which(data$Dataset=="FAQSD"),]$colour<-3
data[which(data$Dataset=="EPA - 6mMDA8"),]$colour<-4
data[which(data$Dataset=="GBD"),]$colour<-5
data$variable<-as.factor(data$colour)

data$linetype<-as.factor(data$linetype)

p<-ggplot(data,aes(x=Year,y=`PWA_O3`,group=Dataset,colour=Dataset,linetype=linetype))+
  #ggtitle("Population-Weighted Averages of Ozone Concentrations")+
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
  #ylim(0,75)+
  ylab("Ozone (ppb)")+
  scale_color_manual(name="Dataset",
                     labels=c("EPA - 6mMDA1","NACR - 6mMDA1","FAQSD - 6mMDA8",
                              "EPA - 6mMDA8","GBD - 6mMDA8"),
                     values=colors)+
  scale_fill_manual(values=colors)
p


##################################### PWA sums ##########################################

# Set working directory
setwd('/nas/longleaf/home/revathi/HAQAST/thesis/Code/5_figures/PWA/')

mynames<-c('Lon', 'Lat', 'O3', 'Pop', 'PWA_O3','Year')

year1=2009
yearlast=2020
nYear=yearlast-year1

dname="NACR"

for(i in year1:yearlast){
  if(dname=="NACR" & i==2017){
    next
  }
  fname<-paste("NACR_O3_PWA_",i,".csv",sep="")
  data<-fread(fname)
  data$Year<-i
  data[c(nrow(data)+1),]<-names(data)
  names(data)<-mynames
  assign(paste("data",i,sep=""),data)
}

rm(data)
data<-rbindlist(mget(ls()[grep("data",ls())]))
data<-data %>% mutate_if(is.character,as.numeric)

d2<-data%>%group_by(Year)%>%summarise_at(vars(PWA_O3),sum,na.rm=T)
d2[which(d2$Year==2020),]$PWA_O3<-d2[which(d2$Year==2020),]$PWA_O3/1000

p<-ggplot(d2,aes(x=Year,y=`PWA_O3`))+geom_line()+
  guides(color=F)
p + theme(panel.background = element_rect(fill="white",colour="white"),
          panel.grid.major = element_line(linetype="blank"),
          panel.grid.minor = element_line(linetype="blank")) + 
  theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1))
d2$'Dataset'<-c("NACR")
d2$'Pollutant'<-c("O3")
#write.csv(d2,'NACR_O3_2009-2020_PWA_results.csv',na="",row.names=F,quote=FALSE)
