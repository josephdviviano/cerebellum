function [rs, ps, sig] = permutation_test(a, b, iterations)
    % does iterations permutations, randomizing a and b to determine the null
    % distributions of correlations between datasets. Finally, computes the
    % actual correlation and calculates the proportion of null trials that
    % produced a stronger effect than the real data. correlations computed
    % between rows of a and b. all tests are two-tailed (see abs() when
    % computing p value)

    dims = size(a);

    rs = zeros(dims(1), 1);
    ps = zeros(dims(1), 1);
    sig = zeros(dims(1), 1);

    for row = 1:dims(1);

        % null correlations
        null_rs = zeros(iterations,1);

        for iter = 1:iterations;
            idx_a = randperm(dims(2));
            idx_b = randperm(dims(2));

            null_rs(iter) = corr(a(row, idx_a)', b(row, idx_b)');
        end

        % true correlation
        r = corr(a(row, :)', b(row, :)');

        % proportion of trials where true correlation is smaller in magnitude
        % than the null correlations
        p = length(find(abs(r) <= abs(null_rs))) / iterations;

        % store values
        rs(row, 1) = r;
        ps(row, 1) = p;
        disp(['r=' num2str(r) ',p=' num2str(p)])
    end

    % fdr correction
    ps(ps == 0) = realmin;
    cutoff = fdr_1995(ps, 0.05);
    if isempty(cutoff) == 1;
        cutoff = 0;
    end
    sig(ps < cutoff) = 1;
end

