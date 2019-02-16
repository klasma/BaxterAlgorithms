function oLabels = RemoveWatershedRidges(aLabels, aRidges, aLandscape)
% Assigns watershed ridges to adjacent watersheds in a watershed transform.
%
% When two cells are in close contact with each other, they often need to
% be separated using a watershed transform. Given that the cells are in
% contact with each other, it does however not make sense to have watershed
% ridge voxels (background voxels) separating the two cell regions. The
% function works in both 2D and 3D.
%
% This function will assign the ridge voxels to one of the the adjacent
% regions. The background region is also considered a region for simplicity
% of implementation. Voxels will be assigned to the region which has the
% closest voxel value in an adjacent voxel. The adjacency is defined based
% on an 8-neighborhood in 2D and a 27-neighborhood in 3D. The ridge voxels
% are processed in order of decreasing voxel values.
%
% Inputs:
% aLabels - Label image where the background is 0 and the watershed voxels
%           are labeled with the index of the watershed.
% aRidges - Binary image where watershed ridge voxels are 1.
% aLandscape - The image used to compute the watershed transform. The
%              watersheds have high values in the centers and low values at
%              the edges. This is inverted compared to the algorithm
%              description where a landscape is submerged in water, but
%              makes sense as the input images are usually distance
%              transforms and intensity images.
%
% Outputs:
% oLabels - Modified label image, where all ridge voxels have been assigned
%           to adjacent watersheds.
%
% See also:
% WatershedLabels, Segment_generic, Segment_generic3D

oLabels = aLabels;

% Find indices of ridge voxels and order them in decreasing order based on
% the voxel values in the input image to the watershed transform.
indices = find(aRidges);
values = aLandscape(indices);
[~, order] = sort(values, 'descend');
indices = indices(order);

% Go through the ridge voxels one at a time.
for i = 1:length(indices)
    [y, x, z] = ind2sub(size(oLabels), indices(i));
    
    % Bounding box defining the neighborhood around the ridge voxel.
    xmin = max(x-1,1);
    xmax = min(x+1,size(oLabels,2));
    ymin = max(y-1,1);
    ymax = min(y+1,size(oLabels,1));
    zmin = max(z-1,1);
    zmax = min(z+1,size(oLabels,3));
    
    % x-, y-, and z- coordinates of neighbor voxels.
    [neighborX, neighborY, neighborZ] =...
        meshgrid(xmin:xmax, ymin:ymax, zmin:zmax);
    % Indices of neighbor voxels.
    neighborIndices = sub2ind(size(oLabels),...
        neighborY(:), neighborX(:), neighborZ(:));
    
    % Pick out the indices which correspond to label voxels.
    neighborIndices = neighborIndices(~aRidges(neighborIndices));
    if isempty(neighborIndices)
        % Ridge pixels without adjacent cells are assigned to the
        % background.
        oLabels(indices(i)) = 0;
        aRidges(indices(i)) = false;
        continue
    end
    
    % Get labels and voxel values of the neighboring label voxels.
    neighborLabels = oLabels(neighborIndices);
    neighborLandscape = aLandscape(neighborIndices);
    
    % Find the neighbor which is closest in value to the ridge voxel.
    [~, bestNeighbor] = max(neighborLandscape);
    oLabels(indices(i)) = neighborLabels(bestNeighbor);
    aRidges(indices(i)) = false;
end
end