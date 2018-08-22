% Sample script demonstrating (and) testing plant_stress_phenotyping functionality

%% Get Images from Folder
dataFolder = '/media/flourish/raghavshdd3/khanna2018spatiotemporal/dataset/greenhouse_experiment/Data/dataset-release/images/20180215'; % folder with all images from a measurement date
imageType = 1; % (1 - rgb, 2 - ir1, 3 - ir2, 4 - multispec)
imagePaths = getimagesfromfolder(dataFolder, imageType);
image = imread(imagePaths{5});
figure; imshow(image);
title('RGB Image');
%% Detect box in RGB image
% see script_detect_box_rgb

%% Crop Box from Image
load('results/boxDetections.mat');
box = boxDetections{7}(5,:);
croppedImage = cropboxfromimage(image, box);
figure; imshow(croppedImage);
title('Cropped RGB Image');
%% Calibrate cameras
realsenseParams = calibratecameraarray(3, 50);

%% Create 3D point clouds
pointcloudArray = stereoreconstruction(realsenseParams{1});

%% Color point clouds using RGB images
colorPointcloudArray = colorpointcloud(pointcloudArray, realsenseParams{2});

%% Visualise a pointcloud
displayboxpointcloud(colorPointcloudArray{5});




%% Estimate Canopy Cover from RGB images
canopyCoverArray = estimatecanopycover();
% TODO: work on createplantmask

%% Estimate Height from RGB Pointcloud
%plantHeightArray = estimateplantheight(colorPointcloudArray);
