function [m] = collapse_to_rois(m, rois, mask);

    dims = size(m);
    m_final = zeros(length(rois), dims(2));
    count = 1;
    for roi = rois';
        tmpidx = find(mask == roi);
        tmpval = mean(m(tmpidx, :));
        m_final(count, :) = tmpval;
        count = count+1;
    end
    m = m_final;
    clear m_final;
end