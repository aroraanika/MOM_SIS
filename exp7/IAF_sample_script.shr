utput files
#PBS -e last.err
#PBS -o last.log
### Queue name
#PBS -q batch
### Number of nodes
#PBS -l nodes=npgo12:ppn=24+npgo13:ppn=24
#PBS -j oe
# Run the parallel MPI executable

# Minimal runscript for MOM experiments

set type          = MOM_SIS       # type of the experiment
set name          = om3_core3
set platform      = ifort11     # A unique identifier for your platform
set npes          = 48            # number of processor
                                 # Note: If you change npes you may need to change
                                 # the layout in the corresponding namelist

set mpirunCommand = /usr/local/mpi/intel/mvapich2-1.7/bin/mpirun
#set mpirunCommand = /usr/local/mpich2/intel11/bin/mpirun

set valid_npes = 0
set help = 0
set download = 0
set debug = 0
set valgrind = 0
set argv = (`getopt -u -o h -l type: -l platform: -l npes: -l experiment: -l debug -l valgrind -l help -l download_input_data --  $*`)
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
                set debug = 1; breaksw
        case --valgrind:
                set valgrind = 1; breaksw
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
    echo "             Available experiments for MOM_solo:"
    echo "             box1, box_channel1, bowl1, dome1, gyre1, iom1, mk3p51, symmetric_box1, torus1, dome_bates_blobs1"
    endif
    if ( $type == MOM_SIS ) then
    echo "             Available experiments for MOM_SIS:"
    echo "             om3_core1, om3_core3, MOM_SIS_TOPAZ, MOM_SIS_BLING, atlantic1, global_0.25_degree_NYF"
    endif
    if ( $type == CM2M ) then
    echo "             Available experiments for CM2M:"
    echo "             CM2.1p1, CM2M_coarse_BLING"
    endif
    if ( $type == ESM2M ) then
    echo "             Available experiments for ESM2M:"
    echo "             ESM2M_pi-control_C2"
    endif
    if ( $type == ICCM ) then
    echo "             Available experiments for ICCM:"
    echo "             ICCMp1"
    endif
    if ( $type == EBM ) then
    echo "             Available experiments for EBM:"
    echo "             mom4p1_ebm1"
    endif
    echo 
    echo 
    echo "--platform   followed by the platform name that has a corresponfing environ file in the ../bin dir, default is gfortran"
    echo 
    echo "--npes       followed by the number of pes to be used for this experiment"
    echo
    echo "--download_input_data  download the input data for the test case"
    echo 
    echo "Note that the executable for the run should have been built before calling this script. See MOM_compile.csh"
    echo 
    exit 1
endif

set root          = /home/MOM_tgnoh/mom5/MOM5-master         # The directory in which you checked out src
set code_dir      = $root/src                         # source code directory
set workdir       = $root/work/     # where the model is run and model output is produced
                                   # This is recommended to be a link to the $WORKDIR of the platform.
set expdir        = $workdir/$name
set restartdir    = $expdir/RESTART
set inputDataDir  = $root/core_c   # This is path to the directory that contains the input data for this experiment.

set Core          = $inputDataDir# You should have downloaded and untared this directory from MOM4p1 FTP site.
set diagtable     = $inputDataDir/diag_table  # path to diagnositics table
set datatable     = $inputDataDir/data_table  # path to the data override table.
set fieldtable    = $inputDataDir/field_table # path to the field table
set namelist      = $inputDataDir/input.nml   # path to namelist file

set executable    = $root/exec/$platform/$type/fms_$type.x      # executable created after compilation
set static        = 0
if($static) set executable = $root/exec/$platform/${type}_static/fms_$type.x

set archive       = $expdir/archive #Large directory to host the input and output data.
set save          = /data2/Model/LSB/MOM5/work/om3_core3/
set StartYear     = 1987
set RestartYear   = 1987
set EndYear       = 1988

#===========================================================================
# The user need not change any of the following
#===========================================================================

if ( $debug || $valgrind ) then
    setenv DEBUG true
endif

#
# Users must ensure the correct environment file exists for their platform.
#
# source $root/bin/environs.$platform  # environment variables and loadable modules

set mppnccombine  = $root/bin/mppnccombine.$platform  # path to executable mppnccombine
set time_stamp    = $root/bin/time_stamp.csh          # path to cshell to generate the date

# Check if the user has extracted the input data
#if( $download ) then
#    cd $root/data
#    ./get_exp_data.py $name.input.tar.gz
#    mkdir -p $workdir
##    cp archives/$name.input.tar.gz $workdir
##    cd $workdir
#    tar zxvf $name.input.tar.gz
#endif

