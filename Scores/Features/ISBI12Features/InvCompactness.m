function oInvComp = InvCompactness(aBlob, ~)
% The inverse of the feature Compactness
%
% The feature is is given by (2*pi*area)/perimeter^2. A circle has the
% value 1 and the value decreases toward zero as the contour of the shape
% becomes more elongated and jagged. This features is sometimes referred to
% as the shape factor.
%
% Inputs:
% aBlob - Blob object to compute the inverse compactness of.
%
% Outputs:
% oInvComp - The inverse compactness of the blob.
%
% See also:
% ComputeFeatures, Compactness, ShapeFactor

oInvComp = 1/Compactness(aBlob, []);
end