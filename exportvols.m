% create subject-wise & run-wise correlation matricies for cerebellum data 

runcount = 1;

for s = 1:length(subj);

    figure;

    for runs = 1:4;

        f = subj{s};

        subplot(2,2, runs);
        imagesc(cmat(:,:, runcount), [-2, 2]);
        colormap(redblue);

        if runs == 4;
            suptitle(f);
        end

        runcount = runcount + 1;
    end

    saveas( gcf, [f '.jpg']);
    clf;

end
