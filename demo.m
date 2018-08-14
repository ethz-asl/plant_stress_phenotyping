% Sample script demonstrating (and) testing crop_phenotyping functionality

%% Calibrate cameras
realsenseParams = calibratecameraarray(2, 70);

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
