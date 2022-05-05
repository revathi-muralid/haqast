;*******************************************
; Written by Yuqiang Zhang,US EPA 2016 
;
; Concepts illustrated:
;   - Plotting CMAQ data; also works for data using LCC project, like WRF and other RCM
;   - Drawing filled contours over a Lambert Conformal map
;   - Drawing U.S. states
;********************************************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"

;load ".hluresfile"
 
begin

;Step 1: read the 9 months with 6month ozone season 1hr-daily maximum 
;  dir1 = "/nas02/depts/ese/chaq/rasilva/ACCMIP/past/ozone/max6mon.ox/zyq_ACCMIP/"
 dir1 = "/home/yzhang07/Scripts/US_Mortality_Burden_36km/ACCMIP/ozone/"

  file1 = systemfunc (" ls -1 " + dir1 + "max6mon.ox/zyq_ACCMIP/"+"regrid"+"*"+"_acchist_6month_1850.05x05_annual_average.nc") 
  numFILES1 = dimsizes(file1)
  print("numFILES = " + numFILES1)
  print(file1)
  print (" ")

  f1 = addfiles(file1,"r")
  ListSetType (f1, "join") ; read multiple files 
  O3_9models_temp = f1[:]->ox1max1
  printVarSummary(O3_9models_temp)
  
  O3_9models = dim_avg_n_Wrap(O3_9models_temp, (/0/))
  printVarSummary(O3_9models)
 
  ;find the left 5 models with annual average
  file2 = systemfunc (" ls -1 " + dir1 + "annavg.ox/"+"annavg.ox."+"*"+"_acchist_1850.05x05.nc") 
  numFILES2 = dimsizes(file2)
  print("numFILES = " + numFILES2)
  print(file2)
  print (" ")

  f2 = addfiles(file2,"r")
  ListSetType (f2, "join") ; read multiple files 
  O3_5models_temp = f2[:]->ox1max1
  printVarSummary(O3_5models_temp)
  
