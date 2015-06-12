function [t] = r_2_t(r, df);
   % rsq = r.^2;
   % tsq = df.*rsq ./ (1-rsq);
   % t = sqrt(rsq);
   % if sign(r) == -1;
   %     t = t .* -1;
   %  end
   t = r.*sqrt(df ./ (1-r.^2));
end