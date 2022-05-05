;*******************************************
; Written by Yuqiang Zhang,US EPA 2016 
; To calculate the PM25 mortality burden from 1990 to 2010 using the WRF_CMAQ_36km runs
;
;********************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

;load ".hluresfile"

begin

start_cpu_time = get_cpu_time()     ; We will time this example

; RR for respiratory disease 
Disease = (/"COPD", "LC", "IHD", "STROKE"/)
;we need to find the right RR from the Burnett et al., 2014 IER RR
RR_Burnett = "$MORTALITY/RR_IER/"

;read ACCMIP historical PM25 data from Regrid_ACCMIP_1850_WRF_CMAQ_36km.ncl for the COL and ROW purpose
file1850 = "$MORTALITY/Saved_ACCMIP_1850_14models_6months_Daily1hrMaximum.nc"
f1850 = addfile(file1850,"r")

O3_6months_1850 = f1850->O3_avg_regrid 
printVarSummary(O3_6months_1850)

YearsB = 1990
YearsE = 2010
nyears = YearsE - YearsB + 1

;define an array to put the 21 years deaths
dims = dimsizes(O3_6months_1850)
print(dims)

count = 0
;loop over the Diseases
do D = 0, dimsizes(Disease)-1 
 count = count + 1

 deaths_21yrs_mean = new((/nyears, dims(0),dims(1)/), float)
 deaths_21yrs_low  = new((/nyears, dims(0),dims(1)/), float)
 deaths_21yrs_high = new((/nyears, dims(0),dims(1)/), float)

 Dir = "/home/yzhang07/Scripts/Dry_Deposition_36km/WRF_CMAQ_36km/NF_aconc/" 
; Dir = "/nas02/depts/ese/chaq/yuqiangz/Mortality_Burden_Data/WRF_CMAQ_36km/NF_aconc/"
 DirM = "$MORTALITY/CDC_Mortality_Data/"

 ;loop over the Year
 do Y = 0, nyears-1

  if (Y .lt. 5) then 
   files = systemfunc ("ls -1 " + Dir + "CCTM_DOE_36km_NF_combine.aconc."+(YearsB+Y)+"*")
  else
   files = systemfunc ("ls -1 " + Dir + "CCTM_DOE_36km_NF_RERUN_combine.aconc."+(YearsB+Y)+"*")
  end if

  numFILES1 = dimsizes(files)
  print("numFILES = " + numFILES1)
  print(files)
  print (" ")

  f1 = addfiles(files,"r")
  ListSetType (f1, "join") ; read multiple files 
  PM25_Annual_temp = f1[:]->PM25_TOT
  printVarSummary(PM25_Annual_temp)

  PM25_Annual_year = dim_avg_n_Wrap(PM25_Annual_temp, (/0,1,2/))
  printVarSummary(PM25_Annual_year)
  printMinMax(PM25_Annual_year, True)

  ;read the Population and Baseline mortality data for adulst > 25; see Silva 2016_EHP, why using 25 above not 30 above
  fileM = DirM + Disease(D) + "/Saved_WRF_CMAQ_36km_"+Disease(D)+"_CDC_"+(YearsB+Y)+".nc" 
  print(fileM)
  fM = addfile(fileM, "r")
  
  ;read the variables of Baseline mortaity rates (Mrates), and the Population (Pops)
  ;remember that the first 2 disease, the dims are (Lat, Lon), for IHD and STR, the dims are (ages, Lat, Lon)
  Pops       = fM->Pops
  Mrates     = fM->Mrates 
  ;printVarSummary(Pops)

  ;find the dimensions for the Pops and Mrates
  dimspops = dimsizes(Pops)
  print(dimspops)

  if (dimsizes(dimspops) .eq. 2) then
    print("We don't have age-specific baseline mortality info for disease "+ Disease(D))
    print("However, we do need to read the Population data from IHD or STROKE to account for Population larger than 25")
   else
    print("We have age-specific baseline mortality info for disease "+Disease(D))
    print("Be careful that the ages_groups for the RR from Burnett are different from CDC mortality data ")
    print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
    print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
   end if

  ;The health funciton is from IER from Burnett 2014: delta Mort = Yo *AF*Pop ;AF = 1 - 1/RR
  ;First two don't have age-specific; but IHD and STROKE do
  ;loop over the RR (low, mean, high)
  RR_deaths = new(1, float)
  RR_deaths_lb = new(1, float)
  RR_deaths_ub = new(1, float)

  if (count .eq. 1 .and. Y .eq. 0) then  ;(D .eq. 0 .and. Y .eq. 0) then 
   RR_PM25_deaths = new(nyears, float)
   RR_PM25_deaths_lb = new(nyears, float)
   RR_PM25_deaths_ub = new(nyears, float)
   RR_PM25_deaths(:) = 0.
   RR_PM25_deaths_lb(:) = 0.
   RR_PM25_deaths_ub(:) = 0.
  end if

  deaths_year = O3_6months_1850
  deaths_year(:,:) = 0.0
  deaths_year_lb = O3_6months_1850
  deaths_year_ub = O3_6months_1850
  deaths_year_lb(:,:) = 0.0
  deaths_year_ub(:,:) = 0.0

