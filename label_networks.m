function labels = labels_networks(network);
    for i = 1:size(network, 1);
        idx = find(network(i, :));
        network(i, idx) = i;
    end
    labels = sum(network, 1);
end
