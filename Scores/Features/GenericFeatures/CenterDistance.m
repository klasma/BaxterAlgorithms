function oDist = CenterDistance(aBlob, aImProcessor)
% Blob feature which measures relative distance to the microwell center.
%
% The function computes the distance from the center of the microwell and
% divides it by the microwell radius. A blob in the center will get the
% value 0 and one on the microwell edge will get the value 1.
%
% Inputs:
% aBlob - Blob object.
% aImProcessor - ImageProcessor object for the image.
%
% Outputs:
% oDist - Normalized distance between blob centroid and the microwell
%         center. If the image sequence does not have a microwell, the
%         function returns NaN.
%
% See also:
% GetWellCircle, ComputeFeatures

x = aBlob.centroid(1);
y = aBlob.centroid(2);
[cx, cy, cr] = GetWellCircle(aImProcessor.imData);
if isnan(cr) % There is no microwell in the image sequence.
    oDist = nan;
else
    oDist = sqrt((x - cx)^2 + (y - cy)^2) / cr;
end
end