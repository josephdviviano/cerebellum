% boostrap
load('func_vertex_CV_WMREG.mat')

% free up ram, because this takes a lot...
clearvars vol* surf* c pvec graph_* idx_* list mask_n mask_p vals

% file dimensions 
dims = size(cmat);
n_runs = dims(3);

% relevant options
n_iter = 1000;

% where our results go (only storing means at the moment)
bootmat = zeros(dims(1), dims(2), n_iter);

for iter = 1:n_iter;

    % resampling with replacement
    subjects = datasample(1:n_runs, n_runs);

    % output matrix
    testmat = zeros(dims(1), dims(2), n_runs);

    x = 1;
    for s = subjects;
        testmat(:, :, x) = cmat(:, :, s);
        x = x + 1;
    end

    % nb -- this will include a small number of corrupted nans -- they will
    % just become zeros... this is due to ram constraints and laziness
    testmat = mean(testmat, 3);
    testmat(isnan(testmat) == 1) = 0;

    bootmat(:, :, iter) = testmat;

    disp(['Done iteration ' int2str(iter)])
end

save('func_bootstrap_1000_reduced.mat', '-v7.3')

% calculate the standard deviation
bootmat_mean = mean(bootmat, 3);

for x = 1:n_iter;
    % calculate the squared difference from the mean
    bootmat(:, :, x) = (bootmat(:, :, x) - bootmat_mean).^2;
end

bootmat_std = sqrt(mean(bootmat, 3));


