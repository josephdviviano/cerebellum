function plot_difference(d1, d2, sp_x, sp_y, sp_i);

    g1 = corr(d1);
    g2 = corr(d2);

    subplot(sp_x, sp_y, sp_i);
	imshow(g1-g2, [-1 1]);
	colormap(redblue);
end