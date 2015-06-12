function print_out_data(basefile, m, rois, basename);
    % prints out multple niftis (numbered) from a matrix m containing 
    % n x vals statistics. One nifti for each 'n' row.
    count = 1;
    for v = m';
    	idx_to_nifti(basefile, v, rois, [basename int2str(count) '.nii.gz']);
    	count = count + 1;
    end
end