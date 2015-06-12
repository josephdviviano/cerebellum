function [g] = sparsify(g, pct);
    % [g] = sparsify(g, pct);
    %
	% Makes an input matrix g sparse, retaining only the top n percent
	% of values. Removes all negative weights.

	dims = size(g);
	g = reshape(g, dims(1)*dims(2), 1); % turn matrix into vector
	g(g<0) = 0; % remove negative weights
    cutoff = floor(length(g)*pct);  % calculate number of nodes to retain
    [gs, idx_sort] = sort(g); % sort notes by weight
    idx_rm = idx_sort(1:end-cutoff); % find nodes below cutoff
    g(idx_rm) = 0; % set these notes to be 0
    g = reshape(g, dims(1), dims(2)); % convert back to matrix

end