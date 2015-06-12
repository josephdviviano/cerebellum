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
filt_hi_hz = 0.20; % in Hz % changed to 0.2
filt_order = 100;  

% pca stuff
stopping_rule = 80;

% 
% labels
labels = {...
 'Vermal I II', 'L III', 'L IV', 'L V', 'L VI', 'L Crus I', 'L Crus II', ...
 'L VIIB', 'L VIIIA', 'L VIIIB', 'L IX', 'L X', 'L CM', 'Vermal III', ...
 'Vermal IV', 'Vermal V', 'Vermal VI', 'Vermal VIIA', 'Vermal VIIB', ...
 'Vermal VIIIA', 'Vermal VIIIB', 'Vermal IX', 'Vermal X', 'R III', 'R IV', ...
 'R V', 'R VI', 'R Crus I', 'R Crus II', 'R VIIB', 'R VIIIA', 'R VIIIB', ...
 'R IX', 'R X', 'R CM'...
 };

 dummy = {...
 '', '', '', '', '', '', '', '', '', '', ... 
 '', '', '', '', '', '', '', '', '', '', ...
 '', '', '', '', '', '', '', '', '', '', ...
 '', '', '', '', '', ...
 }

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% subject folders + do it all

d = dir(pwd);
idx_subj = [d(:).isdir];
subj = {d(idx_subj).name};
subj(ismember(subj, {'.', '..'})) = [];

%init experiment-wide arrays
pca_data = zeros(35, length(subj)*2 + 1);
size_data = zeros(35, length(subj)*2);

% generate our bandpass filter
nyquist = 1/tr_s/2;
filt_hi_ratio = filt_hi_hz / nyquist;
filt_lo_ratio = filt_lo_hz / nyquist;

filt = fir1(filt_order, [filt_lo_ratio, filt_hi_ratio], ...
                                   kaiser(filt_order+1, 2.5));

runcount = 1;

for s = 1:length(subj);

    for runs = [1, 2, 3, 4];

        % load in volume data
        r = sprintf('%02d', runs);
        f = subj{s};

        vol_data = load_nii([f '/proc/func_cwm_regress.' r '.nii.gz']);
        vol_vals = load_nii([f '/proc/smoothmask.nii.gz']);
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
        for roi = vol_list';
            idx_roi = find(tmp_atlas == roi);

            % perform PCA on correlation matrix of the data
            roi_data = tmp_data(idx_roi, :);

            % remove NaNs
            roi_sum = sum(roi_data');
            idx_nan = find(roi_sum ~= 0);
            roi_data = roi_data(idx_nan, :);
            roi_data = corr(roi_data');
            
            % pca
            [pca_cof, pca_lat, pca_exp] = pcacov(roi_data);

            % calculate number of components that explain x cumulative var.
            pca_cum = cumsum(pca_exp);
            pca_num = length(find(pca_cum <= stopping_rule));

            pca_data(count, runcount) = pca_num;

            % save size of ROI
            size_data(count, runcount) = length(idx_roi);

            count = count + 1;
        end

        % iterate
        runcount = runcount + 1;

    end
    disp(['done ' f])
    save(['func_vertex_PCA_' int2str(stopping_rule) '_corr.mat'], '-v7.3')

end

% strip off the leading zero
pca_data = pca_data(:, 1:runcount-1);
save(['func_vertex_PCA_' int2str(stopping_rule) '_corr.mat'], '-v7.3')


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Plot party

%% number of components per ROI across 20, 40, 60, 80
load('func_vertex_PCA_20_corr.mat')
subplot(4,1,1);

pca_median = floor(median(pca_data, 2));
pca_sdev = std(pca_data, [], 2);
errorbar(1:length(pca_median), pca_median, pca_sdev, ...
                 'linewidth', 2, 'color', 'black')
set(gca, 'xtick', [1:35])
set(gca, 'xticklabel', dummy)

load('func_vertex_PCA_40_corr.mat')
subplot(4,1,2);

pca_median = floor(median(pca_data, 2));
pca_sdev = std(pca_data, [], 2);
errorbar(1:length(pca_median), pca_median, pca_sdev, ...
                 'linewidth', 2, 'color', 'black')
set(gca, 'xtick', [1:35])
set(gca, 'xticklabel', dummy)

load('func_vertex_PCA_60_corr.mat')
subplot(4,1,3);

pca_median = floor(median(pca_data, 2));
pca_sdev = std(pca_data, [], 2);
errorbar(1:length(pca_median), pca_median, pca_sdev, ...
                 'linewidth', 2, 'color', 'black')
set(gca, 'xtick', [1:35])
set(gca, 'xticklabel', dummy)

load('func_vertex_PCA_80_corr.mat')
subplot(4,1,4);

pca_median = floor(median(pca_data, 2));
pca_sdev = std(pca_data, [], 2);
errorbar(1:length(pca_median), pca_median, pca_sdev, ...
                 'linewidth', 2, 'color', 'black')
set(gca, 'xtick', [1:35])
set(gca, 'xticklabel', labels)
rotateXLabels(gca, 65)



%% Dimensionality vs. ROI size
subplot(2,1,2);

size_mean = mean(size_data, 2);
size_sdev = std(size_data, [], 2);
scatter(size_mean, pca_mean, [], 'black')
% hold all;
% x = 1:1800;
% y = 6.015 * x.^0.3422;
% plot(x, y, 'color', 'red');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
