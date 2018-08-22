function [colorPointcloudArray] = colorpointcloud(pointcloudArray, stereoParams, folderpath)
% colorpointcloud Create a coloured pointcloud given stereo calibration params
% between the point cloud reference camera and a folder containing synchronised images from a colour camera.

%  [colorPointcloudArray] = colorpointcloud(stereoParams, folderpath)
%  returns a cell array of coloured pointcloud objects
%  corresponding to images in the given folders

    if nargin == 2
        folderpath = uigetdir('~', 'Folder with images taken from first camera');
    end
    
    
    imds = imageDatastore(folderpath);
    colorPointcloudArray = {};
    
    for iImg = 1:length(imds.Files)
        frameRGB = readimage(imds, iImg);
        points3D = pointcloudArray{iImg}.Location;
        p3D = reshape(points3D*1000,[size(points3D,1)*size(points3D,2),3]);
        p3D = p3D(~any(isnan(p3D) | isinf(p3D),2),:);
        imagePointsRGB = worldToImage(stereoParams.CameraParameters2, stereoParams.RotationOfCamera2, stereoParams.TranslationOfCamera2, p3D, 'ApplyDistortion', true);
        p3DColors = impixel(frameRGB, floor(imagePointsRGB(:,1)), floor(imagePointsRGB(:,2)));
        colorPointcloudArray{iImg} = pointCloud(p3D./1000, 'Color', p3DColors./255);
    end
    
end