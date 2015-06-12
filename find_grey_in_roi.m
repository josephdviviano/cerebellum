function [idx] = find_grey_in_roi(mask, segmentation);
    %
    % This assumes your segmentation came from CIVET...
    %
    wm_val = max(unique(segmentation));
    idx_gm = find(segmentation < wm_val);
    idx_vol = find(mask > 0);
    idx = intersect(idx_vol, idx_gm);
end