% Q1: plot instabilities using KMEANS
n_tests_stability = 1000;

subplot(3,4,1);
instability_plot(inst_r_func, inst_sd_r_func, 2, 25); title('BOLD: CERE * CTX')
subplot(3,4,5);
instability_plot(inst_g_grey, inst_sd_g_grey, 2, 25); title('GREY: CERE * CTX')
subplot(3,4,9);
instability_plot(inst_g_volu, inst_sd_g_volu, 2, 25); title('VOLU: CERE * CTX')

subplot(3,4,2);
dendrogram_plot(r_func, labels, 0.5, 0)
subplot(3,4,6);
dendrogram_plot(g_grey, labels, 1, 0)
subplot(3,4,10);
dendrogram_plot(g_volu, labels, 1, 0)

subplot(3,4,3);
instability_plot(inst_g_func_ctx, inst_sd_g_func_ctx, 2, 25); title('BOLD: CTX^2')
subplot(3,4,7);
instability_plot(inst_g_grey_ctx, inst_sd_g_grey_ctx, 2, 25); title('GREY: CTX^2')
subplot(3,4,11);
instability_plot(inst_g_volu_ctx, inst_sd_g_volu_ctx, 2, 25); title('VOLU: CTX^2')


[l_r_func, lsrt_r_func, idx_r_func] = kmeansapply(r_func, 3, n_iter, 0);
[l_g_func_ctx, lsrt_g_func_ctx idx_g_func_ctx] = kmeansapply(g_func_ctx, ...
    5, n_iter, 0);