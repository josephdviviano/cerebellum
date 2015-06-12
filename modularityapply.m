function [partitions, q] = modularityapply(graph, g, n, bin, dig, iter)
    %[instability, instab_sd, instab_stat] = modularityapply(inmat, gamma)
    %
    % inmat -- n x n matrix of data to determine community structure
    % gamma -- model orders to test
    % iter  -- number of times to run each model order (for stability estimates)
    % bin   -- if 1, data is binary, so we use hamming distance
    %
    % This takes a graph and makes it g % sparse. Next it applies the louvain
    % modularity maximization algorithm iter times, returning the partition with
    % the highest Q. The returned partitions have communities smaller than n
    % nodes removed. If bin == 1, the graph is binarized before partitioning.

    % set matrix to g sparseness excluding diagonal.
    if dig == 1;
        graph = set_diagonal(sparsify(set_diagonal(graph, 0), g), 1);
    else;
        graph = sparsify(set_diagonal(graph, 0), g);
    end

    if bin == 1;
        graph(graph > 0) = 1;
    end

    dims = size(graph);

    qs = zeros(iter, 1);
    partitons = zeros(iter, dims(1));

    for it = 1:iter;
        [a, q] = modularity_louvain_und_sign(graph, 'pos');
        a = remove_small_communities(a, n);

        % save results
        qs(it) = q;
        partitions(it, :) = a;
    end

    % find maximum q
    idx = find(qs == max(q));
    if length(idx) > 1;
        idx = idx(1);
    end
    partitions = partitions(idx, :);
end
