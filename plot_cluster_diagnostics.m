function plot_cluster_diagnostics(inst, q, comms, xlabels, ylabels);

    dims = size(inst.mean);
	pct_removed = calc_pct_removed(comms.exemplars);

	subplot(4,1,1);
	imagesc(inst.mean')
	colormap(hot); colorbar
	title('stability (rand)')
	% xlim([1, dims(1)])
	% ylim([min(inst.mean)-0.1, max(inst.mean)+0.1])
	set(gca, 'xtick', [1:dims(1)]);
	set(gca, 'xticklabel', []);
	set(gca, 'ytick', [1:dims(2)]);
	set(gca, 'yticklabel', ylabels);
	grid('on')

	subplot(4,1,2);
	imagesc(q.mean')
	colormap(hot); colorbar
	title('modularity (q)')
	ylabel('nodes removed (n)')
	% xlim([1, dims(1)])
	% ylim([min(q.mean)-0.1, max(q.mean)+0.1])
	set(gca, 'xtick', [1:dims(1)]);
	set(gca, 'xticklabel', []);
	set(gca, 'ytick', [1:dims(2)]);
	set(gca, 'yticklabel', ylabels);
	grid('on')

	subplot(4,1,3);
	imagesc(comms.mean_clean')
	colormap('hot'); colorbar
	title('n communities')
	% xlim([1, dims(1)])
	% ylim([min(comms.mean_clean)-0.1, max(comms.mean_clean)+0.1])
	set(gca, 'xtick', [1:dims(1)]);
	set(gca, 'xticklabel', []);
	set(gca, 'ytick', [1:dims(2)]);
	set(gca, 'yticklabel', ylabels);
	grid('on')

	subplot(4,1,4);
	imagesc(pct_removed')
	colormap(hot); colorbar
	xlabel('sparsity (%)')
	title('nodes removed (%)')
	% xlim([1, dims(1)])
	% ylim([0, max(pct_removed)])
	set(gca, 'xtick', [1:dims(1)]);
	set(gca, 'xticklabel', xlabels);
	set(gca, 'ytick', [1:dims(2)]);
	set(gca, 'yticklabel', ylabels);
	%rotate_x_labels(gca, 60)
	grid('on')
end