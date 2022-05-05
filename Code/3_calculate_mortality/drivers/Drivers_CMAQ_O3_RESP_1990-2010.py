#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Jan 21 13:26:37 2022

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

Dir = "/nas/longleaf/home/revathi/chaq/revathi/mortality_results/RESP/EPA/"

# Hold values from 1990 constant for drivers analysis

dat1990 = pd.read_csv(Dir+'CDC_EPA_grid_mort_results_1990.csv')
dat1990.columns=['Lon', 'Lat', 'BLDeaths_1990', 'Pop_1990', 
                 'Mrate_1990','O3_1990', 'dO3_1990', 'AF_1990','AF_low_1990', 'AF_up_1990', 'deaths_1990', 
                 'deaths_RRlow_1990', 'deaths_RRup_1990']
dat1990['O3_1990'] = dat1990['O3_1990'].fillna(0)
dat1990['dO3_1990'] = dat1990['dO3_1990'].fillna(0)
dat1990['AF_1990'] = dat1990['AF_1990'].fillna(0)
dat1990['AF_low_1990'] = dat1990['AF_low_1990'].fillna(0)
dat1990['AF_up_1990'] = dat1990['AF_up_1990'].fillna(0)
dat1990['deaths_1990'] = dat1990['deaths_1990'].fillna(0)
dat1990['deaths_RRlow_1990'] = dat1990['deaths_RRlow_1990'].fillna(0)
dat1990['deaths_RRup_1990'] = dat1990['deaths_RRup_1990'].fillna(0)

for Year in range(startyear,endyear):
    
    dat_old = pd.read_csv(Dir+'CDC_EPA_grid_mort_results_'+str(Year)+'.csv')
    
    dat_old.columns=['Lon', 'Lat', 'BLDeaths', 'Pop', 'Mrate', 'O3', 'dO3', 'AF',
       'AF_low', 'AF_up', 'deaths', 'deaths_RRlow', 'deaths_RRup']
    
    # Get constant pop, mort, and conc data
    dat=pd.merge(dat_old,dat1990, how = 'left', on=['Lon','Lat'])
    
    dat['O3'] = dat['O3'].fillna(0)
    
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
    
    deaths_P = []
    deaths_M = []
    deaths_noC = []
    deaths_C = []
    
    for i in range(0,dat.shape[0]):
        deaths_P.append(dat['Mrate_1990'].loc[i]*dat['AF_1990'].loc[i]*dat['Pop'].loc[i])
        deaths_M.append(dat['Mrate'].loc[i]*dat['AF_1990'].loc[i]*dat['Pop_1990'].loc[i])
        deaths_noC.append(dat['Mrate'].loc[i]*dat['AF_1990'].loc[i]*dat['Pop'].loc[i])
        deaths_C.append(dat['Mrate_1990'].loc[i]*dat['AF'].loc[i]*dat['Pop_1990'].loc[i])
    dat['deaths_P'] = deaths_P
    dat['deaths_M'] = deaths_M
    dat['deaths_noC'] = deaths_noC
    dat['deaths_C'] = deaths_C
    
    # Set output filename
  
    outfname = '/nas/longleaf/home/revathi/chaq/revathi/mortality_results/RESP/EPA/Drivers/CDC_EPA_grid_mort_drivers_'+str(Year)+'.csv'
  
    np.savetxt(outfname, dat, delimiter=',', fmt='%s') 
