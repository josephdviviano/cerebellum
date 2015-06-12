%% MATLAB FOR GENEZ: YOURE GOING TO LOVE IT! %%
% data from http://human.brain-map.org/static/download

%
% demographics table
% sex[m=1], age[years], post-mortem[hours]
%
demographics = [1,24,23;
                1,39,10;
                1,57,25.5;
                1,31,17.5;
                2,49,30;
                1,55,18]

%
% housekeeping genes from http://www.tau.ac.il/~elieis/HKG/
% Human housekeeping genes revisited
% E. Eisenberg and E.Y. Levanon, Trends in Genetics, 29 (2013)
%

f = fopen('HK_genes.txt');
C = textscan(f, '%s %s');
housekeeper_name = C{1};
housekeeper_symbol = C{2};

% loop through subjects to load in the data
for subj = [1002, 1287, 1438, 1549, 1569, 9861];
	
	% read in the expression values, calls
	samp = dlmread([int2str(subj) '/MicroarrayExpression.csv'], ',', 0, 1);
	samp_std = std(samp,0,2);

    % call stats (number of successful probes)
	call = dlmread([int2str(subj) '/PACall.csv'], ',', 0, 1);
	call_sum = sum(call, 2);

	% read in the expression labels
	[status, result] = system( ['cat ' int2str(subj) '/MicroarrayExpression.csv | wc -l'] );
	numlines = str2num(result);
	labels = csvread([int2str(subj) '/MicroarrayExpression.csv', 0, 0, [0 0 numlines-1 0]]);

	% read in the probearinos
	f = fopen([int2str(subj) '/Probes.csv'])
	C = textscan(f, '%f %q %f %q %q %f %s', ...
	                'delimiter',',', ...
	                'MultipleDelimsAsOne', 1, ...
	                'headerLines', 1, ...
	                'EmptyValue',NaN, ...
	                'EndOfLine', '\n')
	fclose(f)
	
    % Load each cell into its own array
	probe_id = C{1};
	probe_name = C{2};
	gene_id = C{3};
	gene_symbol = C{4};
	gene_name = C{5};
	entrez_id = C{6};
	chromosome = C{7};

    % extract the non-refseq genes
    idx = zeros(numlines,1);

    % filter out the uninteresting genes
    for x = 1:numlines;
        
        % filter RefSeq genes
    	test = findstr('non-RefSeq', gene_name{x});
    	
    	if isempty(test) == 1;
    		idx(x) = 1;
    	end
        
        % filter housekeeping genes
    	for y = 1:length(housekeeper_symbol);
            
            test = findstr(housekeeper_name{y}, gene_name{x});
            
            if isempty(test) == 0;
                idx(x) = 0;
            end
        end
        
        % filter genes with no entrez id
        if entrez_id(x) == 0;
        	idx(x) = 0;
        end

        % filter genes that we didn't sample
        if call_sum(x) == 0;
        	idx(x) = 0;
        end
        
        % collapse genes if required -- take the 'most matched one'
        % NB: how to verify that it matches the 'whole exonic region?'
        test = find(gene_id == gene_id(x));
        if length(test) > 1;
        	
        	% if we only get a single most matched probe
        	if length(max(call_sum(test))) == 1;
        	
        		% take the most-matched probe
        	    if call_sum(x) ~= max(call_sum(test));
        		    idx(x) = 0;
        		end
        	
        	% if we get more than one most-matched probe
        	else
        	
        		% take the probe with highest SD
        		test_std = find(max(call_sum(test)));
        		if samp_std(x) ~= max(samp_std(test(test_std)));
	                idx(x) = 0;
	            end
        	end
        end
    end
    %% append to some sort of experiment wide megathing
    str = ['subject ' int2str(subj) ': survived, ' int2str(sum(idx)) '\n'];
    fprintf(str)
end
    

%% build an index of all the interesting genes

labels = labels(idx);

%% http://www.mathworks.com/help/stats/regress.html

regressors = ones(6,1); % constant term
%% now run our regression of these surviving genes
% regress average intensity, sex, age, interval

for gene in 1:length(labels);
    b = regress(array(gene, :), regressors);


% create co-expression data table
data = zeros(length(unique(gene_id)), length(array));

% test -- take average value within each probe
counter = 1;
for id = probe_id';
    idx_probe = find(labels == id);
    data(counter, :) = mean(array(:, idx_probe), 2);
    counter = counter + 1;
end;

% create correlation matrix
data = corr(data');
