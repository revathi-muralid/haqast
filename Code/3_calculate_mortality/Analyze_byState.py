#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Feb  6 17:36:56 2022

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

Dir = "/nas/longleaf/home/revathi/chaq/revathi/mortality_results/ACM/CMAQ/"

lookup = pd.read_csv('/nas/longleaf/home/revathi/HAQAST/thesis/population/USA_100_NOFILL_12km.csv')

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

#grid.dimensions['COL']
mycol= np.array(range(1,445))

#grid.dimensions['ROW']
myrow = np.array(range(1,337))

row_flat = myrow.reshape(myrow.size,1)
col_flat = mycol.reshape(mycol.size,1)

for Year in range(startyear,endyear):
    
    
    dat = pd.read_csv(Dir+'CDC_CMAQ_grid_mort_results_'+str(Year)+'.csv')
    
    dat.columns=['Lon', 'Lat', 'P_25-34', 'P_35-44', 'P_45-54', 'P_55-64', 'P_65-74',
           'P_75-84', 'P_85+', 'M_25-34', 'M_35-44', 'M_45-54', 'M_55-64',
           'M_65-74', 'M_75-84', 'M_85+', 'D_25-34', 'D_35-44', 'D_45-54',
           'D_55-64', 'D_65-74', 'D_75-84', 'D_85+', 'PM25', 'dPM25', 'AF',
           'AF_low', 'AF_up', 'deaths_age1', 'deaths_RRlow_age1',
           'deaths_RRup_age1', 'deaths_age2', 'deaths_RRlow_age2',
           'deaths_RRup_age2', 'deaths_age3', 'deaths_RRlow_age3',
           'deaths_RRup_age3', 'deaths_age4', 'deaths_RRlow_age4',
           'deaths_RRup_age4', 'deaths_age5', 'deaths_RRlow_age5',
           'deaths_RRup_age5', 'deaths_age6', 'deaths_RRlow_age6',
           'deaths_RRup_age6', 'deaths_age7', 'deaths_RRlow_age7',
           'deaths_RRup_age7']
    
    fname2 = "/nas/longleaf/home/revathi/chaq/revathi/EPA_21yr_CMAQ/NF_aconc/CMAQ_PM25_Regridded_36km_to_12km_"+str(Year)+"01.nc"
  
    # Get row/col data to match to lon/lat
    conc = Dataset(fname2, 'r')
    print(conc.variables.keys())
    
    # Merge

    output = pd.merge(cdc, dat, how = 'left', on=['Lon', 'Lat', 'P_25-34', 'P_35-44', 'P_45-54', 'P_55-64', 'P_65-74',
       'P_75-84', 'P_85+', 'M_25-34', 'M_35-44', 'M_45-54', 'M_55-64',
       'M_65-74', 'M_75-84', 'M_85+', 'D_25-34', 'D_35-44', 'D_45-54',
       'D_55-64', 'D_65-74', 'D_75-84', 'D_85+'])
    output['PM25'] = output['PM25'].fillna(0)
    
        
    