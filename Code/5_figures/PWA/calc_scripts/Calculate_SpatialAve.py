#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jan 28 09:32:43 2022

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

startyear = 1990 # 2000 has diff varnames, run separately after changing lat2d and lon2d to LAT and LON respectively
endyear = 2011 #n+1

Dir = "/nas/longleaf/home/revathi/chaq/revathi/FAQSD/gridded/Pooled12_36DSSurfaces/"

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
    Filename = Dir + "pm25_"+str(Year)+".csv"
    
   # Get FAQSD conc data
    dat = pd.read_csv(Filename)
    
    # Rename df_means to reflect year
    
    # Do summertime 6-month average
    # global scale: let's find 6-month period that has highest average ozone
    # some places ozone season might not be May - October
    # Turner: 6 month average of April through Sept (April 1 - Sept 30)
    # Find day # of April 1 and Sept 30
    # Do this with Turner 2016 risk ratio
    # Does it define the resp mort endpoint the same way that Jerrett et al. did?
    
    yrdf_name = "output_" + str(Year)
    output = dat
    
    # set nan to 0
    output['Prediction'] = output['DSPred'].fillna(0)
    
    output2=output
    output2['Date'] = pd.to_datetime(output2['Date'])
    
    date1 = str(Year)+'-03-31'
    date2 = str(Year)+'-10-01'

    output2 = output2[(output2['Date'] > date1) & (output2['Date'] < date2)]
    
    # Take annual PM2.5 average per location
    
    output = output2.groupby('Gridcell').mean('Prediction').reset_index()
    
    # Rename lat/lon columns
    # output = output.rename(columns={"Latitude" : "Lat", "Longitude" : "Lon", "Prediction": "Ozone"})
    
    
    np.nanmean(output['Prediction'])
    