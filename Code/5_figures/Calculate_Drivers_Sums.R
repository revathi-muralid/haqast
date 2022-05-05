
#test<-fread('/nas/longleaf/home/revathi/chaq/revathi/mortality_results/RESP/FAQSD/CDC_FAQSD_grid_mort_results_2012.csv')

# Created by: Revathi Muralidharan
# Last updated: 4/26/22

rm(list=ls())

library(plyr)
library(dplyr)
library(ggplot2)
library(data.table)
library(janitor)
library(tidyr)

dname=c("NACR")
pollname=c("O3")
healthname=c("RESP")
year1=2009
yearlast=2021
nYear=yearlast-year1

# Set working directory
setwd(paste('/nas/longleaf/home/revathi/chaq/revathi/mortality_results/',healthname,'/',dname,'/Drivers/',sep=""))

# mort calcsheaders
# 'Row', 'Col', 'Lon', 'Lat', 'Deaths', 'Pop', 'Mrate', 'O3', 'dO3', 'AF',
# 'AF_low', 'AF_up', 'deaths', 'deaths_RRlow', 'deaths_RRup'

mynames<-c('Lon', 'Lat', 'BLDeaths', 'Pop', 'Mrate', pollname, 
           paste('d',pollname,sep=""), 'AF',
           'AF_low', 'AF_up', 'deaths', 'deaths_RRlow', 'deaths_RRup',
           'BLDeaths_1990', 'Pop_1990', 'Mrate_1990', 
           paste(pollname,'_1990',sep=""), paste('d',pollname,'_1990',sep=""),
           'AF_1990', 'AF_low_1990', 'AF_up_1990', 'deaths_1990',
           'deaths_RRlow_1990', 'deaths_RRup_1990', 'deaths_P', 'deaths_M',
           'deaths_noC', 'deaths_C')

names90<-c('Lon', 'Lat', 'BLDeaths', 'Pop', 'Mrate', pollname, 
           paste('d',pollname,sep=""), 'AF',
           'AF_low', 'AF_up', 'deaths', 'deaths_RRlow', 'deaths_RRup',
           'BLDeaths_1990', 'Pop_1990', 'Mrate_1990', 
           paste(pollname,'_1990',sep=""), paste('d',pollname,'_1990',sep=""),
           'AF_1990', 'AF_low_1990', 'AF_up_1990', 'deaths_1990',
           'deaths_RRlow_1990', 'deaths_RRup_1990', 'deaths_P', 'deaths_M',
           'deaths_noC', 'deaths_C','Year')

newnames<-c('Lon', 'Lat', 'BLDeaths', 'Pop', 'Mrate', pollname, 
            paste('d',pollname,sep=""), 'AF',
            'AF_low', 'AF_up', 'deaths', 'deaths_RRlow', 'deaths_RRup',
            'BLDeaths_1990', 'Pop_1990', 'Mrate_1990', 
            paste(pollname,'_1990',sep=""), paste('d',pollname,'_1990',sep=""),
            'AF_1990', 'AF_low_1990', 'AF_up_1990', 'deaths_1990',
            'deaths_RRlow_1990', 'deaths_RRup_1990', 'deaths_P', 'deaths_M',
            'deaths_noC', 'deaths_C','Year')

for(i in year1:yearlast){
  if(dname=="NACR" & i==2017){
    next
  }
  fname<-paste("CDC_",dname,"_grid_mort_drivers_",i,".csv",sep="")
  data<-fread(fname)
  if(i>year1){
    data$Year<-i
    data[c(nrow(data)+1),]<-names(data)
    names(data)<-newnames
    assign(paste("data",i,sep=""),data)
  } else {
    if(dname=="x"){
      if(i<2007){
        names(data)<-faqsd_names
        data<-data[,c(1:23,27:52)]
      } else{
        names(data)<-faqsd_names2
        data<-data[,c(1:23,25,27:52)]
      }
    } else{
      names(data)<-mynames
    }
    data$deaths_P<-data$deaths
    data$deaths_M<-data$deaths
    data$deaths_noC<-data$deaths
    data$deaths_C<-data$deaths
    data$Year<-year1
    data[c(nrow(data)+1),]<-names(data)
    names(data)<-names90
    assign(paste("data",i,sep=""),data)
  }
}

rm(data)
#data1990<-data1990[,c(1:2,50:78)]
data<-rbindlist(mget(ls()[grep("data",ls())]))
data<-data %>% mutate_if(is.character,as.numeric)

d2<-data%>%group_by(Year)%>%summarise_at(vars(deaths,deaths_RRlow,deaths_RRup,deaths_P,deaths_M,deaths_noC,deaths_C),sum,na.rm=T)
d3<-gather(d2,Dataset,Excess_Deaths,deaths:deaths_C)

