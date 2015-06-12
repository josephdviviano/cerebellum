function write_link_list(graph, output);
    % Writes a link list in a very simple format:
    %    a b W
    %    a b W
    %
    % where a and b denote node numbers and W denotes the weight of the edge.
    % This is mostly so we can communicate with InfoMap from
    % http://www.mapequation.org .
    %
    % USAGE:
    %    graph = weighted or non weighted matrix.
    %    output = name of the output file, which will be plain text.

    dims = size(graph);
    outmat = zeros(3, dims(1)*dims(2));

    row = 1;
    for x = [1:dims(1)];
        for y = [1:dims(2)];
            outmat(1, row) = x;
            outmat(2, row) = y;
            outmat(3, row) = graph(x, y);

            row = row + 1;
        end
    end

    dlmwrite(output, outmat', ' ');
end