;  O3_5models = dim_avg_n_Wrap(O3_5models_temp, (/0/))
;  printVarSummary(O3_5models)

  ;get the ratio= 6months of 1hr daily maximum/annual average
  file3 = systemfunc ( "ls -1 " + dir1 + "max6mon.ox/zyq_ACCMIP/" + "ratio_acchist_6month_1850_annual_average_9models.nc")
  numFILES3 = dimsizes(file3)
  print("numFILES = " + numFILES3)
  print(file3)
  print (" ")

  f3 = addfile(file3,"r")
  ratio = f3->ratio
  lats  = f3->lat
  lons  = f3->lon
  nlat = dimsizes(lats)
  nlon = dimsizes(lons) 
  printVarSummary(nlat)
  printVarSummary(nlon)
  printVarSummary(ratio)

  ;loop over the files
  do N = 0, numFILES2-1
   O3_5models_temp(N, :, :) = O3_5models_temp(N, :, :) * ratio(:, :) 
  end do

  ;calcualte the 5 models average
  O3_5models = dim_avg_n_Wrap(O3_5models_temp, (/0/))
  printVarSummary(O3_5models)

  ;append these 14 models together
  O3_total_temp = array_append_record(O3_9models_temp, O3_5models_temp, 0)
  printVarSummary(O3_total_temp)
  
  O3_14models_avg = dim_avg_n_Wrap(O3_total_temp, (/0/)) 
  O3_14models_std = dim_stddev_n_Wrap(O3_total_temp, (/0/))
  O3_14models_cv  = O3_14models_std/O3_14models_avg 
  print("Min and Max for std before regrid ")
  printMinMax(O3_14models_std, True)

  copy_VarCoords(O3_9models, O3_14models_avg)
  
  printVarSummary(O3_14models_avg) ; optional, prints out array info 
  printVarSummary(O3_14models_avg&lat) ; optional 
  printVarSummary(O3_14models_avg&lon) ; optional "

   ;read the MCIP file and the 2D lon&lat for the dst file
   lonlatfile = "/home/yzhang07/Scripts/Dry_Deposition_36km/GRIDCRO2D_us36_35L"
   flonlat = addfile(lonlatfile,"r")
   lon2d_temp := flonlat->LON
   lat2d_temp := flonlat->LAT
   printVarSummary(lon2d_temp)
   lon2d_dst = lon2d_temp(0,0,:,:)
   lat2d_dst = lat2d_temp(0,0,:,:)
   printVarSummary(lon2d_dst)
   printVarSummary(lat2d_dst)
   
  ;get the dimensions
   dims_dst=dimsizes(lon2d_dst)                            ; get dimensions
   print(dims_dst)
   ndims = dimsizes(dims_dst)
   nlon_dst=dims_dst(ndims-1)                                ; assign # lat/lon points
   nlat_dst=dims_dst(ndims-2)
   print(nlon_dst)
   print(nlat_dst)

   ;get the source lon&lat
   src_lat = lats
   src_lon = lons
   dst_lat2d       = lat2d_dst
   dst_lon2d       = lon2d_dst

 
    ;---Set up regridding options
    method = "bilinear"

    Opt                   = True
    ;---"bilinear" is the default. "patch" and "conserve" are other options.
    Opt@SrcFileName     = "Global_lon_lat_2_CMAQ_36km.nc" ;Do NOT set this to the original file that contains your data! This is the name of the *new* source description file that will get written.

    Opt@ForceOverwrite  =  True
    Opt@SrcTitle        = "Global lon&lat 720x360"          ; Optional, but good idea
    Opt@SrcRegional     = True
    Opt@SrcGridLat      = src_lat            ; source grid
    Opt@SrcGridLon      = src_lon
    Opt@DstGridLat      = dst_lat2d
    Opt@DstGridLon      = dst_lon2d
    Opt@DstFileName     = "CCTM_combine.aconc.1km.DstFileName.nc";Do NOT set this to the original file that contains your data! This is the name of the *new* destination description file that will get written. 
    Opt@DstRegional     = True

;---Regrid using bilinear
    Opt@InterpMethod  = method
    Opt@WgtFileName   = "Global_05x0.5_to_36km."+method+".nc"   ; use subsequently

    O3_total_regrid          = ESMF_regrid(O3_total_temp,Opt)
    printVarSummary(O3_total_regrid)

    O3_14models_avg_regrid = dim_avg_n_Wrap(O3_total_regrid, (/0/))
    O3_14models_std_regrid= dim_stddev_n_Wrap(O3_total_regrid, (/0/))
    O3_14models_cv_regrid = O3_14models_std_regrid/O3_14models_avg_regrid

    copy_VarCoords(lon2d_dst, O3_14models_avg_regrid)
    copy_VarCoords(lon2d_dst, O3_14models_std_regrid)
    copy_VarCoords(lon2d_dst, O3_14models_cv_regrid)

;    O3_14models_avg_regrid = lonFlip(O3_14models_avg_regrid)
;    O3_14models_std_regrid = lonFlip(O3_14models_std_regrid)
;    O3_14models_cv_regrid  = lonFlip(O3_14models_cv_regrid)
    printVarSummary(O3_14models_cv_regrid)
    print("Min and Max for std after regrid ")
    printMinMax(O3_14models_std_regrid, True) 
 
; zyq, 11/16/16, this is the old options for the regridding
;    Opt@WgtFileName       = "rec_to_SMOKE_from_MCIP.nc"
;    Opt@SrcGridLat        = src_lat           ; source grid
;    Opt@SrcGridLon        = src_lon
;    Opt@SrcRegional       = False              ;;--Change (maybe)
;    Opt@SrcInputFileName  = src_file          ; optional, but good idea
;    Opt@SrcMask2D         = where(.not.ismissing(var_temp),1,0) ; Necessary if has  missing values.
;    Opt@DstGridLat        = dst_lat           ; destination grid
;    Opt@DstGridLon        = dst_lon
;    Opt@DstRegional       = True              ;;--Change (maybe)
;    Opt@ForceOverwrite    = True
;    Opt@PrintTimings      = True
;    Opt@Debug             = True

