function [oMajorAxisLength, oMinorAxisLength] = AxisLengths3(aMask, aImData)
% Computes the major and minor axis lengths of a binary pixel mask in 3D.
%
% Inputs:
% aMask - Binary 3D array where the region is ones and the background is
%         zeros. The input can have the types logical and double.
% aImData - ImageData object for the image sequence that the binary pixel
%           mask was extracted from.
%
% Outputs:
% oMajorAxisLength - Major (longest) axis length of the region.
% oMinorAxisLength - Minor (shortest) axis length of the region.

[y, x, z] = ind2sub(size(aMask), find(aMask));

X = [x(:) y(:) z(:)*aImData.voxelHeight];
N = size(X,1);
Xn = X - repmat(mean(X,1), N, 1);

cov = 1/N * (Xn' * Xn);
% Add the covariance of a voxel.
mom = cov + diag([1/12 1/12 aImData.voxelHeight^2/12]);

lambda = eig(mom);

oMajorAxisLength = 2 * sqrt(5) * sqrt(lambda(end));
oMinorAxisLength = 2 * sqrt(5) * sqrt(lambda(1));
end