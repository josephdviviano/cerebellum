function vals_to_nifti(file, idx, rois, outname)
	% Takes an input mask, a set of new values (one for each unique value in
	% the mask) and an output file name. Returns an output mask file with the
	% new labels assigned, for doing things like visualizing cluster outputs.
	%
	% If rois is supplied, we match to that label list instead of computing it
	% directly from the data.
	%
	file = load_nii(file);
	output = file;
	dims = size(file.img);
    file = reshape(file.img, [dims(1)*dims(2)*dims(3), 1]);

    if isempty(rois) == 1;
        rois = unique(file(file > 0));
    end

    output.img = zeros(dims(1)*dims(2)*dims(3), 1);

    % loop through ROIs, assigning cluster value
    count = 1;
    for roi = rois';
        idxroi = find(file == roi);
        output.img(idxroi) = idx(count);
        count = count+1;
    end

    output.img = reshape(output.img, [dims(1), dims(2), dims(3)]);
    save_nii(output, outname)
end
