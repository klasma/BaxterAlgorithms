function oValue = IBoundary(aBlob, aImProcessor)
% Feature which returns the average intensity on the boundary of a blob.
%
% Inputs:
% aBlob - Blob object to compute the feature for.
% aImProcessor - ImageProcessor object for the image.
%
% Outputs:
% oValue - The computed feature value.
%
% See also:
% ComputeFeatures, ICenter, ICentroid, IFraction

B = bwboundaries(aBlob.image);

% Concatenate the pixel coordinates of different parts of the boundary.
xb = [];
yb = [];
for i = 1:length(B)
    xb = [xb; B{i}(:,2)]; %#ok<AGROW>
    yb = [yb; B{i}(:,1)]; %#ok<AGROW>
end

im = aBlob.GetSubImage(aImProcessor.GetNormIm());
oValue = mean(im(sub2ind(size(im),yb,xb)));
end