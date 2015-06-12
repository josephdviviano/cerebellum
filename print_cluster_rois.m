function print_cluster_rois(rois, clusters, labels);
    % prints all ROI numbers and associated labels within each cluster.

    for c = unique(clusters);
    	disp(['+ Cluster ' int2str(c)]);

        idx = find(clusters == c);
        for ind = idx;
        	disp(['    ' int2str(rois(ind)) ': ' labels{ind}])
        end
    end
end
