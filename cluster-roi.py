#!/usr/bin/env python
"""
Uses the random-connectivity method from 

Craddock, R. C.; James, G. A.; Holtzheimer, P. E.; Hu, X. P. & Mayberg, H. S.
A whole brain fMRI atlas generated via spatially constrained spectral
clustering Human Brain Mapping, 2012, 33, 1914-1928 doi: 10.1002/hbm.21333.

to generate an n-ROI cortical mask at the group level.

I generated the input mask using AFNI:

# find cortex
3dcalc \
    -prefix ctxmask.nii.gz \
    -a ribbon.nii.gz \
    -expr 'equals(a, 3) + equals(a, 42)'

# downsample 2x
3dresample \
    -prefix ctxmask-lowres.nii.gz \
    -rmode NN \
    -dxyz 1.4 1.4 1.4 \
    -inset ctxmask.nii.gz

# run cluster-roi.py
./cluster-roi.py

# resample to match surfvol
3dresample \
    -prefix parcellation_320-native.nii.gz \
    -rmode NN \
    -master T1w_resample_brain.nii.gz \
    -inset parcellation_320.nii.gz

# dilate mask to ensure surface coverage
fslmaths \
    parcellation_320.nii.gz \
    -dilD \
    parcellation_320-dil.nii.gz

# project ROIs onto surface
3dVol2Surf \
  -spec quick.spec \
  -surf_A proc/surf_mid_L.asc \
  -sv T1w/T1w_acpc_dc_restore_brain.nii.gz \
  -grid_parent T1w/parcellation_1000-dil.nii.gz \
  -map_func mask \
  -f_steps 2 \
  -f_index nodes \
  -out_1D proc/rois_civ.L.1D

3dVol2Surf \
  -spec quick.spec \
  -surf_A proc/surf_mid_R.asc \
  -sv T1w/T1w_acpc_dc_restore_brain.nii.gz \
  -grid_parent T1w/parcellation_1000-dil.nii.gz \
  -map_func mask \
  -f_steps 2 \
  -f_index nodes \
  -out_1D proc/rois_civ.R.1D 

"""

# this requires cluster_roi -- uglytown.
from make_local_connectivity_ones import *
from binfile_parcellation import *
from make_image_from_bin_renum import *
from time import time
import os, sys

def main(maskname, output, k):
    """
    This loops through input subjects, constructs individual cortical cluster
    maps, and then generates a single map at the group level.
    """

    # keep track of the time 
    T0 = time()

    # perform random clustering
    localcon = os.path.dirname(maskname) + '/rm_ones_connectivity.npy'
    
    if os.path.isfile(localcon) == False:
        # calculates local connectivity from binary mask
        make_local_connectivity_ones(maskname, localcon)
    
    if os.path.isfile(output + str(k[0]) + '.npy') == False:
        # segments into k clusters using local connectivity 
        binfile_parcellate(localcon, output, k)

    if os.path.isfile(output + str(k[0]) + '.nii.gz') == False:
        # write out a nifti
        make_image_from_bin_renum(output + str(k[0]) + '.nii.gz', 
                                  output + str(k[0]) + '.npy', maskname);

    T1 = time()
    print '**** Done in ' + str(T1-T0)

if __name__ == '__main__':

    k = [320]
    maskname = '/srv/data/cere-conn/working/100307/T1w/ctxmask-lowres.nii.gz'
    output = '/srv/data/cere-conn/working/100307/T1w/parcellation_'

    print('Parcellating using k = ' + str(k) + ' on ' + str(maskname))
    main(maskname, output, k)

