%
% performs ROI x Surface Node correlations of:
%     + bold covariance
%     + volume covariance (normalized by brain mask)
%     + gray intensity covariance
%
% these are saved in a roi x surface x subject 3d stack of graphs
%     + g_func
%     + g_volu
%     + g_grey
%
% req MATLAB 2014
addpath(genpath('/home/jdv/code/analysis-scripts/projects/cere-conn/'))
cd /srv/data/cere-conn/working
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Options
civet_format = 1;   % if this = 1, use civet surfaces,
                    %        else, use freesurfer surfaces.
% low-pass options
tr_s = 0.7;         % length of TR in secs
tr_n = 1200;        % number of TRs per run
filt_lo_hz = 0.009; % in Hz
filt_hi_hz = 0.08;  % in Hz
filt_order = 100;   %

tested_runs = [1, 2, 3, 4]; % can use a subset of runs (for split half?)

update_func = 0; % if 1, overwrite outputs from previous run (or generate them)
update_volu = 1; % if 1, overwrite outputs from previous run (or generate them)
update_grey = 0; % if 1, overwrite outputs from previous run (or generate them)

use_ctx_mask = 1; % if 1, use a cortical roi mask to collapse the data down to 
                  %       n ROIs.
use_filter = 1;   % if 1, bandpasses the data using a bi directional 
                  % kaiser filter.
testmode = 0;     % if 1, only runs on the first subject.

labels = {...
 'Vermal I II', 'L III', 'L IV', 'L V', 'L VI', 'L Crus I', 'L Crus II', ...
 'L VIIB', 'L VIIIA', 'L VIIIB', 'L IX', 'L X', 'L CM', 'Vermal III', ...
 'Vermal IV', 'Vermal V', 'Vermal VI', 'Vermal VIIA', 'Vermal VIIB', ...
 'Vermal VIIIA', 'Vermal VIIIB', 'Vermal IX', 'Vermal X', 'R III', 'R IV', ...
 'R V', 'R VI', 'R Crus I', 'R Crus II', 'R VIIB', 'R VIIIA', 'R VIIIB', ...
 'R IX', 'R X', 'R CM'...
 };

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize
d = dir(pwd); % get the subject folders
idx_subj = [d(:).isdir];
subj = {d(idx_subj).name};
subj(ismember(subj, {'.', '..'})) = [];

if testmode == 1;
    subj = {subj{1}};
end

nrun = length(tested_runs);
nsub = length(subj);

% determine number of ROIs in subcortical mask
sub_mask = load_nii([subj{1} '/proc/smoothmask.nii.gz']);
dims = size(sub_mask.img);
sub_mask = reshape(sub_mask.img, [dims(1)*dims(2)*dims(3), 1]);
vol_list = unique(sub_mask(sub_mask > 0));

if civet_format == 1;
    outputname = 'CV'; % civet
    n_vertex = 40962;  %
    f_type = 'civ';    %
else;
    outputname = 'FS'; % freesurfer
    n_vertex = 32492;  % 
    f_type = 'fs';     %
end

% if we aren't using a mask, then treat each vertex as an 'ROI'
if use_ctx_mask == 0;
    ctx_n_rois = n_vertex*2;
end

% determine number of ROIs in cortical mask, load in, and init output matricies
if use_ctx_mask == 1;
    fname = fopen(['ctx_roi_' f_type '.L.1D'], 'rt');
    fdata = textscan(fname, '%f%f%f%f%f%f%f', ...
                            'Whitespace', ' ', ...
                            'MultipleDelimsAsOne', 1, ...
                            'HeaderLines', 5);
    ctx_tmp_maskL = fdata{7};
    fclose(fname);

    fname = fopen(['ctx_roi_' f_type '.R.1D'], 'rt');
    fdata = textscan(fname, '%f%f%f%f%f%f%f', ...
                            'Whitespace', ' ', ...
                            'MultipleDelimsAsOne', 1, ...
                            'HeaderLines', 5);
    ctx_tmp_maskR = fdata{7};
    fclose(fname);

    ctx_mask = [ctx_tmp_maskL; ctx_tmp_maskR];

    ctx_rois = unique(ctx_mask);
    ctx_rois = ctx_rois(ctx_rois ~= 0);
    ctx_n_rois = length(ctx_rois);

    % when using ROIs, also
    if update_func == 1;

        g_func_ctx = zeros(ctx_n_rois, ctx_n_rois, nsub*nrun);
        g_func_sub = zeros(35, 35, nsub*nrun);
    end

    if update_volu == 1;
        g_volu_ctx = zeros(ctx_n_rois, ctx_n_rois);
        g_volu_sub = zeros(35, 35);
    end

    if update_grey == 1;
        g_grey_ctx = zeros(ctx_n_rois, ctx_n_rois);
        g_grey_sub = zeros(35, 35);
    end
