% boostrap
load('struct_vertex_CV.mat')

% free up ram, because this takes a lot...
%clearvars vol* surf* c pvec graph_* idx_* list mask_n mask_p vals

% file dimensions 
dims = size(graph);
n_runs = length(vol);

% relevant options
n_iter = 1000;

% where our results go (only storing means at the moment)
bootmat = zeros(dims(1), dims(2), n_iter);

for iter = 1:n_iter;

    % resampling with replacement
    subjects = datasample(1:n_runs, n_runs);

    % output matrix
    test_vol = zeros(dims(1), n_runs);
    test_surf = zeros(dims(2), n_runs);

    x = 1;
    for s = subjects;
        test_vol(:, x) = vol(s, :);
        test_surf(:, x) = surf(s, :);
        x = x + 1;
    end

    % load in the bootstrap

    testmat = corr(test_vol', test_surf');
    bootmat(:, :, iter) = testmat;

    disp(['Done iteration ' int2str(iter)])
end

save('struct_bootstrap_1000.mat', '-v7.3')

clearvars graph* mask* list idx* vol* surf* test* tmp* vals* pvec*

% calculate the standard deviation
bootmat_mean = mean(bootmat, 3);

for x = 1:n_iter;
    % calculate the squared difference from the mean
    bootmat(:, :, x) = (bootmat(:, :, x) - bootmat_mean).^2;
end

bootmat_std = mean(bootmat, 3);

% calculate the coefficient of variation
bootmat_cv = bootmat_std ./ bootmat_mean;

save('struct_bootstrap_outputs.mat', ...
     'struct_bootmat_mean', 'struct_bootmat_std', 'struct_bootmat_cv');
