function inst = clusterestimate(data, gs, bin, ns, iter)
    %[inst, q, comms] = clusterestimate(graph, gs, iter)
    %
    % data  -- subject * connectivity matrix to cluster into n networks
    % gs    -- sparsities to test
    % bin   -- if 1, set all surviving edges to 1
    % ns    -- cluster levels (k) to test
    % iter  -- number of times to run each sparsity.
    %
    % This iteratively (iter times) clusters the input data into n networks
    % using hierarchical clustering. First, all negative weights are set to 0.
    % The each row of the matrix is set to g% sparseness, and binarized if bin
    % == 1. For each iteration, we compute two partitions A and B, on a random
    % split of the subjects. We also train a KNN model on the labels found on A,
    % and use them to predict the labels from B. We then calculate the hamming
    % distance between the predicted labels for B, and the real ones, compute the
    % similarity of each cluster solution. The mean and standard deviation of
    % the stability over all iterations is returned as a measure of stability at
    % a given sparseness. The number of communities detected is also returned.

    dims = size(data);
    ng = length(gs);
    n_thresh = length(ns);

    % init outputs
    inst.mean = zeros(ng, n_thresh);
    inst.meannorm = zeros(ng, n_thresh);
    inst.sd = zeros(ng, n_thresh);

    dist_fxn = 'euclidean';
    link_fxn = 'ward';

    % loop through ns, gs
    n_count = 1;
    for n = ns;
        g_count = 1;
        for g = gs;

            tic
            dist = zeros(iter, 1);
            test = data;

            % set each subject to have g sparseness
            %for i = 1:dims(1);
            %    test(i, :) = sparsify(data(i, :), g);
            %end

            % set matrix to g sparseness excluding diagonal.
            test = sparsify(set_diagonal(test, 0), g);

            % binarize
            if bin == 1;
                test(test > 0) = 1;
                dist_fxn = 'hamming';
            end

            % remove features that are all zero -- no information
            %sums = sum(test);
            %sum_idx = find(sums ~= 0);
            %test = test(:, sum_idx);
            %disp([num2str(length(sum_idx)) '/' num2str(dims(2)) ' features retained'])

            parfor it = 1:iter;

                % randomly split subjects into 2 groups
                idx = randperm(size(test, 1));
                idxa = idx(1:floor(length(idx)/2));
                idxb = idx(floor(length(idx)/2)+1:end);

                da = test(idxa, :);
                db = test(idxb, :);

                % compute two random partitions of the data and compare cluster
                % solutions for both, using a KNN model as an intermediary

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
            inst.mean(g_count, n_count) = mean(dist);
            % normalize by 'null' for this n
            inst.meannorm(g_count, n_count) = mean(dist) / (1-(1/n));
            inst.sd(g_count, n_count) = std(dist);

            disp(['+ g=' num2str(g) ...
                  ', n=' num2str(n) ...
                  ', inst=' num2str(inst.mean(g_count, n_count))])
            toc
            g_count = g_count + 1;
        end
        n_count = n_count + 1;
    end
end