end

if use_ctx_mask == 0;
    if update_func == 1;
        ctx_vals = zeros(1, ctx_n_rois);
    end
end

if update_func == 1;
    g_func = zeros(35, ctx_n_rois, nsub*nrun);
    ctx_func = zeros(1, ctx_n_rois);
    sub_func = zeros(1, length(vol_list));
end

if update_volu == 1;
    g_volu = zeros(35, ctx_n_rois);
    ctx_volu = zeros(1, ctx_n_rois);
    sub_volu = zeros(1, length(vol_list));
end

if update_grey == 1;
    g_grey = zeros(35, ctx_n_rois);
    ctx_grey = zeros(1, ctx_n_rois);
    sub_grey = zeros(1, length(vol_list));
end

% bandpass filter
nyquist = 1/tr_s/2;
filt_hi_ratio = filt_hi_hz / nyquist;
filt_lo_ratio = filt_lo_hz / nyquist;

filt = fir1(filt_order, [filt_lo_ratio, filt_hi_ratio], ...
                                   kaiser(filt_order+1, 2.5));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Harvest
% load in regressors of no interest
age_anat = dlmread('demo-age.csv');
hnd_anat = dlmread('demo-hand.csv');
sex_anat = dlmread('demo-gender.csv');

% expand regressors to match the number of runs for functional data
age_func = zeros(nrun*nsub, 1);
hnd_func = zeros(nrun*nsub, 1);
sex_func = zeros(nrun*nsub, 1);

count = 0;
for x = 1:nsub;
    age_func(count*nrun+1:count*nrun+nrun) = repmat(age_anat(x), nrun, 1);
    hnd_func(count*nrun+1:count*nrun+nrun) = repmat(hnd_anat(x), nrun, 1);
    sex_func(count*nrun+1:count*nrun+nrun) = repmat(sex_anat(x), nrun, 1);
    count = count + 1;
end

