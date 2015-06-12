function instability_plot(x, e, kx, ky);
    % 
    % :D
    % 
    % 
    errorbar(x, e, 'color', 'black', 'linewidth', 2);
    set(gca, 'xtick', [1:ky-(kx-1)]);
    set(gca, 'xticklabel', [kx:ky]);
    xlabel('k')
    ylabel('instability')

end