function [starred_labels] = star_labels(labels, sig);
    count = 1;
    starred_labels = labels;
    for test = sig;
        if test == 1;
            starred_labels{count} = [labels{count} '*'];
        end
        count = count + 1;
    end
end
