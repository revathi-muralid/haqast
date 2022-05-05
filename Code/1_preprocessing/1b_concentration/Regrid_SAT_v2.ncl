;======================================================================
; rgrid2rcm
;
; Regrid 1kmx1km WGS84 Dalhousie satellite dataset to 12kmx12km CONUS grid
;======================================================================
;No need to load these after 6.1.2
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

; must load the 'ESMF-regridding.ncl' library
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

; Loop through years from 2000 to 2018

start_year = 2000
end_year = 2018
nyears = start_year - end_year + 1
Y=1

;do Y=3,18
	;----------------------------------------------------------------------
	; Read source and destination grids, and variable to be regridded
	;----------------------------------------------------------------------
	
	;---Source grid is rectilinear (EDGAR)
	path_edgar = "/nas/longleaf/home/revathi/chaq/revathi/SAT_PM25_Dalhousie/"
	fn_pm25     = "V4NA03_PM25_NA_"+(start_year+Y)+"01_"+(start_year+Y)+"12-RH35.nc"
	printVarSummary(fn_pm25)
	f_pm25      = addfile(path_edgar+fn_pm25,"r")
	sfile      = f_pm25
	emi_pm25    = f_pm25->PM25
	yorig = f_pm25->LAT
	xorig = f_pm25->LON

	;---Destination grid is curvilinear (WRF)
	path_wrf   = "/nas/longleaf/home/revathi/chaq/revathi/"
	fwrf       = addfile(path_wrf+"CONUS12_444x336.ncf","r")
	lat2d      = fwrf->LAT(0,0,:,:)
	lon2d      = fwrf->LON(0,0,:,:)
	
	;----------------------------------------------------------------------
	; Regridding section
	;----------------------------------------------------------------------
	
	xgrd = rgrid2rcm_Wrap(yorig(::-1),xorig, emi_pm25(::-1,:), lat2d, lon2d, 1)
	
	;----------------------------------------------------------------------
	; Output file
	;----------------------------------------------------------------------
	ofile = "/nas/longleaf/home/revathi/chaq/revathi/SAT_PM25_Dalhousie/SAT_PM25_Regridded_WRF_1km_to_12km_"+(start_year+Y)+".nc"
	system("rm -f "+ofile) ;-- delete netCDF file if it exist
	cdf_file = addfile(ofile,"c") ;-- create a new netCDF file
	;-- lat2d and lon2d
	cdf_file->LAT = lat2d ;-- write lat2d to file
	cdf_file->LON = lon2d ;-- write lon2d to file
	cdf_file->PM25 = xgrd ;-- write variable to file
;end do
end