d3[which(d3$Dataset=="deaths"),]$Dataset<-c("Total")
d3[which(d3$Dataset=="deaths_RRlow"),]$Dataset<-c("LB Total")
d3[which(d3$Dataset=="deaths_RRup"),]$Dataset<-c("UB Total")
d3[which(d3$Dataset=="deaths_P"),]$Dataset<-c("Pop Only")
d3[which(d3$Dataset=="deaths_M"),]$Dataset<-c("Mort Only")
d3[which(d3$Dataset=="deaths_noC"),]$Dataset<-c("Conc Exc")
d3[which(d3$Dataset=="deaths_C"),]$Dataset<-c("Conc Only")

#d3<-read.csv("MDA1_O3_RESP_Total_Drivers.csv")

d3$Dataset <- factor(d3$Dataset, 
                              levels = c("Total","LB Total",
                                         "UB Total","Conc Exc","Conc Only","Mort Only","Pop Only"))

d3<-as.data.frame(d3)

driver_colors <- c("Total" = "black", "Conc Only" = "red", "Conc Exc" = "blue", "Mort Only" = "magenta", "Pop Only" = "brown")
d3$colour<-c("")
d3[which(d3$Dataset=="Total"),]$colour<-1
d3[which(d3$Dataset=="Conc Only"),]$colour<-2
d3[which(d3$Dataset=="Conc Exc"),]$colour<-3
d3[which(d3$Dataset=="Mort Only"),]$colour<-4
d3[which(d3$Dataset=="Pop Only"),]$colour<-5
d3$variable<-as.factor(d3$colour)

d3$linetype<-2
d3[which(d3$Dataset=="Total"),]$linetype<-1
d3$myline<-as.factor(d3$linetype)

d4<-d3
d3c<-d3[which(d3$Dataset=="Total"),]
d3l<-d3[which(d3$Dataset=="LB Total"),]
d3u<-d3[which(d3$Dataset=="UB Total"),]
d3t<-merge(d3u,merge(d3c,d3l,by="Year"),by="Year")
d3t2<-d3t[,c(1:3,9,15,4:7)]
names(d3t2)[3]<-c("LB")
names(d3t2)[4]<-c("Total")
names(d3t2)[5]<-c("UB")

#d3$Year<-as.factor(d3$Year)

p<-ggplot(d3[which(d3$Dataset!=""),],aes(x=Year,y=`Excess_Deaths`,group=`Dataset`,color=`Dataset`,linetype=myline))

p + theme(panel.background = element_rect(fill="white",colour="white"),
          panel.grid.major = element_line(linetype="blank"),
          panel.grid.minor = element_line(linetype="blank"),
          plot.title = element_text(hjust = 0.5,face="bold"),
          axis.line = element_line(colour = "black"),
          plot.background = element_rect(color = "black", size = 0.5),
          panel.border = element_rect(colour = "black", fill=NA, size=0.5))+
  geom_line(size=1)+geom_point(size=0.8)+guides(linetype=F)+
  #geom_errorbar(aes(ymin=Dataset=="LB Total", ymax=Dataset=="UB Total"), width=.2,
  #position=position_dodge(0.05))+
  scale_color_manual(values=driver_colors)+
  scale_fill_manual(values=driver_colors)+
  ylab("Ozone Deaths")+xlim(year1,2021)+
  ggtitle("NACR")

#write.csv(d3,'../../FAQSD_PM25_ACM_Drivers.csv',na="",quote=FALSE,row.names=F)

q<-ggplot(d3t2[which(d3t2$Dataset!=""),],aes(x=Year,y=`Total`,group=`Dataset`,color=`Dataset`,linetype=myline))

q + theme(panel.background = element_rect(fill="white",colour="white"),
          panel.grid.major = element_line(linetype="blank"),
          panel.grid.minor = element_line(linetype="blank"),
          plot.title = element_text(hjust = 0.5,face="bold"),
          axis.line = element_line(colour = "black"),
          plot.background = element_rect(color = "black", size = 0.5),
          panel.border = element_rect(colour = "black", fill=NA, size=0.5))+
  geom_line(size=1)+geom_point(size=0.8)+guides(linetype=F)+
  geom_errorbar(aes(ymin=`LB`, ymax=`UB`), width=.2,
                position=position_dodge(0.05))+
  scale_color_manual(values=driver_colors)+
  scale_fill_manual(values=driver_colors)+
  ylab("PM25 Deaths")+xlim(year1,2021)+
  ggtitle("EPA")

d3t2<-d3t2[,c(1:5)]
#write.csv(d3t2,'../../EPA_MDA8_Mortality_Uncertainty.csv',na="",row.names=F,quote=FALSE)
