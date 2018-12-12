function [oX, oY, oR] = FindWellsHough(aImData, aFrame, varargin)
% Uses a Hough transform to find circular microwells in an image.
%
% The well size is determined automatically, but the user must have defined
% the settings minWellR and maxWellR, which specify a minimum and a maximum
% well radius in pixels. If these settings have not been set in aImData,
% the function will produce an error message. Both wells with and without
% cells are found. It can find wells where less than half the well is
% outside the image. Use the input argument 'MaxOut' to determine how much
% of the well is allowed to be outside the image. The returned wells will
% be ordered after their Hough transform values, starting with the highest
% value. Wells will only be returned if they have a transform value which
% is twice as high as the maximum value in a transform of a randomly
% generated image. The returned microwells are not allowed to overlap.
%
% Inputs:
% aImData - Image data object for the image sequence.
% aFrame - Frame that should be processed.
%
% Property/Value inputs:
% MaxOut - The amount by which a circle is allowed to extend outside the
%          image, given as a fraction of the circle radius. The default is
%          0.33.
%
% Outputs:
% oX - Column vector with x-coordinates of microwell centers in pixels.
% oY - Column vector with y-coordinates of microwell centers in pixels.
% oR - Column vector with microwell radii in pixels.

% Parse property/value inputs.
aMaxOut = GetArgs({'MaxOut'}, {0.33}, true, varargin);

% Read the image.
im = aImData.GetDoubleImage(aFrame);
[height, width] = size(im);

% The minimum and maximum well radii in pixels.
minWellRpix = aImData.Get('minWellR');
maxWellRpix = aImData.Get('maxWellR');

% Check the minimum and maximuim well radii.
if isnan(minWellRpix) || isnan(minWellRpix)
    error(['The settings minWellR and maxWellR must not be set to NaN '...
        'when microwells are to be found.'])
end
imDiag = sqrt(height^2+width^2);
if minWellRpix > imDiag/2
    error('The setting minWellR must be larger than half the image diagonal.')
end

% Resize the image to reduce noise and to make lines thinner, which will
% give better results when the edge finder is applied.
downscale = 2.5;
im = imresize(im, 1/downscale);

% Apply edge finder.
im = SobelEdge(im);

% Well radii to look for in the resized image.
rVec2 = round(minWellRpix/downscale) : round(maxWellRpix/downscale);

if length(rVec2) == 1
    % There is only a single possible radius.
    rMax = rVec2;
else
    % Run the algorithm on a random image with the same ratio of white
    % pixels, to see how the maximum value of the transform scales with the
    % circle radius. One can get a rather good fit with an affine function.
    randIm = rand(size(im)) > (sum(~im(:)) / numel(im));
    lb = 10*floor(min(rVec2)/10);
    ub = 10*ceil(max(rVec2)/10);
    rVec1 = max(10,lb) : 10 : max(max(10,lb)+10,ub);
    maxVec = zeros(size(rVec1));
    for rIndex = 1:length(rVec1)
        r = rVec1(rIndex);
        transform = HoughTransform(randIm, r);
        transform = SmoothComp(transform, 2);
        maxVec(rIndex) = max(transform(:));
    end
    p = polyfit(rVec1, maxVec, 1);
    
    while true
        % Find the well radius by taking the radius that gives the highest
        % maximum transform value compared to the expected value for a
        % random image.
        maxVec = zeros(size(rVec2));
        for rIndex = 1:length(rVec2)
            r = rVec2(rIndex);
            transform = HoughTransform(im, r);
            transform = SmoothComp(transform, 2);
            maxVec(rIndex) = max(transform(:));
        end
        maxFit = polyval(p, rVec2);
        maxVec = maxVec./maxFit;
        [~, maxIndex] = max(maxVec);
        rMax = rVec2(maxIndex);
        
        % If the well radius is to small we should not down-scale the
        % image size this much.
        if rMax < 20 && downscale > 1
            downscale = max(downscale/2, 1);
            im = imresize(aImData.GetUint8Image(aFrame), 1/downscale);
            im = SobelEdge(im);
            rVec2 = (rMax*2-5) : (rMax*2+5);
        else
            break
        end
    end
end

% Re-compute a Hough transform for a random image with the best radius.
randIm = rand(size(im)) > (sum(~im(:)) / numel(im));
randTrans = HoughTransform(randIm, rMax);
randTrans = SmoothComp(randTrans, 2);
randTransMax = max(randTrans(:));

% Perform the transform with the best radius, and normalize it using the
% maximum transform value for a random image.
transform = HoughTransform(im, rMax);
transform = SmoothComp(transform, 2);
transform = transform / randTransMax;

