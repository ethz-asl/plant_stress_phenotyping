function [ exposureTime ] = readExposureTimeMS( bag, iImage )
%UNTITLED6 Summary of this function goes here

exposureBag = select(bag, 'Topic', '/ximea_asl/exposure_time');
exposureMsg = readMessages(exposureBag, iImage);
exposureTime = double(exposureMsg{1}.Data)/1000;
%   Detailed explanation goes here


end

