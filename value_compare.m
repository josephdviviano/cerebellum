function [rs, ps] = value_compare(a, b, q, sparsity);
    % regresses the columns of A onto B, outputs the r^2 for each column.

    % if sparsity is less than 1, that % of the strongest values will be found
    % in a and used to compare with b.

    dims = size(a);
    rs = zeros(dims(2), 1);
    ps = zeros(dims(2), 1);    
    
    for col = 1:dims(2);
        x = a(:, col);
        y = b(:, col);

        if sparsity < 1;
            [tmp, idx] = sort(x);
            idx = idx(length(x)-round(length(x)*sparsity):length(x));

            x = x(idx);
            y = y(idx);
        end

        % linear relationship?
        %r = corr(a(:,col), b(:,col), 'linear');
        r = corr(x, y);
        df = length(x)-2;
        t = r_2_t(r, df);
        p = t_2_p(t, df);
        % t = r*sqrt(df) / sqrt(1-r^2);
        % %t = sqrt((length(x)-2) * rsq) / sqrt(1 - rsq);
        % p = 1-tcdf(abs(t), df);

        rs(col) = r^2;
        ps(col) = p;
    end

    % fdr correction
    ps(ps == 0) = realmin;

    if isempty(q) == 0;
        cutoff = fdr_1995(ps, q);
        if isempty(cutoff) == 1;
            cutoff = 0;
        end
        rs(ps > cutoff) = 0;
    end
end
