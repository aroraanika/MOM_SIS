#!/bin/csh -f

#!/bin/sh


#PBS -q DESK
#PBS -l select=2:ncpus=36
#PBS -l walltime=4000:00:00
#PBS -N am4run
#PBS -l place=scatter

#PBS -M anika.cat@tropmet.res.in

# Minimal runscript for MOM experiments

set type          = MOM_SIS       # type of the experiment
set name          = om3_core1 
set platform      = ncrc2.intel     # A unique identifier for your platform
set npes          = 24              # number of processor
                                   # Note: If you change npes you may need to change
                                   # the layout in the corresponding namelist
set valid_npes = 0
set help = 0
set download = 0
set argv = (`getopt -u -o h -l type: -l platform: -l npes: -l experiment: -l debug  -l help -l download_input_data --  $*`)
while ("$argv[1]" != "--")
    switch ($argv[1])
        case --type:
                set type = $argv[2]; shift argv; breaksw    
        case --platform:
                set platform = $argv[2]; shift argv; breaksw
        case --npes:
                set npes = $argv[2]; shift argv; breaksw
        case --experiment:
                set name = $argv[2]; shift argv; breaksw
        case --debug:
                set debug = 1;  breaksw
        case --help:
                set help = 1;  breaksw
        case -h:
                set help = 1;  breaksw
        case --download_input_data:
                set download = 1;  breaksw
    endsw
    shift argv
end
shift argv

if ( $help ) then
    echo "The optional arguments are:"
    echo "--type       followed by the type of the experiment, currently one of the following:"
    echo "             MOM_solo : solo ocean model"
    echo "             MOM_SIS  : ocean-seaice model"
    echo "             CM2M     : ocean-seaice-land-atmosphere coupled climate model"
    echo "             ESM2M    : ocean-seaice-land-atmosphere coupled climate model with biogeochemistry, EarthSystemModel"
    echo "             ICCM     : ocean-seaice-land-atmosphere coupled model"
    echo 
    echo "--experiment followed by the name of the experiment of the specified type"
    echo "             To see the list of available experiments for each type use  -h --type type_name"
    if ( $type == MOM_solo ) then    
    echo "             Available expeiments for MOM_solo:"
    echo "             box1, box_channel1, bowl1, dome1, gyre1, iom1, mk3p51, symmetric_box1, torus1, dome_bates_blobs1"
    endif
    if ( $type == MOM_SIS ) then    
    echo "             Available expeiments for MOM_SIS:"
    echo "             om3_core1, om3_core3, MOM_SIS_TOPAZ, MOM_SIS_BLING, atlantic1"
    endif
    if ( $type == CM2M ) then    
    echo "             Available expeiments for CM2M:"
    echo "             CM2.1p1, CM2M_coarse_BLING"
    endif
    if ( $type == ESM2M ) then    
    echo "             Available expeiments for ESM2M:"
    echo "             ESM2M_pi-control_C2"
    endif
    if ( $type == ICCM ) then    
    echo "             Available expeiments for ICCM:"
    echo "             ICCMp1"
    endif
    if ( $type == EBM ) then    
    echo "             Available expeiments for EBM:"
    echo "             mom4p1_ebm1"
    endif
    echo 
    echo 
    echo "--platform   followed by the platform name that has a corresponfing environ file in the ../bin dir, default is ncrc.intel"
    echo 
    echo "--npes       followed by the number of pes to be used for this experiment"
    echo 
    echo Note that the executable for the run should have been built before calling this script. This could be done by calling the appropriate compile script for this experiment \"type\" beforehand.
    echo 
    echo 
    exit 0
endif

set root          = /home/DESK         # The directory in which you checked out src
set code_dir      = $root/anika/MOM_SIS/src                         # source code directory
set workdir       = /home/DESK/anika/MOM_SIS/work_IAF     # where the model is run and model output is produced
                                   # This is recommended to be a link to the $WORKDIR of the platform.
set expdir        = $workdir/$name
#set inputDataDir  = /home/DESK/anika/MOM_SIS/INPUT   # This is path to the directory that contains the input data for this experiment.
#set inputDataDir  = /home/DESK/anika/MOM_SIS/work/box1/INPUT   # ANIKA RESTART files are copied to this folder in addition to INPUT files required data.
#set inputDataDir = /home/DESK/anika/MOM_SIS/MOM_SIS_TOPAZ/INPUT                                    # You should have downloaded and untared this directory from MOM4p1 FTP site.
#set inputDataDir = /home/DESK/anika/MOM_SIS/om3_core1/INPUT
set inputDataDir = /home/DESK/anika/MOM_SIS/work_IAF/om3_core1/INPUT

set diagtable     = $inputDataDir/diag_table  # path to diagnositics table
set datatable     = $inputDataDir/data_table  # path to the data override table.
set fieldtable    = $inputDataDir/field_table # path to the field table
set namelist      = $inputDataDir/input.nml   # path to namelist file

set executable    = $root/anika/MOM_SIS/exec/$platform/$type/fms_$type.x      # executable created after compilation

