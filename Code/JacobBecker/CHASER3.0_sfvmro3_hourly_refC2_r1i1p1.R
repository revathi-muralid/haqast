# COMBINES HOURLY MODEL OUTPUT TO SIX MONTH MAX AVERAGE

# MODEL: CHASER
# to change to another model: (marked with ***CHANGE**** in code)
# 1. first year we have this models data
# 2. last year we have this models data
# 3. model name
# 4. working directory
# 5-7. names of input files
# 8. ozone variable name in netcdf
# 9. longitude cutoffs

# Notes on this code:
#     6 month combinations wrap to the next March
#     january 1st in eastern hemisphere uses values from december 31st of previous year
#     december 31st in western hemisphere uses values from january 1st of next year
#     if in start or end year, use current year for pre and post respectively 


##########################################################################################
#initialization

col=c(rgb(0.2081, 0.1663, 0.5292),
      rgb(0.3961, 0.3176, 0.8000),
      rgb(0.0123, 0.4213, 0.8802),
      rgb(0.4941, 0.7647, 0.8980),
      rgb(0.1157, 0.7022, 0.6843),
      rgb(0.5216, 0.6980, 0.1725),
      rgb(0.9968, 0.7513, 0.2325),
      rgb(1.0000, 0.4863, 0.0000),
      rgb(0.8000, 0.3176, 0.3176),
      rgb(0.6980, 0.1725, 0.1725))
N=10

library(chron)
library(RColorBrewer)
library(lattice)
library(ncdf4)
library(mgcv)
library(data.table)
library(fields)

########################################################################################

modelstartyear=1994; #******CHANGE1***************
modelendyear=2010; #******CHANGE2***************

modelname="CHASER" #******CHANGE3***************
setwd("C:\\Users\\jsbecker\\Desktop\\ModelCombination\\CHASER")

