for f in *; do

    #3dcalc \
    #    -a ${f}/proc/smoothmask.nii.gz \
    #    -b ${f}/proc/anat_pve_classify_resample.nii.gz \
    #    -expr 'ispositive(a) * astep(b, 0.03)' \
    #    -prefix ${f}/proc/cerebellum_wm.nii.gz

    # remove mean cerebellar WM signal from all voxels
    RUNS="01 02 03 04"
    for RUN in ${RUNS}; do 

    #    3dmaskave \
    #        -mask ${f}/proc/cerebellum_wm.nii.gz \
    #        -quiet \
    #        ${f}/proc/func_warped.${RUN}.nii.gz \
    #        > ${f}/proc/cerebellum_wm.${RUN}.1D

        if [ ! -f ${f}/proc/func_cwm_regress.${RUN}.nii.gz ]; then
            3dDetrend \
                -prefix ${f}/proc/func_cwm_regress.${RUN}.nii.gz \
                -vector ${f}/proc/cerebellum_wm.${RUN}.1D \
                -polort 1 \
                ${f}/proc/func_warped.${RUN}.nii.gz
        fi

    done

done
