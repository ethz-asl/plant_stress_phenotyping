function [scaledNDMatrix] = rescale(ndMatrix, range)
    xmin = min(ndMatrix(:));
    xmax = max(ndMatrix(:));
    scaledNDMatrix = range(2)*(ndMatrix - xmin)./(xmax - xmin) + range(1);
    % make Nan values 0
    scaledNDMatrix(isnan(scaledNDMatrix))=0;
end

