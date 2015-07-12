A collection of scripts used to perform the analysis in

Cross-network integration in the human cerebellum. Viviano, Park, Voineskos, & Chakravarty, 2015. The Journal of Thoughts and Feelings.

**Dependencies**

External code I depend on and could not package.

+ [pyClusterROI](https://github.com/ccraddock/cluster_roi)
+ MATLAB 2014 & Stats toolbox.


**Includes**

External code I depend on and could package. See includes/README.md for details.

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

NB: Wrong script in repo atm!!!

**cluster-roi.py**

A function that takes and input subject's T1 and generates n random equally-spaced ROIs. This can then be propogated to the other subjects via surface space.

**conn_full_rois.m**

Takes the pre-processed functional data, MaGeT-Brain non-cortical segmentations, and Civet cortical measures, to compute:

+ BOLD functional connectivity (run-wise).
+ T1 intensity correlations (group-wise).
+ Volume - Volume correlations (group-wise).
+ Volume - Thickness correlations (group-wise).

**analysis.m**

This script generates most of the outputs / figures found in the paper. It references a host of subroutines I wrote to accomplish various small tasks. Note that many subroutines aren't being used for anything any longer. I left them in this repo because they might be of use to someone, even if they weren't ultimately usefule to me for this project.

+ plots the cortico-cortico & cerebellar-cortico correlation matricies. [dendrogram_plot]
+ computes the R^2 of the linear relationship between the image modalities on a ROI by ROI basis [value_compare].
+ writes out 3D volumes for visualization. [idx_to_nifti].
+ preforms a grid search over various clustering paramaters for the luvain algorithm. Here we use it on a second-order cerebellar-cortico connectivity matrix, which should be one way of getting around analyzing non-square matricies for any type of data. [modularityestmate].
+ plots the outputs of this grid search [plot_cluster_diagnostics / plot_cluster_diagnostics_dual]
+ applies the selected partitioning [modularityapply].
+ computes network-specific correlation vectors given the network partition [compute_network_maturation_corrs].
+ computes a cross-network diagram to be imported into a program like pajek. used to easily visualize cross-network integration in the cerebellum but could be used to analyze any subcortical / cortical relationship.

