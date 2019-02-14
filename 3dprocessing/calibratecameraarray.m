function [calibrationParameters] = calibratecameraarray(nCams, checkerboardSquareSizeMM, visualizeReprojection)
% CALIBRATECAMERAARRAY Determine Intrinsics and extrinsic claibration parameters
%  of a set of cameras given sychronised images of a checkerboard.
%
%    [calibrationParameters] = calibratecameraarray(nCams,
%    checkerboardSquareSizeMM) returns a cell array of stereoParam objects
%    where the ith cell contains intrinsic and extrinsic parameters for the
%    1st and (i+1)th camera pair.
    
    if nargin < 3
        visualizeReprojection = false;
    end
    currentFolder = pwd;
    imageFolderArray = {};  % row vectors of objects for each camera
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
        
% Check to ensure only pairs of images with checkerboard detected in both cameras
%are used
    usedImageIDs = logical(ones(size(imagesUsedArray{1})));
    nullPointArray = ones(size(imagePointsArray{iCam}(:,:,1)))*nan;
    for iCam = 1:nCams
        for iImg = 1:size(imagesUsedArray{iCam})
            if ~imagesUsedArray{iCam}(iImg)
                imagePointsArray{iCam} =  cat(3, imagePointsArray{iCam}(:,:,1:iImg-1), nullPointArray, imagePointsArray{iCam}(:,:,iImg:end));
            end
        end
        usedImageIDs = usedImageIDs & imagesUsedArray{iCam};
    end
    for iCam = 1:nCams     
        imagePointsArray{iCam}(:,:,~usedImageIDs) = [];
        imageLocationArray{iCam}(~usedImageIDs) = []; % remove outlier image sets
    end
    
    worldPoints = generateCheckerboardPoints(boardSizeArray{1}, checkerboardSquareSizeMM);

    for iCam = 2:nCams
        imagePointsPair = cat(4, imagePointsArray{1}, imagePointsArray{iCam});
        [calibrationParameters{iCam-1},pairsUsed,estimationErrors] = estimateCameraParameters(imagePointsPair,...
         worldPoints,'EstimateSkew', false, 'EstimateTangentialDistortion', true, ...
         'NumRadialDistortionCoefficients', 3, 'WorldUnits', 'mm');
         figure; showReprojectionErrors(calibrationParameters{iCam-1}); title(strcat('Mean Reprojection Errors Cams ', num2str(1), ' and ', num2str(iCam)));
        figure; showExtrinsics(calibrationParameters{iCam-1}); title(strcat('Extrinsics Cams ', num2str(1), ' and ', ' ', num2str(iCam)));
    end
    
%     if visualizeReprojection
%         for iCam = 2:nCams
%             for iImg = 1:size(usedImageIDs)
%                 imagePoints = imagePointsArray{iCam}(:,:,iImg);
%                 undistortedImg = undistortImage(imread(imageLocationArray{iCam}(iImg)), calibrationParameters{iCam-1}.CameraParameters2);
%                 reprojectedPointsCam = worldToImage(calibrationParameters{iCam-1}.CameraParameters2, RotationOfCamera2, TranslationOfCamera2, worldPoints, 'ApplyDistortion', false);
%                 figure; imshow(undistortedImg); hold on;
%                 plot(imagePoints(:,1), imagePoints(:,2), 'ro');
%                 plot(reprojectedPointsCam(:,1), reprojectedPointsCam(:,2), 'go');
%                 legend('detected corners', 'reprojectedCorners');
%                 title('Undistorted Cam2 Image');
%                 hold off
%             end
%         end
%     end

end
