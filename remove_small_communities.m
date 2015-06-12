function [c] = remove_small_communities(c, n);
	% removes communities with less than n nodes (sets them to 0). Remaining
	% communities are then mapped linearly.

    % remove small communities
	for idx = unique(c); 
		if length(find(c == idx)) < n; 
			c(c == idx) = 0;
		end
	end

    % linear mapping
    count = 1;
    for idx = unique(c(c > 0));
    	c(c == idx) = count;
    	count = count + 1;
    end
end
