function [H, T, perm] =  dendrogram_plot(graph, labels, perm, range, sq);
    % Clustering 4 Dollars
    %
    % This clusters the rows of the submitted matrix using hierarchical
    % ammagolrative clustering (ward linkage, euclidean), and plots the results
    % for great justice.
    %
    % [H, T, perm] =  dendrogram_plot(graph, labels, perm, range, sq);
    %
    % ARGUEMENTS:
    %   graph  = matrix (full or bipartite) to cluster and plot.
    %   labels = labels for the rows of graph.
    %   perm   = if not [], skip clustering and apply that specified by perm.
    %   range  = range of values (-ve +ve) for plotting.
    %   sq     = if 1, matrix is reordered on both axes. If 0, we reorder rows.
    %
    % RETURNS:
    %   H    = :D
    %   T    = :D
    %   perm = permutation of dendrogram to produce an ordered visualization. 
    dims = size(graph);

     % compute dendrogram if permutation was not supplied
    if isempty(perm) == 1;
		dend_pdist = pdist(graph, 'euclidean');
		dend_link = linkage(dend_pdist, 'ward');
		[H, T, perm] = dendrogram(dend_link, 0);
    end

    % permute the graph for visualization.
    graph = graph(perm, :);
	if sq == 1;
        graph = graph(:, perm, :);
    end

    % plot the graph
	imagesc(graph, [-range range]);
	colormap(redblue);
	colorbar();
	
		if isempty(labels) == 0;
	    set(gca, 'xtick', [1:dims(2)]);
		set(gca, 'ytick', [1:dims(1)]);
	    labels_perm = labels(perm);
	    set(gca, 'yticklabel', labels_perm);

	    if sq == 1;
	        set(gca, 'xticklabel', labels_perm);
		    %rotate_x_labels(gca, 65)
	    end
	else
		set(gca, 'xtick', []);
	    set(gca, 'ytick', []);
end
