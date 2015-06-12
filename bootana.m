% structure-function bootstrap analysis

subplot(2,3,1);
    imagesc(struct_bootmat_mean, [-0.5 0.5]);
    title('struct - mean')
    colorbar()
subplot(2,3,2);
    imagesc(struct_bootmat_std, [-0.1 0.1]);
    title('struct - std')
    colorbar()
subplot(2,3,3);
    imagesc(struct_bootmat_cv, [-0.5 0.5]);
    title('struct - cv')
    colorbar()
subplot(2,3,4);
    imagesc(func_bootmat_mean, [-0.5 0.5]);
    title('func - mean')
    colorbar()
subplot(2,3,5);
    imagesc(func_bootmat_std, [-0.1 0.1]);
    title('func - std')
    colorbar()
subplot(2,3,6);
    imagesc(func_bootmat_cv, [-0.5 0.5]);
    title('func - cv')
    colorbar()

colormap(redblue);

threshold = 0.1; % maximum coeff. of variance allowed.

dims = size(func_bootmat_mean);

idx_func = find(abs(func_bootmat_cv) < threshold);
idx_struct = find(abs(struct_bootmat_cv) < threshold);
idx_both = intersect(idx_func, idx_struct);

func_mask = zeros(dims(1), dims(2));
struct_mask = zeros(dims(1), dims(2));
both_mask = zeros(dims(1), dims(2));

func_mask(idx_func) = 1;
struct_mask(idx_struct) = 1;
both_mask(idx_both) = 1;

figure;
subplot(3,1,1)
imagesc(func_mask);
title('func')
subplot(3,1,2)
imagesc(struct_mask);
title('struct')
subplot(3,1,3)
imagesc(both_mask);
title('intersection')
colormap(bone)