function  visualizeReprojection(stereoParams, img1, img2, checkerboardSquareSizeMM)
%visualizeReprojection Visualizes reprojection of checkerboard points given calibration params between a pair of cameras
%   Detailed explanation goes here
    
    camParams1 = stereoParams.CameraParameters1;
    camParams2 = stereoParams.CameraParameters2;
    img1 = undistortImage(im2double(img1), camParams1);
    img2 = undistortImage(im2double(img2), camParams2);
    [imagePoints1, boardSize1, imageUsed1] = detectCheckerboardPoints(img1);
    [imagePoints2, boardSize2, imageUsed2] = detectCheckerboardPoints(img2);
    figure; imshow(img1);title('Cam 1 Image');hold on;
    legend('detected corners');
    plot(imagePoints1(:,1), imagePoints1(:,2), 'ro');

    if (imageUsed1 & imageUsed2) & (boardSize1==boardSize2)
       worldPoints = generateCheckerboardPoints(boardSize1, checkerboardSquareSizeMM);
       worldPoints = [worldPoints ones(size(worldPoints,1),1)];
       
        [worldOrientation1,worldLocation1] = estimateWorldCameraPose(imagePoints1,worldPoints,camParams1);
        [rotationMatrix1,translationVector1] = cameraPoseToExtrinsics(worldOrientation1,worldLocation1);
        T_Cam1_W = zeros(4,4);
        T_Cam1_W(1:3,1:3) = rotationMatrix1';
        T_Cam1_W(1:3,4) = translationVector1';
        T_Cam1_W(4,4) = 1;

        % not needed here, just for reference

%         [worldOrientation2,worldLocation2] = estimateWorldCameraPose(imagePoints2,worldPoints,camParams2);
%         [rotationMatrix2,translationVector2] = cameraPoseToExtrinsics(worldOrientation2,worldLocation2);
%         T_Cam2_W = zeros(4,4);
%         T_Cam2_W(1:3,1:3) = rotationMatrix2';
%         T_Cam2_W(1:3,4) = translationVector2';
%         T_Cam2_W(4,4) = 1;

        %T_Cam2_Cam1 = T_Cam2_W/T_Cam1_W; % What does this division mean?
        %T_Cam2_Cam1 = T_Cam2_W * (T_Cam1_W)^(-1) T_Cam1_W == ^{Cam1}T_{W}

    %stereoParams = stereoParameters(camParams1, camParams2, ...
     %   T_Cam2_Cam1(1:3, 1:3)', T_Cam2_Cam1(1:3, 4)');
        T_Cam2_Cam1 = zeros(4,4);
        T_Cam2_Cam1(1:3, 1:3) = stereoParams.RotationOfCamera2';
        T_Cam2_Cam1(1:3,4) = stereoParams.TranslationOfCamera2';
        T_Cam2_Cam1(4,4) = 1;
        T_Cam2_W = T_Cam2_Cam1 * T_Cam1_W;
        rotationMatrix2 = T_Cam2_W(1:3,1:3)';
        translationVector2 = T_Cam2_W(1:3,4)';
        reprojectedPointsCam2 = worldToImage(camParams2, rotationMatrix2, translationVector2, worldPoints, 'ApplyDistortion', false);
        figure; imshow(img2); hold on;
        plot(imagePoints2(:,1), imagePoints2(:,2), 'ro');
        plot(reprojectedPointsCam2(:,1), reprojectedPointsCam2(:,2), 'go');
        legend('detected corners', 'reprojectedCorners');
        title('Cam2 Image');
        hold off
    end
end

