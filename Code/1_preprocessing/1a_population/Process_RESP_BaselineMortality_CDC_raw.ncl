;*******************************************
; Written by Yuqiang Zhang, US EPA 10, 2016 
;
; Concepts illustrated:
;   - part1, read the data from CDC baseline mortality data 
;   - part2, replace the missing/suppressed data into zero
;   - part3, process the death counts less than 20 over one county as unrealizable 
;       1) Calculate the total mortality over the state, and if the total deaths are larger than 20, then divided by the total populations over these counties which have less than 20 deaths
;       2) If still less than 20, then calculate the total deaths over the regions (See BenMAP or CDC-WONDER webs for the region definition) 
;       3) If still less than 20, then calculate the total deaths over US
;    - part4, output the variable into new CVS file
;
;********************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;load ".hluresfile"

begin
 start_cpu_time = get_cpu_time()     ; We will time this example
 
 ;step1, read the data
;Dir = "$MORTALITY/"
Dir = "/nas/longleaf/home/revathi/HAQAST/thesis/mortality/"

yrs1 = 1990
yrs2 = 2020
numY = yrs2-yrs1

diseases = (/"RESP"/)

;zyq, 03/17/2017, add the ratios between ICD9 & ICD10 for data from 1998
;refer the paper published by CDC in 2001 & 2003
;ratios = new((/3,numY+1/),float)
;ratios(:,:) = 1.

;for LC
;ratios(0,0:8) = 0.984

;for COPD
;ratios(1,0:8) = 1.056

;for RESP
;ratios(0,0:8) = 1.046 
ratios = 0.8556

do D = 0, dimsizes(diseases)-1

;02/28/2017, define total_deaths_21years
total_deaths_21years = new(numY+1, float)
total_pops_21years = new(numY+1, float)

do Y =  0, numY

Year = yrs1 + Y
;Year = 1990

Filename = Dir + "CDC_RESP_Processed/Processed_"+ diseases(D)+"_CDC_"+Year+".csv"
print(Filename)
;read the csv files
lines = asciiread(Filename, -1, "string")
delim = ","
nlines = dimsizes(lines)
;print(nlines)
;print(lines(1))
;print(lines(nlines-1))

states_name_temp  = new(nlines-1,string)
states_code_temp  = new(nlines-1,integer)
countys_code_temp = new(nlines-1,integer)
deaths_temp = new(nlines-1, integer)
pops_temp   = new(nlines-1, integer)

count = 0
;loop over the data
do n = 0, nlines-2
 temp = tointeger(str_get_field(lines(n+1),5,delim))

  ;get the state, county, county code, deaths, population 
  count = count + 1
  states_name_temp(n) = (str_get_field(lines(n+1),1,delim))
  states_code_temp(n) = tointeger(str_get_field(lines(n+1),2,delim))
  countys_code_temp(n) = tointeger(str_get_field(lines(n+1),5,delim))

  ;for Suppressed mortality rates and Missing mortality and population
  temp1 = str_get_field(lines(n+1),8,delim)
   if (temp1 .eq. "Suppressed" .or. temp1 .eq. "Missing") then 
    deaths_temp(n) = 0
   else  
    deaths_temp(n) = tointeger(str_get_field(lines(n+1),8,delim))
   end if

  ;for Missing populations
  temp2 = str_get_field(lines(n+1),9,delim)
  if ((temp2 .eq. "Missing") .or. (temp2 .eq. "Suppressed")) then 
    pops_temp(n) = 0
  else 
    pops_temp (n) = tointeger(str_get_field(lines(n+1),9,delim))
  end if

 ;for last county, Weston County, Wyoming
 if (temp .eq. 56045) then 
  break   ;jump out the loop
 end if 

end do

print("The total deaths from the Raw data for the year "+Year+ " "+sum(deaths_temp))
print("The total deaths from the Raw data for the year "+Year+ " after the ratios "+sum(deaths_temp)*ratios)
print("The total population from the Raw data for the year "+Year + " "+sum(pops_temp))
total_deaths_21years(Y) = sum(deaths_temp)
total_pops_21years(Y) = sum(pops_temp)

;print(count)
;print(deaths_temp(count-1))
;print(pops_temp(count-1))
;index_sta = ind (state_temp .gt. 0)
;print(dimsizes(index_sta))
;print(countys_temp(count-1))
;these are the variables that are need to output to new csv files
states_name = states_name_temp(0:count-1)
states_code = states_code_temp(0:count-1)
countys_code = countys_code_temp(0:count-1)
deaths =  deaths_temp(0:count-1)
pops   =  pops_temp(0:count-1)
mrates = pops*0.0

