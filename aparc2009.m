% written for MATLAB 2014 -- so there is some strangeness.
% simply needs to be run from the hcp directory -- it should spider
% down into the /proc/ directories created in each subject's folder
% (this is designed to work with the 'hcpresto' pipeline available 
%  here: https://bitbucket.org/josephdviviano/hcpresto)

% this works with the APARC 2009 Atlas

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Options
civet_format = 0;  % if this = 1, we use civet surfaces,
                   % if this = 0, we use freesurfer surfaces.

% low-pass options
tr_s = 0.7;        % length of tr in secs
tr_n = 1200;       % number of TRs per run
filt_lo_hz = 0.01; % in Hz
filt_hi_hz = 0.10; % in Hz
filt_order = 100;  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize
% get the subject folders
d = dir(pwd);
idx_subj = [d(:).isdir];
subj = {d(idx_subj).name};
subj(ismember(subjects, {'.', '..'})) = [];

% init experiment-wide arrays
data = zeros(1,183);
list = zeros(1,183);

% set the output name
if civet_format == 1;
    ouputname = 'CV'
else;
    outputnamr = 'FS'
end

% generate our bandpass filter
nyquist = 1/tr_s/2;
filt_hi_ratio = filt_hi_hz / nyquist;
filt_lo_ratio = filt_lo_hz / nyquist;

filt = fir1(filt_order, [filt_lo_ratio, filt_hi_ratio], ...
                                   kaiser(filt_order+1, 2.5));

for s = 1:length(subj);

    %for runs = 1:4;
    for runs = [1, 3]; % right now, we're only using the l-->r set of runs.

        % load in volume data
        r = sprintf('%02d', runs);
        f = subj{s}

        vol_data = load_nii([subj(s) 'proc/func_volsmooth.' r '.nii.gz']);
        vol_vals = load_nii([subj(s) 'proc/smoothmask.' r '.nii.gz']);
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
        tmp_data = double(tmp_data);
        tmp_data = filtfilt(filt, 1, tmp_data')';

        % generate the output data matrix
        vol_list = unique(tmp_atlas);
        vol_data = zeros(dims(4), length(vol_list));

        % loop through ROIs in volume, take mean timeseries
        count = 1;
        for roi = vol_list';
            idx_roi = find(tmp_atlas == roi);
            roi_mean = mean(tmp_data(idx_roi, :), 1);
            vol_data(:, count) = roi_mean;
            count = count + 1;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Surface Data
        if civet_format == 1;

            % load in civet surface data and stack (L over R)
            surf_dataL = dlmread(...
                         [f 'proc/func_surface_civ.L.' r '.1D.dset'], ...
                                                 ' ', [5,2, 40966, 1201]);
            surf_dataR = dlmread(...
                         [f 'proc/func_surface_civ.R.' r '.1D.dset'], ...
                                                 ' ', [5,2, 40966, 1201]);

            % load in the surface atlas and stack (L over R)
            fname = fopen('proc/atlas_civ.L.1D','rt');
            fdata = textscan(fname, '%f%f%f%f%f%f%f', ...
                                    'Whitespace', ' ', ...
                                    'MultipleDelimsAsOne', 1, ...
                                    'HeaderLines', 5);
            surf_valsL = fdata{7};
            fclose(fname);

            fname = fopen('proc/atlas_civ.R.1D','rt');
            fdata = textscan(fname, '%f%f%f%f%f%f%f', ...
                                    'Whitespace', ' ', ...
                                    'MultipleDelimsAsOne', 1, ...
                                    'HeaderLines', 5);
            surf_valsR = fdata{7};
            fclose(fname);

        else;

            % load in freesurfer surface data and stack (L over R)
            surf_dataL = dlmread(...
                         [f '/proc/func_surface_fs.L.' r '.1D.dset'], ...
                                                 ' ', [5,2, 32496, 1201]);
            surf_dataR = dlmread(...
                         [f '/proc/func_surface_fs.R.' r '.1D.dset'], ...
                                                 ' ', [5,2, 32496, 1201]);
            
            % load in the surface atlas and stack (L over R)
            fname = fopen([f '/proc/atlas_fs.L.1D'],'rt');
            fdata = textscan(fname, '%f%f%f%f%f%f%f', ...
                                    'Whitespace', ' ', ...
                                    'MultipleDelimsAsOne', 1, ...
                                    'HeaderLines', 5);
            surf_valsL = fdata{7};
            fclose(fname);

            fname = fopen([f '/proc/atlas_fs.R.1D'],'rt');
            fdata = textscan(fname, '%f%f%f%f%f%f%f', ...
                                    'Whitespace', ' ', ...
                                    'MultipleDelimsAsOne', 1, ...
                                    'HeaderLines', 5);
            surf_valsR = fdata{7};
            fclose(fname);

        end;

        % stack L&R hemisphere, filter
        surf_data = [surf_dataL; surf_dataR];
        surf_vals = [surf_valsL; surf_valsR];
        surf_data = filtfilt(filt, 1, surf_data')';

        if runs == 1;
            % keep track of non surface values on a per-subject basis
            if civet_output == 1;
                idx_surf = zeros(1, 81924);
            else;
                idx_surf = zeros(1, 64984);
            end;
            
            idx_surf(surf_vals > 11100) = 1;
            idx_surf(surf_vals > 13000) = 0;
            
            disp('good surface nodes:');
            surface_size = sum(idx_surf);
            disp(surface_size);
        end;

        % extract non-cortex / non labeled data
        idx_lo = find(surf_vals > 11100);
        idx_hi = find(surf_vals < 13000); 
        idx_surf = intersect(idx_lo, idx_hi);

        % clear variables
        clearvars surf_dataL surf_dataR ...
                  surf_valsL surf_valsR ...
                  fdata fname ...
                  tmp_atlas tmp_data ...
                  idx_lo idx_hi

        tmp_data = surf_data(idx_surf, :);
        tmp_atlas = surf_vals(idx_surf, :);

        % generate the output data matrix
        surf_list = unique(tmp_atlas);
        surf_data = zeros(dims(4), length(surf_list));

        % loop through ROIs on the surface, take mean timeseries
        count = 1;
        for roi = surf_list';
            idx_roi = find(tmp_atlas == roi);
            roi_mean = mean(tmp_data(idx_roi, :), 1);
            surf_data(:, count) = roi_mean;
            count = count + 1;
        end

        % concatenate volume and cortical data, append runs
        d = [vol_data, surf_data];
        l = [vol_list; surf_list]';
        
        data = [data; d];
        list = [list; l];
       
        data_size = size(data);
        list_size = size(list);

    end

    % strip zeros
    vol = vol(2:end, :);
    surf = surf(2:end, :);

    % keep track of good nodes & number of subjects
    list = [list; idx_surf];
    vals = [vals; surf_vals]
    
    % load z-scored correlation matrix into cmat
    c = corr(vol, surf);
    c = 0.5 * log( (1+c) ./ (1-c) );
    cmat(:, :, subjcount) = c;

    % back up, just in case
    save(['func_aparc2009_' outputname '.mat'])

    % update
    disp(['subject ' int2str(subjcount) ' done...'])

    % iterate
    subjcount = subjcount + 1;

end

% strip zeros from index of good vertex's
list = list(2:end, :);
vals = vals(2:end, :);

% create graph
graph_z = nanmean(cmat, 3);

% convert graph back to r values
graph_r = (exp(2*graph_z) - 1) ./ (exp(2*graph_z) + 1);

% back up, just in case
save(['func_aparc2009_' outputname '.mat'])

% create ctx X cerebellum
% array = corr(vol_data, surf_data);