#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sat Oct 30 20:04:17 2021

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

startyear = 2009 # 2000 has diff varnames, run separately after changing lat2d and lon2d to LAT and LON respectively
endyear = 2016 #n+1

Dir = "/nas/longleaf/home/revathi/chaq/revathi/NACR_update/NACR_O3_2018/"

test = "output/ozone6m2018.nc"
test = "output/NACR_O3_merged_2018.ncf"
test = "output/NACR_O3_DailyMax_Aug2018.ncf"

myfile = Dir + test
myf = Dataset(myfile, 'r')
print(myf.variables.keys())

o3 = myf.variables['O3']
o3 = o3[:]
o3 = ma.asarray(o3)
    
o3_flat = o3.ravel()
o3_flat = o3_flat.reshape(o3_flat.size,1)

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

oGridname = "/nas/longleaf/home/revathi/chaq/revathi/NACR/NACR/aqm.latlon.ncf"
ogrid = Dataset(Gridname, 'r')
print(ogrid.variables.keys())

olat = grid.variables['LAT']
olat = olat[:]
olat = ma.asarray(olat)
    
olon = grid.variables['LON']
olon = olon[:]
olon = ma.asarray(olon)

olat_flat = olat.ravel()
olon_flat = olon.ravel()

olat_flat = olat_flat.reshape(olat_flat.size,1)
olon_flat = olon_flat.reshape(olon_flat.size,1)

for filename in os.listdir(Dir):
    
    # Set concentration filename
    f = Dir + filename
    
    # Get concentration data
    if os.path.isfile(f):
        dat = Dataset(f, 'r')
    
    print(dat.variables.keys())
    #dict_keys(['TFLAG', 'O3'])
    
    o3 = dat.variables['O3']
    o3 = o3[:]
    o3 = ma.asarray(o3)
    
    o3_flat = o3.ravel()
    o3_flat = o3_flat.reshape(o3_flat.size,1)

    # Put concentration data in dataframe
    output = ma.column_stack((lon_flat,lat_flat,pm_flat))

    output = pd.DataFrame(output)
    output.columns = ['Lon','Lat','PM25']
    
    # nan = 56163 for PM25
    # set nan to 0
    
    output['PM25'] = output['PM25'].fillna(0)
    
   
    
    m_dfs = dict()
    
    for i in range(0,7):
        
        
        output3 = ma.column_stack((lon_flat,lat_flat,death_flat,pop_flat,mrate_flat))
        
        output3 = pd.DataFrame(output3)
        output3.columns = ['Lon','Lat','BLDeaths','Pop','Mrate']
        
        # Set unique df name for each age group
        new_dname = "output" + str(i) 
        
        m_dfs[new_dname] = output3

    # Bind all monthly dfs into one large df for annual averaging
    
    df_concat = pd.concat((m_dfs))
    
    #how to extract one df from the dictionary of dfs: m_dfs['output01_1990']
    
    df_means = df_concat.groupby(['Lon','Lat']).sum(['BLDeaths','Pop'])
    df_means['Mrate'] = df_means['BLDeaths']/df_means['Pop']
    
    df_means = df_means.reset_index()
    
    # Put concentration data in dataframe
    cdcdat = df_means

    #cdcdat = pd.DataFrame(cdcdat)
    #cdcdat.columns = ['Lon','Lat','BLDeaths','Pop','Mrate']
    
    cdcdat['Lon']=np.float64(cdcdat['Lon'])
    cdcdat['Lat']=np.float64(cdcdat['Lat'])
    
    # Merge
    dat = pd.merge(cdcdat, output, how = 'left', on=['Lon','Lat'])
    dat['PM25'] = dat['PM25'].fillna(0)
    # Make copy of dat
    dat_raw = dat
  
    # Set output filename
  
    outfname = '/nas/longleaf/home/revathi/chaq/revathi/mortality_results/ACM/NACR/CDC_NACR_grid_mort_results_'+str(Year)+'.csv'
  
    np.savetxt(outfname, dat, delimiter=',', fmt='%s') 
