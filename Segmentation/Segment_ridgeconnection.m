function [oBW, oGray, oSteps] = Segment_ridgeconnection(...
    aI,...
    aAlpha,...
    aBeta,...
    aSmooth,...
    aScaling,...
    aThreshold,...
    aMaxDist,...
    aMinVar,...
    aMinArea)
% Segments HeLa cells in DIC microscopy using ridge detection.
%
% This segmentation algorithm was designed specifically for the
% DIC-C2DH-HeLa dataset of the ISBI 2014 Cell Tracking Challenge. The
% following algorithm description is taken from the method description that
% we submitted for the challenge.
%
% The algorithm was inspired by the algorithm used to segment muscle fibers
% in [1]. We first apply a ridge detection filter similar to the filter
% described in [1], to highlight the boundaries between the cells. The
% ridge detection is done by smoothing the image with Gaussian kernels with
% standard deviations of 5, 6, 7, 8, 9, and 10 pixels, and computing the
% Hessian at each pixel of the 6 resulting images. The ridge image nu at
% each scale is then computed from the eigenvalues lambda1 and lambda2,
% where lambda1 < lambda2, of the corresponding Hessians as
%
% nu = 0                                     if lambda1 > 0
%      exp(-R/gamma^2)*(1-exp(-S/beta^2})    otherwise,
%
% where R = |lambda2|/|lambda1| and S = lambda1^2 + lambda2^2. The final
% ridge image is obtained by taking the pixel-wise maximum of the nus over
% all standard deviations, and then smoothing using a Gaussian kernel. Once
% we have the ridge image, we transform the intensities using an inverse
% hyperbolic sine, to enhance dim ridges, and divide by the mean intensity
% of the transformed image. Then we threshold the ridge image and
% skeletonize the resulting binary mask to extract cell boundaries. To
% determine which of the resulting regions are cells and which are
% background, we compute a local variance image where each pixel value
% represents the sample variance in a 9 x 9 pixel neighborhood of the
% corresponding pixel in the original image. Regions with an average local
% variance above a threshold are considered to be cell regions. To fill in
% gaps in the skeletonized boundaries, we detect all end points of the
% skeleton and connect pairs of end-points by straight lines of pixels.
% End-points are connected if they are close enough together, and if the
% added line cuts through a single segment, without generating a fragment
% smaller than a size threshold. If one of the new regions would become a
% background region, the size threshold is instead set to 200 pixels, as
% the operation would not split a cell in two. After joining end-points, we
% remove cracks in regions by erasing all boundary pixels which were
% bordering a single region. Then we merge the background regions and the
% border pixels into a single background region. Finally we merge cell
% regions smaller than the size threshold into adjacent cell regions until
% all cell regions are either above the size threshold or surrounded by
% background pixels.
%
% Inputs:
% aI - Double image with values between 0 and 255.
% aAlpha - Scaling of R in the formula for nu.
% aBeta - Scaling of S in the formula for nu.
% aSmooth - Standard deviation of Gaussian kernel applied after the maximum
%           over different nus has been taken.
% aScaling - Scaling factor which multiplies the ridge image before it is
%            passed through the inverse hyperbolic sine function.
% aThreshold - Threshold applied to the ridge image. This can be decreased
%              to find fainter cell borders.
% aMaxDist - Maximum distance between two joined end-points.
% aMinVar - Threshold on the local variance, below which regions are
%           considered to belong to the background.
% aMinArea - Area threshold for the cells. Larger regions can be split by
%            joining end-points and smaller regions will be merged into
%            larger regions.
%
% Outputs:
% oBW - Binary segmentation mask.
% oGray - Ridge image prior to thresholding.
% oSteps - Struct with images from intermediate segmentation steps. The
%          struct has the following fields:
%    numax - Ridge image prior to thresholding.
%    ridges - Ridges after thresholding.
%    skeleton - Cell boundaries created by skeletonizing the ridges.
%    connected - Cell boundaries after connecting end-points.
%    nocracks - Cell boundaries after removing cracks (pixels which border
%               a single cell region).
%    foreground - Binary image with cell regions before small regions have
%                 been merged.
%    mask - The same as oBW.
%
% [1] Sertel, O.; Dogdas, B.; Chiu, C. S. & Gurcan, M. N. Microscopic image
%     analysis for quantitative characterization of muscle fiber type
%     composition Comput. Med. Imaging Graph., Elsevier, 2011, 35, 616-628
%
% See also:
% Segment_generic