if ( ! -d $inputDataDir ) then
        echo "ERROR: the experiment directory '$inputDataDir' does not exist or does not contain input and preprocessing data directories!"
        echo "Either use the --download_input_data option or copy the input data from the MOM data directory manually."
        echo "To manually dowload the data execute the following:"
        echo "cd $root/data"
        echo "./get_exp_data.py $name.input.tar.gz"
        echo "mkdir -p $workdir"
        echo "cp archives/$name.input.tar.gz $workdir"
        echo "cd $workdir"
        echo "tar zxvf $name.input.tar.gz"
        exit 1
endif

# setup directory structure
if ( ! -d $expdir )         mkdir -p $expdir
if ( ! -d $expdir/RESTART ) mkdir -p $expdir/RESTART
if ( ! -d $expdir/INPUT ) mkdir -p $expdir/INPUT

if ( ! -e $namelist ) then
    echo "ERROR: required input file does not exist $namelist."
    echo "Need to download input data? See ./MOM_run.csh -h"
    exit 1
endif
if ( ! -e $datatable ) then
    echo "ERROR: required input file does not exist $datatable."
    echo "Need to download input data? See ./MOM_run.csh -h"
    exit 1
endif
if ( ! -e $diagtable ) then
    echo "ERROR: required input file does not exist $diagtable."
    echo "Need to download input data? See ./MOM_run.csh -h"
    exit 1
endif
if ( ! -e $fieldtable ) then
    echo "ERROR: required input file does not exist $fieldtable."
    echo "Need to download input data? See ./MOM_run.csh -h"
    exit 1
endif

#
#Check the existance of essential input files

  if ( ! -e $inputDataDir/grid_spec.nc ) then
    echo "ERROR: required input file does not exist $inputDataDir/grid_spec.nc "
	exit 1
  endif
  if ( ! -e $inputDataDir/ocean_temp_salt.res.nc ) then
    echo "ERROR: required input file does not exist $inputDataDir/ocean_tmep_salt.res.nc "
	exit 1
  endif


# --- make sure executable is up to date ---
  set makeFile      = Make_$type
