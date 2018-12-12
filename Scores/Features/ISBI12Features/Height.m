function oHeight = Height(aBlob, aImProcessor)
% The difference between the maximum and minimum intensities in a blob.
%
% Inputs:
% aBlob - Blob object to compute the feature for.
% aImProcessor - ImageProcessor object for the image.
%
% Outputs:
% oHeight - The computed feature value.
%
% See also:
% ComputeFeatures, HeightMean

oHeight = Texture(aBlob, aImProcessor, 'im', 'max') -...
    Texture(aBlob, aImProcessor, 'im', 'min');
end