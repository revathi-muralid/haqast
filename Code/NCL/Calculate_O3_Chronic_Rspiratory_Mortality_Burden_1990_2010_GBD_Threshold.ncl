;*******************************************
; Written by Yuqiang Zhang,US EPA 2016 
; To calculate the O3 mortality burden from 1990 to 2010 using the WRF_CMAQ_36km runs
;
;********************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;load ".hluresfile"

begin

; RR for respiratory disease 
Disease = "RESP"
RR=(/1.04,1.013,1.067/)
CI=(/"mean","low","high"/)

;read ACCMIP historical O3 data from Regrid_ACCMIP_1850_WRF_CMAQ_36km.ncl ;
file1850 = "$MORTALITY/Saved_ACCMIP_1850_14models_6months_Daily1hrMaximum.nc"
f1850 = addfile(file1850,"r")

O3_6months_1850 = f1850->O3_avg_regrid 
printVarSummary(O3_6months_1850)
;zyq, 05/23/17, update to use the GBD O3 threshold value for the O3 burden calculations
;O3_6months_1850(:,:) = 37.6  ;from Lim et al., 2012 & Lelieveld et al., 2015

;read the 6 months O3 average data from 1990 to 2010
YearsB = 1990
YearsE = 2010
nyears = YearsE - YearsB + 1

;define an array to put the 21 years deaths
dims = dimsizes(O3_6months_1850)
print(dims)

deaths_21yrs_mean = new((/nyears, dims(0),dims(1)/), float)
deaths_21yrs_low  = new((/nyears, dims(0),dims(1)/), float)
deaths_21yrs_high = new((/nyears, dims(0),dims(1)/), float)

deaths_21yrs_mean = 0.
deaths_21yrs_mean@_FillValue = -999.

Dir = "$EPADATA/DOE_20years/data/36km/6months_Daily1hrMaximumO3/"
;Dir = "/nas02/depts/ese/chaq/yuqiangz/Mortality_Burden_Data/6months_Daily1hrMaximumO3/" 
DirM = "$MORTALITY/CDC_Mortality_Data/"

deathrates = new(21, float)