;zyq stop here, 10/11/16
regions_northeast = (/"Maine", "New Hampshire", "Vermont", "Massachusetts", "Rhode Island", "Connecticut", "New York", "New Jersey", "Pennsylvania"/)

regions_midwest = (/"Ohio", "Indiana", "Illinois", "Michigan", "Wisconsin","Minnesota", "Iowa", "Missouri", "North Dakota", "South Dakota", "Nebraska", "Kansas"/)

regions_south = (/"Delaware", "Maryland", "District of Columbia", "Virginia", "West Virginia", "North Carolina", "South Carolina", "Georgia", "Florida", "Kentucky", "Tennessee", "Alabama", "Mississippi", "Arkansas","Louisiana", "Oklahoma", "Texas"/)
regions_west = (/"Montana", "Idaho", "Wyoming", "Colorado", "New Mexico", "Arizona", "Utah", "Nevada","Washington", "Oregon", "California", "Alaska", "Hawaii"/)
print(dimsizes(regions_northeast)+dimsizes(regions_midwest)+dimsizes(regions_west)+dimsizes(regions_south))

usstates = new(51, string)

;index_states = get_unique_values(states_code)
;print(index_states)

;print(deaths(0:10))
;print(pops(0:10))
;print(mrates(0:10))
index_states = 0
 do C = 0, count-1
   if (C .eq. 0) then 
    usstates(index_states) = states_name(C)
    index_states = index_states + 1 
   else 
     if (states_name(C) .ne. usstates(index_states-1)) then 
         usstates(index_states) = states_name(C)
         index_states = index_states + 1
     else 
         ;just do nothing
     end if
   end if
 ;end loop for the states finding
 end do

;print(index_states)
;print(usstates)

;zyq, 10/12/16, find the indexes for the regions
regions_index = states_name

;for northeast
do R = 0, dimsizes(regions_northeast)-1
  index_regional = ind((states_name .eq. regions_northeast(R)))
  regions_index(index_regional) = "northeast"
  delete(index_regional)
end do

;for midwest
do R = 0, dimsizes(regions_midwest)-1
  index_regional = ind((states_name .eq. regions_midwest(R)))
  regions_index(index_regional) = "midwest"
  delete(index_regional)
end do

;for south
do R = 0, dimsizes(regions_south)-1
  index_regional = ind((states_name .eq. regions_south(R)))
  regions_index(index_regional) = "south"
  delete(index_regional)
end do

;for west
do R = 0, dimsizes(regions_west)-1
  index_regional = ind((states_name .eq. regions_west(R)))
  regions_index(index_regional) = "west"
  delete(index_regional)
end do
;print(regions_index)

print("for last time step, we have "+states_code(count-1) + " "+countys_code(count-1)+ ";  "+ " deaths are "+ deaths(count-1)+ " with pop "+ pops(count-1))
print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
index_20 = ind(deaths .ge. 20)

;step a) get the mortality rates for counties with death counts above 20
mrates (index_20) = deaths(index_20)*1.0/pops(index_20)
;print(mrates(0:10))

frac = dimsizes(index_20)*1.0/count
print("For Year "+ Year + " we have " + count + " counties")
print("We have "+dimsizes(index_20)+ " counties with deaths greater than 20; total fraction of "+frac)

delete(index_20)

;use this to calculate how many counties we have that didn't pass the State aggregate method
count_failure1 = 0