;********************************
; plot
;********************************
   wks = gsn_open_wks("pdf","./plots/Regrid_ACCMIP_1850_WRF_CMAQ_36km")          ; open a workstation
   plots = new(6, graphic)
   gsn_define_colormap(wks,"BlAqGrYeOrReVi200");(wks,"gui_default")  "BlAqGrYeOrRe" ; choose colormap

  ;to decide which kind of plots needed to draw for MZ4
  mzres                             = True
  mzres@cnLinesOn                   = False               ; default is true;False, no contour lines will appear in the contour plot
  mzres@cnLineLabelsOn              = False               ; turn off contour lines
  mzres@cnFillOn                    = True                ; color plot desired
  mzres@cnFillMode                  = "CellFill"
  mzres@gsnAddCyclic      = True            ; data already has cyclic point
  mzres@tmXBMajorOutwardLengthF = -0.00
  mzres@tmXBMinorOutwardLengthF = -0.00

  mzres@tmYLMajorOutwardLengthF = -0.00
  mzres@tmYRMajorOutwardLengthF = -0.00
  mzres@tmYLMinorOutwardLengthF = -0.00
  mzres@tmYRMinorOutwardLengthF = -0.00
  mzres@tmXBTickSpacingF = 60


;  mzres@mpGeophysicalLineColor = "Black"                   ; color of continental outlines
;  mzres@mpPerimOn              = True                      ; draw box around map
;  mzres@mpGridLineDashPattern  = 2                         ; lat/lon lines as dashed
;  mzres@mpGridLineColor        = "Black"                   ; GridLine color
;  mzres@mpOutlineBoundarySets  = "GeophysicalAndUSStates"   ; add state boundaries
;  mzres@mpUSStateLineColor     = "Black"                    ; make them red

;  mzres@tfDoNDCOverlay = True
;  mzres@pmTickMarkDisplayMode = "Always"                 ; turn on tickmarks
;  mzres@tmXTOn = False            ; turn off top   labels  
;  mzres@tmYROn = False             ; turn off right labels
;  mzres@tmXBOn = True            ; turn off bottom lables
;  mzres@tmYLOn = True            ; turn off left lables

  mzres@lbLabelBarOn           = True           ; turn off individual cb's  
  mzres@mpOutlineOn = True ; turn on continental outlines 
  mzres@mpOutlineBoundarySets = "National" ; add country boundaries
  mzres@mpFillOn = False

 ; panel plots
  mzres@gsnDraw                = False     ; do not draw
  mzres@gsnFrame               = False     ; do not advance frame

  mzres@cnLevelSelectionMode  = "ManualLevels"
  mzres@cnMinLevelValF     = 24
  mzres@cnMaxLevelValF     = 38
  mzres@cnLevelSpacingF    = 2
;  mzres@cnFillPalette      = "temp_diff_18lev"

;  mzres@mpLimitMode       = "Corners"            ; choose range of map
;  mzres@mpProjection        = "LambertConformal"
;  mzres@mpLambertParallel1F = 33
;  mzres@mpLambertParallel2F = 45
;  mzres@mpLambertMeridianF  = -97

;  mzres@mpLeftCornerLatF  = lat2d_dst(0,0) ; 22.36774
;  mzres@mpLeftCornerLonF  = lon2d_dst(0,0) ; -119.7271
;  mzres@mpRightCornerLatF = lat2d_dst(nlat_dst-1, nlon_dst-1) ;48.52279
;  mzres@mpRightCornerLonF = lon2d_dst(nlat_dst-1, nlon_dst-1) ;-64.05692

  ;zyq, 4/21/2015, created for the ACP paper
