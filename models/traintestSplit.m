function [trainX, trainY, testX, testY, trainT, testT] = traintestSplit(X,Y, testFraction, variableNames, labelNames)
%testSplit splits data into training and testing sets given a test fraction
%   X : nObs x nFeatures double matrix
%   Y : nObs x m categorical matrix
%   testFraction : double fraction of observations in test data
%   variableNames : 1 X nFeatures cell array of valid feature/ indicator names
%   labelNames : 1 X m cell array of valid target stress factor names

testX = [];
trainX = [];
trainY = [];
testY = [];
nObs = size(X,1);
testObs = randperm(nObs, round(testFraction*nObs));
trainObs = setdiff(1:nObs, testObs);
trainX = X(trainObs, :);
testX = X(testObs, :);
trainY = Y(trainObs, :);
testY = Y(testObs, :);
        
variableNames = genvarname(variableNames);
trainZ = array2table(trainX, 'VariableNames', variableNames);
trainW = array2table(trainY, 'VariableNames', labelNames);
trainT = [trainZ trainW];

% Create test table
testZ = array2table(testX, 'VariableNames', variableNames);
testW = array2table(testY, 'VariableNames', labelNames);
testT = [testZ testW];

end

