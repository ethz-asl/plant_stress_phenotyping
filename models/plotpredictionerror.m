function errors = plotpredictionerror(Ypred, Ytrue, showPlot)
%PLOTPREDICTIONERROR Display the correctness of prediction distributed over
%the different dimensions (such as treatment, time and cause) of the data.
%   Read as: Given <groundtruth in dimension of plot equals X-axis value>, 
%   how often were the matching data predicted correctly.
%   [errors] = validateprediction(Ypred, Ytrue, showPlot) or
%   [~] = validateprediction(errorsIn)
%   errors:     Cell with errors for {boxes, water, N, weeds, dataset}
%   Ypred:      Cause predictions, size (Datasets*Boxes) x Causes
%   Ytrue:      Groundtruth, same size as Ypred
%   showPlot:   Display the error plot (default: true);
%   errorsIn:   Hand in an errors-Cell to plot instead of data.
Ypred = double(Ypred);
Ytrue = double(Ytrue);
if(nargin >= 2)
    nObs = size(Ytrue,1);
    daysAfterSowing = [12 14	18	21	25	28	32	36	39	43	46	49	53	56]; % N_datasets representing number of measurement dates
    nBoxes = nObs/size(daysAfterSowing,2);
    
    % Ypred in for evaluation, compute errors
    Yerr = Ypred == Ytrue;
    % Boxes
    errBox = zeros(nBoxes,1);
    for i=1:nBoxes
        errBox(i) = sum(sum(Yerr(i:nBoxes:nObs,:)))/numel(Yerr(i:nBoxes:nObs,:));
    end
    % Water
    errWater = zeros(2,1);
    for i=1:2
        errWater(i) = sum(Yerr(Ytrue(:,1)==i,1))/numel(Yerr(Ytrue(:,1)==i,1));
    end
    % Nitrogen
    errN = zeros(3,1);
    for i=1:3
        errN(i) = sum(Yerr(Ytrue(:,2)==i,2))/numel(Yerr(Ytrue(:,2)==i,2));
    end
    % Weeds
    errWeeds = zeros(4,1);
    for i=1:4
        errWeeds(i) = sum(Yerr(Ytrue(:,3)==i,3))/numel(Yerr(Ytrue(:,3)==i,3));
    end
    % Dataset
    errDS = zeros(nObs/nBoxes,1);
    for i=1:nObs/nBoxes
        errDS(i) = sum(sum(Yerr((i-1)*nBoxes+1:i*nBoxes,:)))/numel(Yerr((i-1)*nBoxes+1:i*nBoxes,:));
    end
else
    % Errors in
    errBox = Ypred{1};
    errWater = Ypred{2};
    errN = Ypred{3};
    errWeeds = Ypred{4};
    errDS = Ypred{5};
end
if (nargin < 3)
    showPlot = true;
end

if(showPlot)
    % Figure
    f = figure;
    p = uipanel('Parent', f, 'BorderType', 'none'); 
    p.Title = ['Prediction Accuracy (overall: ' sprintf('%.2f',mean(errBox)*100) '%)']; 
    p.TitlePosition = 'centertop'; 
    p.FontSize = 24;
    p.FontWeight = 'bold';
    p.FontName = 'Times';
    %Per box
    subplot(3, 3, [1 2 3], 'Parent', p);
    bar(errBox, 'FaceAlpha',.5);
    ylim([0 1]);
    title('Box Numbers', 'FontSize', 16);
    set(gca, 'FontSize', 12, 'XTick', 1:30);
    hold on;
    errMean = mean(errBox);
    plot(get(gca,'xlim'),[1 1]*errMean,'r-', 'LineWidth', 3);
    text(0, errMean+0.05, strcat('Average: ', sprintf('%.2f',errMean*100), '%'), 'Color', 'r', 'FontSize', 14);

    %Per Cause
    % Water
    subplot(3, 3, 4, 'Parent', p);
    bar(errWater, 'FaceAlpha',.5);
    ylim([0 1]);
    hold on;
    title('Water', 'FontSize', 16);
    xt = get(gca, 'XTick');
    set(gca, 'FontSize', 12)
    set(gca,'xticklabel', {'Sufficient', 'Drying'});
    errMean = 0.5*errWater(1) + 0.5*errWater(2);
    plot(get(gca,'xlim'),[1 1]*errMean,'r-', 'LineWidth', 3);
    text(0, errMean+0.05, strcat('Average: ', sprintf('%.2f',errMean*100), '%'), 'Color', 'r', 'FontSize', 16);
    % Nitrogen
    subplot(3, 3, 5, 'Parent', p);
    bar(errN, 'FaceAlpha',.5);
    ylim([0 1]);
    hold on;
    title('Nitrogen', 'FontSize', 16);
    set(gca, 'FontSize', 12);
    set(gca,'xticklabel', {'Low', 'Medium', 'High'});
    errMean = 0.33334*errN(1) + 0.33333*errN(2) + 0.33333*errN(3);
%     for i=1:max(Ytrue(:,2))
%         errMean = errMean + sum(Ytrue(:,2)==i)/numel(Ytrue(:,2))*errN(i);
%     end
    plot(get(gca,'xlim'),[1 1]*errMean,'r-', 'LineWidth', 3);
    text(0, errMean+0.05, strcat('Average: ', sprintf('%.2f',errMean*100), '%'), 'Color', 'r', 'FontSize', 16);
    % Weeds
    subplot(3, 3, 6, 'Parent', p);
    bar(errWeeds, 'FaceAlpha',.5);
    ylim([0 1]);
    hold on;
    title('Weeds', 'FontSize', 16);
    set(gca, 'FontSize', 12);
    set(gca,'xticklabel', {'None', 'Few', 'Many', 'Only'});
    errMean = 0.25*errWeeds(1) + 0.25*errWeeds(2) + 0.25*errWeeds(3) + 0.25*errWeeds(4);
%     for i=1:max(Ytrue(:,3))
%         errMean = errMean + sum(Ytrue(:,3)==i)/numel(Ytrue(:,3))*errWeeds(i);
%     end
    plot(get(gca,'xlim'),[1 1]*errMean,'r-', 'LineWidth', 3);
    text(0, errMean+0.05, strcat('Average: ', sprintf('%.2f',errMean*100), '%'), 'Color', 'r', 'FontSize', 16);

    % Dataset number
    subplot(3, 3, [7 8 9], 'Parent', p);
    bar(errDS, 'FaceAlpha',.5);
    ylim([0 1]);
    title('Days After Sowing', 'FontSize', 16);
    set(gca, 'FontSize', 12, 'XTick', 1:16, 'XTickLabels', strsplit(num2str(daysAfterSowing)));
    hold on;
    errMean = mean(errDS);
    plot(get(gca,'xlim'),[1 1]*errMean,'r-', 'LineWidth', 3);
    text(0, errMean+0.05, strcat('Average: ', sprintf('%.2f',errMean*100), '%'), 'Color', 'r', 'FontSize', 16);
end

% Return result
errors = {errBox, errWater, errN, errWeeds, errDS};
end

