function plotindicators(data, groundTruth, varargin)
% PLOTINDICATORS Create a figure of the desired slice of input datacube.
% Always 3 following entries of data correspond to boxes of same treatment.
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

% Input parsing
p = inputParser;
   addRequired(p, 'data');
   addRequired(p, 'groundTruth');
   addParameter(p,'figTitle', 'auto');
   addParameter(p, 'yLabel', 'Value');
   addParameter(p, 'average', true);
   addParameter(p, 'showLegend', true);
   addParameter(p, 'legendText', 'short');
   addParameter(p, 'coloring', 0);
   addParameter(p, 'timeline', 0);
   parse(p, data, groundTruth, varargin{:});

if (length(p.Results.showLegend) == 1)
    showLegend = repmat(p.Results.showLegend, 3, 1);
else
    showLegend = p.Results.showLegend;
end
if(strcmpi(p.Results.figTitle, 'auto') && ~strcmp(p.Results.yLabel,'Value'))
    figTitle = p.Results.yLabel(1:min(regexpi(p.Results.yLabel,' [')));
else
    figTitle = p.Results.figTitle;
end
if (p.Results.timeline == 0)
    timeline = 1:16;
else
    timeline = p.Results.timeline;
end

%Default colors % Control Weed Stress Water Stress Nitrogen Stress
defaultColors = {[0 0 0], [0 1 0], [0 0 1], [1 0 0], [0 0.8 0], ...
    [0 1 0.8], [0 0.6 1], [0 0.2 0.8], [0.5 0 1], [0.8 0 0.8]};

% Presets
colors = {[1 0 0], [1 0.4 0], [1 0.9 0], [0.8 1 0 ], [0 0.8 0], ...
    [0 1 0.8], [0 0.6 1], [0 0.2 0.8], [0.5 0 1], [0.8 0 0.8]};
colorsCause = {[0 0 0.8], [0.2 0.6 1],'' ,'' ; ...
    [0.6 0.8 0.4], [0 0.7 0.4], [0 0.4 0], ''; ...
    [1 .8 0], [1 0.5 0], [1 0 0], [0.8 0 0.8]};
lineStyles = {'-', '--', ':', '-.', '-' , '-', '-'};
lineMarkers = {'none', 'none', 'none', 'none', 'x', 'o', '^'};
causeLabelsWa = {'Suff. Water', 'Low Water'}; 
if (strcmpi(p.Results.legendText, 'short'))     
    causeLabelsN = {'Low N', 'Med N', 'High N'};                  % short labels
    causeLabelsWe = {'No Weeds', 'Few Weeds', 'Many Weeds', 'Only Weeds'};
else        
    causeLabelsN = {'Low N', 'Medium N', 'High N'};     % long labels
    causeLabelsWe = {'No Weeds', 'Few Weeds', 'Many Weeds', 'Only Weeds'};
end

% Data Processing
if(p.Results.average)
    Z = zeros(size(data));
    for i=0:3:size(data, 1)-1
        Z(i+1,:) = mean(data(i+1:i+3,:));
        Z(i+2,:) = mean(data(i+1:i+3,:))+var(data(i+1:i+3,:)).^0.5;
        Z(i+3,:) = mean(data(i+1:i+3,:))-var(data(i+1:i+3,:)).^0.5;
    end
    data = Z;
end

% Create Plot
data = data';
figure;
legendHandle = [];
lineStyleCounter = zeros(4,1);
for i=0:size(data, 2)/3-1
    if (p.Results.coloring == 0)
        useColor = defaultColors{i+1};
        useLine = '-';
        useMarker = 'none';
    else
        useColor = colorsCause{p.Results.coloring, groundTruth(i*3+1, ...
            p.Results.coloring)};
        lineStyleCounter(groundTruth(i*3+1, p.Results.coloring)) = ...
            lineStyleCounter(groundTruth(i*3+1, p.Results.coloring)) + 1;
        useLine = lineStyles{lineStyleCounter(groundTruth(i*3+1, ...
            p.Results.coloring))};
        useMarker = lineMarkers{lineStyleCounter(groundTruth(i*3+1, ...
            p.Results.coloring))};
    end
    h = plot(timeline,data(:, i*3+1),'linewidth',1.5, 'color', useColor, ...
        'linestyle', useLine, 'marker', useMarker); hold on;
    legendHandle = [legendHandle h];
    if(p.Results.average)
        for j = 1:length(timeline)-1
            fill([timeline(j) timeline(j) timeline(j+1) timeline(j+1)], [data(j, i*3+2) data(j, i*3+3) ...
                data(j+1, i*3+3) data(j+1, i*3+2)], useColor, ...
                'linestyle', 'none');
            alpha(0.15);
        end
    else
        plot(timeline,data(:, i*3+2),'linewidth',1.5, 'color', useColor, ...
            'linestyle', useLine, 'marker', useMarker);
        plot(timeline,data(:, i*3+3),'linewidth',1.5, 'color', useColor, ...
            'linestyle', useLine, 'marker', useMarker);
    end
end

% Format plot
if(~(strcmpi(figTitle, 'auto') || isempty(figTitle)))
    title(figTitle);
end
xlabel('Days after sowing', 'FontSize', 16);
ylabel(p.Results.yLabel, 'FontSize', 16);
xlim([min(timeline) max(timeline)]);
xticks(timeline);
xt = get(gca, 'XTick');
set(gca, 'FontSize', 12);

% Create Legend
if (any(showLegend))
    legendText = cell(size(data, 2)/3, 1);
    for i=1:size(data, 2)/3
        if (showLegend(1))
            legendText{i} = causeLabelsWa{groundTruth(i*3, 1)};
            if (any(showLegend(2:3)))
                legendText{i} = [legendText{i} ', '];
            end
        end
        if (showLegend(2))
            legendText{i} = [legendText{i} causeLabelsN{groundTruth(i*3, 2)}];
            if (showLegend(3))
                legendText{i} = [legendText{i} ', '];
            end
        end
        if (showLegend(3))
            legendText{i} = [legendText{i} causeLabelsWe{groundTruth(i*3, 3)}];
        end
    end
    legend(legendHandle, legendText, 'Location', 'northwest');
end
end
