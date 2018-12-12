function [oBlobs, oBw, oGray, oImages] = Segment_template(...
    aImData,...
    aFrame,...
    aI,...
    aMinArea,...
    aMaxArea,...
    aTMSegTemplate,...
    aCorrThreshold,...
    aCovThreshold,...
    aMinSeparation,...
    aComplementAlg,...
    aComplementErode,...
    aComplementOpen,...
    varargin)
% Segments a gray scale image by correlating it with a template.
%
% The template is resized to 5 different sizes to allow the objects to be
% of different sizes. The template has to be a square region and the width
% has to be an odd number. The cells are normally detected by finding local
% maxima in a correlation coefficient image. The correlation coefficient
% image is a maximum intensity projection of the correlation coefficient
% images for templates of different sizes. The radii of the cells are found
% as the radii which have the maximum correlation coefficients for the
% local maximum pixels. Only local maxima which are above thresholds on the
% correlation coefficient and the covariance are included in the output. If
% the correlation coefficient threshold is set to 0, that threshold is not
% used, and the cells are instead detected in a maximum intensity
% projection of covariance images. The function outputs blobs instead of a
% binary mask, as there can be more than one cell in each connected
% component of the mask. This segmentation algorithm works best on round
% cells.
%
% Inputs:
% aImData - ImageData object associated with the image sequence.
% aFrame - Index of the frame to be segmented.
% aI - Image to segment.
% aMinArea - Minimum area of segmented cells in pixels.
% aMaxArea - Maximum area of segmented cells in pixels.
% aTMSegTemplate - Name of the mat-file where the template is saved.
% aCorrThreshold - Threshold that defines how high the correlation
%                  coefficient between the image and the template has to be
%                  for a cell to be detected.
% aCovThreshold - Threshold that defines how high the covariance between
%                 the image and the template has to be for a cell to be
%                 detected.
% aMinSeparation - Minimum separation between cell centers in pixels.
% aComplementAlg - Name of a complementary segmentation algorithm which is
%                  used to detect cells in regions where no cells were
%                  detected using template matching. This can be used to
%                  detect cells with an irregular appearance.
%                  Segment_localvariance can be used for transmission
%                  microscopy images.
% aComplementErode - Radius of a structuring element used for erosion of
%                    the binary segmentation mask created by the
%                    complementary segmentation algorithm. Set this input
%                    to 0 if you do not want to use erosion.
% aComplementOpen - Radius of a structuring element used for morphological
%                   opening of the binary segmentation mask created by the
%                   complementary segmentation algorithm. Set this input to
%                   0 if you do not want to use erosion.
%
% Property/Value inputs:
%
% Inputs for segmentation of a sub-image. When these inputs are given, the
% input argument aI has to be a cropped image. These inputs are only used
% to make the complementary segmentation algorithm create an output of the
% right size.
%
% X1 - First pixel in x-dimension of sub-image to be segmented.
% X2 - Last pixel in x-dimension of sub-image to be segmented.
% Y1 - First pixel in y-dimension of sub-image to be segmented.
% Y2 - Last pixel in y-dimension of sub-image to be segmented.
%
% Outputs:
% oBlobs - Array of Blob objects with the segmented regions.
% oBw - Binary segmentation mask with all segmented regions.
% oGray - The maximum intensity projection used for detection of cells.
% oImages - Struct with intermediate processing results. The struct has the
%           field maxMatch which is the maximum intensity projection used
%           for detection of cells.
%
% TODO:
% Sub-pixel x- and y-coordinates.
% Sub-pixel radii.
% Make parameters for what radii to try.
% Allow multiple templates.

% Rescale the image to be approximately between 0 and 1.
aI = aI/255;

% Remove global and local mean.
Me = 30;
B = -1/((2*Me+1)^2)*ones(2*Me+1,2*Me+1);
B(Me+1,Me+1) = B(Me+1:Me+1)+1;
aI = aI-mean(aI(:));
aI = conv2(aI,B,'same');

% Load the template.
templatePath = FindFile('Templates', aTMSegTemplate);
tmp = load(templatePath);
template = tmp.template;

% Flip the template, so that the convolution slides the un-flipped template
% across the image.
% template = rot90(template,2);

% The template has a one pixel border around it to allow interpolation.
d = size(template,1)-2;  % Width of template without border.
[X, Y] = meshgrid(0:d+1,0:d+1);  % Coordinates of pixels in template.

% 3D arrays with covariances and correlations. The third dimension is for
% different template sizes.
corrs = zeros(size(aI,1),size(aI,2),5);
covars = zeros(size(aI,1),size(aI,2),5);
ns = d-4 : 2 : d+4;  % The template widths that will be used.
radii = (ns-3)/2;  % Cell radii corresponding to the widths.
for i = 1:length(ns)
    xi = 0.5 + (0.5*d/ns(i) : d/ns(i) : (ns(i)-0.5)*d/ns(i));
    % Coordinates of pixels in resized template.
    [XI, YI] = meshgrid(xi,xi);
    % Resize template.
    templateN = interp2(X,Y,template,XI,YI);
    % Normalize template to have zero mean.
    templateN = templateN - mean(templateN(:));
    % Normalize template to have a standard deviation of 1.
    templateN = templateN / std(templateN(:));
    
    m = size(templateN,1);
    
    locVar = LocalVariance(aI, floor(m/2));
    
    covars(:,:,i) = conv2(aI, templateN, 'same') / (m^2 - 1); % Covariance.
    corrs(:,:,i) = covars(:,:,i) ./ sqrt(locVar); % Correlation coefficient.
