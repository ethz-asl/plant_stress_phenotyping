%% Detect boxes in rgb image
% Searches for the inner border of the top of the box by projecting rays
% outward until the border is reached. works quite robust until there are
% too many overlapping leaves.
% For manual update of boxes change manualDetection to true, targetBox to
% desired box number(s) and run script again to select box.
% After detecting all boxes save the 'boxes' variable, which contains 
% the results (boxes(i,:) = [Xmin, Ymin, Width, Height, Theta] for box i).

%% Parameters
% Algorithm Parameters
initialBox = [400, 250, 900, 700];  % Reduce image size, where to detect the box (must contain entire box)
%initialBox = [60, 120, 410, 280];  boxWidth = 70, for image set 2 (from 24.1.,has smaller resolution)
boxWidth = 150 ;       % Width where to seach for box edges, starting from initialBox inwards
thetaRange = -2:0.5:2.5;   % Sweep box orientations
errorTol = 20;          % Outlier rejection distance for error measurement (in most prominent edges fit)
grayMin = 100;          % Minimum Color Value for Thresholding
grayMax = 200;          % Maximum Color Value for Thresholding
N_rays = 300;           % Number of points to find box edge
ray_step = 2;           % Stepwidth to detect box edge
fitMethod = 1;          % 1 - most prominent edges fit (works quite robust 
                        % until ~50% the box boundaries are covered up), 
                        % 2 - maximum size rectangle (gives a shot at  
                        % barely visible boxes)

% Manual box detection
manualDetection = false;    % Set to true to sweep entire folder, AFTERWARDS 
                            % change to false for manual adjustment of certain boxes
targetBox = [18];     % Boxnumber(s), which is/are to be manually modified.
plotThreshold = false;      % Show thresholded images for every step in new figure (not recommended).

%% Code
% Select data folder to work through
if(~manualDetection)
    folderPath = uigetdir(pwd, 'Select the measurement-date-folder');
    imgSet = getimagesfromfolder(folderPath,1);
    boxes = zeros(30,5);    % Result, box(i,:) = 
                            % [Xmin, Ymin, Width, Height, Theta], 
                            % rotation before position extraction
    range = 1:30;
else
    range = targetBox;    
end

