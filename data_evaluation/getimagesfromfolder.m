function imagePaths = getimagesfromfolder(folderPath, imageType)
%GETIMAGESETFROMFOLDER Retrieves 31 images of given image type from the
%specified measurement date folder.
%   [imageSetReturn] = getimagesetfromfolder(folderPath,imageType) 
%   imagePaths: 31x1 cell, where the i-th entry is the path to box number i.
%   folderPath: the path to the xxxx_greenhouse_measurements folder
%   imageType: int 1-4 (1 - rgb, 2 - ir1, 3 - ir2, 4 - multispec)
%

    % Presets
    typeString = {'rgb','ir1', ...
            'ir2','multispec'};
    imageNumbers = 1:31;
    imagePaths = cell(31,1);

    % Build image set
    for i=imageNumbers
        imagePaths{i} = fullfile(folderPath, typeString{imageType}, ...
            [num2str(i) '.png']);   
    end
end

