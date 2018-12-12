function oPerimeter = Perimeter(aBlob, ~)
% Feature which returns the perimeter length of a blob in pixels.
%
% Inputs:
% aBlob - Blob object to compute the perimeter of.
%
% Outputs:
% oPerimeter - The perimeter length of the blob.
%
% See also:
% ComputeFeatures, PerimeterNorm

props = regionprops(double(aBlob.image), 'Perimeter');
oPerimeter = props.Perimeter;
end