#  cd $executable:h
#  make -f $makeFile
#  if ( $status != 0 ) then
#    unset echo
#    echo "ERROR: make failed"
#    exit 1
#  endif
#-------------------------------------------

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
cp -f $inputDataDir/* $expdir/INPUT/.
cp -f $restartdir/* $expdir/INPUT/.
  
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
  else
    cp -f $expdir/RESTAR/* $expdir/INPUT/.
  endif

 endif #HS-loop <==

 ####wind&Heat fluxforcing modified by HS####
 @ iyr = $year  # '#'=original
 cp -f /data1/Model/MOM4/LSB/test/u10/u10/u.$iyr.input.nc $expdir/INPUT/u_10_mod.clim.nc
 cp -f /data1/Model/MOM4/LSB/test/v10/v10/v.$iyr.input.nc  $expdir/INPUT/v_10_mod.clim.nc
 cp -f /data1/Model/MOM4/LSB/test/q/q/q10.$iyr.input.nc $expdir/INPUT/q_10_mod.clim.nc
 cp -f /data1/Model/MOM4/LSB/test/t2m/t2m/t.$iyr.input.nc $expdir/INPUT/t_10_mod.clim.nc
 cp -f /data1/Model/MOM4/LSB/test/slp/slp/slpres.$iyr.input.nc $expdir/INPUT/slp_.nc
 cp -f /data1/Model/MOM4/LSB/test/rad/rad/radio.$iyr.input.nc  $expdir/INPUT/ncar_rad_clim.nc
 cp -f /data1/Model/MOM4/LSB/test/prcp/prcp/prcp.$iyr.input.nc $expdir/INPUT/ncar_precip_clim.nc
 ############################################

# Preprocessings
$root/exp/preprocessing.csh

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

if ( $name  == global_0.25_degree_NYF & $npes != 960) then
    set valid_npes = 960
endif


set runCommand = "$mpirunCommand -machinefile $PBS_NODEFILE -np $npes $executable >fms.out"
if ( $valgrind ) then
    set runCommand = "$mpirunCommand $npes -x LD_PRELOAD=$VALGRIND_MPI_WRAPPERS valgrind --gen-suppressions=all --suppressions=../../test/valgrind_suppressions.txt --main-stacksize=2000000000 --max-stackframe=2000000000 --error-limit=no $executable >fms.out"
endif

if ( $debug ) then
    set runCommand = "$mpirunCommand -machinefile $PBS_NODEFILE -np --debug $npes $executable >fms.out"
endif

echo "About to run experiment $name with model $type at `date`. The command is: $runCommand"

if ( $valid_npes ) then
    echo "ERROR: This experiment is designed to run on $valid_npes pes. Please specify --npes  $valid_npes "
    echo "Note:  In order to change the default npes for an expeiment the user may need to edit the values of layouts and atmos_npes and ocean_npes in the input.nml and run the mpi command manually in the working dir"
    exit 0
endif

else
	if( ! -d $expdir/RESTART) then
		echo " ERROR : required restart files do not exist."
		exit 1
endif
else
	cp -f $expdir/RESTART/* $expdir/INPUT/.
endif

# Run the model
$runCommand
set model_status = $status
if ( $model_status != 0) then
    echo "ERROR: Model failed to run to completion"
    exit 1
endif

# generate date for file names ---
set begindate = `$time_stamp -bf digital`
if ( $begindate == "" ) then
    set begindate = tmp`date '+%j%H%M%S'`
endif
set enddate = `$time_stamp -ef digital`
if ( $enddate == "" ) then
    set enddate = tmp`date '+%j%H%M%S'`
endif
if ( -f time_stamp.out ) then
    rm -f time_stamp.out
endif

# combine output files
if ( $npes > 1 ) then
    set file_previous = ""
    set multioutput = (`ls *.nc.????`)
    foreach file ( $multioutput )
        if ( $file:r != $file_previous:r ) then
            set input_files = ( `ls $file:r.????` )
            if ( $#input_files > 0 ) then
                $mppnccombine $file:r $input_files
                if ( $status != 0 ) then
                    echo "ERROR: in execution of mppnccombine on outputs"
                    echo "Command was: $mppnccombine $file:r $input_files"
                    break
                endif
            endif
        else
            continue
        endif
        set file_previous = $file
    end
endif

# get a tar restart file
cd RESTART
cp $expdir/input.nml .
cp $expdir/*_table .

# combine netcdf files
if ( $npes > 1 ) then
    # Concatenate blobs restart files. mppnccombine would not work on them.
 if ( -f ocean_blobs.res.nc.0000 ) then
        ncecat ocean_blobs.res.nc.???? ocean_blobs.res.nc
        rm ocean_blobs.res.nc.????
    endif

    # Concatenate iceberg restarts
    if ( -f icebergs.res.nc.0000 ) then
        ncrcat icebergs.res.nc.???? icebergs.res.nc
        rm icebergs.res.nc.????
    endif

    # Land restarts need to be combined with  combine-ncc
    # More simply just tar them up in this version
    set land_files = ( cana glac lake land snow soil vegn1 vegn2 )
    foreach file ( $land_files )
       set input_files = `/bin/ls ${file}.res.nc.????`
       if ( $#input_files > 0 ) then
          tar czf ${file}.res.nc.tar $input_files
          if ( $status != 0 ) then
             echo "ERROR: in creating land restarts tarfile"
             exit 1
          endif
          rm $input_files
       endif
    end

    set file_previous = ""
    set multires = (`ls *.nc.????`)
    foreach file ( $multires )
    if ( $file:r != $file_previous:r ) then
        set input_files = ( `ls $file:r.????` )
            if ( $#input_files > 0 ) then
                $mppnccombine $file:r $input_files
                if ( $status != 0 ) then
                    echo "ERROR: in execution of mppnccombine on restarts"
                    echo "Command was: $mppnccombine $file:r $input_files"
					exit 1
                endif
				rm -rf $input_files
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

#-----------------------------------------------------------------------------------------
# rename ascii files with date
  foreach out ('ls *.out')
     mv -f $out ascii/$begindate.$out
  end

#-----------------------------------------------------------------------------------------

# rename nc files with the date
foreach ncfile (`/bin/ls *.nc`)
   mv -f $ncfile history/$begindate.$ncfile
end

unset echo

echo end_of_run
echo "NOTE: Natural end-of-script for experiment $name with model $type at `date`"

#Archive the results

cd $workdir
tar cvf $name.output.tar $name/history/ $name/ascii/ $name/RESTART/##--exclude=data_table --exclude=diag_table --exclude=field_table --exclude=fms_$type.x --exclude=input.nml --exclude=INPUT $name
gzip $name.output.tar
  if (! -d $save) mkdir -p $save                      #KDH-loop
  mv -f $name.output.tar $save/$year.$name.output.tar #KDH-loop
  rm -rf $expdir/ascii/*.out $expdir/*.nc.* ._mpp.* #KDH-loop

  @ year++ #KDH-loop
end #while #KDH-loop
  mv $name.output.tar.gz $archive/

exit 0


