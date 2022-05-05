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

startyear = 1990 # 2000 has diff varnames, run separately after changing lat2d and lon2d to LAT and LON respectively
endyear = 2011 #n+1

Dir = "/nas/longleaf/home/revathi/chaq/revathi/EPA_21yr_CMAQ/NF_aconc/"

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
    
    for Month in range(1,13):
        
        if Month<10:
            Month = str(0)+str(Month)
        else:
            Month = str(Month)
        
        # Set concentration filename
        Filename = Dir + "CMAQ_PM25_Regridded_36km_to_12km_"+str(Year)+str(Month)+".nc"
        
        # Get concentration data
        dat = Dataset(Filename, 'r')
    
        print(dat.variables.keys())
        #dict_keys(['lat2d', 'lon2d', 'PM25'])
    
        pm25 = dat.variables['PM25']
        pm25 = pm25[:]
        pm25 = ma.asarray(pm25)
        
        pm_flat = pm25.ravel()
        pm_flat = pm_flat.reshape(pm_flat.size,1)
    
        # Put concentration data in dataframe
        output = ma.column_stack((lon_flat,lat_flat,pm_flat));
    
        output = pd.DataFrame(output)
        output.columns = ['Lon','Lat','PM25']
    
        # nan = 56163 for PM25
        # set nan to 0
        
        output['PM25'] = output['PM25'].fillna(0)
        
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
    cdcfname = '/nas/longleaf/home/revathi/HAQAST/thesis/mortality/CDC_ACM_Regridded/CDC_ACM_CMAQ_12km_'+str(Year)+'.csv'
  
    # Get pop/mort data
    cdc = pd.read_csv(cdcfname)
    
    # Merge
    dat = pd.merge(cdc, output, how = 'left', on=['Lon','Lat'])
    dat['PM25'] = output['PM25']
    dat['PM25'] = dat['PM25'].fillna(0)
   # Make copy of dat
    dat_raw = dat
    
    dat['M_25-34'] = dat['M_25-34'].replace(9.970000000000001e+36,np.nan)
    dat['P_25-34'] = dat['P_25-34'].replace(9.970000000000001e+36,np.nan)
    dat['M_35-44'] = dat['M_35-44'].replace(9.970000000000001e+36,np.nan)
    dat['P_35-44'] = dat['P_35-44'].replace(9.970000000000001e+36,np.nan)
    dat['M_45-54'] = dat['M_45-54'].replace(9.970000000000001e+36,np.nan)
    dat['P_45-54'] = dat['P_45-54'].replace(9.970000000000001e+36,np.nan)
    dat['M_55-64'] = dat['M_55-64'].replace(9.970000000000001e+36,np.nan)
    dat['P_55-64'] = dat['P_55-64'].replace(9.970000000000001e+36,np.nan)
    dat['M_65-74'] = dat['M_65-74'].replace(9.970000000000001e+36,np.nan)
    dat['P_65-74'] = dat['P_65-74'].replace(9.970000000000001e+36,np.nan)
    dat['M_75-84'] = dat['M_75-84'].replace(9.970000000000001e+36,np.nan)
    dat['P_75-84'] = dat['P_75-84'].replace(9.970000000000001e+36,np.nan)
    dat['M_85+'] = dat['M_85+'].replace(9.970000000000001e+36,np.nan)
    dat['P_85+'] = dat['P_85+'].replace(9.970000000000001e+36,np.nan)
  
    # Loop over each grid cell to calculate population-weighted PM2.5 average
    
    P_TOT = []
    
    P_TOT = dat['P_25-34']+dat['P_35-44']+dat['P_45-54']+ dat['P_55-64']+dat['P_65-74']+dat['P_75-84']+ dat['P_85+']
        
    dat['P_TOT'] = P_TOT
    
    pwa_pm25 = []
    pop_tot = np.sum(P_TOT)
    
    for i in range(0, dat.shape[0]):
        
        pwa_pm25.append((dat['PM25'].loc[i]*dat['P_TOT'].loc[i])/pop_tot)
    
    dat['PWA_PM25'] = pwa_pm25
    
    out = dat[['Lon', 'Lat','PM25', 'P_TOT', 'PWA_PM25']]

    # Set output filename
  
    outfname = '/nas/longleaf/home/revathi/HAQAST/thesis/Code/5_figures/PWA/CMAQ_PM25_PWA_'+str(Year)+'.csv'
  
    np.savetxt(outfname, out, delimiter=',', fmt='%s') 