end

% Create maximum intensity projections to detect cells in and to use as
% detection thresholds.
[maxCovar, maxCovarIndex] = max(covars,[],3);  % Best radius for every pixel.
[maxCorr, maxCorrIndex] = max(corrs,[],3);  % Best radius for every pixel.
if aCorrThreshold > 0
    % If a threshold is defined for the correlation coefficient, the
    % correlation image is used to detect cells and determine their radii.
    % Then, the covariance is only used as a criteria to reject cells
    % detected using the correlation image.
    maxMatch = maxCorr;
    maxIndex = maxCorrIndex;
else
    % If no threshold is defined for the correlation coefficient, the cells
    % are detected, and their radii are determined, using the covariance
    % image.
    maxMatch = maxCovar;
    maxIndex = maxCovarIndex;
end

% Store the image used for detection so that it can be visualized.
oImages.maxMatch = maxMatch;

% Find cells by detecting local maxima.
maxima = imregionalmax(maxMatch);
% Reject local maxima if they are not above both thresholds.
maxima = maxima & maxCorr >= aCorrThreshold & maxCovar >= aCovThreshold;
% Coordinates of the local maxima.
[y,x] = find(maxima);
% Intensity values of the local maxima.
v = maxMatch(sub2ind(size(corrs),y,x));
% Cell radii (indices) corresponding to the local maxima.
rIndex = maxIndex(sub2ind(size(corrs),y,x));

% Sort the local maxima after intensity.
[v, order] = sort(v, 'descend');
x = x(order);
y = y(order);
rIndex = rIndex(order);

% Add the local maxima one at a time, starting with the one with highest
% intensity. Local maxima that are too close to already added local maxima
% will not be added. TODO: Use the real cell radii.
vFinal = [];
xFinal = [];
yFinal = [];
rIndexFinal = [];
for i = 1:length(v)
    dists = sqrt((xFinal - x(i)).^2 + (yFinal - y(i)).^2);
    if ~any(dists < aMinSeparation)
        vFinal = [vFinal; v(i)]; %#ok<AGROW>
        xFinal = [xFinal; x(i)]; %#ok<AGROW>
        yFinal = [yFinal; y(i)]; %#ok<AGROW>
        rIndexFinal = [rIndexFinal; rIndex(i)]; %#ok<AGROW>
    end
end

% Label the pixels inside the circles, so that pixels that lie in more than
% one circle are assigned to the closest center.
[X, Y] = meshgrid(1:size(maxCorr,2), 1:size(maxCorr,1));  % Pixel coordinates.
% Distance to the closest centers, for pixels inside circles.
closest = inf(size(maxCorr));
% Labels of the centers that the pixels are assigned to.
labels = zeros(size(maxCorr));
for i = 1:length(rIndexFinal)
    d = sqrt((X-xFinal(i)).^2 + (Y-yFinal(i)).^2);
    mask = d < radii(rIndexFinal(i)) & d < closest;
    labels(mask) = i;
    closest(mask) = d(mask);
end

if ~strcmpi(aComplementAlg, 'none')
    % Computes a complementing pixel mask of pixels that are missed by
    % template segmentation but segmented by the complementing segmentation
    % algorithm.
    
    % Create a mask of pixels segmented by the complementing algorithm.
    imDataCloned = aImData.Clone();
    imDataCloned.Set('SegAlgorithm', aComplementAlg)
    complementBlobs = Segment_generic(imDataCloned, aFrame, varargin{:});
    complementMask = ReconstructSegmentsBlob(complementBlobs, size(labels));
    
    % Find the pixels that are found only by the complementing algorithm.
    addMask = complementMask > 0 & labels == 0;
    
    % Erode the complementing pixel mask.
    if aComplementErode >= 1
        se = strel(Ellipse(aComplementErode*[1 1]));
        addMask = imerode(addMask, se);
    end
    
    % Apply morphological opening.
    if aComplementOpen >= 1
        addMask = imopen(addMask, Ellipse(aComplementOpen*[1 1]));
    end
    
    % Add additional regions to the label image.
    addLabels = bwlabel(addMask, 4);
    addLabels(addLabels > 0) = addLabels(addLabels > 0) + max(labels(:));
    labels = labels + addLabels;
end

rawProps = regionprops(...
    labels,...
    'BoundingBox',...
    'Image',...
    'Centroid',...
    'Area');

% Remove regions that are too small or too large.
areas = [rawProps.Area];
rawProps(areas < aMinArea | areas > aMaxArea) = [];

% Create the blobs.
if isempty(rawProps)
    oBlobs = [];
else
    oBlobs(length(rawProps)) = Blob();  % Pre-allocate.
    for i = 1:length(rawProps)
        oBlobs(i) = Blob(rawProps(i), 'index', i);
    end
end

oBw = labels > 0;
oGray = maxCorr;
end

% % Old plotting code used to display circles of different colors around the
% % detected cells
% colors = {'b', 'm', 'g', 'y', 'r'};
% theta = 0:pi/50:2*pi;
%
% hold on
% for i = 1:length(xFinal)
%     cx = xFinal(i) + radii(rIndexFinal(i))*cos(theta);
%     cy = yFinal(i) + radii(rIndexFinal(i))*sin(theta);
%     plot(cx,cy,colors{rIndexFinal(i)})
% end