;loop over the Year
do Y = 0, nyears-1

 if (Y .lt. 5) then 
  files = systemfunc ("ls -1 " + Dir + "CCTM_DOE_36km_NF_combine.aconc."+(YearsB+Y)+"*"+".O3.1hr.dmax.monthly.mean.nc")
 else
  files = systemfunc ("ls -1 " + Dir + "CCTM_DOE_36km_NF_RERUN_combine.aconc."+(YearsB+Y)+"*"+".O3.1hr.dmax.monthly.mean.nc")

 end if

  numFILES1 = dimsizes(files)
  print("numFILES = " + numFILES1)
  print(files)
  print (" ")

  f1 = addfiles(files,"r")
  ListSetType (f1, "join") ; read multiple files 
  O3_6months_temp = f1[:]->O3
  ;printVarSummary(O3_6months_temp)

  O3_6months_year = dim_avg_n_Wrap(O3_6months_temp, (/0,1,2/))
  ;printVarSummary(O3_6months_year)

  ;read the Population and Baseline mortality data for adulst > 25; see Silva 2016_EHP, why using 25 above not 30 above
  fileM = DirM + Disease + "/Saved_WRF_CMAQ_36km_"+Disease+"_CDC_"+(YearsB+Y)+".nc" 
  print(fileM)
  fM = addfile(fileM, "r")
  
  ;read the variables of Baseline mortaity rates (Mrates), and the Population (Pops)
  Pops       = fM->Pops
  Mrates     = fM->Mrates 

  ;zyq, 12/07/16, add the deathrates
  Deaths_temp = fM->Deaths
  ;calculate the death rates per 100, 000 people
  deathrates (Y) = sum(Deaths_temp)/sum(Pops)*100000

  ;find the dimensions for the Pops and Mrates
  dimspops = dimsizes(Pops)
  print(dimspops)

  if (dimsizes(dimspops) .eq. 2) then
    print("We don't have age-specific baseline mortality info for disease "+ Disease)
    print("However, we do need to read the Population data from IHD or STROKE to account for Population larger than 25")

   else

   end if

  ;to read the population from IHD/STROKE to account for populations larger than 25
  file_25yrs =  DirM + "IHD/Saved_WRF_CMAQ_36km_IHD_CDC_"+(YearsB+Y)+".nc"
  print("Read the population with age-specific")
  print(file_25yrs)
  f25 = addfile(file_25yrs, "r")
  
  ;read the populations
  Pops_25yrs_temp = f25->Pops
  Pops_25yrs = dim_sum_n_Wrap(Pops_25yrs_temp, 0)
  ;printVarSummary(Pops_25yrs)
  print("We compare the Population > 25yrs reading from IHD and RESP")
  print(sum(Pops_25yrs))
  print(sum(Pops))

  ;calculate the Popweighted, zyq, 12/2/2016
   Popweighted = sum(O3_6months_year*Pops_25yrs)/sum(Pops_25yrs)
   ;create the regional mask
   USmask = where(Pops_25yrs .gt. 0, 1, 0)
   printMinMax(USmask,True)
   print(sum(USmask))
   Regionalavg = sum(O3_6months_year*USmask)/sum(USmask)
 
  ;The health funciton is from Jerrett 2009: delta Mort = Yo * (1-exp(-beta*delta X))*Pop
  ;RESP don't have age-specific
  ;loop over the RR (low, mean, high)
  RR_deaths = new(3, float)
  do R = 0, dimsizes(RR)-1  

   ;calculate the betar
   betar = log(RR(R))/10.

   ;calculate the delta concentration
   deltaO3 = O3_6months_year - O3_6months_1850

   ;calculte the deaths
   deaths_year  = Pops_25yrs * Mrates * (1-(exp(-betar*deltaO3)))

   ;printVarSummary(deaths_year)
   print("For the Year "+ (YearsB+Y)+ " the mortality burden at "+CI(R) + " level is "+ sum(deaths_year) ) 

   ;save the total annual deaths for all the grid cells_csv purpose
   RR_deaths(R) = sum(deaths_year)

   ;save the annual deaths at the grid cell
   if (R .eq. 0) then 
    deaths_21yrs_mean(Y, :,:) = deaths_year
   else if (R .eq. 1) then 
    deaths_21yrs_low(Y, :,:) = deaths_year
   else 
    deaths_21yrs_high(Y, :,:) = deaths_year
   end if
   end if

  ;end loop for the RR
  end do

  if (Y .eq. 0) then
   ;output the txt file
   file_i = "Saved_O3_"+Disease+"_Mortality_Burden_1990-2010_NF_GBD_Threshold.csv"
   system("/bin/rm -f "+file_i)   ; remove any pre-existing file
   firstline = (/"Year,mean deaths,low CI,high CI, US Population > 25yrs from RESP, US Population > 25yrs from IHD, fraction, Popweighted Avg, Regional Avg"/)
   write_table (file_i, "w", [/firstline/], "%s")
   write_table (file_i, "a", [/YearsB+Y,RR_deaths(0), RR_deaths(1), RR_deaths(2), sum(Pops), sum(Pops_25yrs), \
           sum(Pops_25yrs)/sum(Pops), Popweighted, Regionalavg/], "%i,%6.f,%6.f,%6.f, %9.f, %9.f, %2.3f, %3.2f, %3.2f")
  else 
   write_table (file_i, "a", [/YearsB+Y,RR_deaths(0), RR_deaths(1), RR_deaths(2), sum(Pops), sum(Pops_25yrs), \
           sum(Pops_25yrs)/sum(Pops), Popweighted, Regionalavg/], "%i,%6.f,%6.f,%6.f, %9.f, %9.f, %2.3f, %3.2f, %3.2f")
  end if
 
