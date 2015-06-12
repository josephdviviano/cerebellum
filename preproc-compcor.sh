#! /bin/bash

# load AFNI, FSL, MINCtools
# module compatibility isn't working, so we're running 
# with the following amazingly inflexible solution
#                                                  -ed.

# AFNI
#export PATH=/quarantine/AFNI/AFNI_DEC_6_2013:${PATH}

# FSL
#export FSLDIR=/quarantine/FSL/fsl_5.0.3/fsl
#. ${FSLDIR}/etc/fslconf/fsl.sh
#export PATH=${FSLDIR}/bin:${PATH}

# MINC
#export PATH=/quarantine/MINC/minc/bin:${PATH}
# export variables to the top of the script
export DIR_PIPE=/home/jdv/code/hcpresto/bin/ 
export DIR_DATA=/srv/data/cere-conn/working
export DIR=/srv/data/cere-conn/working/100307
export SSID=100307
export AFNI_DECONFLICT=OVERWRITE
export OMP_NUM_THREADS=7

# set up analysis directory
cd /srv/data/cere-conn/working/100307
mkdir /srv/data/cere-conn/working/100307/proc 2> /dev/null
mkdir /srv/data/cere-conn/working/100307/proc/params 2> /dev/null
mkdir /srv/data/cere-conn/working/100307/tmp 2> /dev/null

echo '************ Loaded in modules, moving on to the pipeline. *************'
COUNT=1
echo ''
echo '************ Noise Regression Module for Resting State fMRI ************'
echo '               Making regressors masks for subject' ${SSID} 
echo '************************************************************************'
echo ''

# make eroded white matter mask in EPI space
if [ ! -f ${DIR}/proc/anat_wm_ero.nii.gz ]; then
    3dcalc \
        -a ${DIR}/MNINonLinear/aparc+aseg.nii.gz \
        -expr "equals(a,2)  + \
               equals(a,7)  + \
               equals(a,41) + \
               equals(a,46) + \
               equals(a,251)+ \
               equals(a,252)+ \
               equals(a,253)+ \
               equals(a,254)+ \
               equals(a,255)" \
        -prefix ${DIR}/proc/anat_wm.nii.gz

    3dcalc \
        -a ${DIR}/proc/anat_wm.nii.gz \
        -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k \
        -expr 'a*(1-amongst(0,b,c,d,e,f,g))' \
        -prefix ${DIR}/proc/anat_wm_ero.nii.gz

    3dresample \
        -prefix ${DIR}/proc/anat_wm_ero.nii.gz \
        -master ${DIR}/MNINonLinear/T1w_restore.2.nii.gz \
        -rmode NN \
        -inset ${DIR}/proc/anat_wm_ero.nii.gz
fi

# make eroded ventricle mask in EPI space
if [ ! -f ${DIR}/proc/anat_vent_ero.nii.gz ]; then
    3dcalc \
        -a ${DIR}/MNINonLinear/aparc+aseg.nii.gz \
        -expr 'equals(a,4) + equals(a,43)' \
        -prefix ${DIR}/proc/anat_vent.nii.gz

    3dcalc \
        -a ${DIR}/MNINonLinear/aparc+aseg.nii.gz \
        -expr "equals(a,10) + \
               equals(a,11) + \
               equals(a,26) + \
               equals(a,49) + \
               equals(a,50) + \
               equals(a,58)" \
        -prefix ${DIR}/proc/anat_nonvent.nii.gz

    3dcalc \
        -a ${DIR}/proc/anat_nonvent.nii.gz \
        -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k \
        -expr 'amongst(1,a,b,c,d,e,f,g)' \
        -prefix ${DIR}/proc/anat_nonvent_dia.nii.gz

    3dcalc \
        -a ${DIR}/proc/anat_vent.nii.gz \
        -b ${DIR}/proc/anat_nonvent_dia.nii.gz \
        -expr 'a-step(a*b)' \
        -prefix ${DIR}/proc/anat_vent_ero.nii.gz

    3dresample \
        -prefix ${DIR}/proc/anat_vent_ero.nii.gz \
        -master ${DIR}/MNINonLinear/T1w_restore.2.nii.gz \
        -rmode NN \
        -inset ${DIR}/proc/anat_vent_ero.nii.gz       
fi

# make gray matter mask
if [ ! -f ${DIR}/proc/anat_gm.nii.gz ]; then
    3dcalc \
        -a ${DIR}/MNINonLinear/aparc+aseg.nii.gz \
        -short \
        -expr 'step(a-1000)*step(1036-a)+step(a-2000)*step(2036-a)' \
        -prefix ${DIR}/proc/anat_gm.nii.gz

    3dresample \
        -prefix ${DIR}/proc/anat_gm.nii.gz \
        -master ${DIR}/MNINonLinear/T1w_restore.2.nii.gz \
        -rmode NN \
        -inset ${DIR}/proc/anat_gm.nii.gz
