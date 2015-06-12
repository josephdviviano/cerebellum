function [lmat] = labelperm(l);
	% uses greedy algo to find optimal label permutation
	% depricated. please use match_labels instead.
	%

	n_labels = length(unique(l));
	tests = perms(unique(l));
	lmat = zeros(length(tests), n_labels);

	% for each row of the test matrix
	for test = 1:length(tests);
	    % for each of the possible numbers
	    for count = unique(l)';
	        % find where input is equal to input mapper
	        idx = find(l == count);
	        % now set those indicies to be equal to the output mapper from tests
	        lmat(test, idx) = tests(test, count);
	    end
	end
end