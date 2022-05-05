#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Tue Jan 11 11:24:42 2022

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

Dir = "/nas/longleaf/home/revathi/chaq/revathi/NACR/NACR/pm25/"

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
    Filename = Dir + "NACR_PM25_Regridded_"+str(Year)+".nc"
        
    # Get concentration data
    dat = Dataset(Filename, 'r')
    
    print(dat.variables.keys())
    #dict_keys(['Ozone'])
    
    pm25 = dat.variables['PM25']
    pm25 = pm25[:]
    pm25 = ma.asarray(pm25)
    
    pm25_flat = pm25.ravel()
    pm25_flat = pm25_flat.reshape(pm25_flat.size,1)

    # Put concentration data in dataframe
    output = ma.column_stack((lon_flat,lat_flat,pm25_flat))

    output = pd.DataFrame(output)
    output.columns = ['Lon','Lat','PM25']
    
    # nan = 56163 for PM25
    # set nan to 0
    
    output['PM25'] = output['PM25'].fillna(0)
    #output['O3'] = output['O3']*1000
    
    # Set pop/mort filename
    cdcfname = '/nas/longleaf/home/revathi/HAQAST/thesis/mortality/CDC_ACM_Regridded/CDC_ACM_CMAQ_12km_'+str(Year)+'_NEW.nc'
  
    # Get pop/mort data
    cdc = Dataset(cdcfname, 'r')
    
    print(cdc.variables.keys())
    
    m_dfs = dict()
    
    for i in range(0,7):
        
        #age = cdc.variables['Ages_group'][i]
        #age = age[:]
        #age = ma.asarray(age)
    
        #age_flat = age.ravel()
        #age_flat = age_flat.reshape(age_flat.size,1)
#        
#        lat = cdc.variables['Lats'][i]
#        lat = lat[:]
#        lat = ma.asarray(lat)
#    
#        lat_flat = lat.ravel()
#        lat_flat = lat_flat.reshape(lat_flat.size,1)
#        
#        lon = cdc.variables['Lons'][i]
#        lon = lon[:]
#        lon = ma.asarray(lon)
#    
#        lon_flat = lon.ravel()
#        lon_flat = lon_flat.reshape(lon_flat.size,1)
        
        pop = cdc.variables['Pops'][i]
        pop = pop[:]
        pop = ma.asarray(pop)
    
        pop_flat = pop.ravel()
        pop_flat = pop_flat.reshape(pop_flat.size,1)
    
        death = cdc.variables['Deaths'][i]
        death = death[:]
        death = ma.asarray(death)
        
        death_flat = death.ravel()
        death_flat = death_flat.reshape(death_flat.size,1)
        
        mrate = cdc.variables['Mrates'][i]
        mrate = mrate[:]
        mrate = ma.asarray(mrate)
        
        mrate_flat = mrate.ravel()
        mrate_flat = mrate_flat.reshape(mrate_flat.size,1)
        
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
    
    # NA = 64657
    dat['PM25'] = dat['PM25'].fillna(0)
   # Make copy of dat
    dat_raw = dat
  
    # Loop over each grid cell to calculate population-weighted PM2.5 average
    
    pwa_PM25 = []
    pop_tot = np.sum(dat['Pop'])
    
    for i in range(0, dat.shape[0]):
        
        pwa_PM25.append((dat['PM25'].loc[i]*dat['Pop'].loc[i])/pop_tot)
    
    dat['PWA_PM25'] = pwa_PM25
    
    out = dat[['Lon', 'Lat','PM25', 'Pop', 'PWA_PM25']]

    # Set output filename
  
    outfname = '/nas/longleaf/home/revathi/HAQAST/thesis/Code/5_figures/PWA/NACR_PM25_PWA_'+str(Year)+'.csv'
  
    np.savetxt(outfname, out, delimiter=',', fmt='%s') 
