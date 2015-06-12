function [pct_removed] = calc_pct_removed(partitions);
	% given a list of partitions, treats 0s as 'no group' and calculates
	% the percentage of ROIs/nodes not assigned to a group.

	dims = size(partitions);
	pct_removed = zeros(dims(1), dims(2));

	for x = 1:dims(1);
		for y = 1:dims(2);
	        pct_removed(x, y) = length(find(partitions(x, y, :) == 0)) / dims(3);
	    end
	end
end
