function [image_out] = cropboxfromimage(image_in,box_in)
%CROPBOXFROMIMAGE Rotates the input image, then crops a box-rectangle of the
%specified location and size
%   [image_out] = cropboxfromimage(image_in, box_in)
%   image_out:  cropped image
%   image_in:   image where to crop box from
%   box_in:     Array of form [X_min, Y_min, Width, Height, Theta],
%               Values in pixel-coordinates, Theta in degrees.

image_out = imrotate(image_in,box_in(5));
image_out = imcrop(image_out, box_in(1:4));
end

