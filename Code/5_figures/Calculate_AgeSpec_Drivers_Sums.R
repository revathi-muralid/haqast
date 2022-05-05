# Created by: Revathi Muralidharan
# Last updated: 2/10/22

rm(list=ls())

library(plyr)
library(dplyr)
library(ggplot2)
library(data.table)
library(janitor)
library(tidyr)

dname=c("EPA")
pollname=c("O3")
healthname=c("RESP")
year1=1990
yearlast=2010
nYear=yearlast-year1

# Set working directory
setwd(paste('/nas/longleaf/home/revathi/chaq/revathi/mortality_results/',healthname,'/',dname,'/Drivers/',sep=""))

mynames<-c('Lon', 'Lat', 'P_25-34', 'P_35-44', 'P_45-54', 'P_55-64', 'P_65-74',
           'P_75-84', 'P_85+', 'M_25-34', 'M_35-44', 'M_45-54', 'M_55-64',
           'M_65-74', 'M_75-84', 'M_85+', 'D_25-34', 'D_35-44', 'D_45-54',
           'D_55-64', 'D_65-74', 'D_75-84', 'D_85+', pollname, 
           paste('d',pollname,sep=""), 'AF',
           'AF_low', 'AF_up', 'deaths_age1', 'deaths_RRlow_age1',
           'deaths_RRup_age1', 'deaths_age2', 'deaths_RRlow_age2',
           'deaths_RRup_age2', 'deaths_age3', 'deaths_RRlow_age3',
           'deaths_RRup_age3', 'deaths_age4', 'deaths_RRlow_age4',
           'deaths_RRup_age4', 'deaths_age5', 'deaths_RRlow_age5',
           'deaths_RRup_age5', 'deaths_age6', 'deaths_RRlow_age6',
           'deaths_RRup_age6', 'deaths_age7', 'deaths_RRlow_age7',
           'deaths_RRup_age7')

# FAQSD 2002-2006 names
faqsd_names<-c('Lon', 'Lat', 'P_25-34', 'P_35-44', 'P_45-54', 'P_55-64', 'P_65-74',
               'P_75-84', 'P_85+', 'M_25-34', 'M_35-44', 'M_45-54', 'M_55-64',
               'M_65-74', 'M_75-84', 'M_85+', 'D_25-34', 'D_35-44', 'D_45-54',
               'D_55-64', 'D_65-74', 'D_75-84', 'D_85+', 'Gridcell', 'DSPred',
               'DSStErr', pollname, paste('d',pollname,sep=""), 
               'AF', 'AF_low', 'AF_up', 'deaths_age1',
               'deaths_RRlow_age1', 'deaths_RRup_age1', 'deaths_age2',
               'deaths_RRlow_age2', 'deaths_RRup_age2', 'deaths_age3',
               'deaths_RRlow_age3', 'deaths_RRup_age3', 'deaths_age4',
               'deaths_RRlow_age4', 'deaths_RRup_age4', 'deaths_age5',
               'deaths_RRlow_age5', 'deaths_RRup_age5', 'deaths_age6',
               'deaths_RRlow_age6', 'deaths_RRup_age6', 'deaths_age7',
               'deaths_RRlow_age7', 'deaths_RRup_age7')

#FAQSD 2007-2017 names
faqsd_names2<-c('Lon', 'Lat', 'P_25-34', 'P_35-44', 'P_45-54', 'P_55-64', 'P_65-74',
                'P_75-84', 'P_85+', 'M_25-34', 'M_35-44', 'M_45-54', 'M_55-64',
                'M_65-74', 'M_75-84', 'M_85+', 'D_25-34', 'D_35-44', 'D_45-54',
                'D_55-64', 'D_65-74', 'D_75-84', 'D_85+', 'Loc_Label1', pollname,
                'SEpred', paste('d',pollname,sep=""), 
                'AF', 'AF_low', 'AF_up', 'deaths_age1',
                'deaths_RRlow_age1', 'deaths_RRup_age1', 'deaths_age2',
                'deaths_RRlow_age2', 'deaths_RRup_age2', 'deaths_age3',
                'deaths_RRlow_age3', 'deaths_RRup_age3', 'deaths_age4',
                'deaths_RRlow_age4', 'deaths_RRup_age4', 'deaths_age5',
                'deaths_RRlow_age5', 'deaths_RRup_age5', 'deaths_age6',
                'deaths_RRlow_age6', 'deaths_RRup_age6', 'deaths_age7',
                'deaths_RRlow_age7', 'deaths_RRup_age7')

