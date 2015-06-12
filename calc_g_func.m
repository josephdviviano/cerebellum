function [g_func_ctx] = calc_g_func_ctx(data, n);

    dims = size(data);
	data = reshape(data, dims(1)/n, n, dims(2));
	data = permute(data, [1,3,2]);

	dims = size(data);
	output = zeros(dims(2), dims(2), dims(3));

	for s = 1:300;
		d = data(:, :, s);
		d = corr(d);
		d = r_2_z(d);
		output(:,:, s) = d;
	end

	g_func_ctx = mean(output, 3);
	g_func_ctx = z_2_r(g_func_ctx);

	g_func_ctx(logical(eye(size(g_func_ctx)))) = 1;


end