% Sample script demonstrating (and) testing plant_stress_phenotyping functionality
addpath(fullfile('3dprocessing'));
addpath(fullfile('spectral_image')); 
addpath(fullfile('data_evaluation')); 
%% Calibrate cameras
realsenseParams = calibratecameraarray(3, 50);

%% Create 3D point clouds
pointcloudArray = stereoreconstruction(realsenseParams{1});

%% Color point clouds using RGB images
colorPointcloudArray = colorpointcloud(pointcloudArray, realsenseParams{2});

%% Visualise a pointcloud
displayboxpointcloud(colorPointcloudArray{5});
%% Get Images from Folder
dataFolder = uigetdir(pwd, 'Select the measurement-date-folder'); % folder with all images from a measurement date
imageType = 1; % (1 - rgb, 2 - ir1, 3 - ir2, 4 - multispec)
imagePaths = getimagesfromfolder(dataFolder, imageType);
boxNo = 5;
image = imread(imagePaths{boxNo});
figure; imshow(image);
title('RGB Image');
%% Detect box in RGB image
% see script_detect_box_rgb

%% Crop Box from Image
% Assign measurement number to folder
folderDates = {'0118', '0130', '0201', '0205', '0208', ...
    '0212', '0215', '0219', '0223', '0226', '0302', '0305', '0308', ...
    '0312', '0315', '0329'};
folderName = dataFolder(length(dataFolder)-7:end);
dataSetNumber = find(contains(folderDates, folderName(5:8)));
load(fullfile('results','boxDetections.mat'));
box = boxDetections{dataSetNumber}(boxNo,:); % enter the correct dataset number
croppedImage = cropboxfromimage(image, box);
figure; imshow(croppedImage);
title('Cropped RGB Image');

