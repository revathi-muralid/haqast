;======================================================================
; linint2_Wrap
;
; Regrid 12kmx12km FAQSD 16-year fused dataset to 12kmx12km CONUS grid
;======================================================================
;No need to load these after 6.1.2
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

; must load the 'ESMF-regridding.ncl' library
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

; Loop through years from 2002 to 2017

start_year = 2002
end_year = 2017
nyears = start_year - end_year + 1
Y=0

do Y=0,15
	;---Data file containing source grid
 	;month="01"
 	path_srcgrd = "/nas/longleaf/home/revathi/chaq/revathi/FAQSD/"
 	src_file = "CONUS12_459x299"
 	sfile    = addfile(path_srcgrd+src_file,"r")
	
 	;---Get variable to regrid
	fn_o3 = "ozone/processed/ozone_processed_12km_grid_"+(start_year+Y)+".nc"
 
 	printVarSummary(fn_o3)	
 	f_o3 = addfile(path_srcgrd+fn_o3,"r")
 	var_name = "O3"           
 	var      = f_o3->$var_name$(:,:)            
 	src_lat  = sfile->LAT(0,0,:,:)                   
 	src_lon  = sfile->LON(0,0,:,:)                   

 	;---Data file containing destination grid
 	path_dstgrd   = "/nas/longleaf/home/revathi/chaq/revathi/"
 	dfile       = addfile(path_dstgrd+"CONUS12_444x336.ncf","r")
 	dst_lat  = dfile->LAT(0,0,:,:)                   
 	dst_lon  = dfile->LON(0,0,:,:)                  

 	;---Set up regridding options
 	Opt                   = True

 	;---"bilinear" is the default. "patch" and "conserve" are other options.
 	Opt@InterpMethod      = "conserve"        

 	Opt@WgtFileName       = "FAQSD_regrid_weights_O3.nc"  ; optional
	
	Opt@SrcGridLat        = src_lat           ; source grid
 	Opt@SrcGridLon        = src_lon
 	Opt@SrcRegional       = True              
 	Opt@SrcInputFileName  = src_file          ; optional, but good idea
 	;Opt@SrcMask2D         = where(.not.ismissing(var),1,0) ; Necessary if has
                                                           ; missing values.
	
 	Opt@DstGridLat        = dst_lat             ; destination grid
 	Opt@DstGridLon        = dst_lon
 	Opt@DstRegional       = True              ;;--Change (maybe)
 	Opt@DstMask2D = where(.not.ismissing(dst_lat).and.\
                          .not.ismissing(dst_lon),1,0) ; Necessary if lat/lon
                                                      ; has missing values.
 	Opt@ForceOverwrite    = True
 	Opt@PrintTimings      = True
 	Opt@Debug             = True

 	var_regrid = ESMF_regrid(var,Opt)     ; Do the regridding

 	;printVarSummary(var_regrid)

 	;----------------------------------------------------------------------
 	; Plotting section
 	;
 	; This section creates filled contour plots of both the original
 	; data and the regridded data, and panels them.
 	;----------------------------------------------------------------------
 	var@lat2d = src_lat     ; Needed for plotting.
 	var@lon2d = src_lon     ; var_regrid already has these
	
 	wks = gsn_open_wks("ps","curv_to_curv")
	
 	res                       = True
	
 	res@gsnMaximize           = True

 	res@gsnDraw               = False
 	res@gsnFrame              = False
	
 	res@cnFillOn              = True
 	res@cnLinesOn             = False
 	res@cnLineLabelsOn        = False
 	res@cnFillMode            = "RasterFill"

 	res@lbLabelBarOn          = False    ; Turn on later in panel

 	res@mpMinLatF             = min(dst_lat)
 	res@mpMaxLatF             = max(dst_lat)
 	res@mpMinLonF             = min(dst_lon)
 	res@mpMaxLonF             = max(dst_lon)

 	mnmxint = nice_mnmxintvl( min(var), max(var), 18, False)
 	res@cnLevelSelectionMode = "ManualLevels"
 	res@cnMinLevelValF       = mnmxint(0)
 	res@cnMaxLevelValF       = mnmxint(1)
 	res@cnLevelSpacingF      = mnmxint(2)

 	;---Resources for plotting regridded data
 	res@gsnAddCyclic = False            
 	res@tiMainString = "Curvilinear grid (" + Opt@InterpMethod + ")"

 	plot_regrid = gsn_csm_contour_map(wks,var_regrid,res)

 	;---Resources for plotting original data
 	res@gsnAddCyclic = False            
 	res@tiMainString = "Original curvilinear grid"

 	plot_orig = gsn_csm_contour_map(wks,var,res)  

 	;---Compare the plots in a panel
 	pres                   = True
 	pres@gsnMaximize       = True
 	pres@gsnPanelLabelBar  = True

 	gsn_panel(wks,(/plot_orig,plot_regrid/),(/2,1/),pres)
 	;----------------------------------------------------------------------
 	; Output file
 	;----------------------------------------------------------------------

        ofile = "/nas/longleaf/home/revathi/chaq/revathi/FAQSD/ozone/regridded/FAQSD_O3_Regridded_to_CONUS_12km_"+(start_year+Y)+".nc"

 	system("rm -f "+ofile) ;-- delete netCDF file if it exist
 	cdf_file = addfile(ofile,"c") ;-- create a new netCDF file
 	;-- lat2d and lon2d
 	;cdf_file->LAT = lat2d ;-- write lat2d to file
 	;cdf_file->LON = lon2d ;-- write lon2d to file
 	cdf_file->O3 = var_regrid ;-- write variable to file
end do
end