#set archive       = $ARCHIVE/$type #Large directory to host the input and output data.

# ANIKA AUG 3 2020
set restartdir    =   /home/DESK/anika/MOM_SIS/work_IAF/om3_core1/RESTART
set save          = /home/DESK/anika/MOM_SIS/work_IAF/om3_core1/output_IAF
set StartYear     = 1951
set RestartYear   = 1951
set EndYear       = 1954
# ANIKA AUG 3 2020

#===========================================================================
# The user need not change any of the following
#===========================================================================

#
# Users must ensure the correct environment file exists for their platform.
#
source $root/anika/MOM_SIS/bin/environs.$platform  # environment variables and loadable modules

set mppnccombine  = $root/anika/MOM_SIS/bin/mppnccombine.$platform  # path to executable mppnccombine
set time_stamp    = $root/anika/MOM_SIS/bin/time_stamp.csh          # path to cshell to generate the date

# Check if the user has extracted the input data
  if ( ! -d $inputDataDir ) then

    if( $download ) then
      cd $workdir
      wget ftp.gfdl.noaa.gov:/perm/MOM4/mom4p1_pubrel_dec2009/exp/$name.input.tar.gz
      tar zxvf $name.input.tar.gz
    else  

    echo "ERROR: the experiment directory '$inputDataDir' does not exist or does not contain input and preprocessing data directories!"
    echo "Please download and extract the tar ball corresponding to this experiment from GFDL anonymous ftp site!"
    echo " cd  $workdir"
    echo " wget ftp.gfdl.noaa.gov:/perm/MOM4/mom5_pubrel_dec2013/exp/$name.input.tar.gz"
    echo " tar zxvf $name.input.tar.gz" 
    echo "Then rerun this script."
    echo "Or use the --download option to do this automatically"
    exit 1

    endif
  endif

set echo


# setup directory structure
if ( ! -d $expdir )         mkdir -p $expdir
if ( ! -d $expdir/RESTART ) mkdir -p $expdir/RESTART

#
#Check the existance of essential input files
#
 if ( ! -e $inputDataDir/grid_spec.nc ) then
#  if ( ! -e /home/DESK/anika/MOM_CM2M_RASH/src/t-preprocessing/generate_grids/make_xgrids/workdir/grid_spec.nc ) then

    echo "ERROR: required input file does not exist $inputDataDir/grid_spec.nc "
    exit 1
  endif
  if ( ! -e $inputDataDir/ocean_temp_salt.res.nc ) then
    echo "ERROR: required input file does not exist $inputDataDir/ocean_temp_salt.res.nc "
    exit 1
  endif



# --- make sure executable is up to date ---
  set makeFile      = Make_$type
  cd $executable:h
  make -f $makeFile
  if ( $status != 0 ) then
    unset echo
    echo "ERROR: make failed"
    exit 1
  endif
#--------------``-----------------------------



# Change to expdir

  cd $expdir
#KDH-loop strat
@ year = $RestartYear

while ( $year <= $EndYear ) #KDH-loop

echo "$year"

 if( $year == $StartYear ) then #KDH-loop

# Create INPUT directory. Make a link instead of copy
# 
  if ( ! -d $expdir/INPUT   ) mkdir -p $expdir/INPUT
#cp -f $inputDataDir/* $expdir/INPUT/.
#cp -f $restartdir/* $expdir/INPUT/.
  
  if ( ! -e $namelist ) then
    echo "ERROR: required input file does not exist $namelist "
	exit 1
  endif
  if ( ! -e $datatable ) then
    echo "ERROR: required input file does not exist $datatable "
	exit 1
  endif
  if ( ! -e $diagtable ) then
    echo "ERROR: required input file does not exist $diagtable "
	exit 1
  endif
  if ( ! -e $fieldtable ) then
    echo "ERROR: required input file does not exist $fieldtable "
	exit 1
  endif

  cp $namelist   input.nml
  cp $datatable  data_table
  cp $diagtable  diag_table
  cp $fieldtable field_table

 else #HS-loop ==>

  if( ! -d $expdir/RESTART) then
    echo "ERROR: required restart files do not exist."
	exit 1
