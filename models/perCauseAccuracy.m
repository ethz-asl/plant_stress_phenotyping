function [accuracyWater,accuracyNitrogen, accuracyWeeds] = perCauseAccuracy(Ypred, Ytrue)
%perCauseAccuracy Returns the % accuracy of the given predictions and
%ground truth for each stress factor, ignores observation rows with Nan values
%   Ypred : nObs x 3 categorical array
%   Ytrue : nObs x 3 categorical array
% TODO: ignore only individual NaN entries instead of entire rows, perhaps
% by using 3 separate vectors
[definedRows, ~] = find(isundefined(Ytrue)~=1);
definedRows = unique(definedRows);
Ypred = Ypred(definedRows,:);
Ytrue = categorical(Ytrue(definedRows,:));
accuracy = Ypred == Ytrue;
accuracyWater = mean(accuracy(:,1))*100;
accuracyNitrogen = mean(accuracy(:,2))*100;
accuracyWeeds = mean(accuracy(:,3))*100;

end

