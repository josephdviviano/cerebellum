function plot_cluster_diagnostics_dual(inst1, inst2, q1, q2, comms1, comms2, xlabels1, xlabels2, ylabels1, ylabels2);

    dims = size(inst1.mean);
	pct_removed1 = calc_pct_removed(comms1.exemplars);
	pct_removed2 = calc_pct_removed(comms2.exemplars);

	subplot(4,2,1);
	imagesc(inst1.mean', [0.9 1])
	colormap(hot); colorbar
	title('stability (rand)')
	set(gca, 'xtick', [1:dims(1)]);
	set(gca, 'xticklabel', []);
	set(gca, 'ytick', [1:dims(2)]);
	set(gca, 'yticklabel', ylabels1);
	grid('on')

	subplot(4,2,2);
	imagesc(inst2.mean', [0.9 1])
	colormap(hot); colorbar
	title('stability (rand)')
	set(gca, 'xtick', [1:dims(1)]);
	set(gca, 'xticklabel', []);
	set(gca, 'ytick', [1:dims(2)]);
	set(gca, 'yticklabel', ylabels2);
	grid('on')

	subplot(4,2,3);
	imagesc(q2.mean', [0.4 1])
	colormap(hot); colorbar
	title('modularity (q)')
	ylabel('nodes removed (n)')
	set(gca, 'xtick', [1:dims(1)]);
	set(gca, 'xticklabel', []);
	set(gca, 'ytick', [1:dims(2)]);
	set(gca, 'yticklabel', ylabels1);
	grid('on')

	subplot(4,2,4);
	imagesc(q2.mean', [0.4 1])
	colormap(hot); colorbar
	title('modularity (q)')
	ylabel('nodes removed (n)')
	set(gca, 'xtick', [1:dims(1)]);
	set(gca, 'xticklabel', []);
	set(gca, 'ytick', [1:dims(2)]);
	set(gca, 'yticklabel', ylabels2);
	grid('on')

	subplot(4,2,5);
	imagesc(comms1.mean_clean', [0 20])
	colormap('hot'); colorbar
	title('n communities')
	set(gca, 'xtick', [1:dims(1)]);
	set(gca, 'xticklabel', []);
	set(gca, 'ytick', [1:dims(2)]);
	set(gca, 'yticklabel', ylabels1);
	grid('on')

	subplot(4,2,6);
	imagesc(comms2.mean_clean', [0 20])
	colormap('hot'); colorbar
	title('n communities')
	set(gca, 'xtick', [1:dims(1)]);
	set(gca, 'xticklabel', []);
	set(gca, 'ytick', [1:dims(2)]);
	set(gca, 'yticklabel', ylabels2);
	grid('on')

	subplot(4,2,7);
	imagesc(pct_removed1', [0 1])
	colormap(hot); colorbar
	xlabel('sparsity (%)')
	title('nodes removed (%)')
	set(gca, 'xtick', [1:dims(1)]);
	set(gca, 'xticklabel', xlabels1);
	set(gca, 'ytick', [1:dims(2)]);
	set(gca, 'yticklabel', ylabels1);
	grid('on')

	subplot(4,2,8);
	imagesc(pct_removed2', [0 1])
	colormap(hot); colorbar
	xlabel('sparsity (%)')
	title('nodes removed (%)')
	set(gca, 'xtick', [1:dims(1)]);
	set(gca, 'xticklabel', xlabels2);
	set(gca, 'ytick', [1:dims(2)]);
	set(gca, 'yticklabel', ylabels2);
	grid('on')
end