function oMeans = MeanNoNan(aMat, aDim)
% Computes the mean of matrix element that are not nan or infinite.
%
% Inputs:
% aMat - Matrix to compute mean values in. The mean value is computed along
%        one dimension of the matrix.
% aDim - The dimension along which to compute the mean.
%
% Outputs:
% oMeans - Mean values along the specified matrix dimension. The specified
%          matrix dimension will have a single element while the number of
%          elements in the other dimensions are unaltered. If all elements
%          are nan or inf, the corresponding element in oMeans will be nan.

tmpMat = aMat;
num = sum(~isnan(tmpMat) & ~isinf(tmpMat), aDim);
tmpMat(isnan(tmpMat) | isinf(tmpMat)) = 0;
oMeans = sum(tmpMat,aDim) ./ num;
end