#!/bin/csh
#SBATCH -p cleanup_queue
#SBATCH -t 24:00:00               # wall-clock time (hrs:mins)
#SBATCH --mem=64g
#SBATCH -n 1                   # number of tasks in job         
#SBATCH --ntasks-per-node=1     # run 16 MPI tasks per node
#SBATCH -J ihme_process
#SBATCH -o myjob.%J.out        # output file name in which %J is replaced by the job ID

#run the executable
#source /glade/u/apps/opt/slurm_init/init.csh
module load ncarg/6.4.0
module load python/3.7.9 

#python create_population_age_fraction_3D.py
#python humanhealth_calcs_01x01_ozone_GBD2019.py

#foreach LOOPYEARS (1990 1995 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019)
#  setenv LOOPYEAR $LOOPYEARS
#  echo ${LOOPYEAR}
  python 1a_prepdata.py
  python Feature_to_Raster.py 
#end

