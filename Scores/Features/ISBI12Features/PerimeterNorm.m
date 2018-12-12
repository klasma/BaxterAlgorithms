function oPerimeter = PerimeterNorm(aBlob, ~)
% Feature that relates the perimeter length of a blob to its area.
%
% The feature is computed by dividing the perimeter length of the blob by
% the radius of a circle with the same area as the blob.
%
% Inputs:
% aBlob - Blob object to compute the feature for.
%
% Outputs:
% oPerimeter - The computed feature value.
%
% See also:
% ComputeFeatures, Perimeter

props = regionprops(double(aBlob.image), 'Perimeter');
oPerimeter = props.Perimeter / sqrt(sum(aBlob.image(:)) / pi);
end