newnames<-c('Lon', 'Lat', 'deaths_age1_P','deaths_age1_M','deaths_age1_noC','deaths_age1_C',
            'deaths_age2_P','deaths_age2_M','deaths_age2_noC','deaths_age2_C',
            'deaths_age3_P','deaths_age3_M','deaths_age3_noC','deaths_age3_C',
            'deaths_age4_P','deaths_age4_M','deaths_age4_noC','deaths_age4_C',
            'deaths_age5_P','deaths_age5_M','deaths_age5_noC','deaths_age5_C',
            'deaths_age6_P','deaths_age6_M','deaths_age6_noC','deaths_age6_C',
            'deaths_age7_P','deaths_age7_M','deaths_age7_noC','deaths_age7_C','Year')

names90<-c('Lon', 'Lat', 'P_25-34', 'P_35-44', 'P_45-54', 'P_55-64', 'P_65-74',
           'P_75-84', 'P_85+', 'M_25-34', 'M_35-44', 'M_45-54', 'M_55-64',
           'M_65-74', 'M_75-84', 'M_85+', 'D_25-34', 'D_35-44', 'D_45-54',
           'D_55-64', 'D_65-74', 'D_75-84', 'D_85+', pollname, paste('d',pollname,sep=""),
           'AF','AF_low', 'AF_up', 'deaths_age1', 'deaths_RRlow_age1',
           'deaths_RRup_age1', 'deaths_age2', 'deaths_RRlow_age2',
           'deaths_RRup_age2', 'deaths_age3', 'deaths_RRlow_age3',
           'deaths_RRup_age3', 'deaths_age4', 'deaths_RRlow_age4',
           'deaths_RRup_age4', 'deaths_age5', 'deaths_RRlow_age5',
           'deaths_RRup_age5', 'deaths_age6', 'deaths_RRlow_age6',
           'deaths_RRup_age6', 'deaths_age7', 'deaths_RRlow_age7',
           'deaths_RRup_age7','deaths_age1_P','deaths_age1_M','deaths_age1_noC','deaths_age1_C',
           'deaths_age2_P','deaths_age2_M','deaths_age2_noC','deaths_age2_C',
           'deaths_age3_P','deaths_age3_M','deaths_age3_noC','deaths_age3_C',
           'deaths_age4_P','deaths_age4_M','deaths_age4_noC','deaths_age4_C',
           'deaths_age5_P','deaths_age5_M','deaths_age5_noC','deaths_age5_C',
           'deaths_age6_P','deaths_age6_M','deaths_age6_noC','deaths_age6_C',
           'deaths_age7_P','deaths_age7_M','deaths_age7_noC','deaths_age7_C','Year')

faqsd90_names<-c('Lon', 'Lat', 'P_25-34', 'P_35-44', 'P_45-54', 'P_55-64', 'P_65-74',
                 'P_75-84', 'P_85+', 'M_25-34', 'M_35-44', 'M_45-54', 'M_55-64',
                 'M_65-74', 'M_75-84', 'M_85+', 'D_25-34', 'D_35-44', 'D_45-54',
                 'D_55-64', 'D_65-74', 'D_75-84', 'D_85+', 'Gridcell', 'DSPred','DSStErr',
                 'PM25','dPM25', 'AF','AF_low', 'AF_up', 'deaths_age1', 
                 'deaths_RRlow_age1','deaths_RRup_age1', 'deaths_age2', 'deaths_RRlow_age2',
                 'deaths_RRup_age2', 'deaths_age3', 'deaths_RRlow_age3',
                 'deaths_RRup_age3', 'deaths_age4', 'deaths_RRlow_age4',
                 'deaths_RRup_age4', 'deaths_age5', 'deaths_RRlow_age5',
                 'deaths_RRup_age5', 'deaths_age6', 'deaths_RRlow_age6',
                 'deaths_RRup_age6', 'deaths_age7', 'deaths_RRlow_age7',
                 'deaths_RRup_age7')