% Local maxima of the transform that are not too close to the boundary are
% taken to be well centers. The wells are not allowed to overlap, and they
% are added in order after the magnitude of the local maxima. The local
% maxima must be higher than 2 times randTransMax.
taken = false(size(im));
[X, Y] = meshgrid(1:size(im,2), 1:size(im,1));
regmax = imregionalmax(transform);
oX = [];
oY = [];
oR = [];
while true
    candidates = find(regmax & ~taken);
    [maxVal, maxIndex] = max(transform(candidates));
    
    % Break when there are no more local maxima or when the local maxima
    % are too low.
    if isempty(maxVal) || maxVal < 2
        break
    end
    
    % Convert from a pixel index to row and column indices.
    [yc, xc] = ind2sub(size(im), candidates(maxIndex));
    
    % Convert coordinates from the down-scaled image to the original image.
    x = round(xc*downscale + 0.5);
    y = round(yc*downscale + 0.5);
    r = rMax*downscale;
    
    % Compute by how much the circle is outside the image.
    outside = max(...
        [r - x + 0.5,...
        x + r - width - 0.5,...
        r - y + 0.5,...
        y + r - height - 0.5])/r;
    
    % Add the circle if enough of it is inside the image.
    if outside < aMaxOut
        oX = [oX; x]; %#ok<AGROW>
        oY = [oY; y]; %#ok<AGROW>
        oR = [oR; r]; %#ok<AGROW>
        % Remove all pixels in a circle with a radius of 2 times the well
        % radius, from the set of possible pixels. This ensures that none
        % of the following wells overlap with the current well.
        taken(sqrt((X-xc).^2 + (Y-yc).^2) < 2*rMax) = true;
    else
        % Remove only the local maxima from the set of possible pixels.
        taken(candidates(maxIndex)) = true;
    end
end
end

function oTransform = HoughTransform(aImage, aR)
% Performs a Hough transform to find centers of circles with radius aR.
%
% Inputs:
% aImage - Image to be transformed.
% aR - Radius in pixels.
%
% Outputs:
% oTransform - Hough transform of aImage.

cnt = 0;
[h, w] = size(aImage);
oTransform = zeros(size(aImage));

% Get x and y pixel coordinates for a circle centered at the origin. Used
% later as shifts to perform the transform.
theta = 0:2*pi/10000 : 2*pi;
xRAW = round(aR*cos(theta));
yRAW = round(aR*sin(theta));
x = [];
y = [];
xprev = nan;
yprev = nan;
% Remove duplicates from xRAW and yRAW.
for pIndex = 1:length(xRAW)
    if xprev ~= xRAW(pIndex) || yprev ~= yRAW(pIndex)
        x = [x; xRAW(pIndex)]; %#ok<AGROW>
        y = [y; yRAW(pIndex)]; %#ok<AGROW>
    end
    xprev = xRAW(pIndex);
    yprev = yRAW(pIndex);
end

% The computations are performed on 500x500 pixels blocks of the image to
% avoid out of memory errors.
for subX = 1:500:w
    for subY = 1:500:h
        imSub = aImage(subY:min(subY+499, h), subX:min(subX+499, w));
        [yIm, xIm] = find(imSub);
        xIm = xIm + subX-1;
        yIm = yIm + subY-1;
        
        % Find x and y coordinates of all terms that should be added in the
        % transform.
        xMat = repmat(xIm, 1, length(x)) + repmat(x', length(xIm), 1);
        xMat = xMat(:);
        yMat = repmat(yIm, 1, length(y)) + repmat(y', length(yIm), 1);
        yMat = yMat(:);
        
        % Remove points outside the image.
        xRemove = xMat < 1 | xMat > size(aImage, 2);
        xMat(xRemove) = [];
        yMat(xRemove) = [];
        yRemove = yMat < 1 | yMat > size(aImage, 1);
        xMat(yRemove) = [];
        yMat(yRemove) = [];
        
        % Get indices of all terms that should be added to the transform,
        % then use a histogram to get the transform.
        unsorted = (xMat-1)*size(aImage,1) + yMat;
        counts = histc(unsorted(:), 1:numel(aImage));
        oTransform = oTransform + reshape(counts, size(oTransform));
        cnt = cnt + 1;
    end
end
end

function oImage = SobelEdge(aImage)
% Creates an edge image using the Sobel edge finder with a low threshold.
%
% The threshold is set to half the automatically selected threshold. This
% gives an image where weak edges are visible.
%
% Inputs:
% aImage - Image to find edges in.
%
% Outputs:
% oImage - Binary edge image.

[~, threshold] = edge(aImage, 'sobel');
oImage = edge(aImage,'sobel', threshold / 2);
end