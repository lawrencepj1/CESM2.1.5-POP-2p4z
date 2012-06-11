#! /bin/csh -f

if !(-d $OBJROOT/ocn/obj   ) mkdir -p $OBJROOT/ocn/obj    || exit 2
if !(-d $OBJROOT/ocn/source) mkdir -p $OBJROOT/ocn/source || exit 3 

if !(-d $CASEBUILD/pop2conf) mkdir $CASEBUILD/pop2conf || exit 1
cd $CASEBUILD/pop2conf || exit -1

set default_ocn_in_filename = "pop2_in"
set inst_counter = 1
while ($inst_counter <= $NINST_OCN)

if ($NINST_OCN > 1) then
    set inst_string = $inst_counter
    if ($inst_counter <= 999) set inst_string = "0$inst_string"
    if ($inst_counter <=  99) set inst_string = "0$inst_string"
    if ($inst_counter <=   9) set inst_string = "0$inst_string"
    set inst_string = _${inst_string}
else
    set inst_string = ""
endif

set ocn_in_filename = ${default_ocn_in_filename}${inst_string}

if ($NINST_OCN > 1) then
   # pop rpointer name for multi-instance case
   if (! -e $RUNDIR/rpointer.ocn${inst_string}.ovf && -e $RUNDIR/rpointer.ocn.ovf) then
      cp $RUNDIR/rpointer.ocn.ovf $RUNDIR/rpointer.ocn${inst_string}.ovf
   endif
   if (! -e $RUNDIR/rpointer.ocn${inst_string}.restart && -e $RUNDIR/rpointer.ocn.restart) then
      cp $RUNDIR/rpointer.ocn.restart $RUNDIR/rpointer.ocn${inst_string}.restart
   endif
   if (! -e $RUNDIR/rpointer.ocn${inst_string}.tavg && -e $RUNDIR/rpointer.ocn.tavg) then
      cp $RUNDIR/rpointer.ocn.tavg $RUNDIR/rpointer.ocn${inst_string}.tavg
   endif
   if (! -e $RUNDIR/rpointer.ocn${inst_string} && -e $RUNDIR/rpointer.ocn) then
      cp $RUNDIR/rpointer.ocn $RUNDIR/rpointer.ocn${inst_string}
   endif
endif

# following env variable is not in any xml files - but is needed by pop's build-namelist
if ($RUN_TYPE == startup) then
  setenv RESTART_INPUT_TS_FMT 'bin'
  if (-e $RUNDIR/rpointer.ocn${inst_string}.restart && $CONTINUE_RUN == 'TRUE') then
    grep 'RESTART_FMT=' $RUNDIR/rpointer.ocn${inst_string}.restart >&! /dev/null
    if ($status == 0) then
      setenv RESTART_INPUT_TS_FMT `grep RESTART_FMT= $RUNDIR/rpointer.ocn${inst_string}.restart | cut -c13-15`
    endif
  endif 
endif
if ($RUN_TYPE == branch || $RUN_TYPE == hybrid) then
  setenv RESTART_INPUT_TS_FMT 'bin'
  grep 'RESTART_FMT=' $RUNDIR/rpointer.ocn${inst_string}.restart >&! /dev/null
  if ($status == 0) then
    setenv RESTART_INPUT_TS_FMT `grep RESTART_FMT= $RUNDIR/rpointer.ocn${inst_string}.restart | cut -c13-15`
  endif
endif

if (-e $CASEROOT/user_nl_pop2${inst_string}) then
  $UTILROOT/Tools/user_nlcreate -user_nl_file $CASEROOT/user_nl_pop2${inst_string} \
	-namelist_name pop2_inparm >! $CASEBUILD/pop2conf/cesm_namelist 
endif

# Check to see if "-preview" flag should be passed
if ( $?PREVIEW_NML ) then
  set PREVIEW_FLAG = "-preview"
else
  set PREVIEW_LINE = ""
endif

# Check to see if build-namelist exists in SourceMods
if (-e $CASEROOT/SourceMods/src.pop2/build-namelist) then
  set BLD_NML_DIR = $CASEROOT/SourceMods/src.pop2
  set CFG_FLAG = "-cfg_dir $CODEROOT/ocn/pop2/bld"
else
  set BLD_NML_DIR = $CODEROOT/ocn/pop2/bld
  set CFG_FLAG = ""
endif

$BLD_NML_DIR/build-namelist $CFG_FLAG $PREVIEW_FLAG \
    -infile $CASEBUILD/pop2conf/cesm_namelist \
    -caseroot $CASEROOT \
    -casebuild $CASEBUILD \
    -scriptsroot $SCRIPTSROOT \
    -inst_string "$inst_string" \
    -ocn_grid "$OCN_GRID" || exit -1  

if (-d ${RUNDIR}) then
  cp $CASEBUILD/pop2conf/pop2_in ${RUNDIR}/$ocn_in_filename || exit -2
endif

# pop rpointer name for multi-instance case
foreach suffix ( ovf restart tavg ) 
   if (! -e $RUNDIR/rpointer.ocn${inst_string}.suffix && -e $RUNDIR/rpointer.ocn.suffix ) then
      cp $RUNDIR/rpointer.ocn.$suffix $RUNDIR/rpointer.ocn${inst_string}.$suffix
   endif
end 
if (! -e $RUNDIR/rpointer.ocn${inst_string} && -e $RUNDIR/rpointer.ocn) then
   cp $RUNDIR/rpointer.ocn $RUNDIR/rpointer.ocn${inst_string}
endif

if (-f $RUNDIR/pop2_in${inst_string}) rm $RUNDIR/pop2_in${inst_string}
cp -fp $CASEBUILD/pop2conf/pop2_in                    ${RUNDIR}/pop2_in${inst_string}
cp -fp $CASEBUILD/pop2conf/${OCN_GRID}_tavg_contents  ${RUNDIR}/${OCN_GRID}_tavg_contents


@ inst_counter = $inst_counter + 1

end



