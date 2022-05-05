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
    #dict_keys(['PM25'])
    
    pm25 = dat.variables['PM25']
    pm25 = pm25[:]
    pm25 = ma.asarray(pm25)
    
    pm_flat = pm25.ravel()
    pm_flat = pm_flat.reshape(pm_flat.size,1)

    # Put concentration data in dataframe
    output = ma.column_stack((lon_flat,lat_flat,pm_flat))

    output = pd.DataFrame(output)
    output.columns = ['Lon','Lat','PM25']
    
    # nan = 56163 for PM25
    # set nan to 0
    
    output['PM25'] = output['PM25'].fillna(0)
    
    # Set pop/mort filename
    cdcfname = '/nas/longleaf/home/revathi/HAQAST/thesis/mortality/CDC_ACM_Regridded/CDC_ACM_CMAQ_12km_'+str(Year)+'_NEW.nc'
  
    # Get pop/mort data
    cdc = Dataset(cdcfname, 'r')
    
    print(cdc.variables.keys())
    
    m_dfs = dict()
    
    for i in range(0,7):
        
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
    dat['PM25'] = dat['PM25'].fillna(0)
    # Make copy of dat
    dat_raw = dat
  
    # Loop over each grid cell to calculate PM2.5-attributable mortality
    # Health impact function is from Jerrett et al. 2009
    # dMort = Y0*AF*Pop
    # AF = 1-exp(beta*dX)
    # dX = change in PM2.5 concentration from baseline
      
    # RR10 = 1.034, [1.016, 1.053] - doesn't seem to have age-specific RR10s
    # beta = log(1.034)/10
    
    # suppressed counties: use the state-level average 
    # still suppressed: use regional-level average
    # region defined following US climate regions that divides US into 9 regions
    # If region is suppressed, use national average
    # same thing for missing values
  
    RR10 = 1.06
    RRlow = 1.04
    RRup = 1.08
  
    beta10 = math.log(RR10)/10
    beta_low = math.log(RRlow)/10
    beta_up = math.log(RRup)/10
  
    dPM25 = []
    
    for i in range(0,dat.shape[0]):
        dPM25.append(dat['PM25'].loc[i] - 5.8) # from Silva 2013
        
    dat['dPM25'] = dPM25
    
    dPM25 = []
    
    for i in range(0,dat.shape[0]):
        if dat['dPM25'].loc[i] < 0:
            dPM25.append(0)
        else:
            dPM25.append(dat['dPM25'].loc[i])
            
    dat['dPM25'] = dPM25
    
    AF = []
    AF_low = []
    AF_up = []
    
    #math.exp(-beta10*dat['dPM25'].loc[random.randint(0,149000)])

    for i in range(0,dat.shape[0]):
        AF.append(1-math.exp(-beta10*dat['dPM25'].loc[i]))
        AF_low.append(1-math.exp(-beta_low*dat['dPM25'].loc[i]))
        AF_up.append(1-math.exp(-beta_up*dat['dPM25'].loc[i]))
        
    dat['AF'] = AF
    dat['AF_low'] = AF_low
    dat['AF_up'] = AF_up
    
    deaths = []
    deaths_RRlow = []
    deaths_RRup = []
    
    for i in range(0,dat.shape[0]):
        deaths.append(dat['Mrate'].loc[i]*dat['AF'].loc[i]*dat['Pop'].loc[i])
        deaths_RRlow.append(dat['Mrate'].loc[i]*dat['AF_low'].loc[i]*dat['Pop'].loc[i])
        deaths_RRup.append(dat['Mrate'].loc[i]*dat['AF_up'].loc[i]*dat['Pop'].loc[i])
    dat['deaths'] = deaths
    dat['deaths_RRlow'] = deaths_RRlow
    dat['deaths_RRup'] = deaths_RRup
    
    # Set output filename
  
    outfname = '/nas/longleaf/home/revathi/chaq/revathi/mortality_results/ACM/NACR/CDC_NACR_grid_mort_results_'+str(Year)+'.csv'
  
    np.savetxt(outfname, dat, delimiter=',', fmt='%s') 
