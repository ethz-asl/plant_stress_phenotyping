function [stereoParams] = calibrateExtrinsicsCaltag(camParams1, camParams2, img1, img2, caltagData, visualizeRepro)
%CALIBRATEEXTRINSICSCALTAG Uses camera intrinsic parameters and (synchronous)images
%of a static scene containing a caltag marker from two cameras to estimate
%their extrinsic transform

% Parse input
if nargin == 5
    visualizeRepro = false;
end

% Preprocess image 1
undistortedImg1 = undistortImage(img1, camParams1);
[wPt1, iPt1] = caltag(undistortedImg1, caltagData, false);
if(size(wPt1,1)==0)
    error('No caltag points detected in Cam2 image')
end
worldPoints1 = [wPt1(:,2) wPt1(:,1)] * 25.4; % swap X and Y to make compatible with MATLAB notation
worldPoints1(:,3) = 1;
imagePoints1 = [iPt1(:,2) iPt1(:,1)];

if visualizeRepro
    fig1 = figure; imshow(undistortedImg1); hold on;
    plot(imagePoints1(:,1), imagePoints1(:,2), 'ro');
    legend('detected corners');
    title('Undistorted Cam1 Image');
    hold off;
    drawnow;
end

% Preprocess image 2
undistortedImg2 = undistortImage(img2, camParams2);
[wPt2, iPt2] = caltag(undistortedImg2, caltagData, false);
if(size(wPt2,1)==0)
    error('No caltag points detected in Cam2 image')
end
worldPoints2 = [wPt2(:,2) wPt2(:,1)] * 25.4; % swap X and Y to make compatible with MATLAB notation
worldPoints2(:,3) = 1;
imagePoints2 = [iPt2(:,2) iPt2(:,1)];



% Use caltag for calibration
[worldOrientation1,worldLocation1] = estimateWorldCameraPose(imagePoints1,worldPoints1,camParams1);
[rotationMatrix1,translationVector1] = cameraPoseToExtrinsics(worldOrientation1,worldLocation1);
T_Cam1_W = zeros(4,4);
T_Cam1_W(1:3,1:3) = rotationMatrix1';
T_Cam1_W(1:3,4) = translationVector1';
T_Cam1_W(4,4) = 1;
 
[worldOrientation2,worldLocation2] = estimateWorldCameraPose(imagePoints2,worldPoints2,camParams2);
[rotationMatrix2,translationVector2] = cameraPoseToExtrinsics(worldOrientation2,worldLocation2);
T_Cam2_W = zeros(4,4);
T_Cam2_W(1:3,1:3) = rotationMatrix2';
T_Cam2_W(1:3,4) = translationVector2';
T_Cam2_W(4,4) = 1;

T_Cam2_Cam1 = T_Cam2_W/T_Cam1_W;

stereoParams = stereoParameters(camParams1, camParams2, ...
    T_Cam2_Cam1(1:3, 1:3)', T_Cam2_Cam1(1:3, 4)');

if visualizeRepro
    reprojectedPointsCam2 = worldToImage(camParams2, rotationMatrix2, translationVector2, worldPoints1, 'ApplyDistortion', false);
    fig2 = figure; imshow(undistortedImg2); hold on;
    plot(imagePoints2(:,1), imagePoints2(:,2), 'ro');
    plot(reprojectedPointsCam2(:,1), reprojectedPointsCam2(:,2), 'go');
    legend('detected corners', 'reprojectedCorners');
    title('Undistorted Cam2 Image');
    hold off
end
end

