;*******************************************
; Written by Revathi Muralidharan on 3/12/22 
;
; Concepts illustrated:
;   - part1, read the FAQSD concentration data from csv files 
;   - part2, regrid from old grid to new grid
;********************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;load ".hluresfile"

begin
 ;start_cpu_time = get_cpu_time()     ; We will time this example

 ;---Data file containing source grid
 path_srcgrd = "/nas/longleaf/home/revathi/chaq/revathi/FAQSD/"
 src_file = "CONUS12_459x299"
 sfile    = addfile(path_srcgrd+src_file,"r")
 
 yrs1=2002
 yrs2=2017
 numY=yrs2-yrs1
 
 do Y=0, numY
  Year = yrs1+Y
  fname = "/nas/longleaf/home/revathi/chaq/revathi/FAQSD/pm25/pm25_orig_12km_grid_"+Year+".csv"
  
  print(fname)
  ;Column 1 has the grid column number for the orig 12km grid
  ;Column 2 has the grid row number for the orig 12km grid
  
  ;read the csv files
  lines = asciiread(fname, -1, "string")
  delim = ","
  nlines = dimsizes(lines)
  print(nlines)
  
  cols_temp = new(nlines-1,integer)
  rows_temp    = new(nlines-1, integer)
  lats_temp  = new(nlines-1, float)  ;fraction of the total population of the county indicated by column 2 in the grid cell indicated by columns 3 and 4
  lons_temp = new(nlines-1, float)
  ;gridcells_temp = new(nlines-1, string)
  pm25_temp = new(nlines-1, float)
  
  count = 0
  ;loop over the data
  do n = 1, nlines-1
   
   count = count + 1
   
   cols_temp(n-1) = tointeger(str_get_field(lines(n),1,delim))    ;save the data to start from index 0 
   rows_temp(n-1)      = tointeger(str_get_field(lines(n),2,delim))    ;remember that the Column here starts from 1
   lats_temp(n-1)         = tofloat(str_get_field(lines(n),3,delim))    ;remember that the Lats here starts from 1
   lons_temp(n-1)   = tofloat(str_get_field(lines(n),4,delim))
   ;gridcells_temp(n-1) = tostring(str_get_field(lines(n),5,delim))
   pm25_temp(n-1) = tofloat(str_get_field(lines(n),6,delim))
   
  ;end loop for reading the data
  end do
  
  cols = cols_temp(0:count-1)
  rows = rows_temp(0:count-1)
  lats = lats_temp(0:count-1)
  lons = lons_temp(0:count-1)
  ;gridcells = gridcells_temp(0:count-1)
  pm25 = pm25_temp(0:count-1)
  print(dimsizes(pm25))
 
  ;loop over the rows from the FAQSD file - each row represents one unique grid cell
  ; Define a new 2D array to put the PM2.5 concentration data
  ;pops_gridcell = new((/nages, nlat, nlon/), float)
  n1 = 459
  n2 = 299
  pm25_new = new((/n1, n2/),float)
  lats_new = new((/n1, n2/),float)
  lons_new = new((/n1, n2/),float)
  do C = 0, 458
   ;find the cols and rows in the surrogate file; remember that it starts from 1
   temp_col = cols(C)
   do R = 0, 298
    temp_row = rows(R)
    ; PM2.5 needs to be read in from 0,0 to 459,299
    temp_pm25 = pm25(C*R)
    temp_lat = lats(C*R)
    temp_lon = lons(C*R)
    pm25_new(C,R)=temp_pm25
    lats_new(C,R) = temp_lat
    lons_new(C,R) = temp_lon
    ;print(dimsizes(pm25_new))
   end do ;end loop for row
   
  end do ;end loop for col
  
  pm25_new@_FillValue = 0.
 
  print(dimsizes(pm25_new))
 
  ;save the data into netcdf file
  outfile = "/nas/longleaf/home/revathi/chaq/revathi/FAQSD/pm25/processed/pm25_processed_12km_grid_"+Year+".nc"
  print(outfile)
  system("rm -f "+outfile)
  outf = addfile(outfile,"c")
  setfileoption(outf,"DefineMode",True)
  
  outf@title         = "NCL Efficient Approach to netCDF Creation"
  outf@source_file   =  fname
  outf@creation_date = systemfunc ("date")
  outf@long_name     = "Created by Revathi Muralidharan using the EPA Runs at 12kmx12km finished by Adam Reff"
  
  ;Define dimensions:
  dim_names = (/"lat","lon"/)
  n1 = 459
  n2 = 299
  n3 = 137241
  dim_sizes = (/n1,n2/)
  dim_unlimited = (/False,False/)
 
  print("Defining dimension sizes to be " + dim_sizes)
  filedimdef(outf,dim_names,dim_sizes,dim_unlimited)
  
  ;Define file variables
  
  filevardef(outf,"PM25","float",(/"lat","lon"/))
  filevardef(outf,"Lats","float",(/"lat","lon"/))
  filevardef(outf,"Lons","float",(/"lat","lon"/))
  
  ;pm25
  pm25atts = True
  pm25atts@long_name = "Annual average PM2.5 concentrations in parts per billion"
  filevarattdef(outf,"PM25",pm25atts)
  
  ;lat
  latatts = True
  latatts@long_name = "Latitude"
  latatts@units = "degrees_north"
  filevarattdef(outf,"Lats",latatts)
  
  ;lon
  lonatts = True
  lonatts@long_name = "Longitude"
  lonatts@units = "degrees_east"
  filevarattdef(outf,"Lons",lonatts)
  
  outf->PM25 = (/tointeger(pm25_new)/)
  print(dimsizes(lats_new))
  print(dimsizes(lons_new))
  outf->Lats = (/lats_new/)
  outf->Lons = (/lons_new/)
  
  delete([/lines, nlines, pm25_new, lats_new, lons_new/])
 ;end loop for the Year 
 end do

;end_cpu_time = get_cpu_time()
;print(get_script_prefix_name() + ": elapsed time = " + (end_cpu_time-start_cpu_time) + " seconds.")

end

