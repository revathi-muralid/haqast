#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Dec 22 20:06:48 2021

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

Dir = "/nas/longleaf/home/revathi/chaq/revathi/EPA_21yr_CMAQ/6moDaily8hrMaxO3/"

#test = Dataset(Dir+'CCTM_DOE_36km_NF_combine.o3_8hrdm_LST.199401','r')

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
    
    for Month in range(4,10): #April through September
        
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
    
    # Rename df_means to reflect year
    
    yrdf_name = "output_" + str(Year)
    output = df_means
    
    # Set pop/mort filename
    cdcfname = '/nas/longleaf/home/revathi/HAQAST/thesis/mortality/CDC_RESP_Regridded/CDC_RESP_CMAQ_12km_'+str(Year)+'.csv'
  
    # Get pop/mort data
    cdc = pd.read_csv(cdcfname)
    
    # Merge
    dat = pd.merge(cdc, output, how = 'left', on=['Lon','Lat'])
    dat['O3'] = output['O3']
    dat['O3'] = dat['O3'].fillna(0)
   # Make copy of dat
    dat_raw = dat
  
    # Loop over each grid cell to calculate PM2.5-attributable mortality
    # Health impact function is from Jerrett et al. 2009
    # dMort = Y0*AF*Pop
    # AF = 1-exp(beta*dX)
    # dX = change in PM2.5 concentration from baseline
    
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
    
    for i in range(0,dat.shape[0]):
        dO3.append(dat['O3'].loc[i] - 28.9) # from Silva 2013
        
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
    
    if Year<1999:
        for i in range(0,dat.shape[0]):
            dat['M_25-34'].loc[i] = dat['M_25-34'].loc[i]*1.046
            dat['M_35-44'].loc[i] = dat['M_35-44'].loc[i]*1.046
            dat['M_45-54'].loc[i] = dat['M_45-54'].loc[i]*1.046
            dat['M_55-64'].loc[i] = dat['M_55-64'].loc[i]*1.046
            dat['M_65-74'].loc[i] = dat['M_65-74'].loc[i]*1.046
            dat['M_75-84'].loc[i] = dat['M_75-84'].loc[i]*1.046
            dat['M_85+'].loc[i] = dat['M_85+'].loc[i]*1.046
    
    deaths_age1 = []
    deaths_RRlow_age1 = []
    deaths_RRup_age1 = []
    deaths_age2 = []
    deaths_RRlow_age2 = []
    deaths_RRup_age2 = []
    deaths_age3 = []
    deaths_RRlow_age3 = []
    deaths_RRup_age3 = []
    deaths_age4 = []
    deaths_RRlow_age4 = []
    deaths_RRup_age4 = []
    deaths_age5 = []
    deaths_RRlow_age5 = []
    deaths_RRup_age5 = []
    deaths_age6 = []
    deaths_RRlow_age6 = []
    deaths_RRup_age6 = []
    deaths_age7 = []
    deaths_RRlow_age7 = []
    deaths_RRup_age7 = []
    
    for i in range(0,dat.shape[0]):
        deaths_age1.append(dat['M_25-34'].loc[i]*dat['AF'].loc[i]*dat['P_25-34'].loc[i])
        deaths_RRlow_age1.append(dat['M_25-34'].loc[i]*dat['AF_low'].loc[i]*dat['P_25-34'].loc[i])
        deaths_RRup_age1.append(dat['M_25-34'].loc[i]*dat['AF_up'].loc[i]*dat['P_25-34'].loc[i])
    dat['deaths_age1'] = deaths_age1 
    dat['deaths_RRlow_age1'] = deaths_RRlow_age1 
    dat['deaths_RRup_age1'] = deaths_RRup_age1 
    
    for i in range(0,dat.shape[0]):
        deaths_age2.append(dat['M_35-44'].loc[i]*dat['AF'].loc[i]*dat['P_35-44'].loc[i])
        deaths_RRlow_age2.append(dat['M_35-44'].loc[i]*dat['AF_low'].loc[i]*dat['P_35-44'].loc[i])
        deaths_RRup_age2.append(dat['M_35-44'].loc[i]*dat['AF_up'].loc[i]*dat['P_35-44'].loc[i])
    dat['deaths_age2'] = deaths_age2
    dat['deaths_RRlow_age2'] = deaths_RRlow_age2
    dat['deaths_RRup_age2'] = deaths_RRup_age2
    
    for i in range(0,dat.shape[0]):
        deaths_age3.append(dat['M_45-54'].loc[i]*dat['AF'].loc[i]*dat['P_45-54'].loc[i])
        deaths_RRlow_age3.append(dat['M_45-54'].loc[i]*dat['AF_low'].loc[i]*dat['P_45-54'].loc[i])
        deaths_RRup_age3.append(dat['M_45-54'].loc[i]*dat['AF_up'].loc[i]*dat['P_45-54'].loc[i])
    dat['deaths_age3'] = deaths_age3
    dat['deaths_RRlow_age3'] = deaths_RRlow_age3
    dat['deaths_RRup_age3'] = deaths_RRup_age3
    
    for i in range(0,dat.shape[0]):
        deaths_age4.append(dat['M_55-64'].loc[i]*dat['AF'].loc[i]*dat['P_55-64'].loc[i])
        deaths_RRlow_age4.append(dat['M_55-64'].loc[i]*dat['AF_low'].loc[i]*dat['P_55-64'].loc[i])
        deaths_RRup_age4.append(dat['M_55-64'].loc[i]*dat['AF_up'].loc[i]*dat['P_55-64'].loc[i])
    dat['deaths_age4'] = deaths_age4
    dat['deaths_RRlow_age4'] = deaths_RRlow_age4
    dat['deaths_RRup_age4'] = deaths_RRup_age4
    
    for i in range(0,dat.shape[0]):
        deaths_age5.append(dat['M_65-74'].loc[i]*dat['AF'].loc[i]*dat['P_65-74'].loc[i])
    for i in range(0,dat.shape[0]):
        deaths_RRlow_age5.append(dat['M_65-74'].loc[i]*dat['AF_low'].loc[i]*dat['P_65-74'].loc[i])
    for i in range(0,dat.shape[0]):
        deaths_RRup_age5.append(dat['M_65-74'].loc[i]*dat['AF_up'].loc[i]*dat['P_65-74'].loc[i])
    
    dat['deaths_age5'] = deaths_age5
    dat['deaths_RRlow_age5'] = deaths_RRlow_age5
    dat['deaths_RRup_age5'] = deaths_RRup_age5
    
    for i in range(0,dat.shape[0]):
        deaths_age6.append(dat['M_75-84'].loc[i]*dat['AF'].loc[i]*dat['P_75-84'].loc[i])
    for i in range(0,dat.shape[0]):
        deaths_RRlow_age6.append(dat['M_75-84'].loc[i]*dat['AF_low'].loc[i]*dat['P_75-84'].loc[i])
    for i in range(0,dat.shape[0]):
        deaths_RRup_age6.append(dat['M_75-84'].loc[i]*dat['AF_up'].loc[i]*dat['P_75-84'].loc[i])
    
    dat['deaths_age6'] = deaths_age6
    dat['deaths_RRlow_age6'] = deaths_RRlow_age6
    dat['deaths_RRup_age6'] = deaths_RRup_age6
    
    for i in range(0,dat.shape[0]):
        deaths_age7.append(dat['M_85+'].loc[i]*dat['AF'].loc[i]*dat['P_85+'].loc[i])
    for i in range(0,dat.shape[0]):
        deaths_RRlow_age7.append(dat['M_85+'].loc[i]*dat['AF_low'].loc[i]*dat['P_85+'].loc[i])
    for i in range(0,dat.shape[0]):
        deaths_RRup_age7.append(dat['M_85+'].loc[i]*dat['AF_up'].loc[i]*dat['P_85+'].loc[i])
    
    dat['deaths_age7'] = deaths_age7
    dat['deaths_RRlow_age7'] = deaths_RRlow_age7
    dat['deaths_RRup_age7'] = deaths_RRup_age7
    # Set output filename
  
    outfname = '/nas/longleaf/home/revathi/chaq/revathi/mortality_results/RESP/CMAQ/CDC_EPA_grid_mort_results_'+str(Year)+'.csv'
  
    np.savetxt(outfname, dat, delimiter=',', fmt='%s') 