fi

# make dilated brain mask
if [ ! -f ${DIR}/proc/anat_EPI_mask_dia.nii.gz ]; then
    3dcalc \
        -a ${DIR}/MNINonLinear/brainmask_fs.nii.gz \
        -b a+i -c a-i -d a+j -e a-j -f a+k -g a-k \
        -expr 'amongst(1,a,b,c,d,e,f,g)' \
        -prefix ${DIR}/proc/anat_EPI_mask_dia.nii.gz

    3dresample \
        -prefix ${DIR}/proc/anat_EPI_mask_dia.nii.gz \
        -master ${DIR}/MNINonLinear/T1w_restore.2.nii.gz \
        -rmode NN \
        -inset ${DIR}/proc/anat_EPI_mask_dia.nii.gz
fi

# Loop through runs
for RUN in `ls -d ${DIR}/MNINonLinear/Results/*/`; do
    
    # generate run number for filenames, add 1 to count
    NUM=`printf %02d ${COUNT}`
    COUNT=$(( $COUNT + 1 ))
    
    # Minimally-preprocessed data
    INPUT=`ls ${RUN}/rfMRI_REST?_??.nii.gz`

    # ICA FIXed OPTION (I am morally opposed to this).
    #INPUT=`ls ${RUN}/*hp2000_clean.nii.gz`

    # only do the things if our output file dosen't exist
    if [ ! -f ${DIR}/proc/func_filtered.${NUM}.nii.gz ]; then