;end loop for the Year
end do

;define output netcdf to save the avoided mortality for the 21 years
;outfile = "/home/yzhang07/Scripts/US_Mortality_Burden_36km/Saved_O3_"+Disease+"_Mortality_Burden_1990-2010_NF.nc"
outfile = "$MORTALITY/Saved_O3_"+Disease+"_Mortality_Burden_1990-2010_NF_GBD_Threshold.nc"
system("/bin/rm -f "+outfile)   ; remove any pre-existing file
print(outfile)
outf = addfile(outfile,"c")
setfileoption(outf,"DefineMode",True)

outf@title         = "NCL Efficient Approach to netCDF Creation"
outf@creation_date = systemfunc ("date")
outf@long_name     = "Create by Yuqiang Zhang using the Health Impact Function from Jerrett et al., 2009"

;Define dimensions:
dim_names = (/"Times", "south_north","west_east"/)
dim_sizes = (/nyears, dims(0), dims(1)/)
dim_unlimited = (/False, False,False/)

print("Defining dimension sizes to be " + dim_sizes)
filedimdef(outf,dim_names,dim_sizes,dim_unlimited)

;Define file variables
filevardef(outf,"Times","integer","Times")
filevardef(outf,"ROW","float",(/"south_north","west_east"/))
filevardef(outf,"COL","float",(/"south_north","west_east"/))

filevardef(outf,"deaths_21yrs_mean","float",(/"Times", "south_north","west_east"/))
filevardef(outf,"deaths_21yrs_low","float",(/"Times",  "south_north","west_east"/))
filevardef(outf,"deaths_21yrs_high","float",(/"Times", "south_north","west_east"/))

  ;Times
  timesatts = True
  timesatts@long_name = "Year from 1990 to 2010 "
  filevarattdef(outf,"Times",timesatts)

  ;lat
  latatts = True
  latatts@long_name = "Latitude"
  latatts@units = "degrees_north"
  filevarattdef(outf,"ROW",latatts)

  ;lon
  lonatts = True
  lonatts@long_name = "Longitude"
  lonatts@units = "degrees_east"
  filevarattdef(outf,"COL",lonatts)

  ;lat
  latatts = True
  latatts@long_name = "Latitude"
  latatts@units = "degrees_north"
  filevarattdef(outf,"ROW",latatts)

  ;lon
  lonatts = True
  lonatts@long_name = "Longitude"
  lonatts@units = "degrees_east"
  filevarattdef(outf,"COL",lonatts)

  ;deaths_21yrs_mean
  Popsatts = True
  Popsatts@long_name = "Yearly mortality burden "
  filevarattdef(outf,"deaths_21yrs_mean",Popsatts)

  ;deaths_21yrs_low
  Deathsatts = True
  Deathsatts@long_name = "low CL for the yearly mortality burden"
  filevarattdef(outf,"deaths_21yrs_low",Deathsatts)

 ;deaths_21yrs_high
  Mratesatts = True
  Mratesatts@long_name = "high CL for the yearly mortality burden"
  filevarattdef(outf,"deaths_21yrs_high",Mratesatts)

  outf->Times = (/ispan(YearsB, YearsE, 1)/)
  outf->ROW = (/f1850->ROW/)
  outf->COL = (/f1850->COL/)
  outf->deaths_21yrs_mean = (/deaths_21yrs_mean/)
  outf->deaths_21yrs_low  = (/deaths_21yrs_low/)
  outf->deaths_21yrs_high = (/deaths_21yrs_high/)

print("Detrend the O3 health burden")
print(dtrend(dim_sum_n_Wrap(deaths_21yrs_mean,(/1,2/)), False))

print(sum(deaths_21yrs_mean(2,:,:)))
print(sum(deaths_21yrs_high(5,:,:)))
print("deathrates " + deathrates)

end