for(i in year1:yearlast){
  if(i>year1){
    fname<-paste("CDC_",dname,"_grid_mort_drivers_",i,".csv",sep="")
    data<-fread(fname)
    data$Year<-i
    data[c(nrow(data)+1),]<-names(data)
    names(data)<-newnames
    assign(paste("data",i,sep=""),data)
  } else {
    fname<-paste("../CDC_",dname,"_grid_mort_results_",i,".csv",sep="")
    data<-fread(fname)
    if(dname=="FAQSD"){
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
    data$deaths_age1_P<-data$deaths_age1
    data$deaths_age1_M<-data$deaths_age1
    data$deaths_age1_noC<-data$deaths_age1
    data$deaths_age1_C<-data$deaths_age1
    data$deaths_age2_P<-data$deaths_age2
    data$deaths_age2_M<-data$deaths_age2
    data$deaths_age2_noC<-data$deaths_age2
    data$deaths_age2_C<-data$deaths_age2
    data$deaths_age3_P<-data$deaths_age3
    data$deaths_age3_M<-data$deaths_age3
    data$deaths_age3_noC<-data$deaths_age3
    data$deaths_age3_C<-data$deaths_age3
    data$deaths_age4_P<-data$deaths_age4
    data$deaths_age4_M<-data$deaths_age4
    data$deaths_age4_noC<-data$deaths_age4
    data$deaths_age4_C<-data$deaths_age4
    data$deaths_age5_P<-data$deaths_age5
    data$deaths_age5_M<-data$deaths_age5
    data$deaths_age5_noC<-data$deaths_age5
    data$deaths_age5_C<-data$deaths_age5
    data$deaths_age6_P<-data$deaths_age6
    data$deaths_age6_M<-data$deaths_age6
    data$deaths_age6_noC<-data$deaths_age6
    data$deaths_age6_C<-data$deaths_age6
    data$deaths_age7_P<-data$deaths_age7
    data$deaths_age7_M<-data$deaths_age7
    data$deaths_age7_noC<-data$deaths_age7
    data$deaths_age7_C<-data$deaths_age7
    data$Year<-year1
    data[c(nrow(data)+1),]<-names(data)
    names(data)<-names90
    assign(paste("data",i,sep=""),data)
  }
}

rm(data)
data1990<-data1990[,c(1:2,50:78)]
data<-rbindlist(mget(ls()[grep("data",ls())]))
data<-data %>% mutate_if(is.character,as.numeric)

d2noC<-data%>%group_by(Year)%>%summarise_at(vars(deaths_age1_noC,deaths_age2_noC,deaths_age3_noC,deaths_age4_noC,
                                               deaths_age5_noC,deaths_age6_noC,deaths_age7_noC),sum,na.rm=T)
d2noC_long <- gather(d2noC, age_group, excess_deaths, deaths_age1_noC:deaths_age7_noC, factor_key=TRUE,na.rm=T)

d3noC<-spread(d2noC_long, key = Year, value = excess_deaths)

d4noC<-d3noC %>%
  adorn_totals("row")
d4noC_long <- gather(d4noC, Year, excess_deaths, toString(year1):toString(yearlast), factor_key=TRUE,na.rm=T)
d4noC_long[which(d4noC_long$age_group=="deaths_age1_noC"),]$age_group<-c("25-34")
d4noC_long[which(d4noC_long$age_group=="deaths_age2_noC"),]$age_group<-c("35-44")
d4noC_long[which(d4noC_long$age_group=="deaths_age3_noC"),]$age_group<-c("45-54")
d4noC_long[which(d4noC_long$age_group=="deaths_age4_noC"),]$age_group<-c("55-64")
d4noC_long[which(d4noC_long$age_group=="deaths_age5_noC"),]$age_group<-c("65-74")
d4noC_long[which(d4noC_long$age_group=="deaths_age6_noC"),]$age_group<-c("75-84")
d4noC_long[which(d4noC_long$age_group=="deaths_age7_noC"),]$age_group<-c("85 plus")
names(d4noC_long)[1]<-c("Age Group")
names(d4noC_long)[3]<-c("Excess Deaths")

p<-ggplot(d4noC_long[which(d4noC_long$'Age Group'=="Total"),],aes(x=Year,y=`Excess Deaths`,group=`Age Group`,color=`Age Group`))+
  ggtitle(paste(pollname,"-Associated Mortality from ",year1,"-",yearlast, " (",dname," - Conc. Exc.)",sep=""))+geom_line()+guides(color=F)
p + theme(panel.background = element_rect(fill="white",colour="white"),
          panel.grid.major = element_line(linetype="blank"),
          panel.grid.minor = element_line(linetype="blank"))
d4noC_long$'Dataset'<-dname
d4noC_long$'Pollutant'<-pollname
#write.csv(d4noC_long,paste(dname,'_',pollname,'_',year1,'-',yearlast,'_ConcExcSums.csv',sep=""),na="",row.names=F)

d2C<-data%>%group_by(Year)%>%summarise_at(vars(deaths_age1_C,deaths_age2_C,deaths_age3_C,deaths_age4_C,
                                               deaths_age5_C,deaths_age6_C,deaths_age7_C),sum,na.rm=T)
d2C_long <- gather(d2C, age_group, excess_deaths, deaths_age1_C:deaths_age7_C, factor_key=TRUE)
d3C<-spread(d2C_long, key = Year, value = excess_deaths)
d4C<-d3C %>%
  adorn_totals("row")
d4C_long <- gather(d4C, Year, excess_deaths, toString(year1):toString(yearlast), factor_key=TRUE)
d4C_long[which(d4C_long$age_group=="deaths_age1_C"),]$age_group<-c("25-34")
d4C_long[which(d4C_long$age_group=="deaths_age2_C"),]$age_group<-c("35-44")
d4C_long[which(d4C_long$age_group=="deaths_age3_C"),]$age_group<-c("45-54")
d4C_long[which(d4C_long$age_group=="deaths_age4_C"),]$age_group<-c("55-64")
d4C_long[which(d4C_long$age_group=="deaths_age5_C"),]$age_group<-c("65-74")
d4C_long[which(d4C_long$age_group=="deaths_age6_C"),]$age_group<-c("75-84")
d4C_long[which(d4C_long$age_group=="deaths_age7_C"),]$age_group<-c("85 plus")

names(d4C_long)[1]<-c("Age Group")
names(d4C_long)[3]<-c("Excess Deaths")
p<-ggplot(d4C_long[which(d4C_long$'Age Group'=="Total"),],aes(x=Year,y=`Excess Deaths`,group=`Age Group`,color=`Age Group`))+
  ggtitle(paste(pollname,"-Associated Mortality from ",year1,"-",yearlast, " (",dname,")",sep=""))+geom_line()+guides(color=F)
p + theme(panel.background = element_rect(fill="white",colour="white"),
          panel.grid.major = element_line(linetype="blank"),
          panel.grid.minor = element_line(linetype="blank"))
d4C_long$'Dataset'<-dname
d4C_long$'Pollutant'<-pollname
#write.csv(d4C_long,paste(dname,'_',pollname,'_',year1,'-',yearlast,'_Conconlysums.csv',sep=""),na="",row.names=F)

d2P<-data%>%group_by(Year)%>%summarise_at(vars(deaths_age1_P,deaths_age2_P,deaths_age3_P,deaths_age4_P,
                                               deaths_age5_P,deaths_age6_P,deaths_age7_P),sum,na.rm=T)
d2P_long <- gather(d2P, age_group, excess_deaths, deaths_age1_P:deaths_age7_P, factor_key=TRUE)
d3C<-spread(d2P_long, key = Year, value = excess_deaths)
d4C<-d3C %>%
  adorn_totals("row")
d4C_long <- gather(d4C, Year, excess_deaths, toString(year1):toString(yearlast), factor_key=TRUE)
d4C_long[which(d4C_long$age_group=="deaths_age1_P"),]$age_group<-c("25-34")
d4C_long[which(d4C_long$age_group=="deaths_age2_P"),]$age_group<-c("35-44")
d4C_long[which(d4C_long$age_group=="deaths_age3_P"),]$age_group<-c("45-54")
d4C_long[which(d4C_long$age_group=="deaths_age4_P"),]$age_group<-c("55-64")
d4C_long[which(d4C_long$age_group=="deaths_age5_P"),]$age_group<-c("65-74")
d4C_long[which(d4C_long$age_group=="deaths_age6_P"),]$age_group<-c("75-84")
d4C_long[which(d4C_long$age_group=="deaths_age7_P"),]$age_group<-c("85 plus")

names(d4C_long)[1]<-c("Age Group")
names(d4C_long)[3]<-c("Excess Deaths")
p<-ggplot(d4C_long[which(d4C_long$'Age Group'=="Total"),],aes(x=Year,y=`Excess Deaths`,group=`Age Group`,color=`Age Group`))+
  ggtitle(paste(pollname,"-Associated Mortality from ",year1,"-",yearlast, " (",dname,")",sep=""))+geom_line()+guides(color=F)
p + theme(panel.background = element_rect(fill="white",colour="white"),
          panel.grid.major = element_line(linetype="blank"),
          panel.grid.minor = element_line(linetype="blank"))
d4C_long$'Dataset'<-dname
d4C_long$'Pollutant'<-pollname
#write.csv(d4C_long,paste(dname,'_',pollname,'_',year1,'-',yearlast,'_Poponlysums.csv',sep=""),na="",row.names=F)


d2M<-data%>%group_by(Year)%>%summarise_at(vars(deaths_age1_M,deaths_age2_M,deaths_age3_M,deaths_age4_M,
                                               deaths_age5_M,deaths_age6_M,deaths_age7_M),sum,na.rm=T)
d2P_long <- gather(d2M, age_group, excess_deaths, deaths_age1_M:deaths_age7_M, factor_key=TRUE)
d3C<-spread(d2P_long, key = Year, value = excess_deaths)
d4C<-d3C %>%
  adorn_totals("row")
d4C_long <- gather(d4C, Year, excess_deaths, toString(year1):toString(yearlast), factor_key=TRUE)
d4C_long[which(d4C_long$age_group=="deaths_age1_M"),]$age_group<-c("25-34")
d4C_long[which(d4C_long$age_group=="deaths_age2_M"),]$age_group<-c("35-44")
d4C_long[which(d4C_long$age_group=="deaths_age3_M"),]$age_group<-c("45-54")
d4C_long[which(d4C_long$age_group=="deaths_age4_M"),]$age_group<-c("55-64")
d4C_long[which(d4C_long$age_group=="deaths_age5_M"),]$age_group<-c("65-74")
d4C_long[which(d4C_long$age_group=="deaths_age6_M"),]$age_group<-c("75-84")
d4C_long[which(d4C_long$age_group=="deaths_age7_M"),]$age_group<-c("85 plus")

names(d4C_long)[1]<-c("Age Group")
names(d4C_long)[3]<-c("Excess Deaths")
p<-ggplot(d4C_long[which(d4C_long$'Age Group'=="Total"),],aes(x=Year,y=`Excess Deaths`,group=`Age Group`,color=`Age Group`))+
  ggtitle(paste(pollname,"-Associated Mortality from ",year1,"-",yearlast, " (",dname,")",sep=""))+geom_line()+guides(color=F)
p + theme(panel.background = element_rect(fill="white",colour="white"),
          panel.grid.major = element_line(linetype="blank"),
          panel.grid.minor = element_line(linetype="blank"))
d4C_long$'Dataset'<-dname
d4C_long$'Pollutant'<-pollname
#write.csv(d4C_long,paste(dname,'_',pollname,'_',year1,'-',yearlast,'_Mortonlysums.csv',sep=""),na="",row.names=F)