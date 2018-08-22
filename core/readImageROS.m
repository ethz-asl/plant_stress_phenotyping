function [ image ] = readImageROS( bag, topic, iImage)
%readImage Reads and returns a grayscale/color image froma rosbag
%   Detailed explanation goes here

%% Create selections for images and exposure times
imgBag = select(bag, 'Topic', topic);

%% read image
imgMsg = readMessages(imgBag, iImage);
image = readImage(imgMsg{1});

end

