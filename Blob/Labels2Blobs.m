function oBlobs = Labels2Blobs(aLabels, aFrame)
% Converts a label matrix to an row vector of of blobs.
%
% Inputs:
% aLabels - Label image where the background is 0 and the cell pixels are
%           integers from 1 to the number of blob regions.
% aFrame - Index of the frame that the labels belong to.
%
% Outputs:
% oBlobs - Row vector of blobs.

rawProps = regionprops(...
    aLabels,...
    'BoundingBox',...
    'Image',...
    'Centroid',...
    'Area');

% Remove properties corresponding to missing labels.
rawProps = rawProps([rawProps.Area] > 0);

if isempty(rawProps)
    oBlobs = [];
else
    % Generate the array of blobs.
    oBlobs(length(rawProps)) = Blob();  % Pre-allocate.
    for i = 1:length(rawProps)
        oBlobs(i) = Blob(rawProps(i), 't', aFrame, 'index', i);
    end
end
end