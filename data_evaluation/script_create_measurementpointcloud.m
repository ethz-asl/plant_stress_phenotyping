%% Create MeasurementPointcloud
% Script should be run from its own folder
% Creates a 'MeasuremenPointcloud' object and specifies the fields
% Location, IRIntensity, IRReflectanceFactor, RGBPosition, Color, 
% RGBReflectanceFactor, MSIntensity, MSReflectanceFactor, MSWaveLengths, 
% NDVI and Label for every box in a single or all datasets.
% Should take about 30 secs to 1 min per dataset on a decent (i7) CPU.

%% Parameters
dataPath = uigetdir(pwd, 'Select the measurement-date-folder'); %/20180212;   
singleDataSet = true;                  % if false evaluates data for all subfolders of 'dataPath', else set 'dataPath' to the ***_greenhouse_measurments folder
useBoxMask = true;                      % Returns 3d Points of box or of crops only (set to true for evaluation)
visualizePointcloud = true;            % display masked pointcloud at the end
visualizationType = 'color';             % Set string what to visualize (color, ir, ndvi, label, MS*)

recalibrateXimeaExtrinsics = true;      % Set to true to recalibrate the ximea extrinsics for datasets 3-16 using caltag.
caltagPath = '../thirdparty/caltag';  % Path to caltag repository
caltagData = '../results/calibration/2x2x2.5in.mat';   % Path, including filename and file extension to caltag calibration file.
recalibrationBand = 22;                 % Multispectral band to use for recalibration image.

seg_methods = {'EGI', 'MSDiff23_5'};        % Methods for crop segmentation by thresholding.
seg_lower = [0.08, 0.35];               % Lower bound for segmentation methods.
seg_upper = [Inf, Inf];                  % Upper bound for segmentation methods.

saveResults = true;                    % True: stores 1 result per dataset, variable name will be the same as the saved file name.
saveName = 'point_cloud_';                   % Results are stored as "saveName<dataset number>.mat'
saveDir = '../results/pointclouds';        % Directory where to store the results

% Results(dont change anything here)
Results = cell(30,1);                   % Contains a MeasurementPointcloud for every box
ResultsFull = {};                       % Stores results for all datasets, ResultsFull{dataSet, boxNo}

%% Load required Parameters and include utility paths
% Change paths here if necessary
load(fullfile('..', 'results','calibration', 'stereoParams.mat')); % Stereoclaibration
load(fullfile('..', 'results', 'boxDetections.mat'));        % Detected boxes in rgb image
load(fullfile('..', 'results', 'soilLevels.mat'));    % Z coordinate of soil (highest Density Estimate from dataset 3)
addpath(fullfile('..', '3dprocessing'));                           % Include path with utility functions for calibration and 3D processing
addpath(fullfile('..', 'spectral_image'));                           % Include path to build multispectral image datacube
if recalibrateXimeaExtrinsics
   addpath(caltagPath);                                      % Include caltag recalibration repo 
end

%% Code: Get all folders to process
if (singleDataSet)
    % Divide datapath into path and measurement folder
    index = max(regexpi(dataPath, '/'));
    subDirs = {dataPath(index+1:end)};
    dataPath = dataPath(1:index);
else
    % Get all data folders
    d = dir(dataPath);
    isub = [d(:).isdir]; % returns logical vector
    subDirs = {d(isub).name}';
    subDirs(ismember(subDirs,{'.','..'})) = [];
end

