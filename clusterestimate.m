function inst = clusterestimate(data, ns, iter)
    % data  -- subcortical ROI * cortical ROI matrix to cluster into n
    %          subcortical networks
    % ns    -- cluster levels (k) to test
    % iter  -- number of times to run each sparsity.
    %
    % This iteratively (iter times) clusters the input data into n networks
    % using hierarchical clustering. First, all negative edges are set to 0. For
    % each iteration, we compute two partitions A and B, on a random split of the
    % subjects. We also train a KNN model on the labels found on A, and use them
    % to predict the labels from B. We then calculate the hamming distance
    % between the predicted labels for B, and the real ones, compute the
    % similarity of each cluster solution. The mean and standard deviation of
    % the stability over all iterations is returned as a measure of stability at
    % a given sparseness. The number of communities detected is also returned.

    dims = size(data);
    n_thresh = length(ns);

    % init outputs
    inst.mean = zeros(n_thresh, 1);
    inst.meannorm = zeros(n_thresh, 1);
    inst.sd = zeros(n_thresh, 1);

    dist_fxn = 'euclidean';
    link_fxn = 'ward';

    % loop through ns, gs
    n_count = 1;
    for n = ns;

        tic
        dist = zeros(iter, 1);
        test = data;

        parfor it = 1:iter;

            % randomly split subjects into 2 groups
            idx = randperm(size(test, 2));
            idxa = idx(1:floor(length(idx)/2));
            idxb = idx(floor(length(idx)/2)+1:end);

            % compute two random partitions of the data and compare cluster
            % solutions for both, using a KNN model as an intermediary
            da = test(:, idxa);
            db = test(:, idxb);

            % cluster 'a' half of data
            Ya = pdist(da, dist_fxn);
            Za = linkage(Ya, link_fxn);
            Ca = cluster(Za,'maxclust', n);

            % train knn classifier on this half of the data
            model = fitcknn(da, Ca, 'NumNeighbors', 4);

            % cluster 'b' half of data
            Yb = pdist(db, dist_fxn);
            Zb = linkage(Yb, link_fxn);
            Cb = cluster(Zb,'maxclust', n);

            % predict cluster labels on b based on those found on a
            Cp = predict(model, db);

            % match labels across predicited partition (Cp, from Ca) and Cb
            % note we introduce all possible labels into both Cp and Cb to
            % allow the algorithm to function when some of the labels aren't
            % predicted (this happens if there are extremely small clusters)
            % in the data... typically due to a bad linkage function
            mappings = match_labels([Cp; unique(Cb)], [Cb; unique(Cb)]);
            Cpout = zeros(length(Cp), 1);
            for x = 1:n;
                idx = find(Cp == x);
                Cpout(idx) = mappings(x);
            end
            Cp = Cpout;

            % store the distance between these two partitions
            dist(it) = pdist([Cp'; Cb'], 'hamming');
        end

        % store stats in output vectors
        inst.mean(n_count) = mean(dist);
        % normalize by 'null' for this n
        inst.meannorm(n_count) = mean(dist) / (1-(1/n));
        inst.sd(n_count) = std(dist);

        disp(['+ n=' num2str(n) ', inst=' num2str(inst.mean(n_count))])
        n_count = n_count + 1;
        toc
    end
end
