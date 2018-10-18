%% Visualize Indicators 
% Load an instance of IndicatorData in order to visualize interesting
% slices of stored data.
close all

%% Parameters
dataPath = fullfile('results','indicatorsAllMeans.mat');  % Path and name of indicator file to load.
displayIndicatorNames = true;   % Display which indicators are available in the laoded data.
preprocessing = '';                 % '' for none, 'S' or 'N' for standardscaler/normalization
presetID = 3;                   % which Presets to show (supports multiple).
indicatorID = 3;            % which indicators to show (supports multiple).
average = true;                 % True: plot mean + stdev, false: plot boxes.
displayPreset = true;           % Keep set to true, false to play around with plotindicator function.
daysAfterSowing = [ 0	12	14	18	21	25	28	32	36	39	43	46	49	53	56	70];
%% Available Indicators (8):
% 1: Canopy Cover [%]
% 2: Volumetric Estimate [m*pixels]
% 3: Average Height [m]
% 4: Average NDVI [-]
% 5: Excess Green Index [-]
% 6: ERI
% 7: NDRI
% 8: MSDiff23_5
%% Presets
% Create preset parameters and sets of preset plots.
% No Context    BoxNos
% 1 water const 4,13
% 2 water const 22,28
% 3 water const both
% 4 N const     1,4,22
% 5 N const     7,25
% 6 N const both
% 7 Weeds const   1,7,10,16
% 8 Weeds const   22, 25 
% 9 Weeds const both
%10 Boxes for paper plots % 1-3 control, 22-24 N, 13-15 Water, 10-12 Weeds

% boxes
boxSelection  = false(30,10);
boxSelection([4:6 13:15],1) = true;
boxSelection([22:24 28:30],2) = true;
boxSelection(:,3) = boxSelection(:,1) | boxSelection(:,2);
boxSelection([1:6 22:24],4) = true;false
boxSelection([7:9 25:27],5) = true;
boxSelection(:,6) = boxSelection(:,4) | boxSelection(:,5);
boxSelection([1:3 7:12 16:18], 7) = true;
boxSelection(22:27,8) = true;
boxSelection(:,9) = boxSelection(:,7) | boxSelection(:,8);
boxSelection([1:3 10:12 13:15 22:24], 10) = true;

%% Load Data
import = load(dataPath);            % Load file
import = struct2cell(import);       % make import data indexable
data = import{1};                   % load first element as data
X = data.getdata(preprocessing);                      % parse to script variables
Y = data.Labels;
indicatorNames = data.IndicatorNames;

if(displayIndicatorNames)
    disp(['Available Indicators (' num2str(length(indicatorNames)) '):']);
    for i = 1:length(indicatorNames)
        disp([num2str(i) ': ' indicatorNames{i}]);
    end
end

%% remove first and last dates from the plots
X = X(:,3:15,:);
daysAfterSowing = daysAfterSowing(3:15);
%% display some preset
if(displayPreset)
    for i = presetID
        color = ceil(i / 3);
        color = 1;
        for j = indicatorID
            data = X(boxSelection(:,i),:,j);
            truth = Y(boxSelection(:,i),:);
            plotindicators(data, truth, 'yLabel', indicatorNames{j}, ...
                'average', average, 'coloring', color, 'timeline', daysAfterSowing);
        end
    end
end

%% Use displaydata-function (play around here)
%   [~] = displaydata(data, groundTruth, varargin)
%   data:           input slice, dim= BoxNo x datasetNo
%   groundTruth:    labels of Datasets for slicing, dim= Causes x BoxNo
%   Name-Value Pairs:
%   figTitle:       Plot title. Use 'auto' to inherit from yLabel.
%   yLabel:         Label of Y axis.
%   average:        Set to true to plot average + uncertainty, false for
%                   single boxes. Default = false.
%   showLegend:     Bool-array (1x1 or 1x3), wether to label causes. 
%                   (1-Water, 2-Nitrogen, 3-Weeds). Default = all true.
%   legendText:     'short' or 'long' for for label descriptiveness.
%                   Default = 'short'.
%   coloring:       0: standard colors, 1, 2 or 3: color w.r.t. 
%                   Water/N/Weeds. Default = 0.

if(~displayPreset)
    for indicatorID = [13 16]
        indices = [1:3 10:12 13:15 22:24]; %1:30;
        data = X(indices,:,indicatorID);
        truth = Y(indices,:);
        plotindicators(data, truth, 'yLabel', indicatorNames{indicatorID}, ...
            'average', true, 'coloring', 0, 'showLegend', [true true true], ...
            'legendText', 'long', 'timeline', daysAfterSowing);
    end
end
