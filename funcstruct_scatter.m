function funcstruct_scatter(d1, d2, l1, l2, labels)
    % scatterplot of structure and function
    for roi = 1:35;
        subplot(7, 5, roi)

        x = d1(roi, :);
        y = d2(roi, :);

        % linear relationship
        df = length(x) - 2;
        r = corr(x, y);
        t = r_to_t(r, df);
        p = t_to_p(t, df);

        % scatterplot
        scatter(x, y, [], 'red'); 
        h = lsline;
        set(h(1),'color','black');
        xlabel(l1)
        ylabel(l2)
        title([labels{roi} ' p = ' num2str(p) ' r^2 = ' num2str(r^2)]);

    end
end
