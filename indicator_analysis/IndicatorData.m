classdef IndicatorData < handle
    %INDICATORDATA class that can store a set of indicator data, including
    %labels and names for standardized processing and storing of data.
    
    properties
        Data            % boxes x datasets x Indicators: indicator values.
        Labels          % boxes x Causes: treatment ground truth.
        IndicatorNames  % N_Indicators cell: Name and unit of Nth indicator.
        LabelNames      % N_Causes cell: Name of all causes
        LabelLevels     % N_causes x max_N_Realizations: Names of all cause realizations.
    end
    
    methods
        function obj = IndicatorData(dataIn, namesIn)
            %INDICATORDATA Create an instance of IndicatorData containing
            %the input.
            %   obj = IndicatorData(dataIn, labelsIn, namesIn)
            %   obj:        Newly created IndicatorData.
            %   dataIn:     Initial data (boxes x datasets x Indicators).
            %   namesIn:    N_Indicators cell with names and units of data.
            
            % Create default labels
            obj.Labels = ones(30,3);
            obj.Labels([13:15 19:21 28:30], 1) = 2;
            obj.Labels([1:3 7:12 16:18], 2) = 3;
            obj.Labels([4:6 13:15 19:21], 2) = 2;
            obj.Labels([7:9 25:27], 3) = 2;
            obj.Labels([10:12 19:21], 3) = 3;
            obj.Labels(16:18, 3) = 4;
            
            obj.LabelNames = {'Water', 'Nitrogen', 'Weeds'};
            obj.LabelLevels = {'Sufficient', 'Drying', '',''; 'Low', ...
                'Medium', 'High', ''; 'None', 'Few', 'Many', 'Only'};
            
            % Read in data
            obj.Data = dataIn;
            obj.IndicatorNames = namesIn;      
        end
        
        function data = getdata(obj, preprocessing)
            % GETDATA Apply preprocessing steps to the stored data.
            %   data = preprocessing(obj, steps)
            %   data:   processed values from the Data property.
            %   preprocessing:  char or cell, which processes to apply. 
            %           Supported are N-normalize with healthy boxes, 
            %           S - standard scaling, T - add time index

            % Input
            if nargin == 1
                preprocessing = '';
            end
            
            % Preprocessing
            data = obj.Data;
            if any(strcmpi('N', preprocessing))     % Normalizer
                for i =1:size(data, 3)
                    data(:,:,i) = data(:,:,i)./ ...
                        repmat(mean(data(1:3,:,i)), 30, 1);
                end
            elseif any(strcmpi('S', preprocessing)) % Standard Scaler
                for i =1:size(data, 3)
                    data(:,:,i) = data(:,:,i) - ...
                        repmat(mean(data(:,:,i)), 30, 1);
                    data(:,:,i) = data(:,:,i)./ ...
                        (repmat(var(data(:,:,i)), 30, 1).^0.5);
                end
            end
            if any(strcmpi('T', preprocessing))     % Add time index
                data = cat(3, data, repmat(1:16, 30, 1));
            end            
        end
        function [data, groups] = getdatastring(obj, preprocessing)
            % GETDATASTRING Return data and groups as 1 dimensional shape,
            % applying the preprocessing steps specified in preprocessing.
            %   [data, groups] = getdatasstring(obj, preprocessing)
            %   data:       N_ind x 480 string for every indicator.
            %   groups:     {Water, N, Weeds} as 1x480 labels
            %   preprocessing:  See member function getdata for args.
            
            % Input
            if nargin == 1
                preprocessing = '';
            end
            
            % Data
            data_temp = obj.getdata(preprocessing);
            data = zeros(size(data_temp, 3), 480);
            for i =1:size(data_temp, 3)
                data(i,:) = reshape(data_temp(:,:,i),1,[]);
            end
            
            % Groups (Labels)
            groups = cell(3, 1);
            for i=1:3 % all causes
                groups{i} = obj.Labels(:, i);
                groups{i} = reshape(repmat(groups{i}, 1, 16), 1, []); 
            end
        end
        function [X, Y] = getdatasheet(obj, preprocessing)
            % GETDATASHEET Return data (X) and Labels (Y) as Boxes x
            % (datasets*indicators) sheets, applying the preprocessing 
            % steps specified in preprocessing.
            %   [X, Y] = getdatasheet(obj, preprocessing)
            %   X:       Boxes x(datasets*indicators) data
            %   Y:      Boxes x(datasets*indicators) labels
            %   preprocessing:  See member function getdata for args.
            
             % Input
            if nargin == 1
                preprocessing = '';
            end
            
            % Data
            data = obj.getdata(preprocessing);
            X = reshape(data, [], size(data, 3), 1);
            
            % Labels
            Y = repmat(obj.Labels, 16, 1);
        end
        function indicatorsNew = copy(obj, indices)
           % COPY returns a second instance of the IndicatorData class that 
           % contains only the indicators specified in indices. Leave empty 
           % to copy full object.
           if nargin == 1
               indices = 1:length(obj.IndicatorNames);
           end
           data = obj.Data(:,:,indices);
           names = obj.IndicatorNames(indices);
           indicatorsNew = IndicatorData(data, names);
           indicatorsNew.Labels = obj.Labels;
           indicatorsNew.LabelNames = obj.LabelNames;
           indicatorsNew.LabelLevels = obj.LabelLevels;
           
           
        end
    end
end

