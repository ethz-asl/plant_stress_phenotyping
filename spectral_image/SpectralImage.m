classdef SpectralImage
    %SPECTRALIMAGE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Default values correspond to Ximea images
        % Image data
        rawImage
        nRows = 216
        nCols = 409
        nBands = 25
        dataCube
        dataCubeOriginalFormat
        exposureTime = 3
        latitude
        longitude
        altitude
        inverseSensorResponse = 0:1:255
        vignetteEffect = ones(216, 409, 25) 
        spectralComponent = ones(1, 25)
        responseCorrectedCube
        vignetteCorrectedCube
        isCalibrated = false
        calibratedDataCube
        
        % Filter pattern information
        % defaults for ximea image
        wavelengthsRowMajor = [615, 623, 608, 790, 686,...
            816, 828, 803, 791, 700,...
            765, 778, 752, 739, 714,...
            653, 662, 645, 636, 678,...
            867, 864, 857, 845, 670];
        
        offset_r = 3;
        offset_c = 0;
        width = 2045;
        height = 1080;
        
        blksize = 5;
    end
    
    methods
        
        function obj = SpectralImage(img, varargin)
            if nargin > 0
                obj.rawImage = img;
                obj = extractDataCube(obj);
                obj = extractDataCubeOriginalFormat(obj);
                obj.nRows = size(obj.dataCube,1);
                obj.nCols = size(obj.dataCube,2);
                
                numvarargs = length(varargin);
                
                if numvarargs > 1
                    error('SpectralImage(img,exposureTime): Too many input arguments');
                end
                
                % set defaults for optional inputs
                optargs = {0};
                % now put these defaults into the valuesToUse cell array,
                % and overwrite the ones specified in varargin.
                optargs(1:numvarargs) = varargin;
                
                if numvarargs == 1
                    obj.exposureTime = optargs{1};
                end
            end
        end
        
        %         function obj = SpectralImage(img, wavelengthsRowMajor, offset_r = 3, offset_c = 0, width = 2045, height = 1080, blksize = 5 )
        %             obj.rawImage = img;
        %             obj.wavelengthsRowMajor = wavelengthsRowMajor;
        %             obj.offset_r = offset_r;
        %             obj.offset_c = offset_c;
        %             obj.width = width;
        %             obj.height = height;
        %             obj.blksize = blksize;
        %         end
        %
        function obj = extractDataCube(obj)
            % Crop raw input image to pattern size
            img = im2double(obj.rawImage(1+obj.offset_r:obj.offset_r+obj.height, 1+obj.offset_c:obj.offset_c+obj.width));
            
            rows = size(img,1);
            cols = size(img,2);
            
            obj.dataCube = zeros(rows/obj.blksize,cols/obj.blksize,obj.blksize^2);
            
            % Extract data cube
            nBands = size(obj.dataCube,3);
            for i = 1:obj.blksize % blkrow
                for j = 1:obj.blksize % blkcol
                    obj.dataCube(:,:,(i-1)*obj.blksize+j) = img(i:5:end,j:5:end);
                end
            end
        end
        
        function obj = extractDataCubeOriginalFormat(obj)
            % Crop raw input image to pattern size
            img = obj.rawImage(1+obj.offset_r:obj.offset_r+obj.height, 1+obj.offset_c:obj.offset_c+obj.width);
            
            rows = size(img,1);
            cols = size(img,2);
            
            obj.dataCubeOriginalFormat = zeros(rows/obj.blksize,cols/obj.blksize,obj.blksize^2);
            
            % Extract data cube
            for i = 1:obj.blksize % blkrow
                for j = 1:obj.blksize % blkcol
                    obj.dataCubeOriginalFormat(:,:,(i-1)*obj.blksize+j) = img(i:5:end,j:5:end);
                end
            end
     
        end  
        
        function obj = setGPSData(obj, lat, lon, alt)
            obj.latitude = lat;
            obj.longitude = lon;
            obj.altitude = alt;
        end
            
        
        function displayDataCube(obj)
            colormap gray;
            
            [ha, pos] = tight_subplot(obj.blksize,obj.blksize,[.04 .01],[.01 .04],[.01 .01]);
            %             for ii = 1:6; axes(ha(ii)); plot(randn(10,ii)); end
            %             set(ha(1:4),'XTickLabel',''); set(ha,'YTickLabel','')
            
            for i = 1:obj.blksize % blkrow
                for j = 1:obj.blksize % blkcol
                    %subplot(obj.blksize, obj.blksize, (i-1)*obj.blksize+j);
                    axes(ha((i-1)*obj.blksize+j));
                    imagesc(obj.dataCube(2:end-1,2:end-1,(i-1)*obj.blksize+j))
                    title(strcat(num2str(obj.wavelengthsRowMajor((i-1)*obj.blksize+j)), ' nm'), 'FontSize', 7, 'FontWeight', 'bold');
                    axis off;
                end
            end
            if obj.exposureTime
                suptitle(['Raw Data Cube, Exposure Time: ', num2str(obj.exposureTime), ' ms']);
            end
        end
        
        function obj = createResponseCorrectedCube(obj, inverseSensorResponse)
            obj.responseCorrectedCube = SpectralImage(inverseSensorResponse(1+obj.rawImage)).dataCube;
            obj.inverseSensorResponse = inverseSensorResponse;
        end
        
        function obj = createVignetteCorrectedCube(obj, vignettingCube)
            %% Remove Vignetting and exposure time
             % Since output format (zero handling) of estimateVignetting is required for estimateIllumination
            % Remove outliers separately for every band
            for iBand = 1:obj.nBands
                vignettingCube(:,:,iBand) = medfilt2(vignettingCube(:,:,iBand));
            end
            % TODO: Find a principled way to handle zeros in the vignetting
            % vignettingCube(vignettingCube==0) = min(vignettingCube(vignettingCube>0)); % Scales all the other
            % bands badly
            obj.vignetteEffect = vignettingCube;
            obj.vignetteCorrectedCube = obj.responseCorrectedCube./(obj.exposureTime * vignettingCube);
            
        end
        
        function obj = createCalibratedDataCube(obj, spectralComponent)
            %% remove spectral component
            obj.calibratedDataCube = obj.vignetteCorrectedCube./repmat(spectralComponent,obj.nRows, obj.nCols);
            % Remove Inf pixels caused due to zeros in the vignetting image
            obj.calibratedDataCube(~isfinite(obj.calibratedDataCube)) = 0;
            obj.calibratedDataCube = im2uint8(rescale(obj.calibratedDataCube,[0 1]));
            obj.spectralComponent = spectralComponent;
            obj.isCalibrated = true;
        end
        
        function displayCalibratedDataCube(obj)
            colormap gray;
            
            [ha, pos] = tight_subplot(obj.blksize,obj.blksize,[.04 .01],[.01 .04],[.01 .01]);
            %             for ii = 1:6; axes(ha(ii)); plot(randn(10,ii)); end
            %             set(ha(1:4),'XTickLabel',''); set(ha,'YTickLabel','')
            
            for i = 1:obj.blksize % blkrow
                for j = 1:obj.blksize % blkcol
                    %subplot(obj.blksize, obj.blksize, (i-1)*obj.blksize+j);
                    axes(ha((i-1)*obj.blksize+j));
                    imagesc(obj.calibratedDataCube(2:end-1,2:end-1,(i-1)*obj.blksize+j))
                    title(strcat(num2str(obj.wavelengthsRowMajor((i-1)*obj.blksize+j)), ' nm'), 'FontSize', 7, 'FontWeight', 'bold');
                    axis off;
                end
            end
            if obj.exposureTime
                suptitle(['Calibrated Data Cube, Exposure Time: ', num2str(obj.exposureTime), ' ms']);
            end
        end
   
        function convert2ENVI(obj, filename)
            if obj.isCalibrated
                disp('Writing calibrated data cube to file')
                info = enviinfo(obj.calibratedDataCube);
                enviwrite(obj.calibratedDataCube, info, strcat(filename, '.bsq'),strcat(filename, '.hdr'));
            else
                disp('Writing uncalibrated data cube to file')
                info = enviinfo(obj.dataCube);
                enviwrite(obj.dataCube, info, strcat(filename, '.bsq'), strcat(filename, '.hdr'));
            end
        end
        
    end
end

