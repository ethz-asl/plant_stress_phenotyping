function imageSetReturn = getimagesetfromfolder(folderPath,imageType)
%GETIMAGESETFROMFOLDER Retrieves 31 images of given image type from the
%specified folder.
%   [imageSetReturn] = getimagesetfromfolder(folderPath,imageType) 
%   imageSetReturn: Set containing 31 images where the image number 
%   corresponds to the box number.
%   folderPath: the path to the xxxx_greenhouse_measurements folder
%   imageType: int 1-5 (1 - RGB, 2 - fisheye, 3 - IR, 4 - IR2, 5 - ximea)
%
%   Assumptions: There exists a "box_weights.csv" file in the target folder,
%   which contains box numbers in column 1 and corresponding image numbers
%   in column 3. Default image numbers are their box numbers. The
%   subfolders are labelled as under "Presets", the image names are "<their
%   number>.png".

% Presets
typeString = {'camera_color_image_raw','camera_fisheye_image_raw', ...
        'camera_ir_image_raw','camera_ir2_image_raw','ximea_asl_image_raw'};
imageNumbers = 1:31;
imageLocation = cell(31,1);

% Retrieve image numbers from box_weights.csv
boxWeightsCSV = readtable([folderPath '\box_weights.csv'], ...
    'ReadVariableNames',false);
for i=1:height(boxWeightsCSV)       
    boxNoTable = boxWeightsCSV{i,1};
    if (isnumeric(boxNoTable))
        boxNo = boxNoTable;
    else
        boxNo = str2num(boxNoTable{1});
    end
    if (~isempty(boxNo) && ~isnan(boxNo))       
        if (boxNo > 0 && boxNo < 32)
            imgNoTable = boxWeightsCSV{i,3};
            if (isnumeric(imgNoTable))
                imgNo = imgNoTable;
            else
                imgNo = str2num(imgNoTable{1});
            end
            if (~isempty(imgNo) && ~isnan(imgNo))
                imageNumbers(boxNo) = imgNo;
                %disp(imgNoTable)
            end
        end
    end   
end


% Build image set
for i=1:31
    imageLocation{i} = strcat(folderPath,'\',typeString{imageType}, '\', ...
        num2str(imageNumbers(i)),'.png');   
end
%disp(imageLocation)
imageSetReturn = imageSet(imageLocation);
end

