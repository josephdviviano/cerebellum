function writesurface(data, surfacetemplate);
    disp('I dont do anything yet')
end


% l = thresholded_l_func_noreg;
% oname = 'cluster_k4_func_noreg_thresh'
% l = thresholded_l_func_reg;
% oname = 'cluster_k4_func_reg_thresh'
% l = thresholded_l_struct_noreg;
% % oname = 'cluster_k4_struct_noreg_thresh'
% l = fthresholded_l_struct_reg;
% oname = 'cluster_k4_struct_reg_thresh'

l = thresholded_conjunction;
oname = 'cluster_k4_conjunction_reg_thresh'


%% Write out Surface map
fname = fopen(['atlas_civ.L.1D'],'rt');
fdata = textscan(fname, '%f%f%f%f%f%f%f', ...
                        'Whitespace', ' ', ...
                        'MultipleDelimsAsOne', 1, ...
                        'HeaderLines', 5);
fdata{7} = l(1:40962);

fout = fopen([oname '_civ.L.1D'],'w');
for iii=1:length(fdata)-1;
    maxNRows = max([length(fdata{iii}) length(fdata{iii+1})]);
end
for ii=1:maxNRows,  %% 1 -> 324912 rows
    for i=1:length(fdata), %% 1 -> 7 columns
        try 
            %if iscell(fdata{i}),
            %    fprintf(fout,'%s ',cell2mat(fdata{i}(ii)));
            %else
            if i == 1;
                fprintf(fout,'         %u',fdata{i}(ii));
            end
            if i == 2;
                fprintf(fout,'   %u',fdata{i}(ii));
            end
            if i == 3;
                fprintf(fout,'   %u',fdata{i}(ii));
            end
            if i == 4;
                fprintf(fout,'  %u',fdata{i}(ii));
            end
            if i == 5;
                fprintf(fout,'  %u',fdata{i}(ii));
            end
            if i == 6;
                fprintf(fout,'       %u',fdata{i}(ii));
            end
            if i == 7;
                fprintf(fout,'       %f',fdata{i}(ii));
            end
            %end
        catch ME
            fprintf(fout,' ');
        end
    end
    fprintf(fout,'\n');
end
fclose(fout);
fclose(fname);

fname = fopen(['atlas_civ.R.1D'],'rt');
fdata = textscan(fname, '%f%f%f%f%f%f%f', ...
                        'Whitespace', ' ', ...
                        'MultipleDelimsAsOne', 1, ...
                        'HeaderLines', 5);
fdata{7} = l(40963:end);

fout = fopen([oname '_civ.R.1D'],'w');
for iii=1:length(fdata)-1;
    maxNRows = max([length(fdata{iii}) length(fdata{iii+1})]);
end
for ii=1:maxNRows,  %% 1 -> 324912 rows
    for i=1:length(fdata), %% 1 -> 7 columns
        try 
            %if iscell(fdata{i}),
            %    fprintf(fout,'%s ',cell2mat(fdata{i}(ii)));
            %else
            if i == 1;
                fprintf(fout,'         %u',fdata{i}(ii));
            end
            if i == 2;
                fprintf(fout,'   %u',fdata{i}(ii));
            end
            if i == 3;
                fprintf(fout,'   %u',fdata{i}(ii));
            end
            if i == 4;
                fprintf(fout,'  %u',fdata{i}(ii));
            end
            if i == 5;
                fprintf(fout,'  %u',fdata{i}(ii));
            end
            if i == 6;
                fprintf(fout,'       %u',fdata{i}(ii));
            end
            if i == 7;
                fprintf(fout,'       %f',fdata{i}(ii));
            end
            %end
        catch ME
            fprintf(fout,' ');
        end
    end
    fprintf(fout,'\n');
end
fclose(fout);
fclose(fname);










% save('cluster_analysis.mat', '-v7.3')

% distances = zeros(24, 1);
% count = 1;
% for l = perm_l_struct_noreg';
%     distances(count) = pdist([perm_l_func_noreg, l]','hamming');
%     count = count+1;
% end

% % find the closest label set
% idx = find(distances == min(distances));
    
% % if we get more than one minimum, take the first one.
% if length(idx) > 1;
%     idx = idx(1);
% end



thresholded_conjunction = zeros(length(thresholded_l_func_reg), 1);
%% idx wise conjunction analysis
for ind = 1:4;
	idxa = find(thresholded_l_func_reg == ind);
	idxb = find(thresholded_l_struct_reg == ind);
	idxc = intersect(idxa, idxb);
    
    disp(length(idxc))

    thresholded_conjunction(idxc) = ind;

end