echo ''
echo '************************************************************************'
echo '      Making regressors timeseries for subject' ${SSID} 'run' ${NUM} 
echo '************************************************************************'
echo ''

        if [ ! -f ${DIR}/proc/func_detrend.${NUM}.nii.gz ]; then
        
            # remove outliers, recording the edits
            3dDespike \
                -prefix ${DIR}/proc/func_tmp_despike.${NUM}.nii.gz \
                -ssave ${DIR}/proc/params/spikes.${NUM}.nii.gz \
                -NEW \
                ${INPUT}

            3dTstat \
                -prefix ${DIR}/proc/func_mean.${NUM}.nii.gz \
                -mean ${DIR}/proc/func_tmp_despike.${NUM}.nii.gz

            3dTstat \
                -prefix ${DIR}/proc/func_stdev.${NUM}.nii.gz \
                -stdev ${DIR}/proc/func_tmp_despike.${NUM}.nii.gz

            # compute temporal SNR
            3dcalc \
                -a ${DIR}/proc/func_mean.${NUM}.nii.gz \
                -b ${DIR}/proc/func_stdev.${NUM}.nii.gz \
                -expr 'a/b' \
                -prefix ${DIR}/proc/func_tSNR.${NUM}.nii.gz

            3dDetrend \
                -prefix ${DIR}/proc/func_detrend.${NUM}.nii.gz \
                -polort 1 \
                ${DIR}/proc/func_tmp_despike.${NUM}.nii.gz
        fi


        ## ANATICOR METHOD -- Depricated in exchange for COMPCOR        
        # # create local white matter regressors +1 lag
        # if [ ! -f ${DIR}/proc/params/wm_local15.${NUM}.nii.gz ]; then
        #     3dLocalstat \
        #         -prefix ${DIR}/proc/params/wm_local15.${NUM}.nii.gz \
        #         -nbhd 'SPHERE(15)' \
        #         -stat mean \
        #         -mask ${DIR}/proc/anat_wm_ero.nii.gz \
        #         -use_nonmask ${INPUT}
        #     3dTcat \
        #         -prefix ${DIR}/proc/params/lag.wm_local15.${NUM}.nii.gz \
        #         ${DIR}/proc/params/wm_local15.${NUM}.nii.gz'[0]' \
        #         ${DIR}/proc/params/wm_local15.${NUM}.nii.gz'[0..$]'
        #     3dDetrend \
        #         -prefix ${DIR}/proc/params/det.wm_local15.${NUM}.nii.gz \
        #         -polort 1 \
        #         ${DIR}/proc/params/wm_local15.${NUM}.nii.gz
        #     3dDetrend \
        #         -prefix ${DIR}/proc/params/det.lag.wm_local15.${NUM}.nii.gz \
        #         -polort 1 \
        #         ${DIR}/proc/params/lag.wm_local15.${NUM}.nii.gz
        # fi
        
        # make ventricle time series & +1 lag
        3dmaskave \
            -q \
            -mask ${DIR}/proc/anat_vent_ero.nii.gz \
            ${DIR}/proc/func_detrend.${NUM}.nii.gz > ${DIR}/proc/params/vent.${NUM}.1D
        
        1dcat \
            ${DIR}/proc/params/vent.${NUM}.1D'{0}' > \
            ${DIR}/proc/params/lag.vent.${NUM}.1D
        
        1dcat \
            ${DIR}/proc/params/vent.${NUM}.1D'{0..$}' >> \
            ${DIR}/proc/params/lag.vent.${NUM}.1D

        # make white matter time series & +1 lag
        3dmaskave \
            -q \
            -mask ${DIR}/proc/anat_wm_ero.nii.gz \
            ${DIR}/proc/func_detrend.${NUM}.nii.gz > ${DIR}/proc/params/wm.${NUM}.1D
        
        1dcat \
            ${DIR}/proc/params/wm.${NUM}.1D'{0}' > \
            ${DIR}/proc/params/lag.wm.${NUM}.1D
        
        1dcat \
            ${DIR}/proc/params/wm.${NUM}.1D'{0..$}' >> \
            ${DIR}/proc/params/lag.wm.${NUM}.1D

        # find top 5 PCs in ventricles
        epi-genregress \
            ${DIR}/proc/func_detrend.${NUM}.nii.gz \
            ${DIR}/proc/anat_vent_ero.nii.gz \
            ${DIR}/proc/params/vent_PC.${NUM}.1D \
            5

        # find top 5 PCs in white matter
        epi-genregress \
            ${DIR}/proc/func_detrend.${NUM}.nii.gz \
            ${DIR}/proc/anat_wm_ero.nii.gz \
            ${DIR}/proc/params/wm_PC.${NUM}.1D \
            5

        ## make physiological regressors if possible
        if [ -f ${RUN}/*Physio_log.txt ]; then
        
            # calculate various timeseries from physio data
            popp \
                 -i ${RUN}/*Physio_log.txt \
                 -s 400 \
                 --tr=0.7 \
                 -o phys \
                 --trigger=1 \
                 --cardiac=2 \
                 --resp=3 \
                 --rvt \
                 --heartrate \
                 -v

            # calculate slice-wise regressors
            pnm_evs \
                 -i ${DIR}/proc/func_detrend.${NUM}.nii.gz \
                 -o phys_ \
                 --tr=0.7 \
                 -c phys_card.txt \
                 -r phys_resp.txt \
                 --rvt=phys_rvt.txt \
                 --heartrate=phys_hr.txt \
                 --slicedir=y \
                 -v
              
            # take 1st voxel (justified by low TR & post slice-correction)
            3dmaskdump \
                -ibox 0 0 0 \
                -noijk phys_ev001.nii.gz \
                > ${DIR}/proc/params/phys.01.${NUM}.1D
            
            3dmaskdump \
                -ibox 0 0 0 \
                -noijk phys_ev002.nii.gz \
                > ${DIR}/proc/params/phys.02.${NUM}.1D
            
            3dmaskdump \
                -ibox 0 0 0 \
                -noijk phys_ev003.nii.gz \
                > ${DIR}/proc/params/phys.03.${NUM}.1D
            
            3dmaskdump \
                -ibox 0 0 0 \
                -noijk phys_ev004.nii.gz \
                > ${DIR}/proc/params/phys.04.${NUM}.1D
            
            3dmaskdump \
                -ibox 0 0 0 \
                -noijk phys_ev005.nii.gz \
                > ${DIR}/proc/params/phys.05.${NUM}.1D
            
            3dmaskdump \
                -ibox 0 0 0 \
                -noijk phys_ev006.nii.gz \
                > ${DIR}/proc/params/phys.06.${NUM}.1D
            
            3dmaskdump \
                -ibox 0 0 0 \
                -noijk phys_ev007.nii.gz \
                > ${DIR}/proc/params/phys.07.${NUM}.1D
            
            3dmaskdump \
                -ibox 0 0 0 \
                -noijk phys_ev008.nii.gz \
                > ${DIR}/proc/params/phys.08.${NUM}.1D

            # remove all tmp phys files
            rm phys*
        fi

echo ''
echo '************************************************************************'
echo '         Fitting noise model for subject ' ${SSID}' run '${NUM} 
echo '************************************************************************'
echo ''

        if [ ! -f ${DIR}/proc/params/det.motion.${NUM}.1D ]; then
            cp ${RUN}/Movement_Regressors.txt \
               ${DIR}/proc/params/motion.${NUM}.1D

            3dDetrend \
                -prefix - \
                -DAFNI_1D_TRANOUT=YES \
                -polort 1 \
                ${DIR}/proc/params/motion.${NUM}.1D\' > \
                ${DIR}/proc/params/det.motion.${NUM}.1D
        fi

        # detrend physio data, if it exists
        if [ -f ${RUN}/*Physio_log.txt ]; then
            3dDetrend \
                -prefix - \
                -DAFNI_1D_TRANOUT=YES \
                -polort 1 \
                ${DIR}/proc/params/phys.01.${NUM}.1D > \
                ${DIR}/proc/params/det.phys.01.${NUM}.1D 

            3dDetrend \
                -prefix - \
                -DAFNI_1D_TRANOUT=YES \
                -polort 1 \
                ${DIR}/proc/params/phys.02.${NUM}.1D > \
                ${DIR}/proc/params/det.phys.02.${NUM}.1D

            3dDetrend \
                -prefix - \
                -DAFNI_1D_TRANOUT=YES \
                -polort 1 \
                ${DIR}/proc/params/phys.03.${NUM}.1D > \
                ${DIR}/proc/params/det.phys.03.${NUM}.1D

            3dDetrend \
                -prefix - \
                -DAFNI_1D_TRANOUT=YES \
                -polort 1 \
                ${DIR}/proc/params/phys.04.${NUM}.1D > \
                ${DIR}/proc/params/det.phys.04.${NUM}.1D

            3dDetrend \
                -prefix - \
                -DAFNI_1D_TRANOUT=YES \
                -polort 1 \
                ${DIR}/proc/params/phys.05.${NUM}.1D > \
                ${DIR}/proc/params/det.phys.05.${NUM}.1D

           3dDetrend \
                -prefix - \
                -DAFNI_1D_TRANOUT=YES \
                -polort 1 \
                ${DIR}/proc/params/phys.06.${NUM}.1D > \
                ${DIR}/proc/params/det.phys.06.${NUM}.1D

            3dDetrend \
                -prefix - \
                -DAFNI_1D_TRANOUT=YES \
                -polort 1 \
                ${DIR}/proc/params/phys.07.${NUM}.1D > \
                ${DIR}/proc/params/det.phys.07.${NUM}.1D

           3dDetrend \
                -prefix - \
                -DAFNI_1D_TRANOUT=YES \
                -polort 1 \
                ${DIR}/proc/params/phys.08.${NUM}.1D > \
                ${DIR}/proc/params/det.phys.08.${NUM}.1D
        fi
    
        # fit each run with all nuisance variables (COMPCOR BELOW)
        if [ -f ${RUN}/*Physio_log.txt ]; then

            3dTfitter \
                -prefix ${DIR}/proc/func_noise_betas.${NUM}.nii.gz \
                -fitts ${DIR}/proc/func_noise.${NUM}.nii.gz \
                -polort 1 \
                -RHS ${DIR}/proc/func_detrend.${NUM}.nii.gz \
                -LHS ${DIR}/proc/params/det.motion.${NUM}.1D \
                     ${DIR}/proc/params/vent.${NUM}.1D \
                     ${DIR}/proc/params/lag.vent.${NUM}.1D \
                     ${DIR}/proc/params/wm.${NUM}.1D \
                     ${DIR}/proc/params/lag.wm.${NUM}.1D \
                     ${DIR}/proc/params/vent_PC.${NUM}.1D \
                     ${DIR}/proc/params/wm_PC.${NUM}.1D \
                     ${DIR}/proc/cerebellum_wm.${NUM}.1D \
                     ${DIR}/proc/params/det.phys.01.${NUM}.1D \
                     ${DIR}/proc/params/det.phys.02.${NUM}.1D \
                     ${DIR}/proc/params/det.phys.03.${NUM}.1D \
                     ${DIR}/proc/params/det.phys.04.${NUM}.1D \
                     ${DIR}/proc/params/det.phys.05.${NUM}.1D \
                     ${DIR}/proc/params/det.phys.06.${NUM}.1D \
                     ${DIR}/proc/params/det.phys.07.${NUM}.1D \
                     ${DIR}/proc/params/det.phys.08.${NUM}.1D

        else

            3dTfitter \
                -prefix ${DIR}/proc/func_noise_betas.${NUM}.nii.gz \
                -fitts ${DIR}/proc/func_noise.${NUM}.nii.gz \
                -polort 1 \
                -RHS ${DIR}/proc/func_detrend.${NUM}.nii.gz \
                -LHS ${DIR}/proc/params/det.motion.${NUM}.1D \
                     ${DIR}/proc/params/vent.${NUM}.1D \
                     ${DIR}/proc/params/lag.vent.${NUM}.1D \
                     ${DIR}/proc/params/wm.${NUM}.1D \
                     ${DIR}/proc/params/lag.wm.${NUM}.1D \
                     ${DIR}/proc/params/vent_PC.${NUM}.1D \
                     ${DIR}/proc/params/wm_PC.${NUM}.1D
        fi

echo ''
echo '************************************************************************'
echo '       Subtracting noise model from subject' ${SSID} 'run ' ${NUM} 
echo '************************************************************************'
echo ''
        # subtracts nuisances from inputs, retaining the mean
        3dcalc \
            -float \
            -a ${DIR}/proc/func_detrend.${NUM}.nii.gz \
            -b ${DIR}/proc/func_noise.${NUM}.nii.gz \
            -c ${DIR}/proc/func_mean.${NUM}.nii.gz \
            -expr 'a-b+c' \
            -prefix ${DIR}/proc/func_filtered.${NUM}.nii.gz
    fi

    rm ${DIR}/proc/func_noise.${NUM}.nii.gz

done

rm ${DIR}/proc/func_tmp_*

INPUT=func_filtered
COUNT=1
echo ''
echo '******* Nonlinear De-Warp to Native Space for Resting State fMRI *******'
echo '                Running on files with prefix' ${INPUT}
echo '************************************************************************'
echo ''

## LOOP THROUGH RUNS
for RUN in `ls -d ${DIR}/MNINonLinear/Results/*/`; do
    # generate run number for filenames, add 1 to count
    NUM=`printf %02d ${COUNT}`
    COUNT=$(( $COUNT + 1 ))

    echo 'De-MNIing subject ' ${SSID} ' run ' ${NUM} 

    # create reg target for escaping from MNI space (re-sampled)
    if [ ! -f ${DIR}/T1w/T1w_resample_brain.nii.gz ]; then
        3dresample \
            -prefix ${DIR}/T1w/T1w_resample_brain.nii.gz \
            -dxyz 2.0 2.0 2.0 \
            -inset ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz
    fi

    # warp image back to ACPC space with spline interpolation
    if [ ! -f ${DIR}/proc/func_warped.${NUM}.nii.gz ]; then

echo ''
echo '************************************************************************'
echo '            Warping' ${SSID} 'run ' ${NUM} 'to native space' 
echo '************************************************************************'
echo ''

        applywarp \
          -i ${DIR}/proc/${INPUT}.${NUM}.nii.gz \
          -o ${DIR}/tmp/func_warped.${NUM}.nii.gz \
          -r ${DIR}/T1w/T1w_resample_brain.nii.gz \
          -w ${DIR}/MNINonLinear/xfms/standard2acpc_dc.nii.gz \
          --interp=spline

        # the FSL transformation makes extra-brain voxels non-zero.
        # this turns them back to zeros, usually resulting in 1/3 compression.
        3dcalc \
            -a ${DIR}/tmp/func_warped.${NUM}.nii.gz \
            -expr 'a*astep(a, 10)' \
            -prefix ${DIR}/proc/func_warped.${NUM}.nii.gz
    fi
done
CIV='civet'
echo ''
echo '************** Moves MNI-space Civet .obj to Native Space **************'
echo '                  No reason to explain this further ;)'
echo '************************************************************************'
echo ''

# invert linear tranform
xfminvert \
    ${DIR}/${CIV}/transforms/linear/*t1_tal.xfm \
    ${DIR}/tmp/dewarp_linear.xfm

# linear dewarp each standard-spaced surface file
if [ ! -f ${DIR}/proc/surf_wm_L.obj ]; then
    transform_objects \
        ${DIR}/${CIV}/surfaces/*${SSID}_white_surface_left_calibrated_*.obj \
        ${DIR}/tmp/dewarp_linear.xfm \
        ${DIR}/proc/surf_wm_L.obj
fi

if [ ! -f ${DIR}/proc/surf_wm_R.obj ]; then
    transform_objects \
        ${DIR}/${CIV}/surfaces/*${SSID}_white_surface_right_calibrated_*.obj \
        ${DIR}/tmp/dewarp_linear.xfm \
        ${DIR}/proc/surf_wm_R.obj
fi

if [ ! -f ${DIR}/proc/surf_mid_L.obj ]; then
    transform_objects \
        ${DIR}/${CIV}/surfaces/*${SSID}_mid_surface_left_*.obj \
        ${DIR}/tmp/dewarp_linear.xfm \
        ${DIR}/proc/surf_mid_L.obj
fi

if [ ! -f ${DIR}/proc/surf_mid_R.obj ]; then
    transform_objects \
        ${DIR}/${CIV}/surfaces/*${SSID}_mid_surface_right_*.obj \
        ${DIR}/tmp/dewarp_linear.xfm \
        ${DIR}/proc/surf_mid_R.obj
fi

if [ ! -f ${DIR}/proc/surf_gm_L.obj ]; then
    transform_objects \
        ${DIR}/${CIV}/surfaces/*${SSID}_gray_surface_left_*.obj \
        ${DIR}/tmp/dewarp_linear.xfm \
        ${DIR}/proc/surf_gm_L.obj
fi

if [ ! -f ${DIR}/proc/surf_gm_R.obj ]; then
    transform_objects \
        ${DIR}/${CIV}/surfaces/*${SSID}_gray_surface_right_*.obj \
        ${DIR}/tmp/dewarp_linear.xfm \
        ${DIR}/proc/surf_gm_R.obj
fi
COUNT=1
CIV='civet'
INPUT=func_warped
FWHM=20
echo ''
echo '*************** Cortical Smoothing for Resting State fMRI **************'
echo '      were going to use the native-space Civet surfaces to get our   '
echo '  functional data on a surface, whence it will be smoothed and exported '
echo '           as an ASCII file to be readinto R / MATLAB / PYTHON          '
echo '************************************************************************'
echo ''

# convert civet surfaces to freesurfer binaries
if [ ! -f ${DIR}/proc/surf_wm_L.asc ]; then
    ConvertSurface \
        -i_mni ${DIR}/proc/surf_wm_L.obj \
        -o_fs ${DIR}/proc/surf_wm_L.asc \
        -sv ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz
fi

if [ ! -f ${DIR}/proc/surf_wm_R.asc ]; then
    ConvertSurface \
        -i_mni ${DIR}/proc/surf_wm_R.obj \
        -o_fs ${DIR}/proc/surf_wm_R.asc \
        -sv ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz
fi

if [ ! -f ${DIR}/proc/surf_mid_L.asc ]; then
    ConvertSurface \
        -i_mni ${DIR}/proc/surf_mid_L.obj \
        -o_fs ${DIR}/proc/surf_mid_L.asc \
        -sv ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz
fi

if [ ! -f ${DIR}/proc/surf_mid_R.asc ]; then
    ConvertSurface \
        -i_mni ${DIR}/proc/surf_mid_R.obj \
        -o_fs ${DIR}/proc/surf_mid_R.asc \
        -sv ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz
fi

if [ ! -f ${DIR}/proc/surf_gm_L.asc ]; then
    ConvertSurface \
        -i_mni ${DIR}/proc/surf_gm_L.obj \
        -o_fs ${DIR}/proc/surf_gm_L.asc \
        -sv ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz
fi

if [ ! -f ${DIR}/proc/surf_gm_R.asc ]; then
    ConvertSurface \
        -i_mni ${DIR}/proc/surf_gm_R.obj \
        -o_fs ${DIR}/proc/surf_gm_R.asc \
        -sv ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz
fi

# make an AFNI-COMPATIBLE spec file
# NB -- lack of absoloute paths here.
# this is likly because AFNI is poorly-written. 
# by hungry graduate students.
# instead of real people.

quickspec \
  -tn FS proc/surf_wm_L.asc \
  -tn FS proc/surf_wm_R.asc \
  -tn FS proc/surf_gm_L.asc \
  -tn FS proc/surf_gm_R.asc \
  -tn FS proc/surf_mid_L.asc \
  -tn FS proc/surf_mid_R.asc

## loop through runs
for RUN in `ls -d ${DIR}/MNINonLinear/Results/*/`; do

    # generate run number for filenames, add 1 to count
    NUM=`printf %02d ${COUNT}`
    COUNT=$(( $COUNT + 1 ))

    # Smooth cortical data on surface for each subject
    if [ ! -f ${DIR}/proc/func_surface_civ.L.${NUM}.1D.dset ]; then
        3dVol2Surf \
          -spec quick.spec \
          -surf_A proc/surf_wm_L.asc \
          -surf_B proc/surf_gm_L.asc \
          -sv T1w/T1w_acpc_dc_restore_brain.nii.gz \
          -grid_parent proc/${INPUT}.${NUM}.nii.gz \
          -map_func ave \
          -f_steps 15 \
          -f_index nodes \
          -outcols_NSD_format \
          -out_1D tmp/func_surface_civ.L.${NUM}.1D

        SurfSmooth \
          -met HEAT_07 \
          -spec quick.spec \
          -surf_A proc/surf_gm_L.asc \
          -input tmp/func_surface_civ.L.${NUM}.1D \
          -target_fwhm ${FWHM} \
          -output proc/func_surface_civ.L.${NUM}.1D
    fi

    if [ ! -f ${DIR}/proc/func_surface_civ.R.${NUM}.1D.dset ]; then
        3dVol2Surf \
          -spec quick.spec \
          -surf_A proc/surf_wm_R.asc \
          -surf_B proc/surf_gm_R.asc \
          -sv T1w/T1w_acpc_dc_restore_brain.nii.gz \
          -grid_parent proc/${INPUT}.${NUM}.nii.gz \
          -map_func ave \
          -f_steps 15 \
          -f_index nodes \
          -outcols_NSD_format \
          -out_1D tmp/func_surface_civ.R.${NUM}.1D
        
        SurfSmooth \
          -met HEAT_07 \
          -spec quick.spec \
          -surf_A proc/surf_wm_R.asc \
          -input tmp/func_surface_civ.R.${NUM}.1D \
          -target_fwhm ${FWHM} \
          -output proc/func_surface_civ.R.${NUM}.1D      
    fi
done
COUNT=1
CIV='civet'
FWHM=20
echo ''
echo '*************** Cortical Smoothing for Native-Space T1 Data *************'
echo '      were going to use the native-space Civet surfaces to get our   '
echo '    native-space T1 intensities on a surface, smoothed, and exported '
echo '           as an ASCII file to be read into R / MATLAB / PYTHON          '
echo '************************************************************************'
echo ''

# convert civet surfaces to freesurfer binaries
if [ ! -f ${DIR}/proc/surf_wm_L.asc ]; then
    ConvertSurface \
        -i_mni ${DIR}/proc/surf_wm_L.obj \
        -o_fs ${DIR}/proc/surf_wm_L.asc \
        -sv ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz
fi

if [ ! -f ${DIR}/proc/surf_wm_R.asc ]; then
    ConvertSurface \
        -i_mni ${DIR}/proc/surf_wm_R.obj \
        -o_fs ${DIR}/proc/surf_wm_R.asc \
        -sv ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz
fi

if [ ! -f ${DIR}/proc/surf_mid_L.asc ]; then
    ConvertSurface \
        -i_mni ${DIR}/proc/surf_mid_L.obj \
        -o_fs ${DIR}/proc/surf_mid_L.asc \
        -sv ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz
fi

if [ ! -f ${DIR}/proc/surf_mid_R.asc ]; then
    ConvertSurface \
        -i_mni ${DIR}/proc/surf_mid_R.obj \
        -o_fs ${DIR}/proc/surf_mid_R.asc \
        -sv ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz
fi

if [ ! -f ${DIR}/proc/surf_gm_L.asc ]; then
    ConvertSurface \
        -i_mni ${DIR}/proc/surf_gm_L.obj \
        -o_fs ${DIR}/proc/surf_gm_L.asc \
        -sv ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz
fi

if [ ! -f ${DIR}/proc/surf_gm_R.asc ]; then
    ConvertSurface \
        -i_mni ${DIR}/proc/surf_gm_R.obj \
        -o_fs ${DIR}/proc/surf_gm_R.asc \
        -sv ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz
fi

# make an AFNI-COMPATIBLE spec file
# NB -- lack of absoloute paths here.
# this is likly because AFNI is poorly-written. 
# by hungry graduate students.
# instead of real people.

quickspec \
  -tn FS proc/surf_wm_L.asc \
  -tn FS proc/surf_wm_R.asc \
  -tn FS proc/surf_gm_L.asc \
  -tn FS proc/surf_gm_R.asc \
  -tn FS proc/surf_mid_L.asc \
  -tn FS proc/surf_mid_R.asc

# Smooth cortical data on surface for each subject
if [ ! -f ${DIR}/proc/anat_surface_civ.L.1D.dset ]; then
    3dVol2Surf \
      -spec quick.spec \
      -surf_A proc/surf_wm_L.asc \
      -surf_B proc/surf_gm_L.asc \
      -sv T1w/T1w_acpc_dc_restore_brain.nii.gz \
      -grid_parent ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz \
      -map_func ave \
      -f_steps 15 \
      -f_index nodes \
      -outcols_NSD_format \
      -out_1D tmp/anat_surface_civ.L.1D

    SurfSmooth \
      -met HEAT_07 \
      -spec quick.spec \
      -surf_A proc/surf_gm_L.asc \
      -input tmp/anat_surface_civ.L.1D \
      -target_fwhm ${FWHM} \
      -output proc/anat_surface_civ.L.1D
fi

if [ ! -f ${DIR}/proc/anat_surface_civ.R.1D.dset ]; then
    3dVol2Surf \
      -spec quick.spec \
      -surf_A proc/surf_wm_R.asc \
      -surf_B proc/surf_gm_R.asc \
      -sv T1w/T1w_acpc_dc_restore_brain.nii.gz \
      -grid_parent ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz \
      -map_func ave \
      -f_steps 15 \
      -f_index nodes \
      -outcols_NSD_format \
      -out_1D tmp/anat_surface_civ.R.1D
    
    SurfSmooth \
      -met HEAT_07 \
      -spec quick.spec \
      -surf_A proc/surf_wm_R.asc \
      -input tmp/anat_surface_civ.R.1D \
      -target_fwhm ${FWHM} \
      -output proc/anat_surface_civ.R.1D      
fi
INPUT=aparc.a2009s+aseg
echo ''
echo '****************** Volume atlas to Civet surface atlas *****************'
echo '      were going to use the native-space Civet surfaces to get our   '
echo '                        input atlas on a surface                     '
echo '************************************************************************'
echo ''

# convert civet surfaces to freesurfer binaries
if [ ! -f ${DIR}/proc/surf_wm_L.asc ]; then
    ConvertSurface \
        -i_mni ${DIR}/proc/surf_wm_L.obj \
        -o_fs ${DIR}/proc/surf_wm_L.asc \
        -sv ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz
fi

if [ ! -f ${DIR}/proc/surf_wm_R.asc ]; then
    ConvertSurface \
        -i_mni ${DIR}/proc/surf_wm_R.obj \
        -o_fs ${DIR}/proc/surf_wm_R.asc \
        -sv ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz
fi

if [ ! -f ${DIR}/proc/surf_mid_L.asc ]; then
    ConvertSurface \
        -i_mni ${DIR}/proc/surf_mid_L.obj \
        -o_fs ${DIR}/proc/surf_mid_L.asc \
        -sv ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz
fi

if [ ! -f ${DIR}/proc/surf_mid_R.asc ]; then
    ConvertSurface \
        -i_mni ${DIR}/proc/surf_mid_R.obj \
        -o_fs ${DIR}/proc/surf_mid_R.asc \
        -sv ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz
fi

if [ ! -f ${DIR}/proc/surf_gm_L.asc ]; then
    ConvertSurface \
        -i_mni ${DIR}/proc/surf_gm_L.obj \
        -o_fs ${DIR}/proc/surf_gm_L.asc \
        -sv ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz
fi

if [ ! -f ${DIR}/proc/surf_gm_R.asc ]; then
    ConvertSurface \
        -i_mni ${DIR}/proc/surf_gm_R.obj \
        -o_fs ${DIR}/proc/surf_gm_R.asc \
        -sv ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz
fi

# make an AFNI-COMPATIBLE spec file
# NB -- lack of absoloute paths here.
# this is likly because AFNI is poorly-written. 
# by hungry graduate students.
# instead of real people.

quickspec \
  -tn FS proc/surf_wm_L.asc \
  -tn FS proc/surf_wm_R.asc \
  -tn FS proc/surf_gm_L.asc \
  -tn FS proc/surf_gm_R.asc \
  -tn FS proc/surf_mid_L.asc \
  -tn FS proc/surf_mid_R.asc

if [ ! -f ${DIR}/proc/atlas.L.${NUM}.1D.dset ]; then
    3dVol2Surf \
      -spec quick.spec \
      -surf_A proc/surf_mid_L.asc \
      -sv T1w/T1w_acpc_dc_restore_brain.nii.gz \
      -grid_parent labels/${INPUT}.nii.gz \
      -map_func mask \
      -f_steps 2 \
      -f_index nodes \
      -out_1D proc/atlas_civ.L.1D
fi

if [ ! -f ${DIR}/proc/atlas.R.${NUM}.1D.dset ]; then
    3dVol2Surf \
      -spec quick.spec \
      -surf_A proc/surf_mid_R.asc \
      -sv T1w/T1w_acpc_dc_restore_brain.nii.gz \
      -grid_parent labels/${INPUT}.nii.gz \
      -map_func mask \
      -f_steps 2 \
      -f_index nodes \
      -out_1D proc/atlas_civ.R.1D 
fi


# clean up unnecessary files
rm -r /srv/data/cere-conn/working/100307/proc/params
rm -r /srv/data/cere-conn/working/100307/tmp

cd /srv/data/cere-conn/working
echo ''
echo '# JDV 2014. Generated: ' 04-07-2015 @ 19:37:29