% Process images
for i = range
    % Initialize
    detectedBox = zeros(length(thetaRange),5);
    images = cell(length(thetaRange),1);
    error = zeros(length(thetaRange),1);
    
    % Sweep Theta range
    for k = 1:length(thetaRange)
        theta = thetaRange(k);

        % Precut image
        img = cropboxfromimage(imread(imgSet{i}),[initialBox(1:4), theta]);
        startPoint = round([size(img,2), size(img,1)]/2);
        edgePoints = zeros(N_rays,2);

        % Threshold grayish colors
        imageGray = ones(size(img,1), size(img,2));
        for j = 1:3
            imageGray = imageGray & img(:,:,j)>grayMin;
            imageGray = imageGray & img(:,:,j)<grayMax;
        end
        imageGray = imopen(imageGray, ones(7));

        % Get Points from inside out until on a border
        for j = 1:N_rays
            r = 0;
            while(true)
                r = r + ray_step;
                X = startPoint + round(r*[cos(2*pi()*j/N_rays), ...
                    sin(2*pi()*j/N_rays)]);
                if(X(2) < 1 || X(2) > size(imageGray,1) || ...
                        X(1) < 1 || X(1) > size(imageGray,2))
                    break
                end
                if(imageGray(X(2),X(1)))
                    edgePoints(j,:) = X;
                    break;
                end
            end
        end

        %Get Size
        % Left
        if(fitMethod ==1)
            points = edgePoints(edgePoints(:,1)<boxWidth,1);
            [F, XI] = ksdensity(points);        
            [~, ind] = max(F);
            a = round(XI(ind));
        else
            points = edgePoints(edgePoints(:,2)>boxWidth,:);
            points = points(points(:,2)<initialBox(4)-boxWidth,:);
            points = points(points(:,1)<boxWidth,1);
            a = max(points);
            if(isempty(a))
                a=10;
            end
        end

        % Right
        if(fitMethod ==1)  
            points = edgePoints(edgePoints(:,1)>initialBox(3)-boxWidth,1);
            [F, XI] = ksdensity(points);
            [~, ind] = max(F);
            c = round(XI(ind)-a);
        else
            points = edgePoints(edgePoints(:,2)>boxWidth,:);
            points = points(points(:,2)<initialBox(4)-boxWidth,:);
            points = points(points(:,1)>initialBox(3)-boxWidth,1);
            c = min(points)-a;
            if(isempty(c))
                c = size(imageGray,2)-a-10;
            end
        end

        % Top
        if(fitMethod ==1)
            points = edgePoints(edgePoints(:,2)<boxWidth,2);
            [F, XI] = ksdensity(points);            
            [~, ind] = max(F);
            b = round(XI(ind));
        else
            points = edgePoints(edgePoints(:,1)>boxWidth,:);
            points = points(points(:,1)<initialBox(3)-boxWidth,:);
            points = points(points(:,2)<boxWidth,2);
            b = max(points);
            if(isempty(b))
                b = 10;
            end
        end

        % Bottom
        if(fitMethod ==1)
            points = edgePoints(edgePoints(:,2)>initialBox(4)-boxWidth,2);
            [F, XI] = ksdensity(points);  
            [~, ind] = max(F);  
            d = round(XI(ind))-b;     
        else
            points = edgePoints(edgePoints(:,1)>boxWidth,:);
            points = points(points(:,1)<initialBox(3)-boxWidth,:);
            points = points(points(:,2)>initialBox(4)-boxWidth,2);
            d = min(points)-b;
            if(isempty(d))
                d = size(imageGray,1)-b-10;
            end
        end

        % Compute Error
        if(fitMethod ==1)  
            tempErr = abs(edgePoints(:,1)-a);  %Left
            error(k) = error(k) + sum(tempErr(tempErr<errorTol));
            tempErr = abs(edgePoints(:,1)-c-a);    %Right
            error(k) = error(k) + sum(tempErr(tempErr<errorTol));
            tempErr = abs(edgePoints(:,2)-b);  %Top
            error(k) = error(k) + sum(tempErr(tempErr<errorTol));
            tempErr = abs(edgePoints(:,2)-d-b);  %Top
            error(k) = error(k) + sum(tempErr(tempErr<errorTol));
        else
            error(k) = -1*c*d;      %rectangle size
        end
        
        % Store intermediate result
        detectedBox(k,:) = [a, b, c, d, theta];
        images{k} = img;

        % Plot Threshold and detection points (test)
        if (plotThreshold)
            figure;
            imshow(imageGray); hold on
            rectangle('Position',detectedBox(k,1:4),'EdgeColor','r', ...
                'LineWidth',3);
            scatter(edgePoints(:,1),edgePoints(:,2));
            title(['Error: ' num2str(error(k))]);
        end
 
    end
    
    % Show images for double checking
    n = length(thetaRange);
    if (manualDetection)    % => manual selection
        % Show range of thetas for manual selection
        figure('units','normalized','outerposition',[0 0 1 1]);
        for j =1:n
            subplot(2,ceil(n/2),j)
            imshow(images{j}); hold on
            for k = 1:5
                line([1,size(images{j},2)], ...
                    round([1,1]*size(images{j},1)*k/6),'Color','yellow');
            end
            title(['Theta: ' num2str(thetaRange(j))]);
        end
        thetaSelected = input('Enter best fitting theta:');
        
        %Get EdgePoints from user
        fig = figure;        
        thetaInd = 1:length(thetaRange);
        imshow(images{thetaInd(thetaRange==thetaSelected)});
        axis equal, axis off; hold on;
        title(['Place box No. ' num2str(i) ' and press Enter']);
        rectSelected = imrect;
        while true
            w = waitforbuttonpress;
            if w==1
                if(get(gcf,'currentcharacter')==13)
                    break;
                end
            end
        end
        
        % Write result
        boxes(i,:) = [getPosition(rectSelected) thetaSelected]';
        boxes(i,1:2) = boxes(i,1:2)+initialBox(1:2);
        close(gcf);
    else
        % Plot best solution to double check from user 
        [~, j] = min(error); 
        figure;      
        imshow(images{j}); hold on    
        title(['Box: ' num2str(i) ', Theta: ' num2str(thetaRange(j)) ...
            ', Press enter to confirm box No. ' num2str(i)]);
        rectSelected = imrect(gca, detectedBox(j,1:4));
        setColor(rectSelected,'red');
        while true
            w = waitforbuttonpress;
            if w==1
                if(get(gcf,'currentcharacter')==13)
                    break;
                end
            end
        end
        
        % Write result
        boxes(i,:) = [getPosition(rectSelected), thetaRange(j)]';
        boxes(i,1:2) = boxes(i,1:2)+initialBox(1:2);
        close(gcf);
    end 
end