;  do R = 0, dimsizes(RR)-1   
  ;find the indexes for the PM25 concentration
;   PM25_Annual_round = decimalPlaces(PM25_Annual_year,1,True)
;   PM25_Annual_round = where (PM25_Annual_round .lt. 1, 1, PM25_Annual_round)
  PM25_Annual_ceil = ceil(PM25_Annual_year)
  PM25_Annual_floor = floor(PM25_Annual_year)
  ;printMinMax(PM25_Annual_floor,True)

;calculate the new Pops and Mortality rates for IHD and STROKE
  if (D .le. 1) then ;for COPD and LC
  ;loop over the ages
   ages_groups = (/"AllAges"/)

  else  ;for IHD and STROKE
   ages_groups := (/"25_29","30_34","35_39","40_44","45_49","50_54","55_59","60_64","65_69","70_74","75_79","80PLUS"/)
   ;Ages-specific for the RR           : 25-30, 30-35, 35-40,......, 80UP        (12)
   ;Ages-specific for the Pops and Mort: 25-34,        35-44......., 75-84, 85UP (7) 
   Pops_new = new((/dimsizes(ages_groups), dims(0), dims(1)/),float)
   Mrates_new = new((/dimsizes(ages_groups), dims(0), dims(1)/),float)
   Pops_new(:,:,:) = 0.
   Mrates_new(:,:,:) = 0.

   ;25-30, 30-35 for new; 25-34
   Pops_new(0,:,:) = Pops(0,:,:)/2.    ;25-34
   Pops_new(1,:,:) = Pops(0,:,:)/2.
   Mrates_new(0,:,:) = Mrates(0,:,:)
   Mrates_new(1,:,:) = Mrates(0,:,:)

   ;35-40, 40-45 for new
   Pops_new(2,:,:) = Pops(1,:,:)/2.    ;35-44
   Pops_new(3,:,:) = Pops(1,:,:)/2.
   Mrates_new(2,:,:) = Mrates(1,:,:)
   Mrates_new(3,:,:) = Mrates(1,:,:)

   ;45-50, 50-55
   Pops_new(4,:,:) = Pops(2,:,:)/2.    ;45-54
   Pops_new(5,:,:) = Pops(2,:,:)/2.
   Mrates_new(4,:,:) = Mrates(2,:,:)
   Mrates_new(5,:,:) = Mrates(2,:,:)

   ;55-60, 60-65
   Pops_new(6,:,:) = Pops(3,:,:)/2.    ;55-64
   Pops_new(7,:,:) = Pops(3,:,:)/2.
   Mrates_new(6,:,:) = Mrates(3,:,:)
   Mrates_new(7,:,:) = Mrates(3,:,:)

   ;65-70, 70-75
   Pops_new(8,:,:) = Pops(4,:,:)/2.    ;65-74
   Pops_new(9,:,:) = Pops(4,:,:)/2.
   Mrates_new(8,:,:) = Mrates(4,:,:)
   Mrates_new(9,:,:) = Mrates(4,:,:)

   ;75-80, 80UP
   Pops_new(10,:,:) = Pops(5,:,:)/2.   ;75-84
   Pops_new(11,:,:) = Pops(5,:,:)/2. +  Pops(6,:,:)   ;(75-84)/2. + (85+)
   Mrates_new(10,:,:) = Mrates(5,:,:)
   Mrates_new(11,:,:) = (Pops(5,:,:)/2.* Mrates(5,:,:) + Pops(6,:,:)*Mrates(6,:,:))/(Pops_new(11,:,:))
   print("zyq test for Populuation before redistribute "+sum(Pops)+ " ; After redistribute "+sum(Pops_new))
  end if

  ;loop over the ages
  do Age = 0, dimsizes(ages_groups)-1
   if (Disease(D) .eq. "STROKE") then 
    file_RR_Burnett = RR_Burnett + "RR_Stroke_"+ages_groups(Age)+".csv"
   else
    file_RR_Burnett = RR_Burnett + "RR_"+Disease(D)+"_"+ages_groups(Age)+".csv"
   end if
   print("We are reading the RR files from Burnett et al., 2014 ES&T ")
   print(file_RR_Burnett)

   ;read the csv files
   lines = asciiread(file_RR_Burnett, -1, "string")
   delim = ","
   nlines = dimsizes(lines)
   print(nlines)
   print(lines(0))
   print(lines(nlines-1))

   ;saved the PM25 concentration and RR
   PM25_Burnett = stringtofloat(str_get_field(lines(1:nlines-1),1,delim))
   ;print(PM25_Burnett(0:10))
