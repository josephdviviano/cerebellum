function [m] = merge_by_cluster(graph, clusters)
	% merges rows of input matrix according to cluster assignment
	% outputs a n x sample matrix 
	% where n = number of clusters and samples = number of samples per cluster.

	dims = size(graph);
	clst = unique(clusters(clusters > 0));
	n_clust = length(clst);

	m = zeros(n_clust, dims(2));

    count = 1;
	for c = clst;
		idx = find(clusters == c);
		m(count, :) = mean(graph(idx, :), 1);

		count = count + 1;
	end