endif
 # else
   cp -f $expdir/RESTART/* $expdir/INPUT  
# endif

 endif #HS-loop <==

 ####wind&Heat fluxforcing modified by HS####
 @ iyr = $year  # '#'=original
 cp -f /home/DESK/anika/MOM_SIS/work_IAF/om3_core1/CIAF/U/u_10.$iyr* $expdir/INPUT/u_10_mod.clim.nc
 cp -f /home/DESK/anika/MOM_SIS/work_IAF/om3_core1/CIAF/V/v_10.$iyr.*  $expdir/INPUT/v_10_mod.clim.nc
 cp -f /home/DESK/anika/MOM_SIS/work_IAF/om3_core1/CIAF/Q/q_10.$iyr.* $expdir/INPUT/q_10_mod.clim.nc
cp -f /home/DESK/anika/MOM_SIS/work_IAF/om3_core1/CIAF/T/t_10.$iyr.* $expdir/INPUT/t_10_mod.clim.nc
cp -f /home/DESK/anika/MOM_SIS/work_IAF/om3_core1/CIAF/SLP/slp.$iyr.* $expdir/INPUT/slp_.nc
cp -f /home/DESK/anika/MOM_SIS/work_IAF/om3_core1/CIAF/RAD/ncar_rad.$iyr.*  $expdir/INPUT/ncar_rad_clim.nc
cp -f /home/DESK/anika/MOM_SIS/work_IAF/om3_core1/CIAF/PRECIP/ncar_precip.$iyr.* $expdir/INPUT/ncar_precip_clim.nc
 ############################################



#Preprocessings
  $root/anika/MOM_SIS/exp/preprocessing.csh
  
if ( $type == CM2M & $npes != 45 ) then
    set valid_npes = 45
endif

if ( $type == ESM2M & $npes != 90 ) then
    set valid_npes = 90
endif
if ( $type == ICCM & $npes != 54 ) then
    set valid_npes = 54
endif
if ( $name  == atlantic1 & $npes != 24) then
    set valid_npes = 24
endif
if ( $name  == mom4p1_ebm1 & $npes != 17) then
    set valid_npes = 17
endif
#set runCommand = "time $mpirunCommand $npes $executable >fms.out"
#set runCommand = "time $mpirunCommand $npes $executable > output.$PBS_JOBID 2>&1" 
set runCommand = "time aprun -n $npes  $executable > output.$PBS_JOBID 2>&1" 
echo "About to run the command $runCommand"

if ( $valid_npes ) then
    echo "ERROR: This experiment is designed to run on $valid_npes pes. Please specify --npes  $valid_npes "
    echo "Note:  In order to change the default npes for an expeiment the user may need to edit the values of layouts and atmos_npes and ocean_npes in the input.nml and run the mpi command manually in the working dir"
    exit 0 
endif

#   --- run the model ---

$runCommand

#----------------------------------------------------------------------------------------------
# generate date for file names ---
    set begindate = `$time_stamp -bf digital`
    if ( $begindate == "" ) set begindate = tmp`date '+%j%H%M%S'`
    set enddate = `$time_stamp -ef digital`
    if ( $enddate == "" ) set enddate = tmp`date '+%j%H%M%S'`
    if ( -f time_stamp.out ) rm -f time_stamp.out
#----------------------------------------------------------------------------------------------
# get a tar restart file
  cd RESTART
  cp $expdir/input.nml .
  cp $expdir/*_table .
# combine netcdf files
  if ( $npes > 1 ) then
    #Concatenate blobs restart files. mppnccombine would not work on them.
    ncecat ocean_blobs.res.nc.???? ocean_blobs.res.nc
    rm ocean_blobs.res.nc.????
    set file_previous = ""
    set multires = (`ls *.nc.????`)
    foreach file ( $multires )
	if ( $file:r != $file_previous:r ) then
	    set input_files = ( `ls $file:r.????` )
              if ( $#input_files > 0 ) then
                 $mppnccombine $file:r $input_files
                 if ( $status != 0 ) then
                   echo "ERROR: in execution of mppnccombine on restarts"
                   exit 1
                 endif
                 rm $input_files
              endif
           else
              continue
           endif
           set file_previous = $file
       end
  endif

  cd $expdir
mkdir history
  mkdir ascii
#----------------------------------------------------------------------------------------------
# rename ascii files with the date
  foreach out (`ls *.out`)
     mv $out ascii/$begindate.$out
  end

#----------------------------------------------------------------------------------------------
# combine netcdf files
  if ( $npes > 1 ) then
    #Don't combine blobs history files. They need special handling.
    mv ocean_blobs.nc.???? history/
    set file_previous = ""
    set multires = (`ls *.nc.????`)
    foreach file ( $multires )
	if ( $file:r != $file_previous:r ) then
	    set input_files = ( `ls $file:r.????` )
              if ( $#input_files > 0 ) then
                 $mppnccombine $file:r $input_files
                 if ( $status != 0 ) then
                   echo "ERROR: in execution of mppnccombine on restarts"
                   exit 1
                 endif
                 rm $input_files
              endif
           else
              continue
           endif
           set file_previous = $file
       end
  endif

#----------------------------------------------------------------------------------------------
# rename nc files with the date
  foreach ncfile (`/bin/ls *.nc`)
     mv $ncfile history/$begindate.$ncfile
  end

  unset echo
  if( ! -d $expdir/RESTART_$iyr) mkdir -p $expdir/RESTART_$iyr

cp -f $expdir/RESTART/* $expdir/RESTART_$iyr/
echo "RESTART_folder generated"
cp -f $expdir/RESTART_$iyr $expdir/INPUT/
echo "restart data of previous year copied to INPUT folder"
echo end_of_run
echo "NOTE: Natural end-of-script."

#Archive the results

#cd $workdir
#tar cvf $name.output.tar --exclude=data_table --exclude=diag_table --exclude=field_table --exclude=fms_$type.x --exclude=input.nml --exclude=INPUT $name
#gzip $name.output.tar
#mv $name.output.tar.gz $archive/

exit 0
  



