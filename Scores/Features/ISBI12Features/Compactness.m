function oCompactness = Compactness(aBlob, ~)
% Feature which measures how compact a blob is.
%
% The feature is is given by perimeter^2/(2*pi*area). A circle has the
% value 1 and the value increases unboundedly as the contour of the shape
% becomes more elongated and jagged. The inverse of the compactness feature
% is sometimes referred to as the shape factor.
%
% Inputs:
% aBlob - Blob object to compute the compactness of.
%
% Outputs:
% oCompactness - The compactness of the blob.
%
% See also:
% ComputeFeatures, InvCompactness, ShapeFactor

bw = aBlob.image;
props = regionprops(double(bw), 'Perimeter');
perimeter = props.Perimeter;
area = sum(bw(:));
oCompactness = max(perimeter^2,1) / (4*pi) / area;
end