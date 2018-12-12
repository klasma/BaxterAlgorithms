function [oMajorAxisLength, oMinorAxisLength] = AxisLengths2(aMask)
% Computes the major and minor axis lengths of a binary pixel mask.
%
% The function has the same output as the built-in function regionprops.
% This function is used to avoid the overhead in regionprops.
%
% Inputs:
% aMask - Binary image where the region is ones and the background is
%         zeros. The input can be either a logical matrix or a double
%         image.
%
% Outputs:
% oMajorAxisLength - Major axis length of the region.
% oMinorAxisLength - Minor axis length of the region.

[y, x] = ind2sub(size(aMask), find(aMask));

X = [x(:) y(:)];
N = size(X,1);
Xn = X - repmat(mean(X,1), N, 1);

cov = 1/N * (Xn' * Xn);
mom = cov + 1/12*eye(2);  % Add the covariance of a pixel.

lambda = eig(mom);

oMajorAxisLength = 4 * sqrt(lambda(end));
oMinorAxisLength = 4 * sqrt(lambda(1));
end