;  mzres@vpXF            = 0.1
;  mzres@vpWidthF        = 0.4
;  mzres@vpYF            = 0.8
;  mzres@vpHeightF       = 0.35

  print("-----------------------------------------------------")

  ;working on titles
  mzres@tiMainFont   = 25
  mzres@tiMainFontHeightF = 0.02

  ;for the average plot
  mzres@gsnLeftString = " "
  mzres@gsnRightString = " "
  mzres@tiMainString   = "14 models avg for 6months_1hrMax O~B~3~N~"
  plots(0) = gsn_csm_contour_map(wks,O3_14models_avg,mzres)

  ;for the std plot
   mzres@cnMinLevelValF     := 0
   mzres@cnMaxLevelValF     := 8
   mzres@cnLevelSpacingF    := 0.8
   mzres@tiMainString   = "14 models std for 6months_1hrMax O~B~3~N~"
   plots(1) = gsn_csm_contour_map(wks,O3_14models_std,mzres)

  ;for the cv plot
   mzres@cnMinLevelValF     := 0
   mzres@cnMaxLevelValF     := 0.2
   mzres@cnLevelSpacingF    := 0.02
   mzres@tiMainString   = "14 models cv for 6months_1hrMax O~B~3~N~"
   plots(2) = gsn_csm_contour_map(wks,O3_14models_cv,mzres)

;==============================================
; create panel
;=============================================
   pres                         = True
   pres@gsnPanelRowSpec         = True      ;tell panel what order to plot
   pres@gsnPanelFigureStringsPerimOn = False
   gsn_panel (wks, plots(0:2), (/3, 1/), pres)
 
   ;add the U.S. average
   txid_tr = new(2,graphic)
   amid_tr = new(2,graphic)
   txres                       = True
   txres@txPerimOn             = False
   txres@txFontHeightF         = 0.02
   txres@txBackgroundFillColor = "White"
   ;---Top right string
   amres_tr                  = True
   amres_tr@amParallelPosF   =  0.40    ; This is the right edge of the plot.
   amres_tr@amOrthogonalPosF = -0.49    ; This is the top edge of the plot.
   amres_tr@amJust           = "TopRight"
   tr_label = "-2.46 ppb" ;"-3.71 ppb"
;   txid_tr(0) = gsn_create_text(wks, tr_label, txres)
;   amid_tr(0) = gsn_add_annotation(plots(0), txid_tr(0), amres_tr)
   
; to define the parameters that needed for the plotting for CMAQ
   res                 = True                    ; plot mods desired
   res@cnLinesOn       = False                   ; default is true;False, no contour lines will appear in the contour plot
   res@cnLineLabelsOn  = False                   ; turn off contour lines
   res@cnFillOn        = True                    ; color plot desired
   res@lbLabelBarOn           = True           ; turn off individual cb's  
   res@cnFillMode      = "CellFill"


; !!!!! any plot of data that is on a native grid, must use the "corners"
; method of zooming in on map.   
   res@mpLimitMode       = "Corners"            ; choose range of map

   ;zyq, 04/07/2015, narrow down the map for the ACP paper
   indexlat1 = 16
   indexlat2 = 25
   indexlon1 = 14
   indexlon2 = 15
   res@mpLeftCornerLatF  = lat2d_dst(0,0);(indexlat1,indexlon1)
   res@mpLeftCornerLonF  = lon2d_dst(0,0);(indexlat1,indexlon1)
   res@mpRightCornerLatF = lat2d_dst(nlat_dst-1,nlon_dst-1) ;(nlat_dst-indexlat2,nlon_dst-indexlon2)
   res@mpRightCornerLonF = lon2d_dst(nlat_dst-1,nlon_dst-1)  ;(nlat_dst-indexlat2,nlon_dst-indexlon2)
  
