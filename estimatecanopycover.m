function [canopyCoverArray] = estimatecanopycover(folderpath)
%estimatecanopycover Estimates canopy cover given a set of color images of
%  plants against soil background

    if nargin == 0
        folderpath = uigetdir('', 'Folder containing RGB images');
    end
    
    imds = imageDatastore(folderpath);
    nImg = length(imds.Files);
    frameRGB = readimage(imds,1);
    [~, rect] = imcrop(frameRGB);   % crop an area which is covering the only the plants
    
    canopyCoverArray = zeros(nImg,1);
    for iImg = 1:nImg
        frameRGB = readimage(imds, iImg);
        I = imcrop(frameRGB, rect);
        [bw, maskedImage] = createplantmask(I);
        canopyCoverArray(iImg,1) = sum(bw)/(size(bw,1)*size(bw,2));
    end
        

    
end

