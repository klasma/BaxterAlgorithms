function RemoveOutlines(aCells, aT)
% Removes the pixel regions associated with Cell objects at one time point.
%
% All blobs of the cells at the specified time point will be point blobs
% without pixel regions (outlines) after the function has been applied. The
% super-relationships among blobs are not maintained.
%
% Inputs:
% aCells - Array of Cell objects for which the regions will be removed.
% aT - Time point (image) where for which the regions will be removed.
%
% See also:
% Cell, Blob

for i = 1:length(aCells)
    c = aCells(i);
    b = c.GetBlob(aT);
    pointBlob = Blob(struct(...
        'BoundingBox', nan(size(b.boundingBox)),...
        'Image', nan,...
        'Centroid', b.centroid,...
        't', aT));
    c.SetBlob(pointBlob.CreateSub(), aT)
end
end