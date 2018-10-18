function [ ha ] = displayDataCube( dataCube )
%displayDataCube Displays given data cube as a series of images in a new
%figure, returns a vector of axes handle objects
%   Detailed explanation goes here

wavelengthsRowMajor = [615, 623, 608, 790, 686,...
    816, 828, 803, 791, 700,...
    765, 778, 752, 739, 714,...
    653, 662, 645, 636, 678,...
    867, 864, 857, 845, 670];

nRows = size(dataCube,1);
nCols = size(dataCube,2);
nBands = size(dataCube,3);
            
             [ha, pos] = tight_subplot(sqrt(nBands),sqrt(nBands),[.03 .01],[.01 .04],[.005 .005]);
             colormap gray;
            
             for i = 1:sqrt(nBands) % blkrow
                 for j = 1:sqrt(nBands) % blkcol
                     iBand = (i-1)*sqrt(nBands)+j;
                     axes(ha(iBand));
                     imagesc(dataCube(2:end-1,2:end-1,iBand))
                     %caxis([0 1]);
                     title(strcat(num2str(wavelengthsRowMajor(iBand)), ' nm'), 'FontSize', 10, 'FontWeight', 'bold');
                     %title(strcat('Band ', num2str(iBand)), 'FontSize', 7, 'FontWeight', 'bold');
                     axis off;
                     pos=get(ha(iBand), 'Position');
                     %set(ha(iBand), 'Position', [pos(1) pos(2) 0.85*pos(3) pos(4)]);
                 end
            end
            
            %h = colorbar;
            %set(h, 'Position', [.92 .0925 .0281 .8150])
end

