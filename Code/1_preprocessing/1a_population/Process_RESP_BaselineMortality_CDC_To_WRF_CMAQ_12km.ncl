;*******************************************
; Written by Yuqiang Zhang, US EPA 10, 2016 
;
; Concepts illustrated:
;   - part1, read the population surrogate data 
;   - part2, using the population fractions between county/grid cell, and apply that to the CDC_WONDER data
;********************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;load ".hluresfile"

begin
 start_cpu_time = get_cpu_time()     ; We will time this example

;surrogate_file = "/work/MOD3EVAL/css/DOE_20years/emis/36km_new/USA_100_NOFILL.txt"
surrogate_file = "/nas/longleaf/home/revathi/HAQAST/thesis/population/USA_100_NOFILL_12km.txt"

print(surrogate_file)
;Column 1 has the surrogate number (100)
;Column 2 has the state/county FIPS code
;Column 3 has the grid column number for the 36km grid
;Column 4 has the grid row number for the 36km grid
;Column 5 has the fraction of the total population of the county indicated by column 2 in the grid cell indicated by columns 3 and 4
;Column 6 (after the ! comment sign) has the total population from this county that is in this grid cell 
;Column 7 has the county total population for this county
;Column 8 provides a cumulative sum of the fractions from column 5 for a given county for QA purposes

;For example, looking at the first six data lines you see that the total population for county 01001 is 43671 and that it is distributed between grid cells (103/36), (104/36), (103/37), (104/37), (103/38) and (104/38) with ratios of 0.00173, 0.00006, 0.12435, 0.832451, 0.00798, and 0.03342.


;read the csv files
lines = asciiread(surrogate_file, -1, "string")
delim = "	"
nlines = dimsizes(lines)
print(nlines)
print(lines(26))  ;first data starts from line 23
print(lines(nlines-1)) ;last data 

countys_code_temp = new(nlines-1,integer)
columns_temp = new(nlines-1, integer)
rows_temp    = new(nlines-1, integer)
pops_fracs_temp  = new(nlines-1, float)  ;fraction of the total population of the county indicated by column 2 in the grid cell indicated by columns 3 and 4
pops_county2gridcell_temp = new(nlines-1, float)

pops_county_total_temp = new(nlines-1, integer)
qa_fracs_temp  = new(nlines-1, float) 

count = 0
;loop over the data
do n = 26, nlines-1

 count = count + 1

 countys_code_temp(n-26) = tointeger(str_get_field(lines(n),2,delim))    ;save the data to start from index 0 
 columns_temp(n-26)      = tointeger(str_get_field(lines(n),3,delim))    ;remember that the Column here starts from 1
 rows_temp(n-26)         = tointeger(str_get_field(lines(n),4,delim))    ;remember that the Row here starts from 1
 pops_fracs_temp(n-26)   = tofloat(str_get_field(lines(n),5,delim))
 pops_county2gridcell_temp(n-26) = tofloat(str_get_field(lines(n),7,delim))
 
 temp = tofloat(str_get_field(lines(n),9,delim))
 qa_fracs_temp(n-26)     = temp
 
 if (temp .eq. 1.) then 
   pops_county_total_temp(n-26) = tointeger(str_get_field(lines(n),8,delim))   ;save the population
 else 
   pops_county_total_temp(n-26) = 0 
 end if

;end loop for reading the data
end do

print(countys_code_temp(0:9))
print(columns_temp(count-10:count-1))
print(rows_temp(count-10:count-1))
print(pops_county_total_temp(count-10:count-1))
print(qa_fracs_temp(count-10:count-1))

countys_code = countys_code_temp(0:count-1)
columns = columns_temp(0:count-1)
rows = rows_temp(0:count-1)
pops_fracs = pops_fracs_temp(0:count-1)
pops_county2gridcell = pops_county2gridcell_temp(0:count-1)
pops_county_total=pops_county_total_temp(0:count-1)