for (year in modelstartyear:modelendyear)
{
    #*******CHANGE4**************
    filename= paste("sfvmro3_hourly_CHASER-MIROC-ESM_refC1SD_r1i1p1_",year,"01010030-",year,"12312330",sep='') #*******CHANGE5*************
    filename_pre=  paste("sfvmro3_hourly_CHASER-MIROC-ESM_refC1SD_r1i1p1_",year-1,"01010030-",year-1,"12312330",sep='') #*****CHANGE6************ file name for year before (if its the first year this won't get used so don't worry about that not being a real file)
    filename_post=  paste("sfvmro3_hourly_CHASER-MIROC-ESM_refC1SD_r1i1p1_",year+1,"01010030-",year+1,"12312330",sep='') #*******CHANGE7********** file name for year after (if its the last year this won't get used so don't worry about that not being a real file)
    
    outputfile=paste("CCMI-",modelname,"-warm-dma8-",year,".txt",sep='')
    imagename=paste("DMA8_", modelname,"_",year,"warm.png",sep='')
  
    ncname <- filename
    ncfname <- paste(ncname, ".nc", sep = "")
    ncin <- nc_open(ncfname)
    print(ncin)
  
    lon = ncvar_get(ncin, "lon")
    lat = ncvar_get(ncin, "lat")
    time= ncvar_get(ncin, "time", verbose = F)
    
    variablename="sfvmro3"    #*******CHANGE8********** update variable name from netcdf
    ots.array = ncvar_get(ncin, variablename) 
    dim(ots.array)
    
    #read previous years data
    if(year==modelstartyear){
      pre.array=ots.array
      pre=pre.array
      ndays_pre=length(pre[1,1,])/24
    }else{
      ncname <- filename_pre
      ncfname <- paste(ncname, ".nc", sep = "")
      ncin <- nc_open(ncfname)
      print(ncin)
      pre.array = ncvar_get(ncin, variablename) 
      dim(pre.array)
      pre=pre.array
      ndays_pre=length(pre[1,1,])/24
    }
    
    #read in next years data (post)
    if(year==modelendyear){
      post.array=ots.array
      post=post.array
      ndays_post=length(post[1,1,])/24
    }else{
      ncname <- filename_post
      ncfname <- paste(ncname, ".nc", sep = "")
      ncin <- nc_open(ncfname)
      print(ncin)
      post.array = ncvar_get(ncin, variablename) 
      dim(post.array)
      post=post.array
      ndays_post=length(post[1,1,])/24
    }
    
    ####################################################################################################
    #CURRENT YEAR CALCULATIONS
    
    ots=ots.array
    ndays=length(ots[1,1,])/24
    nlon=length(lon)                                  #number of longitudes
    nlat=length(lat)                                  #number of latitudes
  
    world8hr=array(0,dim=c(nlon,nlat,ndays))          #to hold 8 hour values
    worldhr=array(0,dim=c(nlon,nlat,ndays))           #to hold 8 hour start month
  
    for (i in 1:nlon){
      xloctm = lon[i]/15
      if (xloctm <=12){                               #EASTERN HEMISPHERE
        offset=-floor(xloctm)
        for (j in 1:nlat){
          for (day in 1:(ndays)){
            mn=offset+24*(day-1)
            max=0
            maxhr=0
            if(day==1){                               #january 1st in the eastern hemisphere uses hours from december 31st of pre
              for (hr in 7:23){                       #start hours 7 am to 11 pm due to EPA definition 
                m=mn+hr
                k=ndays_pre*24+m
                if(m<(-6)){                          #all eight values needed from december 31st of pre
                  max1=mean(c(pre[i,j,k],pre[i,j,(k+1)],pre[i,j,(k+2)],pre[i,j,(k+3)],pre[i,j,(k+4)],pre[i,j,(k+5)],pre[i,j,(k+6)],pre[i,j,(k+7)]), na.rm=T)
                }else if(m==-6){                     #first seven values needed from december 31st of pre
                  max1=mean(c(pre[i,j,k],pre[i,j,(k+1)],pre[i,j,(k+2)],pre[i,j,(k+3)],pre[i,j,(k+4)],pre[i,j,(k+5)],pre[i,j,(k+6)],ots[i,j,(m+7)]), na.rm=T)
                }else if(m==-5){                     #first six values needed from december 31st of pre
                  max1=mean(c(pre[i,j,k],pre[i,j,(k+1)],pre[i,j,(k+2)],pre[i,j,(k+3)],pre[i,j,(k+4)],pre[i,j,(k+5)],ots[i,j,(m+6)],ots[i,j,(m+7)]), na.rm=T)
                }else if(m==-4){                      #first five values needed from december 31st of pre
                  max1=mean(c(pre[i,j,k],pre[i,j,(k+1)],pre[i,j,(k+2)],pre[i,j,(k+3)],pre[i,j,(k+4)],ots[i,j,(m+5)],ots[i,j,(m+6)],ots[i,j,(m+7)]), na.rm=T)
                }else if(m==-3){                      #first four values needed from december 31st of pre
                  max1=mean(c(pre[i,j,k],pre[i,j,(k+1)],pre[i,j,(k+2)],pre[i,j,(k+3)],ots[i,j,(m+4)],ots[i,j,(m+5)],ots[i,j,(m+6)],ots[i,j,(m+7)]), na.rm=T)
                }else if(m==-2){                      #first three values needed from december 31st of pre
                  max1=mean(c(pre[i,j,k],pre[i,j,(k+1)],pre[i,j,(k+2)],ots[i,j,(m+3)],ots[i,j,(m+4)],ots[i,j,(m+5)],ots[i,j,(m+6)],ots[i,j,(m+7)]), na.rm=T)
                }else if(m==-1){                      #first two values needed from december 31st of pre
                  max1=mean(c(pre[i,j,k],pre[i,j,(k+1)],ots[i,j,(m+2)],ots[i,j,(m+3)],ots[i,j,(m+4)],ots[i,j,(m+5)],ots[i,j,(m+6)],ots[i,j,(m+7)]), na.rm=T)
                }else if(m==0){                       #first value needed from december 31st of pre
                  max1=mean(c(pre[i,j,k],ots[i,j,(m+1)],ots[i,j,(m+2)],ots[i,j,(m+3)],ots[i,j,(m+4)],ots[i,j,(m+5)],ots[i,j,(m+6)],ots[i,j,(m+7)]), na.rm=T)
                }else{
                  max1=mean(c(ots[i,j,m],ots[i,j,(m+1)],ots[i,j,(m+2)],ots[i,j,(m+3)],ots[i,j,(m+4)],ots[i,j,(m+5)],ots[i,j,(m+6)],ots[i,j,(m+7)]), na.rm=T) 
                }
              
                if (max1>max){
                  max=max1
                  maxhr=hr
                  }
                }
            }else if(day==ndays){                   #since the EPA defintion loops until the next day 7 am, the last day needs January 1st of post
              for (hr in 7:23){
                m=mn+hr
                if (m+7==ndays*24+1){                 #last value needed from january 1st of post 
                  max1=mean(c(ots[i,j,m],ots[i,j,(m+1)],ots[i,j,(m+2)],ots[i,j,(m+3)],ots[i,j,(m+4)],ots[i,j,(m+5)],ots[i,j,(m+6)],post[i,j,(1)]), na.rm=T)
                }else if(m+7==ndays*24+2){            #last two values needed from january 1st of post 
                  max1=mean(c(ots[i,j,m],ots[i,j,(m+1)],ots[i,j,(m+2)],ots[i,j,(m+3)],ots[i,j,(m+4)],ots[i,j,(m+5)],post[i,j,(1)],post[i,j,(2)]), na.rm=T)
                }else if(m+7==ndays*24+3){            #last three values needed from january 1st of post
                  max1=mean(c(ots[i,j,m],ots[i,j,(m+1)],ots[i,j,(m+2)],ots[i,j,(m+3)],ots[i,j,(m+4)],post[i,j,(1)],post[i,j,(2)],post[i,j,(3)]), na.rm=T)
                }else if(m+7==ndays*24+4){            #last four values needed from january 1st of post
                  max1=mean(c(ots[i,j,m],ots[i,j,(m+1)],ots[i,j,(m+2)],ots[i,j,(m+3)],post[i,j,(1)],post[i,j,(2)],post[i,j,(3)],post[i,j,(4)]), na.rm=T)
                }else if(m+7==ndays*24+5){            #last five values needed from january 1st of post
                  max1=mean(c(ots[i,j,m],ots[i,j,(m+1)],ots[i,j,(m+2)],post[i,j,(1)],post[i,j,(2)],post[i,j,(3)],post[i,j,(4)],post[i,j,(5)]), na.rm=T)
                }else if(m+7==ndays*24+6){            #last six values needed from january 1st of post
                  max1=mean(c(ots[i,j,m],ots[i,j,(m+1)],post[i,j,(1)],post[i,j,(2)],post[i,j,(3)],post[i,j,(4)],post[i,j,(5)],post[i,j,(6)]), na.rm=T)
                }else if(m+7==ndays*24+7){            #last seven values needed from january 1st of post
                  max1=mean(c(ots[i,j,m],post[i,j,(1)],post[i,j,(2)],post[i,j,(3)],post[i,j,(4)],post[i,j,(5)],post[i,j,(6)],post[i,j,(7)]), na.rm=T)
                }else if(m+7>ndays*24+7){             #all eight values needed from january 1st of post
                  k=m-ndays*24
                  max1=mean(c(post[i,j,k],post[i,j,(k+1)],post[i,j,(k+2)],post[i,j,(k+3)],post[i,j,(k+4)],post[i,j,(k+5)],post[i,j,(k+6)],post[i,j,(k+7)]), na.rm=T)
                }else{
                  max1=mean(c(ots[i,j,m],ots[i,j,(m+1)],ots[i,j,(m+2)],ots[i,j,(m+3)],ots[i,j,(m+4)],ots[i,j,(m+5)],ots[i,j,(m+6)],ots[i,j,(m+7)]), na.rm=T) 
                }
                if (max1>max){
                  max=max1
                  maxhr=hr
                }
              }
              
            }else{
              for (hr in 7:23){
                m=mn+hr
                max1=mean(c(ots[i,j,m],ots[i,j,(m+1)],ots[i,j,(m+2)],ots[i,j,(m+3)],ots[i,j,(m+4)],ots[i,j,(m+5)],ots[i,j,(m+6)],ots[i,j,(m+7)]), na.rm=T) 
            
                if (max1>max){
                  max=max1
                  maxhr=hr
                  }
                }
            }
            world8hr[i,j,day]=max*10^9            #convert from vmr to ppb
            worldhr[i,j,day]=maxhr
        }}} 
      else{                                       #WESTERN HEMISPHERE
        offset=24-floor(xloctm)
        for (j in 1:nlat){ 
          for (day in 1:(ndays)){
            mn=offset+24*(day-1)
            max=0
            maxhr=0
            if(day==ndays){                       #december 31st in the western hemisphere uses hours from january 1st of post
              for (hr in 7:23){
                m=mn+hr
                if (m+7==ndays*24+1){                 #last value needed from january 1st of post 
                  max1=mean(c(ots[i,j,m],ots[i,j,(m+1)],ots[i,j,(m+2)],ots[i,j,(m+3)],ots[i,j,(m+4)],ots[i,j,(m+5)],ots[i,j,(m+6)],post[i,j,(1)]), na.rm=T)
                }else if(m+7==ndays*24+2){            #last two values needed from january 1st of post 
                  max1=mean(c(ots[i,j,m],ots[i,j,(m+1)],ots[i,j,(m+2)],ots[i,j,(m+3)],ots[i,j,(m+4)],ots[i,j,(m+5)],post[i,j,(1)],post[i,j,(2)]), na.rm=T)
                }else if(m+7==ndays*24+3){            #last three values needed from january 1st of post
                  max1=mean(c(ots[i,j,m],ots[i,j,(m+1)],ots[i,j,(m+2)],ots[i,j,(m+3)],ots[i,j,(m+4)],post[i,j,(1)],post[i,j,(2)],post[i,j,(3)]), na.rm=T)
                }else if(m+7==ndays*24+4){            #last four values needed from january 1st of post
                  max1=mean(c(ots[i,j,m],ots[i,j,(m+1)],ots[i,j,(m+2)],ots[i,j,(m+3)],post[i,j,(1)],post[i,j,(2)],post[i,j,(3)],post[i,j,(4)]), na.rm=T)
                }else if(m+7==ndays*24+5){            #last five values needed from january 1st of post
                  max1=mean(c(ots[i,j,m],ots[i,j,(m+1)],ots[i,j,(m+2)],post[i,j,(1)],post[i,j,(2)],post[i,j,(3)],post[i,j,(4)],post[i,j,(5)]), na.rm=T)
                }else if(m+7==ndays*24+6){            #last six values needed from january 1st of post
                  max1=mean(c(ots[i,j,m],ots[i,j,(m+1)],post[i,j,(1)],post[i,j,(2)],post[i,j,(3)],post[i,j,(4)],post[i,j,(5)],post[i,j,(6)]), na.rm=T)
                }else if(m+7==ndays*24+7){            #last seven values needed from january 1st of post
                  max1=mean(c(ots[i,j,m],post[i,j,(1)],post[i,j,(2)],post[i,j,(3)],post[i,j,(4)],post[i,j,(5)],post[i,j,(6)],post[i,j,(7)]), na.rm=T)
                }else if(m+7>ndays*24+7){            #all eight values needed from january 1st of post
                  k=m-ndays*24
                  max1=mean(c(post[i,j,k],post[i,j,(k+1)],post[i,j,(k+2)],post[i,j,(k+3)],post[i,j,(k+4)],post[i,j,(k+5)],post[i,j,(k+6)],post[i,j,(k+7)]), na.rm=T)
                }else{
                  max1=mean(c(ots[i,j,m],ots[i,j,(m+1)],ots[i,j,(m+2)],ots[i,j,(m+3)],ots[i,j,(m+4)],ots[i,j,(m+5)],ots[i,j,(m+6)],ots[i,j,(m+7)]), na.rm=T) 
                }
                if (max1>max){
                  max=max1
                  maxhr=hr
                }
              }
          }else{
            for (hr in 7:23){
              m=mn+hr
              max1=mean(c(ots[i,j,m],ots[i,j,(m+1)],ots[i,j,(m+2)],ots[i,j,(m+3)],ots[i,j,(m+4)],ots[i,j,(m+5)],ots[i,j,(m+6)],ots[i,j,(m+7)]), na.rm=T)
              if (max1>max){
                max=max1
                maxhr=hr
            } # close if 
          } # close hour for loop
         }
          world8hr[i,j,day]=max*10^9              #convert to ppb
          worldhr[i,j,day]=maxhr
        } #close day for loop
      } #close j for loop
    } #close else
  } #close i for loop
  
####################################################################################################
#MONTHLY AVERAGES
    
  if (year%%4==0) {                                  #leap year  
    su8hr01=apply(world8hr[,,1:31],c(1,2),mean)
    su8hr02=apply(world8hr[,,32:60],c(1,2),mean)
    su8hr03=apply(world8hr[,,61:91],c(1,2),mean)
    su8hr04=apply(world8hr[,,92:121],c(1,2),mean)
    su8hr05=apply(world8hr[,,122:152],c(1,2),mean)
    su8hr06=apply(world8hr[,,153:182],c(1,2),mean)
    su8hr07=apply(world8hr[,,183:213],c(1,2),mean)
    su8hr08=apply(world8hr[,,214:244],c(1,2),mean)
    su8hr09=apply(world8hr[,,245:274],c(1,2),mean)
    su8hr10=apply(world8hr[,,275:305],c(1,2),mean)
    su8hr11=apply(world8hr[,,306:336],c(1,2),mean)
    su8hr12=apply(world8hr[,,336:366],c(1,2),mean)
  }else{                                           #not a leap year 
    su8hr01=apply(world8hr[,,1:31],c(1,2),mean)
    su8hr02=apply(world8hr[,,32:59],c(1,2),mean)
    su8hr03=apply(world8hr[,,60:90],c(1,2),mean)
    su8hr04=apply(world8hr[,,91:120],c(1,2),mean)
    su8hr05=apply(world8hr[,,121:151],c(1,2),mean)
    su8hr06=apply(world8hr[,,152:181],c(1,2),mean)
    su8hr07=apply(world8hr[,,182:212],c(1,2),mean)
    su8hr08=apply(world8hr[,,213:243],c(1,2),mean)
    su8hr09=apply(world8hr[,,244:273],c(1,2),mean)
    su8hr10=apply(world8hr[,,274:304],c(1,2),mean)
    su8hr11=apply(world8hr[,,305:335],c(1,2),mean)
    su8hr12=apply(world8hr[,,335:365],c(1,2),mean)
  }

  ######################################################################################################
  #POST YEAR
  #calculate monthly averages in post year
  #calculating January - June in case we end up looping through May 
  #set to loop through March at this point
  #dont need to worry about grabbing values from January 1st at end
  world8hr_post=array(0,dim=c(nlon,nlat,182))          #to hold 8 hour values (only 182 days)
  worldhr_post=array(0,dim=c(nlon,nlat,182))           #to hold 8 hour start month (only 182 days)
  
  for (i in 1:nlon){
    xloctm = lon[i]/15
    if (xloctm <=12){                               #EASTERN HEMISPHERE
      offset=-floor(xloctm)
      for (j in 1:nlat){
        for (day in 1:(182)){                       #go to 182 days to do all of june even in leap year
          mn=offset+24*(day-1)
          max=0
          maxhr=0
          if(day==1){                               #january 1st in the eastern hemisphere uses hours from december 31st of ots
            for (hr in 7:23){                       #start hours 7 am to 11 pm due to EPA definition 
              m=mn+hr
              k=ndays*24+m
              
              if(m<(-6)){                          #all eight values needed from december 31st of ots
                max1=mean(c(ots[i,j,k],ots[i,j,(k+1)],ots[i,j,(k+2)],ots[i,j,(k+3)],ots[i,j,(k+4)],ots[i,j,(k+5)],ots[i,j,(k+6)],ots[i,j,(k+7)]), na.rm=T)
              }else if(m==-6){                     #first seven values needed from december 31st of ots
                max1=mean(c(ots[i,j,k],ots[i,j,(k+1)],ots[i,j,(k+2)],ots[i,j,(k+3)],ots[i,j,(k+4)],ots[i,j,(k+5)],ots[i,j,(k+6)],post[i,j,(m+7)]), na.rm=T)
              }else if(m==-5){                     #first six values needed from december 31st of ots
                max1=mean(c(ots[i,j,k],ots[i,j,(k+1)],ots[i,j,(k+2)],ots[i,j,(k+3)],ots[i,j,(k+4)],ots[i,j,(k+5)],post[i,j,(m+6)],post[i,j,(m+7)]), na.rm=T)
              }else if(m==-4){                      #first five values needed from december 31st of ots
                max1=mean(c(ots[i,j,k],ots[i,j,(k+1)],ots[i,j,(k+2)],ots[i,j,(k+3)],ots[i,j,(k+4)],post[i,j,(m+5)],post[i,j,(m+6)],post[i,j,(m+7)]), na.rm=T)
              }else if(m==-3){                      #first four values needed from december 31st of ots
                max1=mean(c(ots[i,j,k],ots[i,j,(k+1)],ots[i,j,(k+2)],ots[i,j,(k+3)],post[i,j,(m+4)],post[i,j,(m+5)],post[i,j,(m+6)],post[i,j,(m+7)]), na.rm=T)
              }else if(m==-2){                      #first three values needed from december 31st of ots
                max1=mean(c(ots[i,j,k],ots[i,j,(k+1)],ots[i,j,(k+2)],post[i,j,(m+3)],post[i,j,(m+4)],post[i,j,(m+5)],post[i,j,(m+6)],post[i,j,(m+7)]), na.rm=T)
              }else if(m==-1){                      #first two values needed from december 31st of ots
                max1=mean(c(ots[i,j,k],ots[i,j,(k+1)],post[i,j,(m+2)],post[i,j,(m+3)],post[i,j,(m+4)],post[i,j,(m+5)],post[i,j,(m+6)],post[i,j,(m+7)]), na.rm=T)
              }else if(m==0){                       #first value needed from december 31st of ots
                max1=mean(c(ots[i,j,k],post[i,j,(m+1)],post[i,j,(m+2)],post[i,j,(m+3)],post[i,j,(m+4)],post[i,j,(m+5)],post[i,j,(m+6)],post[i,j,(m+7)]), na.rm=T)
              }else{
                max1=mean(c(post[i,j,m],post[i,j,(m+1)],post[i,j,(m+2)],post[i,j,(m+3)],post[i,j,(m+4)],post[i,j,(m+5)],post[i,j,(m+6)],post[i,j,(m+7)]), na.rm=T) 
              }
              
              if (max1>max){
                max=max1
                maxhr=hr
              }
            }
          }else{
            for (hr in 7:23){
              m=mn+hr
              max1=mean(c(post[i,j,m],post[i,j,(m+1)],post[i,j,(m+2)],post[i,j,(m+3)],post[i,j,(m+4)],post[i,j,(m+5)],post[i,j,(m+6)],post[i,j,(m+7)]), na.rm=T) 
              
              if (max1>max){
                max=max1
                maxhr=hr
              }
            }
          }
          world8hr_post[i,j,day]=max*10^9            #convert from vmr to ppb
          worldhr_post[i,j,day]=maxhr
        }}} 
    else{                                       #WESTERN HEMISPHERE
      offset=24-floor(xloctm)
      for (j in 1:nlat){ 
        for (day in 1:(182)){
          mn=offset+24*(day-1)
          max=0
          maxhr=0
          for (hr in 7:23){
            m=mn+hr
            max1=mean(c(ots[i,j,m],ots[i,j,(m+1)],ots[i,j,(m+2)],ots[i,j,(m+3)],ots[i,j,(m+4)],ots[i,j,(m+5)],ots[i,j,(m+6)],ots[i,j,(m+7)]), na.rm=T)
            if (max1>max){
              max=max1
              maxhr=hr
              } # close if 
            } # close hour for loop
          world8hr_post[i,j,day]=max*10^9              #convert to ppb
          worldhr_post[i,j,day]=maxhr
        } #close day for loop
      } #close j for loop
    } #close else
  } #close i for loop
    
  if ((year+1)%%4==0) {                                  #leap year  
    su8hr01_post=apply(world8hr_post[,,1:31],c(1,2),mean)
    su8hr02_post=apply(world8hr_post[,,32:60],c(1,2),mean)
    su8hr03_post=apply(world8hr_post[,,61:91],c(1,2),mean)
    su8hr04_post=apply(world8hr_post[,,92:121],c(1,2),mean)
    su8hr05_post=apply(world8hr_post[,,122:152],c(1,2),mean)
    su8hr06_post=apply(world8hr_post[,,153:182],c(1,2),mean)
  }else{                                           #not a leap year 
    su8hr01_post=apply(world8hr_post[,,1:31],c(1,2),mean)
    su8hr02_post=apply(world8hr_post[,,32:59],c(1,2),mean)
    su8hr03_post=apply(world8hr_post[,,60:90],c(1,2),mean)
    su8hr04_post=apply(world8hr_post[,,91:120],c(1,2),mean)
    su8hr05_post=apply(world8hr_post[,,121:151],c(1,2),mean)
    su8hr06_post=apply(world8hr_post[,,152:181],c(1,2),mean)
  }
  
  #################################################################################################################################
  
  rdma8=matrix(0,ncol=nlat, nrow=nlon)

  #wraps through MARCH of next year
  for (i in 1:nlon){
	  for (j in 1:nlat){
      rdma8[i,j]=max(rowMeans(embed(c(su8hr01[i,j],su8hr02[i,j],su8hr03[i,j],su8hr04[i,j],su8hr05[i,j],su8hr06[i,j],su8hr07[i,j],su8hr08[i,j],su8hr09[i,j],su8hr10[i,j],su8hr11[i,j],su8hr12[i,j],su8hr01_post[i,j],su8hr02_post[i,j],su8hr03_post[i,j]),6), na.rm=T))
  }}


  midpoint=nlon/2;
  rdma8=rbind(rdma8[65:128,], rdma8[1:midpoint,]) #******CHANGE9*********************************
  

  obj=list(x=ncvar_get(ncin, "lon")-180, y=ncvar_get(ncin, "lat"), z=rdma8)
  make.surface.grid(list(seq(-180, by=0.5,length=720), seq(-90, by=0.5,length=360)))-> loc
  interp.surface(obj, loc)-> su8hr
  image.plot(as.surface(loc, su8hr))

  su8hr=matrix(su8hr, nrow=720)

  write.table(su8hr,outputfile, sep=" ", row.names=F, col.names=F)

  png(imagename, height =5, width =7, units ="in", res =500)
  image.plot(seq(-180, by=0.5,length=720), seq(-90, by=0.5,length=360),su8hr, xlab="longitude",ylab="latitude", horizontal=F, col=col, breaks=seq(0, 80, length.out= N+1))
  contour(seq(-180, by=0.5,length=720), seq(-90, by=0.5,length=360),su8hr,drawlabels=T, add=TRUE,col=24)
  map(add=T)
  mtext('(ppb)', side=3, line=0, at=210, cex=1.5)
  dev.off()

}

