;*******************************************
; Written by Revathi Muralidharan on 3/11/22 
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
 
 ;ZYQ, 03/14/22, FIND THE LON_2D & LAT_2D
 lat_2d_temp = sfile->LAT
 lon_2d_temp = sfile->LON
 lat_2d = lat_2d_temp(0, 0, :, :)
 lon_2d = lon_2d_temp(0, 0, :, :)

 dimslonlat = dimsizes(lon_2d)
 ;print(dimslonlat)
 ndims = dimsizes(dimslonlat)
 nlat = dimslonlat(ndims-2)  ;rows
 nlon = dimslonlat(ndims-1)  ;columns

 yrs1=2002
 yrs2=2017
 numY=yrs2-yrs1
 
 do Y=0, numY

 ;ZYQ, 03/14/22, ADD NEW VARIABLE TO SAVE THE O3 CONCENTRATION
 O3_SAVE = lat_2d ;HERE IS ASSIGN THE LAT_2D VALUES TO O3_SAVE, BUT I WILL REPLACE THEM LATER WITH THE VALUES WE READ FROM THE CSV FILES

  Year = yrs1+Y
  fname = "/nas/longleaf/home/revathi/chaq/revathi/FAQSD/ozone/ozone_orig_12km_grid_"+Year+".csv"
  
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

  ;loop over the data
  do n = 1, nlines-1
   
;   count = count + 1
   
   cols_temp(n-1) = tointeger(str_get_field(lines(n),1,delim))    ;save the data to start from index 0 
   rows_temp(n-1)      = tointeger(str_get_field(lines(n),2,delim))    ;remember that the Column here starts from 1
   ;lats_temp(n-1)         = tofloat(str_get_field(lines(n),3,delim))    ;remember that the Lats here starts from 1
   ;lons_temp(n-1)   = tofloat(str_get_field(lines(n),4,delim))
   ;gridcells_temp(n-1) = tostring(str_get_field(lines(n),5,delim))
   ;o3_temp(n-1) = tofloat(str_get_field(lines(n),6,delim))
;   print( tofloat(str_get_field(lines(n),6,delim)))

   ;ZYQ, 03/14/22, NOTE HERE THAT I AM PRETTY POSITIVE THE COL AND ROW STANDS FOR THE SAME ORDER FOR THE LAT2D LON2D
    O3_SAVE(rows_temp(n-1)-1, cols_temp(n-1)-1) = tofloat(str_get_field(lines(n),6,delim)) 

  ;end loop for reading the data
  end do
  
  ;cols = cols_temp(0:count-1)
  ;rows = rows_temp(0:count-1)
  ;lats = lats_temp(0:count-1)
  ;lons = lons_temp(0:count-1)
  ;gridcells = gridcells_temp(0:count-1)
  ;o3 = o3_temp(0:count-1)
   ;ZYQ, 03/14/222
   o3 = O3_SAVE
  print(dimsizes(o3))
 
  ;loop over the rows from the FAQSD file - each row represents one unique grid cell
  ; Define a new 2D array to put the ozone concentration data
  ;pops_gridcell = new((/nages, nlat, nlon/), float)
  n1 = 459
  n2 = 299
  o3_new = o3;new((/n1, n2/),float)
  lats_new = lat_2d; new((/n1, n2/),float)
  lons_new = lon_2d; new((/n1, n2/),float)
;  cols_new = new((/n1, n2/),float)
;  rows_new = new((/n1, n2/),float)
;  do C = 0, 458
;   ;find the cols and rows in the surrogate file; remember that it starts from 1
;   temp_col = cols(C)
;   do R = 0, 298
;    temp_row = rows(R)
;    ; O3 needs to be read in from 0,0 to 459,299
;    temp_o3 = o3(C*R)
;    temp_lat = lats(C*R)
;    temp_lon = lons(C*R)
;;    o3_new(C,R)=temp_o3
;    lats_new(C,R) = temp_lat
;    lons_new(C,R) = temp_lon
;    cols_new(C,R) = temp_col
;    rows_new(C,R) = temp_rpw
    ;print(dimsizes(o3_new))
;   end do ;end loop for row
   
;  end do ;end loop for col
  
  o3_new@_FillValue = 0.
 
  print(dimsizes(o3_new))
 
  ;save the data into netcdf file
  outfile = "/nas/longleaf/home/revathi/chaq/revathi/FAQSD/ozone/processed/ozone_processed_12km_grid_"+Year+".nc"
  ;outfile = "ozone_processed_12km_grid_"+Year+".nc"
  print(outfile)
  system("rm -f "+outfile)
  outf = addfile(outfile,"c")
  setfileoption(outf,"DefineMode",True)
  
  outf@title         = "NCL Efficient Approach to netCDF Creation"
  outf@source_file   =  fname
  outf@creation_date = systemfunc ("date")
  outf@long_name     = "Created by Revathi Muralidharan using the EPA Runs at 12kmx12km finished by Adam Reff"
  
  ;ZYQ, 03/14/222
  ;Define dimensions:
  dim_names = (/"south_north","west_east"/)
  dim_sizes = (/nlat, nlon/)
  dim_unlimited = (/False,False/)
 
  print("Defining dimension sizes to be " + dim_sizes)
  filedimdef(outf,dim_names,dim_sizes,dim_unlimited)
  
  ;Define file variables
  ;Define file variables
  filevardef(outf,"ROW","float",(/"south_north","west_east"/))
  filevardef(outf,"COL","float",(/"south_north","west_east"/))
  
  filevardef(outf,"O3","float",(/"south_north","west_east"/))
;  filevardef(outf,"Lats","float",(/"ROW","COL"/))
;  filevardef(outf,"Lons","float",(/"ROW","COL"/))
  
  ;ozone
  o3atts = True
  o3atts@long_name = "MDA8 ozone concentrations in parts per billion"
  filevarattdef(outf,"O3",o3atts)
  
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
  
  outf->O3 = (/o3_new/) ;;(/tointeger(o3_new)/)
  print(dimsizes(lats_new))
  print(dimsizes(lons_new))

  outf->ROW = (/lats_new/)
  outf->COL = (/lons_new/)
;  outf->Lats = (/lats_new/)
;  outf->Lons = (/lons_new/)
  
  delete([/O3_SAVE, lines, nlines, o3_new, lats_new, lons_new/])
 ;end loop for the Year 
 end do

;end_cpu_time = get_cpu_time()
;print(get_script_prefix_name() + ": elapsed time = " + (end_cpu_time-start_cpu_time) + " seconds.")

end

