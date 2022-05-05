
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
setwd(paste('/nas/longleaf/home/revathi/chaq/revathi/mortality_results/',healthname,'/',dname,'/',sep=""))

mynames<-c('Lon', 'Lat', 'P_25-34', 'P_35-44', 'P_45-54', 'P_55-64', 'P_65-74',
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
           'deaths_RRup_age7','Year')

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
               'deaths_RRlow_age7', 'deaths_RRup_age7','Year')

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
                'deaths_RRlow_age7', 'deaths_RRup_age7','Year')

for(i in year1:yearlast){
  fname<-paste("CDC_",dname,"_grid_mort_results_",i,".csv",sep="")
  data<-fread(fname)
  data$Year<-i
  data[c(nrow(data)+1),]<-names(data)
  if(dname=="FAQSD"){
    if(i<2007){
      names(data)<-faqsd_names
      data<-data[,c(1:23,27:53)]
    } else{
      names(data)<-faqsd_names2
      data<-data[,c(1:23,25,27:52)]
    }
    
  } else{
    names(data)<-mynames
  }
  assign(paste("data",i,sep=""),data)
}

rm(data)
data<-rbindlist(mget(ls()[grep("data",ls())]))
data<-data %>% mutate_if(is.character,as.numeric)

d2<-data%>%group_by(Year)%>%summarise_at(vars('P_25-34','P_35-44','P_45-54','P_55-64',
                                              'P_65-74','P_75-84','P_85+',
                                              'D_25-34','D_35-44','D_45-54','D_55-64',
                                              'D_65-74','D_75-84','D_85+'),sum,na.rm=T)

for(i in 1:length(names(d2))){
  if(grepl("RR",names(d2)[i])){
    names(d2)[i]<-gsub("deaths_","",names(d2[i]))
  }
}

d2_pop<-d2[,c(1:8)]
d2_mort<-d2[,c(1,9:15)]

d2_pcums<-d2_pop%>%adorn_totals("col")
d2_mcums<-d2_mort%>%adorn_totals("col")
d2_mcums$Conv_Deaths<-0.8556*d2_mcums$Total
d2_mcums$Conv_Deaths[10:21]<-d2_mcums$Total[10:21]

write.csv(d2_pcums,'CDC_Pops_1990-2010.csv',na="",row.names=F)




d2_long1 <- gather(d2, age_group, deaths_low, starts_with("RRlow"))
d2_long1<-d2_long1[,c(1,16,17)]
d2_long2 <- gather(d2, age_group, deaths_up, starts_with("RRup"), factor_key=TRUE)
d2_long2<-d2_long2[,c(1,16,17)]
d2_long3 <- gather(d2, age_group, excess_deaths, starts_with("deaths_"), factor_key=TRUE)
d2_long3<-d2_long3[,c(1,16,17)]

d2_long1$age_group<-gsub("RRlow_","",d2_long1$age_group)
d2_long2$age_group<-gsub("RRup_","",d2_long2$age_group)
d2_long3$age_group<-gsub("deaths_","",d2_long2$age_group)

d2_long<-merge(d2_long3,merge(d2_long1,d2_long2,by=c("age_group","Year")),by=c("age_group","Year"))

d2_long$age_group<-as.character(d2_long$age_group)

d3_1<-spread(d2_long1, key = Year, value = deaths_low)
d3_2<-spread(d2_long2, key = Year, value = deaths_up)
d3_3<-spread(d2_long3, key = Year, value = excess_deaths)



d4_long1 <- gather(d4_1, Year, deaths_low, toString(year1):toString(yearlast), factor_key=TRUE)
d4_long2 <- gather(d4_2, Year, deaths_up, toString(year1):toString(yearlast), factor_key=TRUE)
d4_long3 <- gather(d4_3, Year, excess_deaths, toString(year1):toString(yearlast), factor_key=TRUE)

d4_long<-merge(d4_long3,merge(d4_long1,d4_long2,by=c("age_group","Year")),by=c("age_group","Year"))

d2_long[which(d2_long$age_group=="age1"),]$age_group<-c("25-34")
d2_long[which(d2_long$age_group=="age2"),]$age_group<-c("35-44")
d2_long[which(d2_long$age_group=="age3"),]$age_group<-c("45-54")
d2_long[which(d2_long$age_group=="age4"),]$age_group<-c("55-64")
d2_long[which(d2_long$age_group=="age5"),]$age_group<-c("65-74")
d2_long[which(d2_long$age_group=="age6"),]$age_group<-c("75-84")
d2_long[which(d2_long$age_group=="age7"),]$age_group<-c("85 plus")
names(d2_long)[1]<-c("Age Group")
names(d2_long)[3]<-c("Excess Deaths")
names(d2_long)[4]<-c("Deaths Low")
names(d2_long)[5]<-c("Deaths Up")

ggplot(d2_long,aes(x=Year,y=`Excess Deaths`,ymin=`Deaths Low`,ymax=`Deaths Up`,group=`Age Group`,color=`Age Group`))+
  ggtitle("PM2.5-Associated Mortality from 2000-2018 (SAT)")+geom_line()+
  geom_point()+
  theme(panel.background = element_rect(fill="white",colour="white"),
        panel.grid.major = element_line(linetype="blank"),
        panel.grid.minor = element_line(linetype="blank"))

names(d4_long)[1]<-c("Age Group")
names(d4_long)[3]<-c("Excess Deaths")
names(d4_long)[4]<-c("Deaths Low")
names(d4_long)[5]<-c("Deaths Up")
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
