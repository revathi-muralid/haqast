#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Oct 29 21:46:22 2021

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

Dir = "/nas/longleaf/home/revathi/chaq/revathi/EPA_21yr_CMAQ/6moDaily1hrMaxO3/"

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
    
    m_dfs = dict()
    
    for Month in range(5,11):
        
        if Month < 10:
            Month = str(0)+str(Month)
        else:
            Month = str(Month)
        
        # Set concentration filename
        Filename = Dir + "CMAQ_O3_monthly_Regridded_36km_to_12km_"+str(Year)+str(Month)+".nc"
        
        # Get concentration data
        dat = Dataset(Filename, 'r')
    
        print(dat.variables.keys())
        #dict_keys(['O3'])
    
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
    
    # Rename df_means to reflect year
    
    yrdf_name = "output_" + str(Year)
    output = df_means
    
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
    
    # Merge
    dat = pd.merge(cdcdat, output, how = 'left', on=['Lon','Lat'])
    #dat['O3'] = output['O3']
    #dat['O3'] = dat['O3'].fillna(0)
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
  
    #MDA8 RRs
    #RR10 = 1.12
    #RRlow = 1.08
    #RRup = 1.16
    
    #6mDMA1 RRs
    RR10 = 1.040
    RRlow = 1.010
    RRup = 1.067
  
    beta10 = math.log(RR10)/10
    beta_low = math.log(RRlow)/10
    beta_up = math.log(RRup)/10
  
    dO3 = []
    
    # LCT: 28.9 for MDA8
    # 37.6 for 6mDMA1
    
    for i in range(0,dat.shape[0]):
        dO3.append(dat['O3'].loc[i] - 37.6) # from Silva 2013
        
    dat['dO3'] = dO3
    
    dO3 = []
    
    for i in range(0,dat.shape[0]):
        if dat['dO3'].loc[i] < 0:
            dO3.append(0)
        else:
            dO3.append(dat['dO3'].loc[i])
            
    dat['dO3'] = dO3
    
    AF = []
    AF_low = []
    AF_up = []
    
    #math.exp(-beta10*dat['dPM25'].loc[random.randint(0,149000)])

    for i in range(0,dat.shape[0]):
        AF.append(1-math.exp(-beta10*dat['dO3'].loc[i]))
        AF_low.append(1-math.exp(-beta_low*dat['dO3'].loc[i]))
        AF_up.append(1-math.exp(-beta_up*dat['dO3'].loc[i]))
        
    dat['AF'] = AF
    dat['AF_low'] = AF_low
    dat['AF_up'] = AF_up
    
    #dat['M_25-34'] = dat['M_25-34'].replace(9.970000000000001e+36,np.nan)
    #dat['P_25-34'] = dat['P_25-34'].replace(9.970000000000001e+36,np.nan)
    
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
  
    outfname = '/nas/longleaf/home/revathi/chaq/revathi/mortality_results/RESP/EPA/CDC_EPA_grid_mort_results_'+str(Year)+'.csv'
  
    np.savetxt(outfname, dat, delimiter=',', fmt='%s') 
