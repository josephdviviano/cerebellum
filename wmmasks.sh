DIR_DATA=`pwd`
TYPE=classify
INPUT=pve_classify
CIV='civet'
echo ''
echo '****************** Volume civet atlas to Native Space  *****************'
echo ' Moves civet classification masks / atlases to a subjects native space  '
echo '************************************************************************'
echo ''

for SUB in `ls -d */`; do
    DIR=`echo ${DIR_DATA}/${SUB}`
    mkdir ${DIR}/tmp

    if [ ! -f ${DIR}/proc/anat_${INPUT}.nii.gz ]; then 

        # make temporary T1 in MINC file as a registration target
        if [ ! -f ${DIR}/proc/anat_wm.nii.gz ]; then    
            cp ${DIR}/T1w/T1w_acpc_dc_restore_brain.nii.gz \
               ${DIR}/tmp/anat_T1_brain.nii.gz

            gunzip ${DIR}/tmp/anat_T1_brain.nii.gz

            nii2mnc \
                ${DIR}/tmp/anat_T1_brain.nii \
                ${DIR}/tmp/anat_T1_brain.mnc
        fi

        # invert linear tranform  
        if [ ! -f ${DIR}/tmp/dewarp_linear.xfm ]; then
            xfminvert \
                ${DIR}/${CIV}/transforms/linear/*t1_tal.xfm \
                ${DIR}/tmp/dewarp_linear.xfm
        fi

        # resample input mask to native space 
        mincresample \
            -2 \
            -near \
            -like ${DIR}/tmp/anat_T1_brain.mnc \
            -transform ${DIR}/tmp/dewarp_linear.xfm \
            ${DIR}/civet/${TYPE}/*${INPUT}.mnc \
            ${DIR}/tmp/anat_${INPUT}.mnc

        mnc2nii \
            ${DIR}/tmp/anat_${INPUT}.mnc \
            ${DIR}/proc/anat_${INPUT}.nii

        gzip ${DIR}/proc/anat_${INPUT}.nii

        rm -r ${DIR}/tmp
    fi

    3dresample \
        -prefix ${DIR}/proc/smoothmask.nii.gz \
        -inset ${DIR}/labels/cerebellum.nii.gz \
        -rmode NN \
        -master ${DIR}/proc/func_warped.03.nii.gz

    3dresample \
        -prefix ${DIR}/proc/anat_${INPUT}_resample.nii.gz \
        -inset ${DIR}/proc/anat_${INPUT}.nii.gz \
        -rmode NN \
        -master ${DIR}/proc/smoothmask.nii.gz

done
