function [m_pp, m_pn] = fdr_mask(pmat)

    % calculate FDR
    dims = size(pmat);
    pvec = reshape(pmat, dims(1)*dims(2), 1);
    [pp, pn] = fdr_1995(pvec, 0.05);

    % convert to zero if required
    if isempty(pp) == 1;
        pp = 0;
    end

    if isempty(pn) == 1;
        pn = 0;
    end

    % make mask matrices
    m_pp = zeros(dims(1), dims(2));
    m_pp(pmat < pp) = 1;

    m_pn = zeros(dims(1), dims(2));
    m_pn(pmat < pn) = 1;

end