im = aI/255;

% Compute a ridge image.
sigma = 5:10;
nu = zeros([size(im) length(sigma)]);
for i = 1:length(sigma)
    ims = SmoothComp(im,sigma(i));
    
    [dx, dy] = gradient(ims);
    [dxx, dxy] = gradient(dx);
    [~, dyy] = gradient(dy);
    
    % The following code agrees with the definitions in [1].
    %
    % tmp2 = 0.5*(dxx+dyy) + sqrt(0.25*(dxx-dyy).^2+dxy.^2);
    % tmp1 = 0.5*(dxx+dyy) - sqrt(0.25*(dxx-dyy).^2+dxy.^2);
    % lambda1 = zeros(size(tmp1));
    % lambda2 = zeros(size(tmp2));
    % lambda1(abs(tmp1) > abs(tmp2)) = tmp1(abs(tmp1) > abs(tmp2));
    % lambda2(abs(tmp1) > abs(tmp2)) = tmp2(abs(tmp1) > abs(tmp2));
    % lambda1(abs(tmp1) <= abs(tmp2)) = tmp2(abs(tmp1) <= abs(tmp2));
    % lambda2(abs(tmp1) <= abs(tmp2)) = tmp1(abs(tmp1) <= abs(tmp2));
    % R = lambda2 ./ lambda1;
    
    % Largest eigenvalue.
    lambda2 = 0.5*(dxx+dyy) + sqrt(0.25*(dxx-dyy).^2+dxy.^2);
    % Smallest eigenvalue.
    lambda1 = 0.5*(dxx+dyy) - sqrt(0.25*(dxx-dyy).^2+dxy.^2);
    
    % Ratio between curvatures in different directions.
    R = abs(lambda2 ./ lambda1);
    % Total amount of curvature.
    S = lambda1.^2 + lambda2.^2;
    
    nui = exp(-R/aAlpha^2).*(1-exp(-S/aBeta^2));
    nui(lambda1 > 0) = 0;  % We only want bright ridges.
    nui = nui / (max(nui(:))+eps(0));
    
    nu(:,:,i) = nui;
end
% Take the maximum ridgeness over all scales.
numax = max(nu,[],3);
% Remove artifacts.
numax = SmoothComp(numax, aSmooth);
% Transform the ridge image using an inverse hyperbolic sine, which is
% linear for small values and logarithmic for larger values.
numax = asinh(numax*aScaling);
oSteps.numax = numax;
oGray = numax;

oSteps.ridges = double(numax>mean(numax(:))*aThreshold);

% Threshold and skeletonize the ridges.
numax = double(bwmorph(numax>mean(numax(:))*aThreshold, 'skel', Inf));
oSteps.skeleton = numax;

% Detect end-points (leaves) of the skeleton.
numax_filter = filter2(ones(3),numax);
leaves = numax_filter == 2 & numax == 1;
[leaves_y, leaves_x] = find(leaves);

% Compute distances between all pairs of skeleton end-points.
N = length(leaves_y);
dists = nan(N*(N-1),1);
from = nan(N*(N-1),1);
to = nan(N*(N-1),1);
index = 1;
for i = 1:N
    for j = i+1:N
        from(index) = i;
        to(index) = j;
        dists(index) = sqrt(...
            (leaves_x(j)-leaves_x(i))^2 +...
            (leaves_y(j)-leaves_y(i))^2);
        index = index + 1;
    end
