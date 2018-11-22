function [Xout, Yout] = removeMissingEntries(X, Ytrue)
%removeMissingEntries Removes observations (rows) with missing or undefined
%entries from the input and output vectors to prepare clean training
%datasets
%   X : nObs x nFeatures matrix
%   Ytrue : nObs x * categorical array
[definedRows, ~] = find(isundefined(Ytrue)~=1);
definedRows = unique(definedRows);
Xout = X(definedRows,:);
Yout = Ytrue(definedRows,:);


end