;   print(lat2d_dst(indexlat1,indexlon1))
;   print(lon2d_dst(indexlat1,indexlon1))
;   print(lat2d_dst(nlat_dst-indexlat2,nlon_dst-indexlon2))
;   print(lon2d_dst(nlat_dst-indexlat2,nlon_dst-indexlon2))

   print(lat2d_dst(0,0))
   print(lon2d_dst(0,0))
   print(lat2d_dst(nlat_dst-1,nlon_dst-1))
   print(lon2d_dst(nlat_dst-1,nlon_dst-1))

; The following 4 pieces of information are REQUIRED to properly display
; data on a native lambert conformal grid.  This data should be specified
; somewhere in the model itself.      
   res@mpProjection        = "LambertConformal"
   res@mpLambertParallel1F = 33
   res@mpLambertParallel2F = 45
   res@mpLambertMeridianF  = -97

   res@mpGeophysicalLineColor = "Black"                   ; color of continental outlines
   res@mpPerimOn              = True                    ; draw box around map
   res@mpGridLineDashPattern  = 2                       ; lat/lon lines as dashed
   res@mpGridLineColor        = "Black"                 ; GridLine color
   res@mpOutlineBoundarySets = "GeophysicalAndUSStates" ; add state boundaries
   res@mpUSStateLineColor    = "Black"                    ; make them red

; usually, when data is placed onto a map, it is TRANSFORMED to the specified
; projection. Since this model is already on a native lambert conformal grid,
; we want to turn OFF the tranformation.
   res@tfDoNDCOverlay = True
   res@pmTickMarkDisplayMode = "Always"                 ; turn on tickmarks
   res@tmXTOn = False            ; turn off top   labels 
   res@tmYROn = False             ; turn off right labels
   res@tmXBOn = True            ; turn off bottom lables
   res@tmYLOn = True            ; turn off left lables

; panel plots
  res@gsnDraw                = False     ; do not draw
  res@gsnFrame               = False     ; do not advance frame

; Define tickmarks for the first two plots
;for the colorbar or called "tickmarks" in NCL
   res@cnLevelSelectionMode  = "ManualLevels"
   res@cnMinLevelValF        = 24 
   res@cnMaxLevelValF        = 38
   res@cnLevelSpacingF       = 2
   res@lbLabelBarOn           = True          ; turn off individual cb's

; this controls the size and location of the second plot
;   dres@vpXF            = 0.6
;   dres@vpWidthF        = 0.4
;   dres@vpYF            = 0.8
;   dres@vpHeightF       = 0.35

   ;working on titles
   res@tiMainFont   = 25 
   res@tiMainFontHeightF = 0.02
   res@tiMainString   = "14 models avg for 6months_1hrMax O~B~3~N~"
   res@gsnLeftString = " "
   res@gsnRightString = " "
   print("Min and Max for the avg after regrid ")
   printMinMax(O3_14models_avg_regrid, True)
   plots(3) = gsn_csm_contour_map(wks,O3_14models_avg_regrid,res)

  ;for the std plot
   res@cnMinLevelValF     := 0
   res@cnMaxLevelValF     := 8
   res@cnLevelSpacingF    := 0.8
   res@tiMainString   = "14 models std for 6months_1hrMax O~B~3~N~"
   print("Min and Max for the std after regrid")
   printMinMax(O3_14models_std_regrid, True)
   plots(4) = gsn_csm_contour_map(wks,O3_14models_std_regrid,res)

  ;for the cv plot
   res@cnMinLevelValF     := 0
   res@cnMaxLevelValF     := 0.2
   res@cnLevelSpacingF    := 0.02
   res@tiMainString   = "14 models cv for 6months_1hrMax O~B~3~N~"
   print("Min and Max for the cv after regrid")
   printMinMax(O3_14models_cv_regrid, True)
   plots(5) = gsn_csm_contour_map(wks,O3_14models_cv_regrid,res)


   ;add the U.S. average
