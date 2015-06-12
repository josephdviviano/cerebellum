A collection of scripts used to perform the analysis in

Divergence and convergence of cerbellar-cortical connectivity metrics using anatomical priors. Viviano, Park, Voineskos, & Chakravarty, 2015. The Journal of Thoughts and Feelings.

**Dependencies**

External code I depend on and could not package.

+ [pyClusterROI](https://github.com/ccraddock/cluster_roi)
+ MATLAB 2014 & Stats toolbox.


**Includes**

External code I depend on and could package. See README.md in includes/

Pipeline
--------

**preproc.sh**

Takes the raw HCP anatomical & functional data, as downloaded, and:

+ Performs aCompCor-style nusiance regression on the data.
    + Mean white matter, ventrical regressors + 1 lag.
    + Physiological + head motion regression + derivatives.
    + Top 5 principal components from the white matter and ventricals.
    + Linear detrend.
+ Nonlinearly warps MNI-space data to native space.
+ Smooths the functional data in volume space.
+ Aligns Civet .obj files to native space, converts them to freesurfer, and projects functional data onto them.
+ Performs surface smoothing.

**cluster-roi.py**

A function that takes and input subject's T1 and generates n random equally-spaced ROIs.

**conn_full_rois.m**

Takes the pre-processed functional data, MaGeT-Brain non-cortical segmentations, and Civet cortical measures, to compute:

+ BOLD functional connectivity (run-wise).
+ T1 intensity correlations (group-wise).
+ Volume - Volume correlations (group-wise).
+ Volume - Thickness correlations (group-wise).

**kmeans-analysis.m**

Does the model-order selection on cerebellum, cortical, and cerebellumi x cortical matricies.

