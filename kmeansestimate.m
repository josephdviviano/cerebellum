function [instability, instab_sd, instab_stat] = kmeansestimate(inmat, ks, iter, bin)
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

    kopts = statset('MaxIter', 1000, 'UseParallel', true);
    dims = size(inmat);
    n = dims(2); % split columns
    nk = length(ks);
    instability = zeros(nk, 1); %
    instab_sd = zeros(nk, 1); % for error bars
    instab_stat = zeros(nk, 5); % for boxplots

    % for data splitting (splits columns) if we have an odd number of datapoints
    if rem(n, 2) ~= 0;
        isodd = 1;
    else;
        isodd = 0;
    end

    % loop through ks
    k_count = 1;
    for k = ks;
        dist = zeros(iter, 1);

        for it = 1:iter;
            tests = randperm(n);

            if isodd == 0;
                a = inmat(:, tests(1:length(tests)/2));
                b = inmat(:, tests(length(tests)/2+1:length(tests)));
            
            elseif isodd == 1;
                coin = randperm(2);

                % a is smaller
                if coin(1) == 1;
                    a = inmat(:, tests(1:floor(length(tests)/2)));
                    b = inmat(:, tests(floor(length(tests)/2)+1:length(tests)));
                
                % b is smaller
                elseif coin(1) == 2;
                    a = inmat(:, tests(1:ceil(length(tests)/2)));
                    b = inmat(:, tests(ceil(length(tests)/2)+1:length(tests)));
                end
            end

            % map kmeans of split a onto kmeans of split b
            if bin == 0;
                a = kmeans(a, k, 'options', kopts);
                b = kmeans(b, k, 'options', kopts);
            elseif bin == 1;
                a = kmeans(logical(a), k, 'Distance', 'hamming', 'options', kopts);
                b = kmeans(logical(b), k, 'Distance', 'hamming', 'options', kopts);
            end
            mappings = match_labels(a, b);

            aout = zeros(length(a), 1);
            for x = 1:k;
                idx = find(a == x);
                aout(idx) = mappings(x);
            end

            % store the hamming distance between these two segmentations
            dist(it) = pdist([aout, b]', 'hamming');
        end

        % normalize stability by k, store stats in output vector
        instability(k_count) = mean(dist) / (1-1/k);
        instab_sd(k_count) = std(dist) / (1-1/k);
        instab_stat(k_count, 1) = min(dist) / (1-1/k);
        instab_stat(k_count, 2) = quantile(dist, 0.25) / (1-1/k);
        instab_stat(k_count, 3) = median(dist) / (1-1/k);
        instab_stat(k_count, 4) = quantile(dist, 0.75) / (1-1/k);
        instab_stat(k_count, 5) = max(dist) / (1-1/k);

        disp(['+ k=' int2str(k) ', inst=' num2str(instability(k_count)) '.'])
        k_count = k_count + 1;
    end
end
