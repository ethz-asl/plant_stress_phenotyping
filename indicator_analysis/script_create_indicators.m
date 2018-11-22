%% Script create indicators
% load the saved results (from script_create_measurementpointcloud) and
% build a set of indicators stored as "indicatorData" of type IndicatorData.
% To be run from plant_stress_phenotyping root folder
%% Parameters
resultsName = 'point_cloud_';    % Stored variables are expected as 
                            % "resultsName<dataset no>.mat".
resultsPath = fullfile('results', 'pointclouds');    % Where to find stored data.
indEval = {'Time', 'CanCov', 'VolEst', 'Height', 'MS1', 'MS2', 'MS3', 'MS4', 'MS5', 'MS6', 'MS7', 'MS8', 'MS9', 'MS10', 'MS11', 'MS12', 'MS13', 'MS14', 'MS15', 'MS16', 'MS17', 'MS18', 'MS19', 'MS20','MS21', 'MS22', 'MS23', 'MS24', 'MS25', 'Height', 'MS1', 'MS2', 'MS3', 'MS4', 'MS5', 'MS6', 'MS7', 'MS8', 'MS9', 'MS10', 'MS11', 'MS12', 'MS13', 'MS14', 'MS15', 'MS16', 'MS17', 'MS18', 'MS19', 'MS20','MS21', 'MS22', 'MS23', 'MS24', 'MS25'};  % Which indicators to extract,
            % Supported are Height, NDVI, MS* with *=1:25 being the 
            % multispectral band, EGI (=Excess green index), NEGI
            % (=normalized EGI), CanCov (=canopy cover), VolEst (=volumetric 
            % estimate), NDRI (normalized difference index), ERI (Excess red
            % index).
indStat = {'m', 'm', 'm', 'm', 'm', 'm', 'm', 'm', 'm', 'm', 'm', 'm', 'm', 'm', 'm', 'm', 'm', 'm', 'm', 'm', 'm', 'm', 'm', 'm', 'm', 'm', 'm', 'm',  'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v','v', 'v', 'v', 'v', 'v', 'v', 'v', 'v'};   % Which statistic to evaluate over the pointcloud (Mean, Var, Min, Max)
%indStat = {'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v', 'v','v', 'v', 'v', 'v', 'v', 'v', 'v', 'v'};   % Which statistic to evaluate over the pointcloud (Mean, Var, Min, Max)

assert(all(size(indEval)==size(indStat)), 'Arrays defining indicators and their statistics should be of the same size');
indNames = {'Canopy Cover [%]', 'Volumetric Estimate [m*pixels]', ...
    ' Height [m]', 'MS1', 'MS2', 'MS3', 'MS4', 'MS5', 'MS6', 'MS7', 'MS8', 'MS9', 'MS10', 'MS11', 'MS12', 'MS13', 'MS14', 'MS15', 'MS16', 'MS17', 'MS18', 'MS19', 'MS20','MS21', 'MS22', 'MS23', 'MS24', 'MS25', ' Height Var [m]', 'MS1 Var', 'MS2 Var', 'MS3 Var', 'MS4 Var', 'MS5 Var', 'MS6 Var', 'MS7 Var', 'MS8 Var', 'MS9 Var', 'MS10 Var', 'MS11 Var', 'MS12 Var', 'MS13 Var', 'MS14 Var', 'MS15 Var', 'MS16 Var', 'MS17 Var', 'MS18 Var', 'MS19 Var', 'MS20 Var','MS21 Var', 'MS22 Var', 'MS23 Var', 'MS24 Var', 'MS25 Var' };      % Indicator names [with unit]
assert(all(size(indEval)==size(indNames)), 'Arrays defining indicators and their names should be of the same size');
saveFile = true;                                       % Set true to save the generated indicator data.
saveName = fullfile('results','indicatorsAllMeansAndVariances.mat');            % save directory, including filename.mat
daysAfterSowing = [ 0	12	14	18	21	25	28	32	36	39	43	46	49	53	56	70];

%% Code
% Load data
fprintf(1, 'Loading data ... ');
addpath(fullfile('data_evaluation'));
addpath(fullfile('indicator_analysis'));
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
indicatorData = IndicatorData(dataMat, indNames, timeline);
if saveFile
    fprintf(1, 'Saving-');
    save(saveName, 'indicatorData');
end
fprintf(1, 'done!\n');