end
% Make a list of end-point pairs, sorted by the distances.
[dists, order] = sort(dists);
from = from(order);
to = to(order);

% Local variance image used to detect background regions.
varim = LocalVariance(im, 4, 'Shape', 'square');

% Connect end-points of the ridge skeleton.
borders = numax;
labels = bwlabel(~borders, 4);  % Labels of segmented regions.
borderLabels = bwlabel(borders);  % Labels of skeleton components.
matched = false(N,1);  % Keeps track of matched ridge ends.
for i = 1:length(dists)
    if dists(i) < aMaxDist && ~matched(from(i)) && ~matched(to(i))
        % Find pixels necessary to connect two ridge ends.
        [px, py] = PixelsBetween(...
            leaves_x(from(i)),...
            leaves_y(from(i)),...
            leaves_x(to(i)),...
            leaves_y(to(i)));
        indices = sub2ind(size(borders), py, px);
        
        if isempty(indices)
            % The original ridge segment has only two pixels.
            continue
        end
        
        % Check that the bridge cuts a single segmented region.
        segmentIndex = labels(indices);
        segmentIndex = unique(segmentIndex);
        if length(segmentIndex) > 1 || segmentIndex == 0
            continue
        end
        
        % Find the indices of the ridge parts that the two end-points
        % belong to. If the end-points belong to different parts, the
        % end-points can be joined without running the risk of cutting
        % segments into too small fragments.
        borderIndexFrom = borderLabels(leaves_y(from(i)), leaves_x(from(i)));
        borderIndexTo = borderLabels(leaves_y(to(i)), leaves_x(to(i)));
        
        % Check that the bridge does not cut segments into too small
        % fragments.
        if borderIndexTo == borderIndexFrom
            segmentImage = labels == segmentIndex;
            segmentImage(indices) = false;
            segmentLabels = bwlabel(segmentImage, 4);
            area1 = sum(segmentLabels(:) == 1);
            area2 = sum(segmentLabels(:) == 2);
            
            % Local variance averaged over the regions.
            var1 = mean(varim(segmentLabels == 1));
            var2 = mean(varim(segmentLabels == 2));
            
            % The first condition checks that a cell segment is not broken
            % into too small fragments. The second condition allows
            % breaking into fragments of down to 200 pixels if the bridge
            % cuts off a fragment from the background.
            if ~(min(area1,area2) >= aMinArea) &&...
                    ~((var1 < aMinVar || var2 < aMinVar) && min(area1,area2) >= 200)
                continue
            end
        end
        
        % Close the gap between the ridge end-points, using the bridge
        % pixels.
        borders(indices) = 1;
        labels = bwlabel(~borders, 4);
        borderLabels = bwlabel(borders);
        matched(from(i)) = true;
        matched(to(i)) = true;
    end
end
oSteps.connected = borders;

% Remove cracks in segments. If a ridge pixel borders a single segment, it
% is considered to be a crack pixel. At the same time, an adjacency matrix
% is built for the segments.
[py, px] = find(labels == 0);
[m, n] = size(labels);
adjacency = zeros(max(labels(:)));
wallpixelsx = cell(max(labels(:)), max(labels(:)));
wallpixelsy = cell(max(labels(:)), max(labels(:)));
for i = 1:length(px)
    square = labels(...
        max(py(i)-1,1):min(py(i)+1,m),...
        max(px(i)-1,1):min(px(i)+1,n));
    neighbors = unique(square(square~=0));
    if length(neighbors) == 1
        % Fill the crack.
        labels(py(i),px(i)) = neighbors;
    elseif length(neighbors) == 2
        % Note adjacency.
        adjacency(neighbors(1),neighbors(2)) =...
            adjacency(neighbors(1),neighbors(2)) + 1;
        adjacency(neighbors(2),neighbors(1)) =...
            adjacency(neighbors(2),neighbors(1)) + 1;
        n1 = min(neighbors(1),neighbors(2));
        n2 = max(neighbors(1),neighbors(2));
        wallpixelsx{n1,n2} = [wallpixelsx{n1,n2} px(i)];
        wallpixelsy{n1,n2} = [wallpixelsy{n1,n2} py(i)];
    end
