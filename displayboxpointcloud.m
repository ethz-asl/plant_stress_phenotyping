function [] = displayboxpointcloud(pc)
%displayboxpointcloud Displays the point cloud(pc) of a plant box from a nice
%viewpoint

    pcshow(pc, 'MarkerSize', 200); xlabel('X'); ylabel('Y'); zlabel('Z');view([-2.7627 -14.9326]);
    
end

