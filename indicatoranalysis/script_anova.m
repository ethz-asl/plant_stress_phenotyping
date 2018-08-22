%% Script ANOVA
% Perform analysis of variance (ANOVA) for different indicators or yields.
% Identify significant differences by using multiple comparison analysis.
%% Parameters
dataPath = fullfile('data','IndicatorsFull.mat'); % Path and name of IndicatorData to load.
processYield = true;    % Evaluate yield instead of indicaotrs. Yield IDs 
                        % are 1-Leaves, 2-Dry Leaves, 3-Beets, 4-Dry Beets.
ID = 1;                 % ID of indicator/yield data to evaluate.
preprocessing = 'N';    % Apply preprocessing (use N for normalizer, S for 
                        % standard scaler) to indicators.
rankAllIndicators = false;   % Set to false to perform standard anova and
                            % display the plots.
                            % Set to true to perform anova ranking of all 
                            % indicators in the loaded indicators. The
                            % ranking value is the difference of class
                            % means diveded by their confidence interval,
                            % averaged for Water: Level 1-2, N: Levels 1-2
                            % and 2-3, Weeds: Levels 1-2 and 2-3 (4 = all
                            % weeds is neglected).
rankingMethod = 1;          % 1- Ranking on all indicators, 2- Only on 
                            % boxes where rest is constant.

%% Code
% Load data
loadData = load(dataPath);
loadData = struct2cell(loadData);
indicator = loadData{1};
[data, groups] = indicator.getdatastring(preprocessing);

% Single Anova
if ~rankAllIndicators
    close all;
    % Process yield or indicator
    if processYield     
         load(fullfile('data','yield.mat'));
         data = reshape(yield(:, ID), 1, []);
         for i=1:3
             temp = groups{i};
             groups{i} = temp(1:30);
         end
    else 
        data = data(ID, :);
    end

    % Anova
    [p, tbl, stats] = anovan(data, groups, 'varnames', ...
        {'Water','Nitrogen','Weeds'}, 'display', 'on');


    % Multiple comparison analysis plots (Find significant groups)
    dims = {1, 2, 3, [1 2], [2 3], [3 1]};
    pos = {[0 1/2], [1/3, 1/2], [2/3, 1/2], [0 0], [1/3, 0], [2/3, 0]};
    titles = {sprintf('Water (overall, p<%0.2f)', p(1)), ...
        sprintf('Nitrogen (overall, p<%0.2f)', p(2)), ...
        sprintf('Weeds (overall, p<%0.2f)', p(3)), ...
        'Water x Nitrogen', 'Nitrogen x Weeds', 'Weeds x Water'};
    yield_names = {'Leaves weight [g]', 'Dry leaves weight [g]', ...
        'Beets weight [g]', 'Dry beets weight [g]'};
    for i =1:6
        figure('units','normalized','outerposition',[pos{i} 1/3 1/2]);
        multcompare(stats, 'Dimension', dims{i});
        if processYield 
            title([yield_names{ID} ': ' titles{i}]);
        else
            title([indicator.IndicatorNames{ID} ': ' titles{i}]);
        end
    end
else
    % Get full ranking for all indicators.
    N = size(data, 1);
    rankingResults = zeros(N,3);
    for i=1:N
        if rankingMethod == 1
            % Perform anova on all datapoints
            [~, ~, stats] = anovan(data(i, :), groups, 'varnames', ...
                {'Water','Nitrogen','Weeds'}, 'display', 'off');
        
            % Evaluate multiple comparison for every cause
            res1 = multcompare(stats, 'Dimension', 1, 'Display', 'off');
            res2 = multcompare(stats, 'Dimension', 2, 'Display', 'off');
            res3 = multcompare(stats, 'Dimension', 3, 'Display', 'off');

            % Evaluate ranking values
            stdev = std(data(i, :));
            rankingResults(i,1) = abs(res1(4))/stdev;
            rankingResults(i,2) = mean(abs(res2(:,4)))/stdev;
            rankingResults(i,3) = mean(abs(res3([1, 2, 4],4)))/stdev;
        else
           	% Perform anova for selected boxes
            indices = false(30, 16, 3);
            indices([4:6 13:15], :, 1) = true;
            indices([1:6 22:24], :, 2) = true;
            indices([1:3 7:12 16:18], :, 3) = true;
            stdev = std(data(i, :));
            
            for j = 1:3 % all causes
                % Select data
                currData = data(i, reshape(indices(:,:,j),1,[]));
                currGroups = groups{j};
                currGroups = {currGroups(reshape(indices(:,:,j),1,[]))};
                
                % Anova and multcompare
                [~, ~, stats] = anovan(currData, currGroups, 'display', 'off');
                res = multcompare(stats, 'Display', 'off');
                
                % Evaluate Ranking (Exclude weed only boxes)
                if j~= 3
                    rankingResults(i,j) = mean(abs(res(:,4)))/stdev;
                else
                    rankingResults(i,j) = mean(abs(res([1, 2, 4],4)))/stdev;
                end
            end
        end        
    end
    
    % Display results
    figure;
    subplot(3,1,1);
    [Res, rankingWater] =sort(rankingResults(:,1), 1, 'descend');
    bar(Res, 'FaceColor', [0.2 0.6 .8]);
    set(gca,'Xtick',1:N)
    xticklabels(indicator.IndicatorNames(rankingWater));
    title('Indicator ranking for water');
    
    subplot(3,1,2);
    [Res, rankingNitrogen] =sort(rankingResults(:,2), 1, 'descend');
    bar(Res, 'FaceColor', [0 0.7 0.4]);
    set(gca,'Xtick',1:N)
    xticklabels(indicator.IndicatorNames(rankingNitrogen));
    title('Indicator ranking for nitrogen');
    
    subplot(3,1,3);
    [Res, rankingWeeds] =sort(rankingResults(:,3), 1, 'descend');
    bar(Res, 'FaceColor', [1 0.5 0]);
    set(gca,'Xtick',1:N)
    xticklabels(indicator.IndicatorNames(rankingWeeds));
    title('Indicator ranking for weeds');
    
end