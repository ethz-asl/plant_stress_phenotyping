function [calibrationParameters] = calibratecameraarray(nCams, checkerboardSquareSizeMM)
% CALIBRATECAMERAARRAY Determine Intrinsics and extrinsic claibration parameters
%  of a set of cameras given sychronised images of a checkerboard.
%
%    [calibrationParameters] = calibratecameraarray(nCams,
%    checkerboardSquareSizeMM) returns a cell array of stereoParam objects
%    where the ith cell contains intrinsic and extrinsic parameters for the
%    1st and (i+1)th camera pair.
    
    currentFolder = pwd;
    imageFolderArray = {};  % rown vectors of objects for each camera
    imageLocationArray = {};
    imagePointsArray = {};
    boardSizeArray = {};
    imagesUsedArray = {};
    calibrationParameters = {};
    for iCam = 1: nCams
        if iCam==1
            imageFolderArray{iCam} = uigetdir(currentFolder, strcat('Folder containing images for Cam ', num2str(iCam)));
        else
            imageFolderArray{iCam} = uigetdir(imageFolderArray{iCam-1}, strcat('Folder containing images for Cam ', num2str(iCam)));
        end
        images = imageSet(imageFolderArray{iCam});
        imageLocationArray{iCam} = images.ImageLocation; % get paths of images in folder
        [imagePointsArray{iCam}, boardSizeArray{iCam}, imagesUsedArray{iCam}] = detectCheckerboardPoints(imageLocationArray{iCam});
    end
%TODO: Add check to ensure only pairs of images with checkerboard detected in both cameras
%are used
    worldPoints = generateCheckerboardPoints(boardSizeArray{1}, checkerboardSquareSizeMM);

    for iCam = 2:nCams
        imagePointsPair = cat(4, imagePointsArray{1}, imagePointsArray{iCam});
        [calibrationParameters{iCam-1},pairsUsed,estimationErrors] = estimateCameraParameters(imagePointsPair,...
         worldPoints,'EstimateSkew', false, 'EstimateTangentialDistortion', true, ...
         'NumRadialDistortionCoefficients', 3, 'WorldUnits', 'mm');
         figure; showReprojectionErrors(calibrationParameters{iCam-1}); title(strcat('Mean Reprojection Errors Cams  ', num2str(1), ' and ', num2str(iCam)));
        figure; showExtrinsics(calibrationParameters{iCam-1}); title(strcat('Extrinsics Cams', ' ', num2str(1), ' and', ' ', num2str(iCam)));
    end

end
