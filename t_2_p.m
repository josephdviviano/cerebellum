function [p] = t_2_p(t, df);
    p = 2 * tcdf(-abs(t), df);
end