;======================================================================
; linint2_Wrap
;
; Regrid 36kmx36km EPA CMAQ 21-year simulation dataset to 12kmx12km CONUS grid
;======================================================================
;No need to load these after 6.1.2
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

; must load the 'ESMF-regridding.ncl' library
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

begin

; Loop through years from 1990 to 2010

start_year = 1990
end_year = 2010
nyears = start_year - end_year + 1
Y=0

do Y=5,20
	do month=1,12
 		;---Data file containing source grid
 		;month="01"
 		path_srcgrd = "/nas/longleaf/home/revathi/chaq/revathi/EPA_21yr_CMAQ/"
 		src_file = "GRIDCRO2D_us36_35L"
 		sfile    = addfile(path_srcgrd+src_file,"r")
	
 		;---Get variable to regrid
		if (month.gt.9) then
			fn_pm25 = "NF_aconc/CCTM_DOE_36km_NF_RERUN_combine.aconc."+(start_year+Y)+(month)
		else
			fn_pm25 = "NF_aconc/CCTM_DOE_36km_NF_RERUN_combine.aconc."+(start_year+Y)+"0"+(month)
		end if
 
 		printVarSummary(fn_pm25)	
 		f_pm25 = addfile(path_srcgrd+fn_pm25,"r")
 		var_name = "PM25_TOT"           
 		var      = f_pm25->$var_name$(0,0,:,:)            
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

 		Opt@WgtFileName       = "CMAQ_regrid_weights.nc"  ; optional
	
		Opt@SrcGridLat        = src_lat           ; source grid
 		Opt@SrcGridLon        = src_lon
 		Opt@SrcRegional       = True              
 		Opt@SrcInputFileName  = src_file          ; optional, but good idea
 		Opt@SrcMask2D         = where(.not.ismissing(var),1,0) ; Necessary if has
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

		if (month.gt.9) then
                	ofile = "/nas/longleaf/home/revathi/chaq/revathi/EPA_21yr_CMAQ/NF_aconc/CMAQ_PM25_Regridded_36km_to_12km_"+(start_year+Y)+month+".nc"
		else
                	ofile = "/nas/longleaf/home/revathi/chaq/revathi/EPA_21yr_CMAQ/NF_aconc/CMAQ_PM25_Regridded_36km_to_12km_"+(start_year+Y)+"0"+month+".nc"
		end if 		

 		system("rm -f "+ofile) ;-- delete netCDF file if it exist
 		cdf_file = addfile(ofile,"c") ;-- create a new netCDF file
 		;-- lat2d and lon2d
 		;cdf_file->LAT = lat2d ;-- write lat2d to file
 		;cdf_file->LON = lon2d ;-- write lon2d to file
 		cdf_file->PM25 = var_regrid ;-- write variable to file
	end do
end do
end
