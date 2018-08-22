classdef MeasurementPointcloud < handle
    %MeasurementPointcloud This class contains all relevant information to
    %evaluate and display the measurements of a single box.
    
    properties
        %% General
        DataSet         % Index of Dataset for this measurement
        BoxNumber       % Number of evaluated box for this measurement
        %% Pointcloud
        Location        % Nx3 Single, [X,Y,Z] coordinates in real world [m]
        IRIntensity     % Nx1 Double, normalized IR-intensities [0-1]
        IRReflectanceFactor     % Scalar, IR reflectance correction factor 
                                % for this dataset.
        RGBPosition     % Nx2 Single, [i, j] coordinates in RGB image
        Color           % Nx3 Double, [R, G, B] normalized colors [0-1]
        RGBReflectanceFactor    % Scalar, RGB reflectance correction 
                                % factor for this dataset. 
        MSIntensity     % Nx25 normalized Intensities for every band [0-1]
        MSReflectanceFactor     % 25x1 Double, multispectral correction 
                                % factor for this dataset per band.
        %% Processing and Evaluation                        
        NDVI            % Nx1 Double, NDVI value for every point
        Label           % Nx1 Single, 1 - is crop, 0 - is not crop
        %% Images
        Box             % 1x5 Double, Boxcoordinates to crop from RGB image
        %% Info
        MSWaveLengths   % 25x1 Single, Wavelenghts of multispectral images
        ReferenceHeight % Z coordinate of soil
        
    end
    
    methods
        %% Setup Pointcloud
        function stereoreconstruction(obj, stereoParams, frameLeft, frameRight)
            % STEREORECONSTRUCTION Create Location and IRIntensity from 
            % given stereo calibration params and 2 IR stereo images.
            
            % stereo reconstruction
            [frameLeftRect, frameRightRect] =  ...
                rectifyStereoImages(frameLeft, frameRight, stereoParams);
            disparityRange = [32, 80];
            blockSize = 5;
            disparityMap = disparity(frameLeftRect, frameRightRect, ...
                'DisparityRange', disparityRange, 'BlockSize', ...
                blockSize, 'Method', 'SemiGlobal', 'DistanceThreshold', 2);
            points3D = reconstructScene(disparityMap, stereoParams);
            points3D = points3D ./ 1000;    % Convert to meters

            % Filter NaN and Inf positions
            location = reshape(points3D,[],3);
            intensity = reshape(im2double(frameLeftRect),[],1);            
            indices = 1:length(location);            
            indices = indices(~any(isnan(location) | isinf(location),2));

            % Store data
            obj.Location = location(indices,:);
            obj.IRIntensity = intensity(indices);
        end        
        function colorpointcloud(obj, stereoParams, frameRGB)
            % COLORPOINTCLOUD sets the Color and RGBPosition fields from 
            % given stereo calibration params and synchronised color image.
            % Needs to be executed after stereoreconstruction.

            % Get color from RGB image
            imagePointsRGB = worldToImage(stereoParams.CameraParameters2, ...
                stereoParams.RotationOfCamera2, ...
                stereoParams.TranslationOfCamera2, ...
                obj.Location*1000, 'ApplyDistortion', true);
            imagePointsRGB = floor(imagePointsRGB);
            color = impixel(frameRGB, imagePointsRGB(:,1), ...
                imagePointsRGB(:,2));
            color = double(color) / 255;

            % Remove Inf and NaN points and store new data
            indices = ~any(isnan(color) | isinf(color),2);
            obj.selectpoints(indices);
            obj.Color = color(indices,:);
            obj.RGBPosition = [imagePointsRGB(indices,1) ...
                imagePointsRGB(indices,2)];
        end         
        function readmultispectral(obj, stereoParams, dataCube)
            % READMULTISPECTRAL sets the MSIntensity  from given stereo 
            % calibration params and multisectral data cube from
            % synchronised multispectral image.
            % Needs to be executed after stereoreconstruction.

            % Get MS image points
            imagePoints = worldToImage(stereoParams.CameraParameters2, ...
                stereoParams.RotationOfCamera2, ...
                stereoParams.TranslationOfCamera2, ...
                obj.Location*1000, 'ApplyDistortion', true);
            imagePoints = floor(imagePoints);
            
            % Test stereo compensation
            imagePoints(:,2) = imagePoints(:,2)-9;

            % Get multispectral Values
            MS = zeros(size(imagePoints,1),25);
            for i = 1:size(MS,1)
                if(imagePoints(i,2) < size(dataCube,1) ...
                        && imagePoints(i,1) < size(dataCube,2) ...
                        && min(imagePoints(i,:)) > 0)
                    MS(i,:) = dataCube(imagePoints(i,2), imagePoints(i,1), :);
                else
                    MS(i,:) = NaN;
                end
            end
            
            % Remove NaN and Inf Values
            indices = ~any(isnan(MS) | isinf(MS),2);
            obj.selectpoints(indices);

            % Store data
            obj.MSIntensity = MS(indices,:);
        end   
        
        %% Utilities
        function selectpoints(obj, indices)
            % SELECTPOINTS selects removes all points from the pointcloud 
            % that don't match with the given indices (logical or as index)
            
            if(size(obj.Location,1) >0)
                obj.Location = obj.Location(indices,:);
            end
            if(size(obj.IRIntensity,1) >0)
                obj.IRIntensity = obj.IRIntensity(indices);
            end
            if(size(obj.RGBPosition,1) >0)
                obj.RGBPosition = obj.RGBPosition(indices,:);
            end
            if(size(obj.Color,1) >0)
                obj.Color = obj.Color(indices,:);
            end
            if(size(obj.MSIntensity,1) >0)
                obj.MSIntensity = obj.MSIntensity(indices,:);
            end
            if(size(obj.NDVI,1) >0)
                obj.NDVI = obj.NDVI(indices);
            end
            if(size(obj.Label,1) >0)
                obj.Label = obj.Label(indices,:);
            end
        end
        function displaypointcloud(obj, plotType)
            % DISPLAYPOINTCLOUD Display the stored pointcloud. 
            % plotTypes: Color, IR, NDVI, Label* (*=0,1), MS* (*=1:25)
                        
            if (nargin == 1)
                plotType = 'Color';
            end          
 %           figure; 
            titleAppend = '';
            markerSize = 50;
            % Plot Types
            if(strcmpi(plotType,'color') || strcmpi(plotType, 'RGB'))  
                titleAppend = 'Color';
                pcshow(obj.Location, obj.Color, 'MarkerSize', markerSize);
            
            elseif(strcmpi(plotType,'IR'))
                titleAppend = 'Infrared';
                pcshow(obj.Location, repmat(obj.IRIntensity, 1, 3), ...
                    'MarkerSize', markerSize);
            
            elseif(strcmpi(plotType,'NDVI'))
                titleAppend = 'NDVI';
                pcshow(obj.Location, obj.NDVI,'MarkerSize', markerSize);
                colormap('jet');
                caxis([-1 1]);
                colorbar;
            
            elseif(strcmpi(plotType,'Label1'))
                titleAppend = 'Crops only';
                pcshow(obj.Location(obj.Label==1,:), ...
                    obj.Color(obj.Label==1,:),'MarkerSize', markerSize);
            
            elseif(strcmpi(plotType,'Label0'))
                titleAppend = 'Non-crops only';
                pcshow(obj.Location(obj.Label==0,:), ...
                    obj.Color(obj.Label==0,:),'MarkerSize', markerSize);
            
            elseif(strcmpi(plotType(1:2), 'MS'))
                ID = str2double(plotType(3:end));
                titleAppend = ['Multispectral: ' ...
                    num2str(obj.MSWaveLengths(ID)) 'nm'];
                pcshow(obj.Location, repmat(obj.MSIntensity(:,ID), 1, 3), ...
                    'MarkerSize', markerSize);
            end
            axis off;
            view(1.3301,-85.556);
            % Axis and title
 %           title(['From dataset ' num2str(obj.DataSet) ': Box No. ' ...
 %               num2str(obj.BoxNumber) ': ' titleAppend]);
 %           xlabel('X'); ylabel('Y'); zlabel('Z'); view(50, 330);
        end
        function [imageOut] = getimage(obj, imageType, cropBox, resolution)
            % GETIMAGE Interpolates the image specified by imageType from 
            % the pointcloud onto an image of dimensions specified in resolution, 
            % Which should match with RGB image (default 1080x1920).
            % Set cropBox to true to get the box only (default: true).
            % imageTypes: RGB, IR, NDVI, Label, Height, MS* (*=1:25, multispectral
            % band no). Default is 'color'.
            
            % Parse arguments
            if (nargin == 1)
                imageType = 'color';
            end
            if (nargin <= 2)
                cropBox = true;
            end
            if (nargin <= 3)
                resolution = [1080, 1920];
            end
         
            % Select data source
            if(strcmpi(imageType, 'RGB') || strcmpi(imageType, 'Color'))
                imageRGB = cell(3,1);
                for i = 1:3
                    data = obj.Color(:,i);
                    % Interpolate (averaging out multiple values)
                    [xMesh, yMesh] = meshgrid(1:resolution(2), 1:resolution(1));
                    [uniquePoints, ~, uIdx] = unique(obj.RGBPosition, 'rows');
                    uData = accumarray(uIdx, data, [], @mean);
                    imageRGB{i} = griddata(double(uniquePoints(:,1)), ...
                        double(uniquePoints(:,2)),uData,xMesh,yMesh);
                end
                
            elseif(strcmpi(imageType, 'IR'))
                data = obj.IRIntensity;  
                
            elseif(strcmpi(imageType, 'NDVI'))
                data = obj.NDVI;
                
            elseif(strcmpi(imageType, 'Label'))
                data = obj.Label;
                
            elseif(strcmpi(imageType, 'Height'))
                data = double(obj.Location(:,3));
                
            elseif strcmpi(imageType(1:2), 'MS')
                ID = str2double(imageType(3:end));
                data = obj.MSIntensity(:, ID);
            end
                
            % Interpolate (averaging out multiple values)
            if(strcmpi(imageType, 'RGB') || strcmpi(imageType, 'Color'))
                imageOut = cat(3, imageRGB{1}, imageRGB{2}, imageRGB{3});
            else
                [xMesh, yMesh] = meshgrid(1:resolution(2), 1:resolution(1));
                [uniquePoints, ~, uIdx] = unique(obj.RGBPosition, 'rows');
                uData = accumarray(uIdx, data, [], @mean);
                imageOut = griddata(double(uniquePoints(:,1)), ...
                    double(uniquePoints(:,2)),uData,xMesh,yMesh);
            end

            % Remove empty pixels
            imageOut(isnan(imageOut)) = 0;

            % Transform Label
            if(strcmpi(imageType, 'Label'))
                imageOut = imageOut > 0.5;
            end            
            
            % Crop box
            if (cropBox)
                imageOut = cropboxfromimage(imageOut, obj.Box);
            end
        end
        
        %% Evaluation
        function computendvi(obj, R_idx, NIR_idx)
            % COMPUTENDVI compute and set the NDVI property of the
            % pointcloud using the multispectral data. Sepcify which bands
            % to use with R- and NIR- idx (=1:25).
            R = obj.MSIntensity(:, R_idx) * obj.MSReflectanceFactor(R_idx);
            NIR = obj.MSIntensity(:, NIR_idx) * obj.MSReflectanceFactor(NIR_idx);
            obj.NDVI = (NIR - R)./(NIR + R); 
        end
        function data = evaluate(obj, indicatorIn)
            % EVALUATE Evaluate the requested indicator for every point in
            % the pointcloud. Supported 
            % indicators are: Height, NDVI, MS* with *=1:25 being the 
            % multispectral band, EGI (=Excess green index), NEGI
            % (=normalized EGI), NDRI (normalized difference index), 
            % ERI (Excess red index), MSDiff<a>_<b>, where <a> and <b> are
            % the band numbers for a - b.
            
            % Get data            
            if strcmpi(indicatorIn, 'Height')
                data = obj.ReferenceHeight - obj.Location(:,3);
                data(data<0) = 0;
                
            elseif strcmpi(indicatorIn, 'NDVI')
                data = obj.NDVI;
                
            elseif strcmpi(indicatorIn(1:min(6, length(indicatorIn))), 'MSDiff')
                idx = strfind(indicatorIn, '_');
                ID1 = str2double(indicatorIn(7:idx-1));
                ID2 = str2double(indicatorIn(idx+1:end));
                data1 = obj.MSIntensity(:, ID1);
                data2 = obj.MSIntensity(:, ID2);

                if ~isempty(obj.MSReflectanceFactor)
                    data1 = data1 .* obj.MSReflectanceFactor(ID1);
                end
                if ~isempty(obj.MSReflectanceFactor)
                    data2 = data2 .* obj.MSReflectanceFactor(ID2);
                end
                data = data1 - data2;
                
            elseif strcmpi(indicatorIn(1:2), 'MS')
                ID = str2double(indicatorIn(3:end));                
                data = obj.MSIntensity(:, ID);
                if ~isempty(obj.MSReflectanceFactor)
                    data = data .* obj.MSReflectanceFactor(ID);
                end
                 
            elseif strcmpi(indicatorIn, 'EGI') || strcmpi(indicatorIn, 'NEGI')
                data = 2 * obj.Color(:,2) - obj.Color(:,1) - obj.Color(:,3);
                if strcmpi(indicatorIn, 'NEGI')
                    data = data ./sum(obj.Color, 2);
                elseif ~isempty(obj.RGBReflectanceFactor)
                    data = data .* obj.RGBReflectanceFactor;                
                end
            elseif strcmpi(indicatorIn, 'NDRI')
                data = (obj.Color(:,2) - obj.Color(:,1)) ./ ...
                    (obj.Color(:,2) + obj.Color(:,1));
            elseif strcmpi(indicatorIn, 'ERI')
                data = (1.4*obj.Color(:,1) - obj.Color(:,2));
                if ~isempty(obj.RGBReflectanceFactor)
                    data = data .* obj.RGBReflectanceFactor; 
                end
            else
                error(['Unknown indicator: ' indicatorIn]);
            end 
        end
        function indicatorOut = evaluateindicator(obj, indicatorIn, indicatorStat)
            % EVALUATEINDICATOR Computes the requested indicator. Supported 
            % indicators are: Height, NDVI, MS* with *=1:25 being the 
            % multispectral band, EGI (=Excess green index), NEGI
            % (=normalized EGI), CanCov (=canopy cover), VolEst (=volumetric 
            % estimate), NDRI (normalized difference index), ERI (Excess red
            % index).
            % Supported indicatorStats: Mean/m (default), Variance/v, Max, Min
            
            % Unique value indicators
            if strcmpi(indicatorIn, 'CanCov')
                indicatorOut = sum(obj.Label)/numel(obj.Label);
                return
            elseif strcmpi(indicatorIn, 'VolEst')
                data = obj.ReferenceHeight - obj.Location(:,3);
                data(data<0) = 0;
                indicatorOut = sum(data(obj.Label));
                return                
            end
            
            % Parse input
            if nargin <= 2
                indicatorStat = 'Mean';
            end
            
            % Evaluate indicator statistics
            data = obj.evaluate(indicatorIn);
            data = data(obj.Label);
            
            % Return statistic
            if strcmpi(indicatorStat, 'Mean') || strcmpi(indicatorStat, 'm')
                indicatorOut = mean(data);
            elseif strcmpi(indicatorStat, 'Variance') || strcmpi(indicatorStat, 'v')
                indicatorOut = var(data);
            elseif strcmpi(indicatorStat, 'Min')
                indicatorOut = min(data);
            elseif strcmpi(indicatorStat, 'Max')
                indicatorOut = max(data);
            end
        end
        function segment(obj, methods, threshLower, threshUpper, union)
            % SEGMENT labels all points in the pointcloud as either crop
            % (label = true) or non-crop by thresholding the indicators
            % specified in methods. Set union to true (default) to apply 
            % union over methods, false for intersection over methods.
            
            % Parse input
            if nargin == 4
                union = true;
            end
            
            % Init
            if union
                obj.Label = false(size(obj.Location, 1), 1);
            else
                obj.Label = true(size(obj.Location, 1), 1);
            end
            
            % Apply methods
            for i =1:length(methods)
                data = obj.evaluate(methods{i});
                seg = data >= threshLower(i) & data <= threshUpper(i);
                if union
                    obj.Label = obj.Label | seg;
                else
                    obj.Label = obj.Label & seg;
                end
            end
        end
    end
end