print(count)
;find how many countyes we have for this year
index_countyes = ind(pops_county_total_temp .gt. 0)
countys_code_unique = countys_code_temp(index_countyes)
print("We have "+dimsizes(countys_code_unique)+ " for this year from the surrogate file")
print("We have "+sum(pops_county_total)+ " Population")

;read how many Columns and Rows for the WRF_CMAQ_36km

;lonlatfile = "/home/yzhang07/Scripts/Dry_Deposition_36km/GRIDCRO2D_us36_35L"
lonlatfile = "/nas/longleaf/home/revathi/HAQAST/thesis/mortality/CONUS12_444x336.ncf"
;lonlatfile="GRIDCRO2D_us36_35L"
flonlat = addfile(lonlatfile,"r")
lon2d_temp = flonlat->LON
lat2d_temp = flonlat->LAT
;printVarSummary(lon2d_temp)
lon2d = lon2d_temp(0,0,:,:)
lat2d = lat2d_temp(0,0,:,:)
;printVarSummary(lon2d)
;printVarSummary(lat2d)
dimslonlat = dimsizes(lon2d)
;print(dimslonlat)
ndims = dimsizes(dimslonlat)
nlat = dimslonlat(ndims-2)  ;rows
nlon = dimslonlat(ndims-1)  ;columns
;print(nlon)
;print(nlat)
delete(lines)

;step2, read the disease-specific county-level population and baseline mortality data
Dir = "/nas/longleaf/home/revathi/HAQAST/thesis/mortality/"
yrs1 = 2021
yrs2 = 2021
numY = yrs2-yrs1

diseases = (/"RESP"/)

do D = 0, dimsizes(diseases)-1

do Y =  0, numY

;define new arrays to put the grid cell pops, deaths, and baseline mortality rates
pops_gridcell = new((/nlat, nlon/), float)
deaths_gridcell = new((/nlat, nlon/),float)
mrates_gridcell = new((/nlat, nlon/),float)

pops_gridcell = 0.
deaths_gridcell = 0.
mrates_gridcell = 0.

Year = yrs1 + Y
;Year = 1990

Filename = Dir + "CDC_RESP_Processed/Processed_"+ diseases(D)+"_CDC_"+Year+"_NEW.csv"
print(Filename)
;read the csv files
lines = asciiread(Filename, -1, "string")
delim = ","
nlines = dimsizes(lines)

;print(lines(nlines-1))
countys_code_yz =   new(nlines-1,integer)
countys_pops_yz =   new(nlines-1,integer)
countys_mrates_yz = new(nlines-1,float)

count_yz = 0
;loop over the data
do n = 0, nlines-2
  count_yz = count_yz + 1
  countys_code_yz(n) = tointeger(str_get_field(lines(n+1),3,delim))
  countys_pops_yz(n) = tointeger(str_get_field(lines(n+1),4,delim))
  countys_mrates_yz(n) = tofloat(str_get_field(lines(n+1),5,delim))
end do

 print("We have "+count_yz+ " counties in the county-level baseline mortality files created by YZ")

 ;check errors
 if (countys_code_yz(count_yz-1) .ne. 56045) then 
   print("We have errors in reading the county-level baseline mortality files created by YZ")
   ;exit
 end if

;loop over the counties from the surrogate file
 do C = 0, dimsizes(countys_code)-1 
  ;find the index of county in the YZ file
  index_yz = ind(countys_code_yz .eq. countys_code(C)) 
  ;print(countys_code(C))
  ;print(index_yz)

 if (.not. all(ismissing(index_yz))) then
 
  ;find the pops and mrates for that county
  pops_yz = countys_pops_yz(index_yz)
  mrates_yz = countys_mrates_yz(index_yz)
  deaths_yz = pops_yz * 1.0 * mrates_yz   ;deaths = populations * rates 

  ;find the cols and rows in the surrogate file; remember that it starts from 1
  temp_col = columns(C)
  temp_row = rows(C) 
  temp_pops_fracs = pops_fracs(C)
  ;print(temp_pops_fracs) 
  ;print(temp_col)
  ;print(temp_row)
  ;print(pops_yz)
  ;print(mrates_yz)
  ;print(deaths_yz)

  ;so for this grid cell, the population should be 
  pops_gridcell(temp_row-1, temp_col-1) = pops_gridcell(temp_row-1, temp_col-1) + pops_yz * 1.0 * temp_pops_fracs
  deaths_gridcell(temp_row-1, temp_col-1) = deaths_gridcell(temp_row-1, temp_col-1) + deaths_yz * 1.0 * temp_pops_fracs 

 end if

 ;end loop for the counties from the surrogate file
 end do

