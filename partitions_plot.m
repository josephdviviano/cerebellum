function partitions_plot(partitions, master);
    % Plots the partitions submitted, using the ordering obtained from master.

    % sort the master partition, save the index
    master = partitions(master, :);
    [master, idx] = sort(master);

    % sort the partitions by the index from the master partitions
    dims = size(partitions);
    for row = 1:dims(1);
        partitions(row, :) = partitions(row, idx);
    end
end