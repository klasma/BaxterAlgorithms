function oArea = Area(aBlob, ~)
% Feature which returns the number of pixels in a blob.
%
% Inputs:
% aBlob - Blob object for which the area features should be computed.
%
% Outputs:
% oArea - Area in pixels
%
% See also:
% ComputeFeatures


oArea = sum(aBlob.image(:));
end