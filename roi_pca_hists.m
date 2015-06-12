% labels
labels = {...
 'Vermal I II', 'L III', 'L IV', 'L V', 'L VI', 'L Crus I', 'L Crus II', ...
 'L VIIB', 'L VIIIA', 'L VIIIB', 'L IX', 'L X', 'L CM', 'Vermal III', ...
 'Vermal IV', 'Vermal V', 'Vermal VI', 'Vermal VIIA', 'Vermal VIIB', ...
 'Vermal VIIIA', 'Vermal VIIIB', 'Vermal IX', 'Vermal X', 'R III', 'R IV', ...
 'R V', 'R VI', 'R Crus I', 'R Crus II', 'R VIIB', 'R VIIIA', 'R VIIIB', ...
 'R IX', 'R X', 'R CM'...
 };

% generate PCA dimensionality per ROI
for x = 1:35;
    subplot(6,6,x);
    maximum = max(pca_data(x, :));
    if maximum < 10;
        hist(pca_data(x, :), maximum);
    else;
        hist(pca_data(x, :), 10);
    end;
    set(get(gca,'child'),'FaceColor','black','EdgeColor','black');

    title(labels(x));

end
