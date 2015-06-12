function [out] = compute_network_maturation_corrs(sub_volu, ctx_volu, partitions)
	%
	dims = size(sub_volu);
	out = zeros(dims(1), length(unique(partitions(partitions > 0))));
	count = 1;
	for c = unique(partitions);
		if c > 0;
		    idx = find(partitions == c);
		    out(:, count) = sum(sub_volu(:, idx), 2);
		    count = count + 1;
		end
	end
	out = corr(out, ctx_volu);
end