end

oSteps.nocracks = double(labels==0);

% Remove background segments (segments with low local variation).
removed = false(max(labels(:)),1);
numRemoved = 0;
for i = 1:max(labels(:))
    indices = labels==i;
    if mean(varim(indices)) < aMinVar
        labels(indices) = 0;
        removed(i) = true;
        numRemoved = numRemoved + 1;
    else
        labels(indices) = i-numRemoved;
    end
end
adjacency(removed,:) = [];
adjacency(:,removed) = [];
wallpixelsx(removed,:) = [];
wallpixelsx(:,removed) = [];
wallpixelsy(removed,:) = [];
wallpixelsy(:,removed) = [];

oSteps.foreground = labels > 0;

% Compute the areas of the blobs and remove regions that are large enough
% from the rows of the adjacency matrix.
areas = zeros(max(labels(:)),1);
for i = 1:max(labels(:))
    areas(i) = sum(labels(:)==i);
    if areas(i) >= aMinArea
        adjacency(i,:) = 0;
    end
end

% Merge small regions into adjacent regions of any size until there are no
% segments below the size threshold, or until there are no regions left to
% merge to. The rows of the adjacency matrix denote segments that should be
% merged into other regions. The rows corresponding to regions that are
% above the area threshold have only zeros. The columns corresponding to
% regions that are above the area threshold have adjacency values, so that
% smaller regions can be merged into them. Regions are merged into other
% regions based on how much of the region border is adjacent to the other
% region. The regions with the largest portion of the boundary in contact
% with another region are merged first.
while any(adjacency(:) > 0)
    % Normalize the adjacency by the boundary length.
    sumAdjacency = sum(adjacency,2);
    normAdjacency = adjacency ./ repmat(sumAdjacency,1,size(adjacency,2));
    
    % Find the region with the largest normalized adjacency.
    [~, minIndex] = max(normAdjacency(:));
    [donor, receiver] = ind2sub(size(normAdjacency),minIndex);
    
    % Merge the blobs.
    labels(labels==donor) = receiver;
    n1 = min(donor,receiver);
    n2 = max(donor,receiver);
    labels(sub2ind(size(labels),...
        wallpixelsy{n1,n2},...
        wallpixelsx{n1,n2})) = receiver;
    % TODO: Remove corners.
    
    % Update the adjacency matrix.
    adjacency(receiver,:) = adjacency(receiver,:) + adjacency(donor,:);
    adjacency(:,receiver) = adjacency(:,receiver) + adjacency(:,donor);
    adjacency(receiver,receiver) = 0;
    adjacency(donor,:) = 0;
    adjacency(:,donor) = 0;
    areas(receiver) = areas(receiver) + areas(donor);
    if areas(receiver) >= aMinArea
        adjacency(receiver,:) = 0;
    end
    
    % Update wall pixels between segments.
    for i = 1:size(wallpixelsx,1)
        if i == receiver
            continue
        end
        n1d = min(donor,i);
        n2d = max(donor,i);
        n1r = min(receiver,i);
        n2r = max(receiver,i);
        
        wallpixelsx{n1r,n2r} = [wallpixelsx{n1r,n2r} wallpixelsx{n1d,n2d}];
        wallpixelsy{n1r,n2r} = [wallpixelsy{n1r,n2r} wallpixelsy{n1d,n2d}];
    end
end

oBW = labels > 0;
oBW = imfill(oBW, 8, 'holes');
oSteps.mask = oBW;
end