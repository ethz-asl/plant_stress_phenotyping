function [reflectanceFactors] = computereflectancefactors(imageSetRGB, imageSetIR, dataCubes)
%COMPUTEREFLECTANCEFACTORS Computes the reflectance factors for the
%specified imageset. Input either RGB, RGB+IR or RGB+IR+Multispectral.
%   [reflectanceFactors] = computereflectancefactors(imageSetRGB, imageSetIR)
%   reflectanceFactors:     a 31x27 vector containing the factors for every
%                           image in the imageset(i,1) = fRGB, (i,2) = IR,
%                           (i,3:27) = Multispectral channels.
%   imageSetRGB:            cell of RGB imagepaths to estimate reflectance.
%   imageSetIR:             cell of correseponding IR imagepaths.
%   dataCube:               Cell containing the datacubes of corresponding 
%                           multispectral images.
%
%   Averages the recorded pixelvalue for a fixed region of the reflectance
%   plate with known refletance of panelReflectance. If the plate is cluttered with
%   plants (detected in RGB image) the reflectance is estimated from its 
%   neighboring images.

reflectanceFactors = zeros(31,27);
occlusions = false(31,1);
panelReflectance = 0.6;

% Compute RGB and occlusion
for i=1:31
    % Get batch of reflectorplate (fixed position within image)
    imgRGB = imcrop(imread(imageSetRGB{i}), [245 427 120 125]);
    
    % Detect occlusion, otherwise write factor
    if (min(imgRGB(:)) > 100)
        reflectanceFactors(i,1) = panelReflectance / mean(imgRGB(:));
    else
        occlusions(i) = true;
    end
end

% Comput IR
if(nargin >= 2)
    for i=1:31
        % Get batch of reflectorplate (fixed position within image)
        if (~occlusions(i))
            imgIR = imcrop(imread(imageSetIR{i}), [1 195 60 54]);
            reflectanceFactors(i,2) = panelReflectance / mean(imgIR(:));
        end
    end
end

% Compute multispectral
if(nargin == 3)
    for i=1:31
        if (~occlusions(i))
        cubeMS = dataCubes{i};
            for j = 1:25    % Wavelengths
                % Get batch of reflectorplate (fixed position within image)
                imgMS = imcrop(cubeMS(:,:,j), [375 107 28 64]);            
                reflectanceFactors(i,2+j) = panelReflectance / mean(imgMS(:));
            end
        end
    end
end

% Interpolate occluded reflector plates
for i=1:31
    if (reflectanceFactors(i,1) == 0)
        % Find lower neighbor
        indices = 1:i;
        indices(occlusions(1:i,1) == true) = 0;
        if (max(indices) == 0)
            lower = 0;
        else
            lower = reflectanceFactors(max(indices),:);
        end
        
        % Find upper neighbor (should always exist --> box 31)
        indices = i:31;
        indices(occlusions(i:31,1) == true) = 32;
        upper = reflectanceFactors(min(indices),:);
        
        % Compute Interpolation
        if (lower == 0)
            reflectanceFactors(i,:) = upper;
        else
            reflectanceFactors(i,:) = (lower + upper) / 2;
        end
    end
end

end

