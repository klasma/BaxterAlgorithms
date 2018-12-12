function oF =  GaussPDF(aX, aM, aE)
% Evaluates a multivariate Gaussian pdf.
%
% The function is faster than mvnpdf.
%
% Inputs:
% aX - Matrix where each column is a point where the pdf should be
%      evaluated.
% aM - Matrix of the same size as aX, where each column is a mean value for
%      the Gaussian pdf.
% aE - Covariance matrix of the Gaussian pdf. The function can only handle
%      a single covariance matrix.
%
% Outputs:
% oF - Row vector with pdf-values corresponding to the columns of aX.

oF = 1 / sqrt((2*pi)^length(aM) * det(aE))...
    * exp(- 1/2 * sum((aX-aM).*(aE\(aX-aM))));
end