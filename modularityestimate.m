function [inst, q, comms] = modularityestimate(graph, gs, bin, dig, ns, iter)
    %[inst, q, comms] = modularityestimate(graph, gs, iter)
    %
    % graph -- n^2 similarity matrix of data to find communities in
    % gs    -- sparsities to test
    % bin   -- if 1, set all surviving edges to 1.
    % dig   -- if 1, keep self loops
    % n     -- remove communities smaller than these numbers.
    % iter  -- number of times to run each sparsity.
    %
    % This iteratively (iter times) partitions a graph using a modularity
    % maximization algorithm. First, all negative weights are set to 0.
    % The matrix is set to g% sparseness, and binarized if bin == 1.
    % For each iteration, we compute two partitions A and B. We repeat B until
    % obtain the same number of clusters as A, Communities smaller than 4 nodes 
    % are set to community 0, which we don't consider for downstream analysis. 
    % We then calculate the rand index to compare the similarity of these 
    % partitions. The mean and standard deviation of the rand index over all
    % iterations is returned as a measure of stability at a given sparseness.
    % The average number of communities detected (after removing very small 
    % communities) is also returned.

    dims = size(graph);
    ng = length(gs);
    n_thresh = length(ns);

    % init outputs
    inst.mean = zeros(ng, n_thresh);   %
    inst.sd = zeros(ng, n_thresh);     % for error bars
    inst.failed = zeros(ng, n_thresh); %
    q.mean = zeros(ng, n_thresh);      %
    q.sd = zeros(ng, n_thresh);        %
    comms.mean_raw = zeros(ng, n_thresh);  %
    comms.sd_raw = zeros(ng, n_thresh);    %
    comms.uniq_raw = zeros(ng, n_thresh);       %
    comms.mean_clean = zeros(ng, n_thresh);     %
    comms.sd_clean = zeros(ng, n_thresh);       %
    comms.uniq_clean = zeros(ng, n_thresh);     %
    comms.exemplars = zeros(ng, n_thresh, dims(1)); %


    % loop through ns, gs
    n_count = 1;
    for n = ns;
        g_count = 1;
        for g = gs;

            dist = zeros(iter, 1);
            ncom.clean = zeros(iter, 1);
            ncom.raw = zeros(iter, 1);
            modu = zeros(iter, 1);

            % set matrix to g sparseness excluding diagonal.
            if dig == 1;
                test = set_diagonal(sparsify(set_diagonal(graph, 0), g), 1);
            else
                test = sparsify(set_diagonal(graph, 0), g);
            end

            if bin == 1;
                test(test > 0) = 1;
            end

            uneq_count = 0;
            failed = 0;
            for it = 1:iter;

                % compute two partitions of the data (using the full graph)
                % only accept partitions of equal number of communities
                % by repeating B if necessary.

                flag = 0;
                while flag == 0;

                    %[a, q_a] = modularity_und(test, g);
                    [a, q_a] = modularity_louvain_und_sign(test, 'pos');
                    n_comm_raw = length(unique(a));
                    a = remove_small_communities(a, n);
                    n_comm_clean = length(unique(a(a > 0)));
                    %[a, q_a] = modularity_probtune_und_sign(test, 'pos', a, 0.25);

                    %[b, q_b] = modularity_und(test, g);
                    [b, q_b] = modularity_louvain_und_sign(test, 'pos');
                    b = remove_small_communities(b, n);
                    %[b, q_b] = modularity_probtune_und_sign(test, 'pos', b, 0.25);
                    
                    % ensure the number of communities in a and b are the same.
                    if length(unique(a)) == length(unique(b));
                        flag = 1;
                    else;
                        uneq_count = uneq_count + 1;
                    end
                    
                    % if the number of times a + b are unequal is as great as the
                    % number of iterations asked for, we fail this level of g.
                    if uneq_count > iter;
                        failed = 1;
                        flag = 1;
                    end
                end

                if failed == 1;
                    break
                end

                % match labels across partitions
                mappings = match_labels(a, b);
                aout = zeros(length(a), 1);
                for x = 1:n_comm_clean;
                    idx = find(a == x);
                    aout(idx) = mappings(x);
                end

                % store the distance between these two partitions
                res = part_agree_coef(aout+1, b+1);
                dist(it) = res.ri;
                ncom.clean(it) = n_comm_clean;
                ncom.raw(it) = n_comm_raw;
                modu(it) = q_a;

            end

            if failed == 0;
                % store stats in output vectors
                inst.mean(g_count, n_count) = mean(dist);
                inst.sd(g_count, n_count) = std(dist);
                
                q.mean(g_count, n_count) = mean(modu);
                q.sd(g_count, n_count) = std(modu);

                comms.mean_raw(g_count, n_count) = mean(ncom.raw);
                comms.sd_raw(g_count, n_count) = std(ncom.raw);
                comms.uniq_raw(g_count, n_count) = length(unique(ncom.raw));

                comms.mean_clean(g_count, n_count) = mean(ncom.clean);
                comms.sd_clean(g_count, n_count) = std(ncom.clean);
                comms.uniq_clean(g_count, n_count) = length(unique(ncom.clean));

                comms.exemplars(g_count, n_count, :) = a;

                disp(['+ g=' num2str(g) ...
                      ', n=' num2str(n) ...
                      ', inst=' num2str(inst.mean(g_count, n_count)) ...
                      ', uniq=' num2str(comms.uniq_clean(g_count, n_count)) ...
                      ', q=' num2str(q.mean(g_count, n_count)) ...
                      ', comms=' num2str(comms.mean_clean(g_count, n_count))...
                      ', uneq=' int2str(uneq_count)])
            else
                inst.mean(g_count, n_count) = nan;
                inst.sd(g_count, n_count) = nan;
                
                q.mean(g_count, n_count) = nan;
                q.sd(g_count, n_count) = nan;

                comms.mean_raw(g_count, n_count) = nan;
                comms.sd_raw(g_count, n_count) = nan;
                comms.uniq_raw(g_count, n_count) = nan;

                comms.mean_clean(g_count, n_count) = nan;
                comms.sd_clean(g_count, n_count) = nan;
                comms.uniq_clean(g_count, n_count) = nan;

                comms.exemplars(g_count, n_count, :) = zeros(size(a));

                disp(['+ g=' num2str(g) ' failed.'])
            end
            g_count = g_count + 1;
        end
        n_count = n_count + 1;
    end
end
