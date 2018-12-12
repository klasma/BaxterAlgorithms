function [oPosFibers, oNegFibers, oPosNuclei, oNegNuclei] =...
    CentralNuclei(aSeqPath, aNucleiVersion, aFiberVersion, varargin)
% Finds central nuclei and fibers with central nuclei.
%
% Central nuclei indicates that a fiber is regenerating. A nucleus is
% considered to be centrally located if the minimum distance from a nucleus
% pixel to a pixel outside the fiber is above a threshold. The function
% outputs fibers with centrally located nuclei, other fibers, centrally
% located nuclei, and other nuclei. Before returning the objects, the
% function colors different types of objects in different colors for
% visualization. The other objects are colored gray. The function can also
% plot the microscope image with the outlines of the colored objects
% overlaid.
%
% Inputs:
% aSeqPath - Full path of the image folder.
% aNucleiVersion - Label of a segmentation version with nuclei.
% aFiberVersion - Label of a segmentation version with fibers.
%
% Property/Value inputs:
% MinDistance - The minimum distance between nuclei pixels and pixels
%               outside the fiber. Nuclei with a greater or equal distance
%               are considered centrally located. The default value is 1,
%               meaning that it is sufficient that the nucleus is
%               completely inside the fiber.
% RemoveBorderFibers - If this is true, all fibers that touch the image
%                      border are excluded from the analysis. The default
%                      is true.
% Plot - If this parameter is set to true, the function creates a new
%        figure and plots the outlines of the colored objects on top of the
%        microscope image.
% PosFiberColor - Color applied to fibers with central nuclei. The default
%                 is red.
% NegFiberColor - Color applied to fibers without central nuclei. The
%                 default is green.
% PosNucleiColor - Color applied to central nuclei. The default is white.
% NegNucleiColor - Color applied to other nuclei. The default is gray.
%
% Outputs:
% oPosFibers - Fibers with centrally located nuclei (array of Cell).
% oNegFibers - Fibers without centrally located nuclei (array of Cell).
% oPosNuclei - Centrally located nuclei (array of Cell).
% oNegNuclei - Nuclei that are not centrally located (array of Cell)
%
% See also:
% CentralNucleiGUI, FusionIndex

% Parse property/value inputs.
[aMinDistance, aRemoveBorderFibers, aPlot, aPosFiberColor,...
    aNegFiberColor, aPosNucleiColor, aNegNucleiColor] = GetArgs(...
    {'MinDistance', 'RemoveBorderFibers', 'Plot', 'PosFiberColor',...
    'NegFiberColor', 'PosNucleiColor', 'NegNucleiColor'},...
    {1, true, false, [1 0 0], [0 1 0], ones(3,1), 0.25*ones(3,1)},...
    true,...
    varargin);

imData = ImageData(aSeqPath);

nuclei = LoadCells(aSeqPath, aNucleiVersion, 'AreCells', true);
fibers = LoadCells(aSeqPath, aFiberVersion, 'AreCells', true);

if aRemoveBorderFibers
    % Remove fibers that are touching the image border.
    fibers = fibers(~IsCellOnBorder(fibers, imData));
end

% Label image where the pixels of fiber i has the value i and the
% background is 0.
fiberLabels = ReconstructSegments(imData, fibers, 1);

% Create a common distance image. The pixels represents the shortest
% distance to the background or to another fiber. The background is 0.
distances = zeros(imData.imageHeight, imData.imageWidth);
for i = 1:length(fibers)
    if fibers(i).HasSegment(1)
        blob = fibers(i).GetBlob(1);
        bb = blob.boundingBox;
        im = blob.image;
        dist = bwdist(~im);
        
        x1 = bb(1) + 0.5;
        x2 = bb(1) + bb(3) - 0.5;
        y1 = bb(2) + 0.5;
        y2 = bb(2) + bb(4) - 0.5;
        
        % Existing distance value in image rectangle.
        existing = distances(y1:y2, x1:x2);
        % Transfer existing values outside the blob so that they are not
        % overwritten.
        dist(~im) = existing(~im);
        distances(y1:y2, x1:x2) = dist;
    end
end

% Construct a matrix where element (a,b) is the shortest distance from a
% pixel in nucleus b to a pixel outside fiber a.
minDists = zeros(length(fibers), length(nuclei));
for i = 1:length(nuclei)
    blob = nuclei(i).GetBlob(1);
    
    nucleusLabels = blob.GetPixels(fiberLabels);
    nucleusDists = blob.GetPixels(distances);
    
    % A value in column i can only be nonzero if the nucleus is completely
    % inside one fiber. If the fiber is in the background, or if it has
    % multiple labels, the entire column is 0.
    if nucleusLabels(1) ~= 0 && all(nucleusLabels == nucleusLabels(1))
        minDists(nucleusLabels(1), i) = min(nucleusDists);
    end
end

positive = minDists >= aMinDistance;
positiveRows = any(positive,2);
positiveColumns = any(positive,1);

oPosFibers = fibers(positiveRows);
oNegFibers = fibers(~positiveRows);
oPosNuclei = nuclei(positiveColumns);
oNegNuclei = nuclei(~positiveColumns);

% Color central nuclei,  other nuclei, fibers with central nuclei, and
% fibers without central nuclei, in different colors.
if nargout > 1 || aPlot
    for i = 1:length(oPosFibers)
        oPosFibers(i).color = aPosFiberColor;
    end
    
    for i = 1:length(oNegFibers)
        oNegFibers(i).color = aNegFiberColor;
    end
    
    for i = 1:length(oPosNuclei)
        oPosNuclei(i).color = aPosNucleiColor;
    end
    
    for i = 1:length(oNegNuclei)
        oNegNuclei(i).color = aNegNucleiColor;
    end
end

% Plot the results.
if aPlot
    % Create the image on which the outlines will be drawn.
    im = imData.GetShownImage(1, 'Channels', imData.channelNames);
    
    f = figure('Name', imData.GetSeqDir(), 'InvertHardcopy', 'off');
    ax = axes('Parent', f);
    imshow(im, 'Parent', ax)
    hold(ax, 'on')
    
    PlotOutlines(ax, oPosFibers, 1, 1)
    PlotOutlines(ax, oNegFibers, 1, 1)
    PlotOutlines(ax, oPosNuclei, 1, 1)
    PlotOutlines(ax, oNegNuclei, 1, 1)
end
end