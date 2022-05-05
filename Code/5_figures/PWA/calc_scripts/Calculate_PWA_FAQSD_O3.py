#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Jan 10 16:12:30 2022

@author: revathi
"""

from netCDF4 import Dataset
import PseudoNetCDF as pnc
import matplotlib.pyplot as plt
import numpy as np
import numpy.ma as ma
import os
import pandas as pd
import math

startyear = 2002 # 2000 has diff varnames, run separately after changing lat2d and lon2d to LAT and LON respectively
endyear = 2018 #n+1

Dir = "/nas/longleaf/home/revathi/chaq/revathi/FAQSD/ozone/regridded/"

Gridname = "/nas/longleaf/home/revathi/chaq/revathi/CONUS12_444x336.ncf"
grid = Dataset(Gridname, 'r')
print(grid.variables.keys())
    
lat = grid.variables['LAT']
lat = lat[:]
lat = ma.asarray(lat)
    
lon = grid.variables['LON']
lon = lon[:]
lon = ma.asarray(lon)

lat_flat = lat.ravel()
lon_flat = lon.ravel()

lat_flat = lat_flat.reshape(lat_flat.size,1)
lon_flat = lon_flat.reshape(lon_flat.size,1)

for Year in range(startyear,endyear):
    
    # Set concentration filename
    Filename = Dir + "FAQSD_O3_Regridded_to_CONUS_12km_"+str(Year)+".nc"
    
    # Get concentration data
    dat = Dataset(Filename, 'r')
    
    print(dat.variables.keys())
    
    ozone = dat.variables['O3']
    ozone = ozone[:]
    ozone = ma.asarray(ozone)
    
    ozone_flat = ozone.ravel()
    ozone_flat = ozone_flat.reshape(ozone_flat.size,1)

    # Put concentration data in dataframe
    output = ma.column_stack((lon_flat,lat_flat,ozone_flat));
    
    output = pd.DataFrame(output)
    output.columns = ['Lon','Lat','O3']
    
    # Rename df_means to reflect year
    
    # Do summertime 6-month average
    # global scale: let's find 6-month period that has highest average ozone
    # some places ozone season might not be May - October
    # Turner: 6 month average of April through Sept (April 1 - Sept 30)
    # Find day # of April 1 and Sept 30
    # Do this with Turner 2016 risk ratio
    # Does it define the resp mort endpoint the same way that Jerrett et al. did?
    
    yrdf_name = "output_" + str(Year)
    #output = dat
    
    # set nan to 0
    output['O3'] = output['O3'].fillna(0)
    
    output2=output
    
    # Set pop/mort filename
    cdcfname = '/nas/longleaf/home/revathi/HAQAST/thesis/mortality/CDC_RESP_Regridded/CDC_RESP_12km_'+str(Year)+'.nc'
  
    # Get pop/mort data
    cdc = Dataset(cdcfname, 'r')
    
    print(cdc.variables.keys())
    
    pop = cdc.variables['Pops']
    pop = pop[:]
    pop = ma.asarray(pop)
    
    pop_flat = pop.ravel()
    pop_flat = pop_flat.reshape(pop_flat.size,1)
    
    death = cdc.variables['Deaths']
    death = death[:]
    death = ma.asarray(death)
    
    death_flat = death.ravel()
    death_flat = death_flat.reshape(death_flat.size,1)
    
    mrate = cdc.variables['Mrates']
    mrate = mrate[:]
    mrate = ma.asarray(mrate)
    
    mrate_flat = mrate.ravel()
    mrate_flat = mrate_flat.reshape(mrate_flat.size,1)
    
    row = cdc.variables['ROW']
    row = row[:]
    row = ma.asarray(row)
    
    row_flat = row.ravel()
    row_flat = row_flat.reshape(row_flat.size,1)
    
    col = cdc.variables['COL']
    col = col[:]
    col = ma.asarray(col)
    
    col_flat = col.ravel()
    col_flat = col_flat.reshape(col_flat.size,1)

    # Put concentration data in dataframe
    cdcdat = ma.column_stack((lon_flat,lat_flat,death_flat,pop_flat,mrate_flat));
    
    cdcdat = pd.DataFrame(cdcdat)
    cdcdat.columns = ['Lon','Lat','BLDeaths','Pop','Mrate']

    # nan = 56163 for PM25
    # set nan to 0
    
    cdcdat['Lon']=np.float64(cdcdat['Lon'])
    cdcdat['Lat']=np.float64(cdcdat['Lat'])
    
    # Merge
    dat = pd.merge(cdcdat, output, how = 'left', on=['Lon','Lat'])
    #dat['O3'] = output['O3']
    # NA = 64657
    dat['O3'] = dat['O3'].fillna(0)
   # Make copy of dat
    dat_raw = dat
  
    # Loop over each grid cell to calculate population-weighted PM2.5 average
    
    pwa_O3 = []
    pop_tot = np.sum(dat['Pop'])
    
    for i in range(0, dat.shape[0]):
        
        pwa_O3.append((dat['O3'].loc[i]*dat['Pop'].loc[i])/pop_tot)
    
    dat['PWA_O3'] = pwa_O3
    
    out = dat[['Lon', 'Lat','O3', 'Pop', 'PWA_O3']]

    # Set output filename
  
    outfname = '/nas/longleaf/home/revathi/HAQAST/thesis/Code/5_figures/PWA/FAQSD_O3_PWA_'+str(Year)+'.csv'
  
    np.savetxt(outfname, out, delimiter=',', fmt='%s') 
