%% regressions between modalities 

labels = {...
 'Vermal I II', 'L III', 'L IV', 'L V', 'L VI', 'L Crus I', 'L Crus II', ...
 'L VIIB', 'L VIIIA', 'L VIIIB', 'L IX', 'L X', 'L CM', 'Vermal III', ...
 'Vermal IV', 'Vermal V', 'Vermal VI', 'Vermal VIIA', 'Vermal VIIB', ...
 'Vermal VIIIA', 'Vermal VIIIB', 'Vermal IX', 'Vermal X', 'R III', 'R IV', ...
 'R V', 'R VI', 'R Crus I', 'R Crus II', 'R VIIB', 'R VIIIA', 'R VIIIB', ...
 'R IX', 'R X', 'R CM'...
 };

func_compcor = load('compcor_func-volu-grey_vertex_CV_proc.mat', 'r_func');
func_compcor = func_compcor.r_func;
func_anatcor = load('anaticor_func-volu-grey_vertex_CV_proc.mat', 'r_func');
func_anatcor = func_anatcor.r_func;
anat_thick = load('anaticor_func-volu-grey_vertex_CV_proc_ctxthick-native.mat', 'g_volu');
anat_thick = anat_thick.g_volu;
anat_volu = load('anaticor_func-volu-grey_vertex_CV_proc.mat', 'g_volu');
anat_volu = anat_volu.g_volu;
anat_t1 = load('anaticor_func-volu-grey_vertex_CV_proc.mat', 'g_grey');
anat_t1 = anat_t1.g_grey;

dims = size(func_compcor);
n_roi = dims(1);

test1 = func_compcor;
test2 = func_anaticor;

test1 = func_compcor;
test2 = anat_thick;

test1 = func_compcor;
test2 = anat_volu;

test1 = func_compcor;
test2 = anat_t1;

test1 = anat_volu;
test2 = anat_thick;

test1 = anat_volu;
test2 = anat_t1;

test1 = anat_thick;
test2 = anat_t1;

%% IN funcstruct_scatter!
%%
% for roi = 1:35;

%     x = test1(roi, :);
%     y = test2(roi, :);

% 	% linear regression
% 	df = length(x) - 2;
% 	[r, slope, intercept] = regression(x,y);

%     t = r*sqrt(df) / sqrt(1-r^2);
% 	%t = sqrt((length(x)-2) * rsq) / sqrt(1 - rsq);
% 	p = 1-tcdf(abs(t), df);
% 	subplot(6,6,roi);

% 	% scatterplot
% 	scatter(x, y, [], 'red'); 
% 	h = lsline;
% 	set(h(1),'color','black');
% 	title([labels{roi} ' p = ' num2str(p) ' r^2 = ' num2str(rsq)]);

% end

%% correlations between modalities
n_sub = 75;
p_sig = 0.05/10;
%df = length(func_compcor(roi, :)) - 2;
df = nsub - 2;

for roi = 1:35;


    data = [func_compcor(roi, :)', ...
            func_anatcor(roi, :)', ...
            anat_volu(roi, :)', ...
            anat_thick(roi, :)', ...
            anat_t1(roi, :)'];
    data = corr(data);

    t = data ./ sqrt((1-data.^2) ./ df);
    p = 2 * tcdf(-abs(t), df);

    data(p > p_sig) = 0;

	subplot(6,6,roi);
	imagesc(data, [-1 1]);
	set(gca, 'YTick', [1:5]);
	set(gca, 'YTickLabel', {'f_ccor', 'f_acor', 'a_vol', 'a_th', 'a_t1'});
	set(gca, 'XTick', [1:5]);
	set(gca, 'XTickLabel', {'fc', 'fa', 'av', 'at', 'at1'});
	colormap(redblue)
    title([labels{roi}]);
end

subplot(6,6,36);
imshow([0], [-1,1]);
colormap(redblue);
colorbar();

%% hemispheric differences
labels = {'III', 'IV', 'V', 'VI', 'CrusI', 'CrusII', ...
          'VIIB', 'VIIIB', 'VIIIA','IX', 'X'}

count = 1;
for roi = 2:12;
    d1 = [func_compcor(roi, :)', ...
          func_anatcor(roi, :)', ...
          anat_volu(roi, :)', ...
          anat_thick(roi, :)', ...
          anat_t1(roi, :)'];

    d2 = [func_compcor(roi+22, :)', ...
          func_anatcor(roi+22, :)', ...
          anat_volu(roi+22, :)', ...
          anat_thick(roi+22, :)', ...
          anat_t1(roi+22, :)'];

    plot_difference(d1,d2,2,6,count);
    title(labels{count});
    count = count + 1;
end