;step b) get the mortality rates for counties with death counts less 20; Begin with states aggregate
 ;loop over the states
  do S = 0, dimsizes(usstates)-1 

  print("We are working in the States "+ usstates(S))    

  ;get the right mortality rates
  index_20 = ind((deaths .lt. 20) .and. (states_name .eq. usstates(S)) )

  ;We focus on the counties with 20 only
 if (.not. all(ismissing(index_20))) then
  ;print("for counties with less than 20 " + deaths(index_20))
  ;print(pops(index_20))

   state_deaths = sum(deaths(index_20))
   state_pops   = sum(pops(index_20))
   if (state_deaths .ge. 20) then 
     mrates (index_20) =  state_deaths*1.0/state_pops 
   else 
     print("===========================================================================================================")
     print("===========================================================================================================")
     print("We have "+dimsizes(index_20)+" counties didn't pass the first State criteria in State of " + usstates(S))     
     count_failure1 = count_failure1 + dimsizes(index_20)
   end if 

 end if 
  delete(index_20)

  ;end loop for the states
  end do 

 index_20 = ind(mrates .gt. 0)
 frac = dimsizes(index_20)*1.0/count
 print("For Year "+ Year +" " + dimsizes(index_20)+ " counties AFTER WE AGGREGATE BY STATES")
 print("We have "+dimsizes(index_20)+ " with deaths greater than 20; total fraction of "+frac)
 print("We have "+sum(pops)+ " Population in US")
 print("We have "+ count_failure1+ " counties left to be processed to use the Regional average")

 ;final check up;
 if (frac .le. 0.95) then 
 print("We have to jump out the script to add extra steps to count for counties have deaths less than 20")
 exit
 end if

 delete(index_20)

 ;use this to calculate how many counties we have that didn't pass the Regional aggregate method
 count_failure2 = 0

 ; step c, we group them by regions:Northeast, Midwest, South and West; See BenMAP_CE, Table D-1 
 regions_name = (/"northeast", "midwest", "south", "west"/)
 do R = 0, dimsizes(regions_name)-1
  print("We are working in the Regional "+ regions_name(R))

   ;get the right mortality rates
   index_20 = ind((deaths .lt. 20) .and. (mrates .eq. 0) .and. (regions_index .eq. regions_name(R)) )

   ;We focus on the counties with 20 only
  if (.not. all(ismissing(index_20))) then 
   ;print("for counties with less than 20 " + deaths(index_20))
   ;print(pops(index_20))

    regions_deaths = sum(deaths(index_20))
    regions_pops   = sum(pops(index_20))
    if (regions_deaths .ge. 20) then
      mrates (index_20) =  regions_deaths*1.0/regions_pops
    else
     print("===========================================================================================================")
     print("===========================================================================================================")
     print("We have "+dimsizes(index_20)+" counties didn't pass the Second Regional criteria in Regions " + regions_name(R))
     count_failure2 = count_failure2 + dimsizes(index_20)
   end if

  end if
  delete(index_20)
 ;end loop for the regions aggregation
 end do

index_20 = ind(mrates .gt. 0)
frac = dimsizes(index_20)*1.0/count
print("For Year "+ Year +" " + dimsizes(index_20)+ " counties AFTER WE AGGREGATE BY REGIONS")
print("We have "+dimsizes(index_20)+ " with deaths greater than 20; total fraction of "+frac)
print("We have "+sum(pops)+ " Population in US in the Year "+Year)
print("We have "+ count_failure2+ " counties left to be processed to use the National average")
delete(index_20)

; step d, we add all the counties in the nation together
   index_20 = ind ((deaths .lt. 20) .and. (mrates .eq. 0))

if (.not. all(ismissing(index_20))) then 
   national_deaths = sum(deaths(index_20))
   national_pops   = sum(pops(index_20))

  if (national_deaths .ne. 0) then 
   mrates (index_20) =  national_deaths*1.0/national_pops
   print("We have "+dimsizes(index_20)+" counties used for the Third  National criteria ")
  else 
    index_not_zero = ind (mrates .gt. 0)
    mrates (index_20) = avg(mrates(index_not_zero))
    delete(index_not_zero)
    print("......................................................................" + mrates(index_20))
  end if
end if 

delete(index_20)

;zyq, 03/17/2017, use the ratios between ICD9 & ICD10
;mrates = mrates*ratios(D, Y)
mrates = mrates*ratios

;part 4, output into new csv file
;file_o = Dir + "CDC_Mortality_Data/" + diseases(D)+ "/Processed_"+ diseases(D)+"_CDC_"+Year+".csv" 
file_o = Dir + "CDC_RESP_Regridded/CDC_"+ diseases(D)+"_12km_"+Year+".csv"

if (fileexists(file_o)) then  
  system("/bin/rm -r " + file_o)
end if

firstline = (/"State, State Code, County Code, Population, Mortality Rates, Deaths"/)
write_table (file_o, "w", [/firstline/], "%s")

write_table (file_o, "a", [/states_name, states_code, countys_code, pops, mrates, pops*mrates/], "%s,%i,%i,%i,%2.10f, %8.f")

delete([/lines, states_name_temp, states_code_temp, countys_code_temp, deaths_temp, pops_temp, states_name, states_code, countys_code, deaths, pops, mrates, regions_index/])

system("/bin/mv " + file_o +" "+ Dir + "CDC_Mortality_Data/" + diseases(D))

;end loop for the Year
end do

print("Note that the data printed below are adjusted by the ratios between ICD9 & ICD 10")
 print("total population for the "+numY+" years above 25 yrs are "+ total_pops_21years)
 print("total deaths for the "+numY+" years are "+total_deaths_21years)
 print("total deaths for the "+numY+" years after the ratios are " + total_deaths_21years(:)*ratios)
 end_cpu_time = get_cpu_time()
 print(get_script_prefix_name() + ": elapsed time = " + (end_cpu_time-start_cpu_time) + " seconds.")

;end loop for the diseases
end do
end