;calulte the mrates after we add the pops & deaths for each grid cell
 pops_gridcell@_FillValue = 0.
 deaths_gridcell@_FillValue = 0.
 mrates_gridcell = deaths_gridcell/1.0/pops_gridcell

 print("============================================================================================================")
 print("============================================================================================================")
 print("For the Year of "+Year )
 
 frac_pop = sum(pops_gridcell)/sum(countys_pops_yz)
 print("Before and After regrid Population fracion "+ frac_pop)
  if (frac_pop .lt. 0.95) then 
   print("We should stop to check as We have very large population differences")
   exit
  end if 
 print("We have "+sum(countys_pops_yz)+ " Population from sums of countyes")
 print("We have "+sum(pops_gridcell) + " Population from sums of grid cells")

 ;zyq, 11/15/16, save the pops/deaths/mrates data into netcdf file
  outfile = Dir + "CDC_RESP_Regridded/CDC_RESP_12km_" + Year + ".nc" 
  print(outfile)
  system("rm -f "+outfile)
  outf = addfile(outfile,"c")
  setfileoption(outf,"DefineMode",True)

  outf@title         = "NCL Efficient Approach to netCDF Creation"
  outf@source_file   =  Filename
  outf@creation_date = systemfunc ("date")
  outf@long_name     = "Create by Yuqiang Zhang using the DOE Runs at 36kmx36km finished by Jia and Meei"

  ;Define dimensions:
  dim_names = (/"south_north","west_east"/)
  dim_sizes = (/nlat, nlon/)
  dim_unlimited = (/False,False/)

  print("Defining dimension sizes to be " + dim_sizes)
  filedimdef(outf,dim_names,dim_sizes,dim_unlimited)
  
  ;Define file variables
  filevardef(outf,"ROW","float",(/"south_north","west_east"/))
  filevardef(outf,"COL","float",(/"south_north","west_east"/))

  filevardef(outf,"Pops","float",(/"south_north","west_east"/))
  filevardef(outf,"Deaths","float",(/"south_north","west_east"/))
  filevardef(outf,"Mrates","float",(/"south_north","west_east"/))

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

  ;Pops
  Popsatts = True
  Popsatts@long_name = "Population at grid cell, integrated from county; >25+ "
  filevarattdef(outf,"Pops",Popsatts)

  ;Deaths
  Deathsatts = True
  Deathsatts@long_name = "Disease-specific deaths at grid cell, integrated from county; >25+ "
  filevarattdef(outf,"Deaths",Deathsatts)

 ;Mrates
  Mratesatts = True
  Mratesatts@long_name = "Disease-specific mortality rates at grid cell, integrated from county; >25+ "
  filevarattdef(outf,"Mrates",Mratesatts)

  outf->ROW = (/lat2d/)
  outf->COL = (/lon2d/)
  outf->Pops = (/pops_gridcell/)
  outf->Deaths = (/deaths_gridcell/)
  outf->Mrates = (/mrates_gridcell/)

delete([/lines, nlines, countys_code_yz, countys_pops_yz, countys_mrates_yz, pops_gridcell, deaths_gridcell, mrates_gridcell/])
;end loop for the Year 
end do

;end loop for the diseases
end do

 end_cpu_time = get_cpu_time()
 print(get_script_prefix_name() + ": elapsed time = " + (end_cpu_time-start_cpu_time) + " seconds.")

end