for ds = 1:length(subDirs)
    %% Get images and box    
    folderName = subDirs{ds};
    currentPath = fullfile(dataPath, folderName);
    
    % Assign measurement number to folder
    folderDates = {'0118', '0130', '0201', '0205', '0208', ...
        '0212', '0215', '0219', '0223', '0226', '0302', '0305', '0308', ...
        '0312', '0315', '0329'};
    dataSetNumber = find(contains(folderDates, folderName(5:8)));
    fprintf(1,['Now processing: Dataset ' num2str(dataSetNumber)])
    
    % Load imagesets and boxes
    imageSetRGB = getimagesfromfolder(currentPath,1);
    imageSetIR1 = getimagesfromfolder(currentPath,2);
    imageSetIR2 = getimagesfromfolder(currentPath,3);
    imageSetMS = getimagesfromfolder(currentPath,4);
    boxes = boxDetections{dataSetNumber};

    %% Create all 3D point clouds
    fprintf(1,' (3D');
    for i = 1:30
        % Set general parameters
        Results{i} = MeasurementPointcloud;
        Results{i}.DataSet = dataSetNumber;
        Results{i}.BoxNumber = i;
        Results{i}.Box = boxes(i,:);
        Results{i}.ReferenceHeight = boxReferenceHeights(i);
        
        % Create Pointcloud
        Results{i}.stereoreconstruction(stereoParams_ir1_ir2_radtan, ...
            imread(imageSetIR1{i}), imread(imageSetIR2{i}));
    end

    %% Create boxmasked RGB image
    fprintf(1,'-RGB');
    RGBmasked = cell(30,1);
    for i=1:30
        img = imread(imageSetRGB{i});
        
        if(useBoxMask)
            W_i = size(img,2);
            H_i = size(img,1);

            % Rotate and apply mask
            img = imrotate(img,boxes(i,5));
            R = img(:,:,1);
            G = img(:,:,2);
            B = img(:,:,3);
            mask = true(size(R));
            mask(int16(boxes(i,2)):int16(boxes(i,2)+boxes(i,4)), ...
                int16(boxes(i,1)):int16(boxes(i,1)+boxes(i,3))) = false;       
            R(mask) = 0;
            G(mask) = 0;
            B(mask) = 0;
            img = cat(3,R,G,B);

            % Rotate back and crop away rotation distortion
            img = imrotate(img,-1*boxes(i,5));
            W_r = size(img,2);
            H_r = size(img,1);
            img = imcrop(img,round([(W_r-W_i)/2, (H_r-H_i)/2, W_i-1, H_i-1]));
        end
        
        RGBmasked{i} = img;
    end

    %% Color point clouds using RGB images and remove masked points
    for i=1:30
        Results{i}.colorpointcloud(stereoParams_ir1_rgb_radtan, ...
            RGBmasked{i});

        % Remove masked points 
        colorValues = sum(Results{i}.Color, 2);      
        Results{i}.selectpoints(colorValues~=0);
    end

    %% Load and preprocess multispectral data
    fprintf(1,'-MS');
    MSdataCubes = cell(31,1);
    for i=1:31
        % Get multispectral datacube
        specImg = SpectralImage(imread(imageSetMS{i}));
        MSdataCubes{i} = specImg.dataCubeOriginalFormat;        
        if(dataSetNumber <2)    % First dataset has 8 bit ximea images, the others have 10 bit raw (read by matlab as 16 bit), hence this normalisation is required
            bitNormalization = 2^8-1;
        else
            bitNormalization = 2^6*(2^10-1);
        end
        MSdataCubes{i} = double(MSdataCubes{i})./bitNormalization;        
    end
    %% Recalibrate ximea extrinsics
    if recalibrateXimeaExtrinsics && dataSetNumber >= 3
        imageMS = MSdataCubes{31};
        iamgeMS = imageMS(:,:, recalibrationBand);
        stereoParams_ir1_ximea_radtan = calibrateExtrinsicsCaltag( ...
            stereoParams_ir1_ximea_radtan.CameraParameters1, ...
            stereoParams_ir1_ximea_radtan.CameraParameters2, ...
            imread(imageSetIR1{31}), iamgeMS, caltagData, false);
    end
    %% Read multispectral data into pointcloud
    for i=1:30
        Results{i}.readmultispectral(stereoParams_ir1_ximea_radtan, ...
            MSdataCubes{i});

        Results{i}.MSWaveLengths = specImg.wavelengthsRowMajor;
    end
    
    %% Compute Reflectance factors and NDVI
    fprintf(1,'-Ref');
    reflectanceFactors = computereflectancefactors(imageSetRGB, ...
        imageSetIR1, MSdataCubes);
    for i = 1:30
        %Write Reflectance
        Results{i}.RGBReflectanceFactor = reflectanceFactors(i,1)*255;
        Results{i}.IRReflectanceFactor = reflectanceFactors(i,2)*255;
        Results{i}.MSReflectanceFactor = reflectanceFactors(i,3:27);
        
        % Compute NDVI from multispectral data
        R_idx = 25;     % 670 nm
        NIR_idx = 8;    % 803 nm
        Results{i}.computendvi(R_idx, NIR_idx);       
    end
    
    %% Crop Segmentation
    fprintf(1,'-Seg');
    for i = 1:30
        Results{i}.segment(seg_methods, seg_lower, seg_upper, true);
    end
    
    %% Visualize a pointcloud    
    if (visualizePointcloud)
        fprintf(1,'-Plot');
        for i=1:30
            figure;
            Results{i}.displaypointcloud(visualizationType);
        end
    end
    
    %% Write full result
    if (~singleDataSet)
        for i=1:30
            ResultsFull{dataSetNumber, i} = Results{i};
        end
    end
    
    %% Store data
    if (saveResults)
        fprintf(1,'-Save');
        eval([saveName num2str(dataSetNumber) ' = Results;'])
        save([fullfile(saveDir, saveName) num2str(dataSetNumber) '.mat'], ...
            [saveName num2str(dataSetNumber)]);
    end
    fprintf(1,'-Done!)\n');
end