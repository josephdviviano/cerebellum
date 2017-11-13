function sparse = make_sparse(g, sparseness);
    sparse = zeros(size(g));
    count = 1;
    for v = g';
        v = sparsify(v, sparseness);
        sparse(count, :) = v;
        count = count + 1;
    end
end

