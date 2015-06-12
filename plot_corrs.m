% % plot thresholded correlation values
% graph_plot = graph_r;
% %graph_plot(mask_p == 0) = 0;
% imagesc(graph_plot, [-1 1])
% colormap(redblue);
% colorbar();

% set(gca, 'ytick', [1:35])
% set(gca, 'yticklabel', labels)

addpath('/home/jdv/code/toolkits/matlab/plot/colourmaps/')

load('compcor_func-volu-grey_vertex_CV_proc.mat')

subplot(2,3,1);
imagesc(r_func, [-0.5, 0.5]);
colormap(redblue);
title('fmri -- anaticor');

load('anaticor_func-volu-grey_vertex_CV_proc_ctxthick-native.mat')

subplot(2,3,4);
imagesc(r_func, [-0.5, 0.5]);
colormap(redblue);
title('fmri -- compcor');

subplot(2,3,2);
imagesc(g_volu, [-0.5, 0.5]);
colormap(redblue);
title('cere vol x ctx thick');

load('anaticor_func-volu-grey_vertex_CV_proc.mat')

subplot(2,3,5);
imagesc(g_volu, [-0.5, 0.5]);
colormap(redblue);
title('cere vol x ctx vol');

subplot(2,3,3);
imagesc(g_grey, [-0.5, 0.5]);
colormap(redblue);
title('t1 intensity');

subplot(2,3,6);
imagesc([0], [-0.5, 0.5]);
colormap(redblue);
colorbar();
