#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Thu Jan 13 21:16:12 2022

@author: revathi
"""
#!/usr/bin/python3
 
from netCDF4 import Dataset
import pandas as pd
import numpy as np
import numpy.ma as ma
import os

# Retrieve data and store as netCDF4 file

Dir = "/nas/longleaf/home/revathi/chaq/revathi/EPA_21yr_CMAQ/6moDaily8hrMaxO3/"

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

yrs1 = 1990
yrs2 = 2011
numY = yrs2-yrs1

dfs={}

for Year in range(yrs1,yrs2):
    coords_file = '/nas/longleaf/home/revathi/HAQAST/thesis/HEALTH/data/other/aqm.latlon.ncf' 
         
    m_dfs = dict()
    
    for Month in range(4,10):
        
        if Month<10:
            Month = str(0)+str(Month)
        else:
            Month = str(Month)
        
        # Set concentration filename
        Filename = Dir + "CMAQ_MDA8_O3_Regridded_36km_to_12km_"+str(Year)+str(Month)+".nc"
        
        # Get concentration data
        dat = Dataset(Filename, 'r')
    
        print(dat.variables.keys())
        #dict_keys(['lat2d', 'lon2d', 'PM25'])
    
        ozone = dat.variables['O3']
        ozone = ozone[:]
        ozone = ma.asarray(ozone)
        
        ozone_flat = ozone.ravel()
        ozone_flat = ozone_flat.reshape(ozone_flat.size,1)
    
        # Put concentration data in dataframe
        output = ma.column_stack((lon_flat,lat_flat,ozone_flat));
    
        output = pd.DataFrame(output)
        output.columns = ['Lon','Lat','O3']
    
        # nan = 56163 for PM25
        # set nan to 0
        
        output['O3'] = output['O3'].fillna(0)
        
        # Set unique df name for each month
        new_name = "output" + str(Month) + "_" + str(Year)
        
        m_dfs[new_name] = output

    # Bind all monthly dfs into one large df for annual averaging
    
    df_concat = pd.concat((m_dfs))
    
    #how to extract one df from the dictionary of dfs: m_dfs['output01_1990']
    
    df_means = df_concat.groupby(level=1).mean()
    
    df_means['Year'] = Year
    
    # Rename df_means to reflect year
    
    yrdf_name = "output_" + str(Year)
    
    #output = ma.column_stack((lat_flat,pm25))
    #print(output.shape)
    #print(type(output))
    
    dfs["output_"+str(Year)] = df_means

output = pd.concat(dfs.values())

outfname = '/nas/longleaf/home/revathi/HAQAST/thesis/BME_Final_withGrid/preprocessed/BMEAnalyticEPASoftData.csv'
  
np.savetxt(outfname, output, delimiter=',', fmt='%s') 
