function [pointcloudArray] = stereoreconstruction(stereoParams, folderpath1, folderpath2)
% stereoreconstruction Create a pointcloud given stereo calibration params
% and 2 folders containing images from a stereo pair.

%  [pointcloudArray] = stereoreconstruction(stereoParams, folderpath1, folderpath2)
%  returns a cell array of pointcloud objects
%  corresponding to image pairs in the given folders

    if nargin == 1
        folderpath1 = uigetdir('~', 'Folder with images taken from first camera');
        folderpath2 = uigetdir(folderpath1, 'Folder with images taken from second camera');
    end
    
    imds1 = imageDatastore(folderpath1);
    imds2 = imageDatastore(folderpath2);
    pointcloudArray = {};
    
    for iImg = 1:length(imds1.Files)
        frameLeft = rgb2gray(readimage(imds1, iImg));
        frameRight = rgb2gray(readimage(imds2, iImg));
        [frameLeftRect, frameRightRect] = ...
            rectifyStereoImages(frameLeft, frameRight, stereoParams);
        
        disparityRange = [32, 48];
        blockSize = 5;
        disparityMap = disparity(frameLeftRect, frameRightRect, 'DisparityRange', disparityRange, 'BlockSize', blockSize, 'Method', 'SemiGlobal', 'DistanceThreshold', 2);
        
        points3D = reconstructScene(disparityMap, stereoParams);

        % Convert to meters and create a pointCloud object
        points3D = points3D ./ 1000;
        pointcloudArray{iImg} = pointCloud(points3D, 'Color', cat(3,frameLeftRect, frameLeftRect, frameLeftRect));
    end

end