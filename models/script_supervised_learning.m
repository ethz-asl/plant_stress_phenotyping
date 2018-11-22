%% Script Supervised Learning
% Use MATLAB supervised learning methods for LOOCV and weighting of used
% indicators.
% TODO: Use these results as baseline
clear; close all; clc;

% Select Data
indicatorIndicesSelection = {[1,55], [1:3, 29,55], [4:28,55], [1:55]};
validationAccsCV = [];
validationAccsTest = [];
for iSelection = 1:size(indicatorIndicesSelection,2)
    
    %% Load indicator data
    scriptMode = 2;         % 1-Test on some values, 2-LOOCV per box, 3 - LOOCV per cause
                            % (Average performance for every cause on single indicator).
    preprocessing = 'T';    % N-normalize with healthy plants, S-Standardscaler, T-add time.
    reduceLabels = false;    % True: merge labels N: High+Med, Weeds: Few,Many,Only
    indicatorIndices = NaN;    % Which indicators (by index) to take into account. Set to NaN for all.
    loadPath = fullfile('results', 'indicatorsAllMeansAndVariances.mat');    % Which indicators to load   %SelectedIndicators
    indNames = {'Canopy Cover', 'Volumetric Estimate', ...
        ' Height', 'MS1', 'MS2', 'MS3', 'MS4', 'MS5', 'MS6', 'MS7', 'MS8', 'MS9', 'MS10', 'MS11', 'MS12', 'MS13', 'MS14', 'MS15', 'MS16', 'MS17', 'MS18', 'MS19', 'MS20','MS21', 'MS22', 'MS23', 'MS24', 'MS25', ' Height Var', 'MS1 Var', 'MS2 Var', 'MS3 Var', 'MS4 Var', 'MS5 Var', 'MS6 Var', 'MS7 Var', 'MS8 Var', 'MS9 Var', 'MS10 Var', 'MS11 Var', 'MS12 Var', 'MS13 Var', 'MS14 Var', 'MS15 Var', 'MS16 Var', 'MS17 Var', 'MS18 Var', 'MS19 Var', 'MS20 Var','MS21 Var', 'MS22 Var', 'MS23 Var', 'MS24 Var', 'MS25 Var', 'DaysAfterSowing' };      % Indicator names [with unit]

    useGroups = false;       % Flags for BDE (clusters same causes) % TODO: something fishy with useGroups=true, gives prediction accuracy of 50% always
    useTime = true;         % Flags for BDE (estimates every measurement independently).
    usePriors = true;       % Flags for BDE (applies filter like state updates, needs useTime=true).

    % Load indicator data
    indicators = load(loadPath);
    indicators = struct2cell(indicators);
    indicatorData = indicators{1};

    % Select indicators
    if ~isnan(indicatorIndices)
        indicatorData.Data = indicatorData.Data(:,:,indicatorIndices);
        indicatorData.IndicatorNames = indicatorData.IndicatorNames(indicatorIndices);
    end
    
    %% Create data selection
    boxLabels = indicatorData.Labels;
    boxIndices = 1:30;
    measurementDateIndices = 2:16;
    indicatorIndices = indicatorIndicesSelection{iSelection};
    nBoxes = size(boxIndices,2);
    nMeasurementDates = size(measurementDateIndices,2);
    nIndicators = size(indicatorIndices,2);

    % Create Input Data
    data = indicatorData.getdata('ST'); % Scales all indicator values, adds the time index and returns a nBoxes x nMeasurementDates x nIndicators cube
    data = data(boxIndices, measurementDateIndices, indicatorIndices);  % Select only required data
    X = reshape(data, [], size(data, 3), 1);
    % Create ground truth labels
    Ytrue = zeros(nBoxes*nMeasurementDates, size(boxLabels,2)+2); % add the boxId to the 4th column and the measurementDateId to the 5th
    for iMeasDate = 1:nMeasurementDates
        % Default
        Ytrue(boxIndices+(iMeasDate-1)*nBoxes,1:3) = boxLabels;
        Ytrue(boxIndices+(iMeasDate-1)*nBoxes,4) = boxIndices;
        Ytrue(boxIndices+(iMeasDate-1)*nBoxes,5) = measurementDateIndices(iMeasDate);
        % No water stress before day 30
        if(indicatorData.daysAfterSowing(measurementDateIndices(iMeasDate)) < 30)
            Ytrue(boxIndices+(iMeasDate-1)*nBoxes, 1) = 1;
        end
        % No plants on day 1 / too many on day 70
        if (measurementDateIndices(iMeasDate) == 1 || measurementDateIndices(iMeasDate) == 16)
            Ytrue(boxIndices+(iMeasDate-1)*nBoxes, 1:3) = nan;
        end
        % No weeds before day 14
        if measurementDateIndices(iMeasDate) == 2
            Ytrue((iMeasDate-1)*nBoxes+[16,17,18], 1:3) = nan;
        end


    end

    Ytrue = categorical(Ytrue);
    % Only Weed Boxes classified as "High" weed pressure
    Ytrue(find(Ytrue(:,3)==categorical(4)),3)=categorical(3);
    % Leave out a few boxes for testing
    testBoxes = [5 10 15 20 25 30];
    trainBoxes = setdiff(1:30, testBoxes);

    % Format Data for Classifiers

    testX = []; %zeros(size(testBoxes,2)*size(indicatorData.daysAfterSowing,2), size(X,2));
    trainX = []; %zeros(size(X,1)-size(testBoxes,2)*size(indicatorData.daysAfterSowing,2), size(X,2));
    testYtrue = [];
    trainYtrue = [];

    for iObs = 1:size(X,1)
        obsBoxNo = mod(iObs,30);
        if obsBoxNo==0
            obsBoxNo = 30;
        end
        if ismember(obsBoxNo, testBoxes)
           testX = [testX;X(iObs,:)];
           testYtrue = [testYtrue;Ytrue(iObs,:)];
        else
            trainX = [trainX;X(iObs,:)];
            trainYtrue = [trainYtrue;Ytrue(iObs,:)];
        end
    end
    YlabelNames = {indicatorData.LabelNames{1:3} 'BoxId' 'MeasDateId'};
    validIndicatorNames = genvarname(indNames(indicatorIndices));
    trainZ = array2table(trainX, 'VariableNames', validIndicatorNames);
    trainW = array2table(trainYtrue, 'VariableNames', YlabelNames);
    trainT = [trainZ trainW];

    % Create test table
    testZ = array2table(testX, 'VariableNames', validIndicatorNames);
    testW = array2table(testYtrue, 'VariableNames', YlabelNames);
    testT = [testZ testW];
    %% Train classifiers
    classifierMethods = {ClassifierMethods.DecisionTrees, ClassifierMethods.LDA, ClassifierMethods.SVM, ClassifierMethods.KNN, ClassifierMethods.BaggedTrees, ClassifierMethods.SubspaceDiscriminant, ClassifierMethods.SubspaceKNN, ClassifierMethods.RUSBoostedTrees};
    classifierMethodsUsed = [3];
    classifierMethods = classifierMethods(classifierMethodsUsed);
    outputClasses = {categorical({'1'; '2'}) categorical({'1'; '2';'3'}) categorical({'1'; '2'; '3'})};
    for iMethod = 1:size(classifierMethods,2)
        [trainedClassifiers{iMethod}, validationAccuracies{iMethod}] = trainSelectedClassifiers(trainT, validIndicatorNames, outputClasses, classifierMethods{iMethod});
    end

    %% Format Validation Accuracies for Output
    prettyVA = [];
    for iMethod = 1:size(classifierMethods,2)
            prettyVA = [prettyVA;cell2mat(validationAccuracies{iMethod})*100];
    end
    prettyVA % Cross Validated Training Accuracies
    %% Get predictions on test set
    prettyTA = [];
    for iMethod = 1:size(classifierMethods,2)
        yfitWater = trainedClassifiers{iMethod}{1}.predictFcn(testT);
        yfitNitrogen = trainedClassifiers{iMethod}{2}.predictFcn(testT);
        yfitWeeds = trainedClassifiers{iMethod}{3}.predictFcn(testT);
        % Get prediction error (testing)
        testYpred = [yfitWater yfitNitrogen yfitWeeds];
        [accWater, accNitrogen, accWeeds] = perCauseAccuracy(testYpred, testYtrue(:,1:3));
        prettyTA = [prettyTA; accWater, accNitrogen, accWeeds];
    end
    prettyTA    % Test Set Accuracies

    %% Visualise prediction errors
    validationAccsCV = [validationAccsCV; prettyTA];
    validationAccsTest = [validationAccsTest; prettyTA];
    
end

%% Plot bar chart of accuracy comparison
xnames = {'Water', 'Nitrogen', 'Weeds'};
y = bar(validationAccsCV');
colorNames = {'RGB Only', 'RGB+3D', 'Hyperspectral Only', 'RGB, 3D and Hyperspectral'};
lgnd = legend(colorNames);
set(lgnd,'color','none');
set(lgnd, 'Box', 'off');
set(gca, 'FontSize', 12);
%set(gca,'XTickLength',[0 0])
xticklabels(xnames)
ylabel('Classifier Accuracy (%)', 'FontSize', 14)
saveaspdf('~/Desktop/feature-comparison-time.pdf')