;   tr_label = "-2.37 ppb";"-3.55 ppb"
;   txid_tr(1) = gsn_create_text(wks, tr_label, txres)
;   amid_tr(1) = gsn_add_annotation(plots(1), txid_tr(1), amres_tr)

;==============================================
; create panel
;=============================================
  pres                         = True
  pres@gsnPanelRowSpec         = True      ;tell panel what order to plot
  pres@gsnPanelLabelBar        = False                ; add common colorbar
  pres@lbTitleOn        =  True                ; turn on title
  pres@gsnPanelFigureStrings= (/"(a)","(b)", "(c)"/) ; add strings to panel
  pres@gsnPanelFigureStringsFontHeightF = 0.015
  pres@amJust   = "BottomLeft"
  pres@amParallelPosF = -0.49
  pres@amOrthogonalPosF = 0.49
  pres@gsnPanelFigureStringsPerimOn = False
  
  gsn_panel (wks, plots(3:5), (/3, 1/), pres)
  print("-------------------------------------------------------------------------")
  print("-------------------------------------------------------------------------")
;delete the parameter

  ;save the regridded data
 ;zyq, 11/15/16, save the pops/deaths/mrates data into netcdf file
  outfile = "/home/yzhang07/Scripts/US_Mortality_Burden_36km/Saved_ACCMIP_1850_14models_6months_Daily1hrMaximum.nc"
  print(outfile)
  system("rm -f "+outfile)
  outf = addfile(outfile,"c")
  setfileoption(outf,"DefineMode",True)

  outf@title         = "NCL Efficient Approach to netCDF Creation"
  outf@source_file   =  "ACCMIP 1850 Historical runs from 14 models "; file1+file2 
  outf@creation_date = systemfunc ("date")
  outf@long_name     = "Create by Yuqiang Zhang using the NCL ESMF_regridding tools with the "+method+" method " 

  ;Define dimensions:
  dim_names = (/"south_north","west_east"/)
  dim_sizes = (/ nlat_dst, nlon_dst/)
  dim_unlimited = (/False,False/)

  print("Defining dimension sizes to be " + dim_sizes)
  filedimdef(outf,dim_names,dim_sizes,dim_unlimited)

  ;Define file variables

  filevardef(outf,"ROW","float",(/"south_north","west_east"/))
  filevardef(outf,"COL","float",(/"south_north","west_east"/))

  filevardef(outf,"O3_avg_regrid","float",(/"south_north","west_east"/))
  filevardef(outf,"O3_std_regrid","float",(/"south_north","west_east"/))
  filevardef(outf,"O3_cv_regrid","float",(/"south_north","west_east"/))

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

  ;O3_avg_regrid
  Popsatts = True
  Popsatts@long_name = "14 models average for the 6months average of daily 1-hr maximum ozone after regrid"
  filevarattdef(outf,"O3_avg_regrid",Popsatts)

  ;O3_std_regrid
  Deathsatts = True
  Deathsatts@long_name = "14 models standard deviation for the 6months average of daily 1-hr maximum ozone after regrid" 
  filevarattdef(outf,"O3_std_regrid",Deathsatts)

 ;Mrates
  Mratesatts = True
  Mratesatts@long_name = "14 models coefficient of variation for the 6months average of daily 1-hr maximum ozone after regrid" 
  filevarattdef(outf,"O3_cv_regrid",Mratesatts)

  outf->ROW = (/lat2d_dst/)
  outf->COL = (/lon2d_dst/)
  outf->O3_avg_regrid = (/O3_14models_avg_regrid/)
  outf->O3_std_regrid = (/O3_14models_std_regrid/)
  outf->O3_cv_regrid = (/O3_14models_cv_regrid/)


  delete(res)
  delete(wks)
  delete(plots)
  delete(pres)
  delete(mzres)
;end loop for the months
;end do 

end