runcount = 1; % initialize for g_func (g_volu + g_grey use s).
for s = 1:nsub;

    f = subj{s};

    %% functional data
    if update_func == 1;
        for runs = tested_runs;

            r = sprintf('%02d', runs);

            % subcortical
            sub_tmp_func = load_nii([f '/proc/func_warped.' r '.nii.gz']);
            sub_mask = load_nii([f '/proc/smoothmask.nii.gz']);
            sub_wm = load_nii([f '/proc/anat_pve_classify_resample.nii.gz']);

            % convert to voxels by timepoints
            dims = size(sub_tmp_func.img);
            sub_tmp_func = reshape(sub_tmp_func.img, [dims(1)*dims(2)*dims(3),dims(4)]);
            sub_mask = reshape(sub_mask.img, [dims(1)*dims(2)*dims(3), 1]);
            sub_wm = reshape(sub_wm.img, [dims(1)*dims(2)*dims(3), 1]);

            % extract labeled data, minus the white matter
            idx_final = find_grey_in_roi(sub_mask, sub_wm);

            vol_list = unique(sub_mask(sub_mask > 0));

            sub_tmp_func = sub_tmp_func(idx_final, :);
            sub_tmp_func = double(sub_tmp_func);
            sub_mask = sub_mask(idx_final);
            
            % filter data
            if use_filter == 1;
                sub_tmp_func = filtfilt(filt, 1, sub_tmp_func')';
            end

            sub_tmp_func = collapse_to_rois(sub_tmp_func, vol_list, sub_mask);

            % surface data
            ctx_tmp_funcL = dlmread(...
                        [f '/proc/func_surface_' f_type '.L.' r '.1D.dset'], ...
                                                  ' ', [5,2, n_vertex+4, 1201]);
            ctx_tmp_funcR = dlmread(...
                        [f '/proc/func_surface_' f_type '.R.' r '.1D.dset'], ...
                                                  ' ', [5,2, n_vertex+4, 1201]);
            % stack L&R hemisphere
            ctx_tmp_func = [ctx_tmp_funcL; ctx_tmp_funcR];
            

            if use_ctx_mask == 0;

                % surface atlas
                fname = fopen([f '/proc/atlas_' f_type '.L.1D'],'rt');
                fdata = textscan(fname, '%f%f%f%f%f%f%f', ...
                                        'Whitespace', ' ', ...
                                        'MultipleDelimsAsOne', 1, ...
                                        'HeaderLines', 5);
                ctx_tmp_valsL = fdata{7};
                fclose(fname);

                fname = fopen([f '/proc/atlas_' f_type '.R.1D'],'rt');
                fdata = textscan(fname, '%f%f%f%f%f%f%f', ...
                                        'Whitespace', ' ', ...
                                        'MultipleDelimsAsOne', 1, ...
                                        'HeaderLines', 5);
                ctx_tmp_valsR = fdata{7};
                fclose(fname);
                ctx_tmp_vals = [ctx_tmp_valsL; ctx_tmp_valsR];
            end
            
            if use_ctx_mask == 1;
                ctx_tmp_func = collapse_to_rois(ctx_tmp_func, ctx_rois, ctx_mask);
            end

            % filter functional data
            if use_filter == 1;
                ctx_tmp_func = filtfilt(filt, 1, ctx_tmp_func')';
            end

            sub_func = [sub_func; sub_tmp_func'];  % append
            ctx_func = [ctx_func; ctx_tmp_func']; % append

            % load z-scored correlation matrix into cmat
            c = corr(sub_tmp_func', ctx_tmp_func');
            c = r_2_z(c);
            g_func(:, :, runcount) = c;

            if use_ctx_mask == 1;
                c = corr(sub_tmp_func');
                c = r_2_z(c);
                g_func_sub(:, :, runcount) = c;

                c = corr(ctx_tmp_func');
                c = r_2_z(c);
                g_func_ctx(:, :, runcount) = c;
            end

            runcount = runcount + 1;
     
        end

        if use_ctx_mask == 0;
            ctx_vals = [ctx_vals; ctx_tmp_vals']; % append
        end
    end

    %% structural data
    % mask = labels, grey = t1, icvm = intercranial volume, wm = civet wm
    sub_mask = load_nii([f '/labels/cerebellum.nii.gz']);
    sub_anat = load_nii([f '/T1w/T1w_acpc_dc_restore_brain.nii.gz']);
    sub_icvm = load_nii([f '/T1w/brainmask_fs.nii.gz']);
    sub_wm = load_nii([f '/proc/anat_pve_classify.nii.gz']);

    % convert to 2D array
    dims = size(sub_mask.img);
    sub_mask = reshape(sub_mask.img, [dims(1)*dims(2)*dims(3), 1]);
    sub_anat = reshape(sub_anat.img, [dims(1)*dims(2)*dims(3), 1]);
    sub_icvm = reshape(sub_icvm.img, [dims(1)*dims(2)*dims(3), 1]);
    sub_wm = reshape(sub_wm.img, [dims(1)*dims(2)*dims(3), 1]);

    % calculate mean t1 value, icvm
    idx_brain = find(sub_icvm > 0);
    t1_mean = mean(sub_anat(idx_brain));
    sub_icvm = sum(sub_icvm);

    % extract labeled data, minus the white matter
    idx_final = find_grey_in_roi(sub_mask, sub_wm);

    sub_tmp_mask = sub_mask(idx_final);
    sub_tmp_anat = sub_anat(idx_final);
    sub_rois = unique(sub_tmp_mask);

    % record roi volume
    if update_volu == 1;
        sub_tmp_volu = zeros(1, length(vol_list));
        
        count = 1;
        for roi = vol_list';
            % normalized by total brain volume
            %roi_vol = length(find(sub_tmp_mask == roi)) / sub_icvm;
            roi_vol = length(find(sub_tmp_mask == roi));
            sub_tmp_volu(count) = roi_vol;

            count = count + 1;
        end
        % % thickness in MNI space
        % ctx_tmp_voluL = dlmread([f '/civet/thickness/HCP_' f ...
        %                         '_native_rms_rsl_tlink_28.2843mm_left.txt']);
        % ctx_tmp_voluR = dlmread([f '/civet/thickness/HCP_' f ...
        %                         '_native_rms_rsl_tlink_28.2843mm_right.txt']);

        % volumes in MNI space        
        ctx_tmp_voluL = dlmread([f '/civet/surfaces/HCP_' f ...
                                '_surface_rsl_left_native_volume_56.5685mm.txt']);

        ctx_tmp_voluR = dlmread([f '/civet/surfaces/HCP_' f ...
                                '_surface_rsl_right_native_volume_56.5685mm.txt']);

        ctx_tmp_volu = [ctx_tmp_voluL; ctx_tmp_voluR];
        clearvars ctx_tmp_voluL ctx_tmp_voluR

        if use_ctx_mask == 1;
            ctx_tmp_volu = collapse_to_rois(ctx_tmp_volu, ctx_rois, ctx_mask);
        end

        sub_volu = [sub_volu; sub_tmp_volu];  % append
        ctx_volu = [ctx_volu; ctx_tmp_volu']; % append
    end

    % record roi intensity normalized by global mean
    if update_grey == 1;
        sub_tmp_grey = zeros(1, length(vol_list));
        
        count = 1;
        for roi = vol_list';
            roi_grey = mean(sub_tmp_anat(find(sub_tmp_mask == roi))) / t1_mean;
            sub_tmp_grey(count) = roi_grey;
        
            count = count + 1;
        end
        ctx_tmp_greyL = dlmread(...
                     [f '/proc/anat_surface_' f_type '.L.1D.dset'], ...
                                                   ' ', [5,2, n_vertex+4, 2]);
        ctx_tmp_greyR = dlmread(...
                     [f '/proc/anat_surface_' f_type '.R.1D.dset'], ...
                                                   ' ', [5,2, n_vertex+4, 2]);
        ctx_tmp_grey = [ctx_tmp_greyL; ctx_tmp_greyR];

        if use_ctx_mask == 1;
            ctx_tmp_grey = collapse_to_rois(ctx_tmp_grey, ctx_rois, ctx_mask);
        end

        sub_grey = [sub_grey; sub_tmp_grey];  % append
        ctx_grey = [ctx_grey; ctx_tmp_grey']; % append
    end
    disp(['subject ' int2str(s) ' done'])
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Wrap up (strip zeros from experiment-wide arrays, clear memory, save)
if update_volu == 1;
    sub_volu = sub_volu(2:end, :);
    ctx_volu = ctx_volu(2:end, :);
end

if update_grey == 1;
    sub_grey = sub_grey(2:end, :);
    ctx_grey = ctx_grey(2:end, :);
end

if update_func == 1;
    if use_ctx_mask == 0;
        ctx_vals = ctx_vals(2:end, :);
    end
    sub_func = sub_func(2:end, :);
    ctx_func = ctx_func(2:end, :);
end

disp(['Data collection done.'])

% clear junk from memory
clearvars ans c  ctx_tmp* d filt* idx_*
clearvars sub_anat sub_mask sub_tmp_*
clearvars civet_format count f* r* s subj_* t1_mean tr_* wm_val

% checkpoint
save(['cere-conn_func-volu-grey_vertex_' outputname '.mat'], '-v7.3');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% regress out uninteresting variables against the corr vectors / struct features
matlabpool open 4

if update_func == 1;
    g_func_mean = repmat(nanmean(g_func, 3), [1, 1, nrun*nsub]);
    for x = 1:length(g_func(:, 1, 1));
        parfor y = 1:length(g_func(1, :, 1));
            mdl = fitlm([age_func, hnd_func, sex_func], ...
                               meshgrid(g_func(x,y,:), 1));
            g_func(x, y, :) = mdl.Residuals.Raw;
        end
    end
    g_func = g_func + g_func_mean;
    clearvars g_func_mean
end

if update_grey == 1;
    parfor roi = 1:length(sub_grey(1, :));
        mdl = fitlm([age_anat, hnd_anat, sex_anat], sub_grey(:, roi));
        sub_grey(:, roi) = mdl.Residuals.Raw;
    end

    parfor roi = 1:length(ctx_grey(1, :));
        mdl = fitlm([age_anat, hnd_anat, sex_anat], ctx_grey(:, roi));
        ctx_grey(:, roi) = mdl.Residuals.Raw;
    end
end

if update_volu == 1;
    parfor roi = 1:length(sub_volu(1, :));
        mdl = fitlm([age_anat, hnd_anat, sex_anat], sub_volu(:, roi));
        sub_volu(:, roi) = mdl.Residuals.Raw;
    end

    parfor roi = 1:length(ctx_volu(1, :));
        mdl = fitlm([age_anat, hnd_anat, sex_anat], ctx_volu(:, roi));
        ctx_volu(:, roi) = mdl.Residuals.Raw;
    end
end
matlabpool close

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%convert z --> t --> p values (using number of runs), calculate fdr mask
g_grey = corr(sub_grey, ctx_grey);
t_grey = r_2_t(g_grey, nsub-2);
p_grey = t_2_p(t_grey, nsub-2);
[m_grey_pp, m_grey_pn] = fdr_mask(p_grey);

g_volu = corr(sub_volu, ctx_volu);
t_volu = r_2_t(g_volu, nsub-2);
p_volu = t_2_p(t_volu, nsub-2);
[m_volu_pp, m_volu_pn] = fdr_mask(p_volu);

z_func = nanmean(g_func, 3);
r_func = z_2_r(z_func);
t_func = r_2_t(r_func, nsub*nrun-2);
p_func = t_2_p(t_func, nsub*nrun-2);
[m_func_pp, m_func_pn] = fdr_mask(p_func);








% checkpoint
save(['cere-conn_func-volu-grey_vertex_' outputname '_proc.mat'], '-v7.3');
