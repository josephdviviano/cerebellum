function [graph] = set_diagonal(graph, val)
	% Sets the diagonal of square matricies to be val (removing self-loops)

	graph(logical(eye(size(graph)))) = val;
end