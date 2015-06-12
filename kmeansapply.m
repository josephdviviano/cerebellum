function [l, sorted_l, idx] = kmeansapply(inmat, k, iter, bin)
    %[instability, instab_sd, instab_stat] = kmeansestimate(inmat, ks, iter)
    %
    % inmat -- n x m matrix of data to estimate model order from
    % ks    -- model orders to test
    % iter  -- number of times to run each model order (for stability estimates)
    % bin   -- if 1, data is binary, so we use hamming distance
    %
    % This iteratively (iter times) splits the data into 2 subsets of columns 
    % and clusters along the rows. The label agreement for each k between these 
    % splits is used to determine the optimal clustering solution of the data.
    %
    % For this measure, an instability of 0 means perfectly so, with a maximum
    % instability of 1-1/k. We therefore normalize each split of the data by
    % 1-1/k.
    %
    % instab_stat returns a matrix containing:
    %     min, 1st quartile, median, 3rd quartile, max. for boxplots.
    %
    % This will take advantage of a matlab parallel pool if you open one before
    % running this function. 

    kopts = statset('MaxIter', iter, 'UseParallel', true);    

    if bin == 0;
        l = kmeans(inmat, k, 'options', kopts, 'replicates', iter);
    elseif bin == 1;
        l = kmeans(logical(inmat), k, 'Distance', 'hamming', ...
                                'options', kopts, 'replicates', iter);
    end
    [sorted_l, idx] = sort(l);
end
