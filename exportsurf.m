
function export_surf(output, filetype);

%% CIVET
if filetype == 'civ';
    for o = 1:35;

        %% Write out Surface map
        fname = fopen(['atlas_civ.L.1D'],'rt');
        fdata = textscan(fname, '%f%f%f%f%f%f%f', ...
                                'Whitespace', ' ', ...
                                'MultipleDelimsAsOne', 1, ...
                                'HeaderLines', 5);
        fdata{7} = output(o, 1:40962);

        fout = fopen(['conn_' int2str(o) '_civ.L.1D'],'w');
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
        fdata{7} = output(o, 40963:end);

        fout = fopen(['conn_' int2str(o) '_civ.R.1D'],'w');
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
    end % for 0 = 1:35


%% FREESURFER
elseif filetype == 'fs';
    for o = 1:35;

        %% Write out Surface map
        fname = fopen(['atlas_fs.L.1D'],'rt');
        fdata = textscan(fname, '%f%f%f%f%f%f%f', ...
                                'Whitespace', ' ', ...
                                'MultipleDelimsAsOne', 1, ...
                                'HeaderLines', 5);
        fdata{7} = output(o, 1:32492);

        fout = fopen(['conn_' int2str(o) '_fs.L.1D'],'w');
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

        fname = fopen(['atlas_fs.R.1D'],'rt');
        fdata = textscan(fname, '%f%f%f%f%f%f%f', ...
                                'Whitespace', ' ', ...
                                'MultipleDelimsAsOne', 1, ...
                                'HeaderLines', 5);
        fdata{7} = output(o, 32493:end);

        fout = fopen(['conn_' int2str(o) '_fs.R.1D'],'w');
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
    end % for 0 = 1:35

else;
    disp('Valid filetypes: `civ` or `fs`')

end