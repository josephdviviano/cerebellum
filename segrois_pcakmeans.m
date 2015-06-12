% written for MATLAB 2014 -- so there is some strangeness.
% simply needs to be run from the hcp directory -- it should spider
% down into the /proc/ directories created in each subject's folder
% (this is designed to work with the 'hcpresto' pipeline available 
%  here: https://bitbucket.org/josephdviviano/hcpresto)

% this find the number of PCs that best represent each ROI over subjects.

% low-pass options
tr_s = 0.7;     % length of tr in secs
tr_n = 1200;    % number of TRs per run
filt_lo_hz = 0.01; % in Hz
filt_hi_hz = 0.10; % in Hz
filt_order = 100;  

% pca stuff
stopping_rule = 20;

civet_format = 0;

% labels
labels = {...
 'Vermal I II', 'L III', 'L IV', 'L V', 'L VI', 'L Crus I', 'L Crus II', ...
 'L VIIB', 'L VIIIA', 'L VIIIB', 'L IX', 'L X', 'L CM', 'Vermal III', ...
 'Vermal IV', 'Vermal V', 'Vermal VI', 'Vermal VIIA', 'Vermal VIIB', ...
 'Vermal VIIIA', 'Vermal VIIIB', 'Vermal IX', 'Vermal X', 'R III', 'R IV', ...
 'R V', 'R VI', 'R Crus I', 'R Crus II', 'R VIIB', 'R VIIIA', 'R VIIIB', ...
 'R IX', 'R X', 'R CM'...
 };

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subject folders + do it all

% get the lower-bound of the median number of PCs per ROI
pca_median = floor(median(pca_data, 2));

d = dir(pwd);
idx_subj = [d(:).isdir];
subj = {d(idx_subj).name};
subj(ismember(subj, {'.', '..'})) = [];

%init experiment-wide arrays
size_data = zeros(35, length(subj)*2);

% generate our bandpass filter
nyquist = 1/tr_s/2;
filt_hi_ratio = filt_hi_hz / nyquist;
filt_lo_ratio = filt_lo_hz / nyquist;

filt = fir1(filt_order, [filt_lo_ratio, filt_hi_ratio], ...
                                   kaiser(filt_order+1, 2.5));

runcount = 1;

% iterate through subjects
for s = 1:length(subj);

    % iterate through runs
    for runs = [1, 2, 3, 4];
        
        % set run, subject
        r = sprintf('%02d', runs);
        f = subj{s};

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % % Surface Data
        % if civet_format == 1;
        
        %     % load in civet surface data and stack (L over R)
        %     surf_dataL = dlmread(...
        %                  [f '/proc/func_surface_civ.L.' r '.1D.dset'], ...
        %                                           ' ', [5,2, 40966, 1201]);
        %     surf_dataR = dlmread(...
        %                  [f '/proc/func_surface_civ.R.' r '.1D.dset'], ...
        %                                           ' ', [5,2, 40966, 1201]);

        %     % load in the surface atlas and stack (L over R)
        %     fname = fopen([f '/proc/atlas_civ.L.1D'],'rt');
        %     fdata = textscan(fname, '%f%f%f%f%f%f%f', ...
        %                             'Whitespace', ' ', ...
        %                             'MultipleDelimsAsOne', 1, ...
        %                             'HeaderLines', 5);
        %     surf_valsL = fdata{7};
        %     fclose(fname);

        %     fname = fopen([f '/proc/atlas_civ.R.1D'],'rt');
        %     fdata = textscan(fname, '%f%f%f%f%f%f%f', ...
        %                             'Whitespace', ' ', ...
        %                             'MultipleDelimsAsOne', 1, ...
        %                             'HeaderLines', 5);
        %     surf_valsR = fdata{7};
        %     fclose(fname);
        
        % else;

        %     % load in freesurfer surface data and stack (L over R)
        %     surf_dataL = dlmread(...
        %                  [f '/proc/func_surface_fs.L.' r '.1D.dset'], ...
        %                                          ' ', [5,2, 32496, 1201]);
        %     surf_dataR = dlmread(...
        %                  [f '/proc/func_surface_fs.R.' r '.1D.dset'], ...
        %                                          ' ', [5,2, 32496, 1201]);
            
        %     % load in the surface atlas and stack (L over R)
        %     fname = fopen([f '/proc/atlas_fs.L.1D'],'rt');
        %     fdata = textscan(fname, '%f%f%f%f%f%f%f', ...
        %                             'Whitespace', ' ', ...
        %                             'MultipleDelimsAsOne', 1, ...
        %                             'HeaderLines', 5);
        %     surf_valsL = fdata{7};
        %     fclose(fname);

        %     fname = fopen([f '/proc/atlas_fs.R.1D'],'rt');
        %     fdata = textscan(fname, '%f%f%f%f%f%f%f', ...
        %                             'Whitespace', ' ', ...
        %                             'MultipleDelimsAsOne', 1, ...
        %                             'HeaderLines', 5);
        %     surf_valsR = fdata{7};
        %     fclose(fname);

        % end

        % % stack L&R hemisphere, filter
        % surf_data = [surf_dataL; surf_dataR];
        % surf_vals = [surf_valsL; surf_valsR];
        % surf_data = filtfilt(filt, 1, surf_data')';

        % clearvars surf_dataL surf_dataR

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Volume Data
        vol_data = load_nii([f '/proc/func_warped.' r '.nii.gz']);
        vol_vals = load_nii([f '/proc/smoothmask.nii.gz']);
        vol_out  = load_nii([f '/proc/smoothmask.nii.gz']);
        vol_white = load_nii([f '/proc/anat_pve_classify_resample.nii.gz']);

        % convert to voxels by timepoints
        dims = size(vol_data.img);
        vol_data = reshape(vol_data.img, [dims(1)*dims(2)*dims(3), dims(4)]);
        vol_vals = reshape(vol_vals.img, [dims(1)*dims(2)*dims(3), 1]);
        vol_white = reshape(vol_white.img, [dims(1)*dims(2)*dims(3), 1]);

        % extract labeled data, minus the white matter
        wm_val = max(unique(vol_white));
        idx_gm = find(vol_white < wm_val);
        idx_vol = find(vol_vals > 0);

        idx_final = intersect(idx_vol, idx_gm);

        tmp_data = vol_data(idx_final, :);
        tmp_atlas = vol_vals(idx_final);
        
        % filter data
        tmp_data = filtfilt(filt, 1, double(tmp_data'))';

        % get a list of the ROIs
        vol_list = unique(tmp_atlas);

        % loop through ROIs in volume
        count = 1;
        roi_num = 100;
        output_atlas = zeros(size(tmp_atlas));

        for roi = vol_list';

            idx_roi = find(tmp_atlas == roi);
            roi_data = tmp_data(idx_roi, :);

            % generate ROI x CTX 
            %corrmat = corr(roi_data', surf_data');
            corrmat = corr(roi_data');

            disp('corrmat size -- ')
            size(corrmat)

            % get k from PCA dimensionality
            k = pca_median(count);

            % conduct k-means segmentation
            [idx_k, kmeans_c] = kmeans(corrmat, k, 'replicates', 100);

            % feed segmentation back into output array
            for output_k = unique(idx_k)';
                output_atlas(idx_roi(idx_k == output_k)) = roi_num + output_k;
            end
            
            % iterate the roi_num
            roi_num = roi_num + 100;

            count = count + 1;
        end

        % write the output
        output_volume = zeros(size(vol_vals));
        output_volume(idx_final) = output_atlas;
        output_volume = reshape(output_volume, dims(1), dims(2), dims(3));
        vol_out.img = output_volume;

        save_nii(vol_out, [f '/proc/mask_kseg_CMAT40_' int2str(runcount) '.nii.gz'])

        display_volume = zeros(size(vol_vals));

        count = 1;
        for roi = unique(output_volume)';
            if roi > 0;
                display_volume(output_volume == roi) = count;
                count = count + 1;
            end
        end
        
        display_volume = reshape(display_volume, dims(1), dims(2), dims(3));
        vol_out.img = display_volume;

        save_nii(vol_out, [f '/proc/mask_kdisp_CMAT40_' int2str(runcount) '.nii.gz'])

        % write a visualization image

        disp(['done!' int2str(runcount)])

        % iterate
        runcount = runcount + 1;

    end

end
