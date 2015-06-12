function [z] = r_2_z(r);
    z = 0.5 * log( (1+r) ./ (1-r) );
end
