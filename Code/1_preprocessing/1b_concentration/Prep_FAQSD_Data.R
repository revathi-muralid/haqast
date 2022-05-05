
# Merge grid row/col info with FAQSD concentration data

rm(list=ls())

library(data.table)
library(dplyr)
library(plyr)

setwd("/nas/longleaf/home/revathi/chaq/revathi/FAQSD/")

grid<-read.csv("cmaq.grid.csv")
names(grid)[2]<-c("Lon")
names(grid)[3]<-c("Lat")
grid$Col<-sub("\\_.*", "", grid$Col_Row)
grid$Row<-sub('.*_', '', grid$Col_Row)

pollname=c("ozone")

for(i in 2002:2017){
  if(i<2007){
    conc<-fread(paste("gridded/Pooled12_36DSSurfaces/",pollname,"_",i,".csv",sep=""))
  } else{
    conc<-fread(paste("gridded/",pollname,"_12km_Predictions_",i,".csv",sep=""))
    names(conc)<-c("Date","Gridcell","Lat","Lon","DSPred","DSStErr")
  }
  names(grid)[1]<-c("Gridcell")
  conc2<-merge(conc,grid,by=c("Gridcell"),all.y=T)
  if(pollname=="ozone"){
    conc3<-filter(conc2, !grepl("Jan|Feb|Mar|Oct|Nov|Dec",Date))
  } else{
    conc3<-conc2
  }
  
  conc4<-conc3%>%group_by(Gridcell)%>%summarise_at(vars(DSPred),mean,na.rm=F)
  conc5<-merge(conc4,unique(conc3[,c("Lat.y","Lon.y","Gridcell","Col","Row")]),by=c("Gridcell"),all.y=T)
  conc6<-conc5[,c(5,6,3,4,1,2)]
  names(conc6)[3]<-c("Lat")
  names(conc6)[4]<-c("Lon")
  names(conc6)[6]<-pollname
  conc7<-conc6%>%arrange(as.numeric(Col),as.numeric(Row))
  fwrite(conc7,paste(pollname,"/",pollname,"_orig_12km_grid_",i,".csv",sep=""))
}