;  index_floor = ind(PM25_Burnett .eq. PM25_Annual_floor)
;  index_ceil  = ind(PM25_Burnett .eq. PM25_Annual_ceil)

   RR_MEAN_Burnett = stringtofloat(str_get_field(lines(1:nlines-1),2,delim))
   RR_LB_Burnett = stringtofloat(str_get_field(lines(1:nlines-1),3,delim))
   RR_UB_Burnett = stringtofloat(str_get_field(lines(1:nlines-1),4,delim))
  ; print(RR_MEAN_Burnett(10:20))

    ;to read the population from IHD/STROKE to account for populations larger than 25
    file_25yrs =  DirM + "IHD/Saved_WRF_CMAQ_36km_IHD_CDC_"+(YearsB+Y)+".nc"
    print("Read the population with age-specific")
    ;print(file_25yrs)
    f25 = addfile(file_25yrs, "r")

    ;read the populations
    Pops_25yrs_temp = f25->Pops
    Pops_25yrs = dim_sum_n_Wrap(Pops_25yrs_temp, 0)
    ;printVarSummary(Pops_25yrs)

    ;loop over the grid cells
    do I = 0, dims(0)-1 
     do J = 0, dims(1)-1 
      index_floor = ind (PM25_Burnett .eq. PM25_Annual_floor(I, J)) 
      index_ceil  = ind (PM25_Burnett .eq. PM25_Annual_ceil(I, J))
      ;print(PM25_Burnett + " "+PM25_Annual_floor(I, J))
      ;print(index_floor + " "+index_ceil)

      RRMEAN = RR_MEAN_Burnett(index_floor) + (RR_MEAN_Burnett(index_ceil)-RR_MEAN_Burnett(index_floor))*(PM25_Annual_year(I,J) -PM25_Annual_floor(I,J))
      RRLB = RR_LB_Burnett(index_floor) + (RR_LB_Burnett(index_ceil)-RR_LB_Burnett(index_floor))*(PM25_Annual_year(I,J) -PM25_Annual_floor(I,J))
      RRUB = RR_UB_Burnett(index_floor) + (RR_UB_Burnett(index_ceil)-RR_UB_Burnett(index_floor))*(PM25_Annual_year(I,J) -PM25_Annual_floor(I,J))

      if (D .le. 1) then  ;for COPD and LC
       ;calculate the deaths
       ;print(index_PM25)
        AF = 1 - 1/RRMEAN
        deaths_year(I, J) = deaths_year(I, J) + Pops_25yrs(I,J)*Mrates(I,J)*AF  ;add them together for different ages groups

        AF = 1 - 1/RRLB
        deaths_year_lb(I, J) = deaths_year_lb(I, J) + Pops_25yrs(I,J)*Mrates(I,J)*AF

        AF = 1 - 1/RRUB
        deaths_year_ub(I, J) = deaths_year_ub(I, J) + Pops_25yrs(I,J)*Mrates(I,J)*AF

       else  ;for IHD and STROKE 
        AF = 1 - 1/RRMEAN
        deaths_year(I, J)=deaths_year(I, J)+Pops_new(Age, I,J)*Mrates_new(Age, I,J)*AF  ;add them together for different ages groups

        AF = 1 - 1/RRLB
        deaths_year_lb(I, J)=deaths_year_lb(I, J)+Pops_new(Age, I,J)*Mrates_new(Age, I,J)*AF

        AF = 1 - 1/RRUB
        deaths_year_ub(I, J)=deaths_year_ub(I, J)+Pops_new(Age, I,J)*Mrates_new(Age, I,J)*AF
       end if
     end do
    end do     

  ;end loop for the ages
  end do    

  if (D .le. 1) then
    Pops_save = Pops

  ;calculate the Popweighted, zyq, 12/2/2016
   Popweighted = sum(PM25_Annual_year*Pops_25yrs)/sum(Pops_25yrs)
   ;create the regional mask
   USmask = where(Pops_25yrs .gt. 0, 1, 0)
   ;printMinMax(USmask,True)
   ;print(sum(USmask))
   Regionalavg = sum(PM25_Annual_year*USmask)/sum(USmask)
  else
    Pops_save := Pops_new

  ;calculate the Popweighted, zyq, 12/2/2016
   Pops_25yrs = dim_sum_n_Wrap(Pops, 0)
   Popweighted = sum(PM25_Annual_year*Pops_25yrs)/sum(Pops_25yrs)
   ;create the regional mask
   USmask = where(Pops_25yrs .gt. 0, 1, 0)
   ;printMinMax(USmask,True)
   ;print(sum(USmask))
   Regionalavg = sum(PM25_Annual_year*USmask)/sum(USmask)

  end if

   delete([/Pops, Mrates, dimspops/])
   ;printVarSummary(deaths_year)

   print("For the Year "+ (YearsB+Y)+ " the mortality burden for disease "+Disease(D)+" is "+ sum(deaths_year) ) 

   ;save the total annual deaths for all the grid cells_csv purpose
   RR_deaths = sum(deaths_year)
   RR_deaths_lb = sum(deaths_year_lb)
   RR_deaths_ub = sum(deaths_year_ub)

   RR_PM25_deaths(Y) = RR_PM25_deaths(Y) + RR_deaths
   RR_PM25_deaths_lb(Y) = RR_PM25_deaths_lb(Y) + RR_deaths_lb
   RR_PM25_deaths_ub(Y) = RR_PM25_deaths_ub(Y) + RR_deaths_ub

   ;save the annual deaths at the grid cell

    deaths_21yrs_mean(Y, :,:) = deaths_year
    deaths_21yrs_low(Y, :,:) = deaths_year_lb
    deaths_21yrs_high(Y, :,:) = deaths_year_ub

  if (Y .eq. 0) then
   ;output the txt file
   file_i = "./Burnett_IER_RR/Saved_PM25_"+Disease(D)+"_Mortality_Burden_1990-2010_NF.csv"
   system("/bin/rm -f "+file_i)   ; remove any pre-existing file

   if (D .le. 1) then 
     firstline = (/"Year,mean deaths, low CI, high CI, US Population >25yrs from disease, US Population > 25yrs from IHD, fraction, Popweighted Avg, Regional Avg"/) ;,low CI,high CI"/)
    write_table (file_i, "w", [/firstline/], "%s")
    write_table (file_i, "a", [/YearsB+Y,RR_deaths,RR_deaths_lb, RR_deaths_ub, sum(Pops_save), sum(Pops_25yrs), \
                 sum(Pops_25yrs)/sum(Pops_save), Popweighted, Regionalavg/], "%i, %6.f, %6.f, %6.f, %9.f, %9.f, %2.3f, %3.2f, %3.2f")
   else 
    firstline = (/"Year,mean deaths, low CI, high CI, US Population > 25yrs, Popweighted Avg, Regional Avg"/) ;,low CI,high CI"/)
    write_table (file_i, "w", [/firstline/], "%s")
    write_table (file_i, "a", [/YearsB+Y,RR_deaths,RR_deaths_lb, RR_deaths_ub, \
                sum(Pops_save), Popweighted, Regionalavg/], "%i, %6.f, %6.f, %6.f, %9.f, %3.2f, %3.2f")
   end if 

  else  ;for differt years 

   ;for different disease
   if (D .le. 1) then 
   write_table (file_i, "a", [/YearsB+Y,RR_deaths,RR_deaths_lb, RR_deaths_ub, sum(Pops_save), sum(Pops_25yrs), \
                sum(Pops_25yrs)/sum(Pops_save), Popweighted, Regionalavg/], "%i, %6.f, %6.f, %6.f, %9.f, %9.f, %2.3f, %3.2f, %3.2f")
   else
    write_table (file_i, "a", [/YearsB+Y,RR_deaths,RR_deaths_lb, RR_deaths_ub, \
               sum(Pops_save), Popweighted, Regionalavg/], "%i, %6.f, %6.f, %6.f, %9.f, %3.2f, %3.2f")
   end if
  end if

