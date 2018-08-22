%% Script create indicators
% load the saved results (from script_create_measurementpointcloud) and
% build a set of indicators stored as "indicatorData" of type IndicatorData. 

%% Parameters
resultsName = 'point_cloud_';    % Stored variables are expected as 
                            % "resultsName<dataset no>.mat".
resultsPath = fullfile('..', 'results', 'pointclouds');    % Where to find stored data.
indEval = {'CanCov', 'VolEst', 'Height', 'NDVI', 'EGI', 'ERI', 'NDRI', 'MSDiff23_5'};  % Which indicators to extract,
            % Supported are Height, NDVI, MS* with *=1:25 being the 
            % multispectral band, EGI (=Excess green index), NEGI
            % (=normalized EGI), CanCov (=canopy cover), VolEst (=volumetric 
            % estimate), NDRI (normalized difference index), ERI (Excess red
            % index).
indStat = {'m', 'm', 'm', 'm', 'm', 'm', 'm', 'm'};   % Which statistic to evaluate over the pointcloud (Mean, Var, Min, Max)
assert(all(size(indEval)==size(indStat)), 'Arrays defining indicators and their statistics should be of the same size');
indNames = {'Canopy Cover [%]', 'Volumetric Estimate [m*pixels]', ...
    'Average Height [m]', 'Average NDVI [-]', 'Excess Green Index [-]', 'ERI', 'NDRI', 'MSDiff23_5'};      % Indicator names [with unit]
assert(all(size(indEval)==size(indNames)), 'Arrays defining indicators and their names should be of the same size');
saveFile = false;                                       % Set true to save the generated indicator data.
saveName = fullfile('..','results','testIndicators.mat');            % save directory, including filename.mat

%% Code
% Load data
fprintf(1, 'Loading data ... ');
addpath(fullfile('..', 'data_evaluation'));
ResultsFull = cell(16, 30);
for i = 1:16    % datasets
    loadData = load(fullfile(resultsPath, [resultsName num2str(i) '.mat']));
    loadData = struct2cell(loadData);
    loadData = loadData{1};
    for j=1:30  % boxes
        ResultsFull{i, j} = loadData{j};
    end
end

% Evaluate indicators
dataMat = zeros(30, 16, length(indEval));
fprintf(1, 'done!\nProcessing indicators: ');
for k = 1:length(indEval)   % indicators
    fprintf(1, [num2str(k) '-']);
    for i = 1:30    % boxes
        for j = 1:16    % datasets
            dataMat(i, j, k) = ResultsFull{j, i}.evaluateindicator(...
                indEval{k}, indStat{k});            
        end
    end
end

% Build IndicatorData and save
indicatorData = IndicatorData(dataMat, indNames);
if saveFile
    fprintf(1, 'Saving-');
    save(saveName, 'indicatorData');
end
fprintf(1, 'done!\n');