;end loop for the Year
end do

;define output netcdf to save the avoided mortality for the 21 years
outfile = "/home/yzhang07/Scripts/US_Mortality_Burden_36km/Burnett_IER_RR/Saved_PM25_"+Disease(D)+"_Mortality_Burden_1990-2010_NF.nc"
;outfile = "/nas02/depts/ese/chaq/yuqiangz/US_Mortality_Burden_36km/Burnett_IER_RR/Saved_PM25_"+Disease(D)+"_Mortality_Burden_1990-2010_NF.nc"
system("/bin/rm -f "+outfile)   ; remove any pre-existing file
;print(outfile)
outf = addfile(outfile,"c")
setfileoption(outf,"DefineMode",True)

outf@title         = "NCL Efficient Approach to netCDF Creation"
outf@creation_date = systemfunc ("date")
outf@long_name     = "Create by Yuqiang Zhang using the Health Impact Function from IER with RR Burnett 2014"

;Define dimensions:
dim_names = (/"Times", "south_north","west_east"/)
dim_sizes = (/nyears, dims(0), dims(1)/)
dim_unlimited = (/False, False,False/)

;print("Defining dimension sizes to be " + dim_sizes)
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

print(sum(deaths_21yrs_mean(2,:,:)))
;print(sum(deaths_21yrs_high(5,:,:)))

;end do for the Disease
end do 


file_t = "./Burnett_IER_RR/Saved_PM25_Total_COPD_LC_IHD_STR_Mortality_Burden_1990-2010_NF.csv"
system("/bin/rm -f "+file_t)   ;remove pre-existing file
firstline = (/"Year,total deaths from PM2.5, low CI, high CI"/) ;,low CI,high CI"/)
print(RR_PM25_deaths)
;for the total
write_table (file_t, "w", [/firstline/], "%s")
write_table (file_t, "a", [/ispan(1990, 2010,1),RR_PM25_deaths, RR_PM25_deaths_lb, RR_PM25_deaths_ub/], "%i,%6.f,%6.f,%6.f")

print("Detrend the PM25 health burden")
print(dtrend(RR_PM25_deaths, False))

end_cpu_time = get_cpu_time()
print(get_script_prefix_name() + ": elapsed time = " + (end_cpu_time-start_cpu_time) + " seconds.")

end
