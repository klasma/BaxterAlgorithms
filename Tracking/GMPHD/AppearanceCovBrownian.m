function [oMean, oVar, oScaling] = AppearanceCovBrownian(aQ)
% Finds parameters for a Gaussian representing objects entering the image.
%
% It is assumed that the particle density is uniform on the other side of
% the image border. This function computes the second moment of the
% entering particles. The particles are then represented using a zero mean
% Gaussian with that second moment as variance, and a scaling factor which
% makes the integral of the distributions the same. The density of entering
% particles at a distance x from the image border will be the density of
% particles outside the image multiplied by ncdf(-x), where ncdf is the CDF
% of the Gaussian distribution which defines the stochastic particle
% displacement between two frames. The second moment of the particles is
% computed by integrating x^2*ncdf(-x) and then normalizing.
%
% Inputs:
% aQ - Variance of the Brownian motion, in the direction perpendicular to
%      the image border. This is a component in the process noise of the
%      Kalman filter.
%
% Outputs:
% oMean - The mean position of entering particles (0).
% oVar - The variance of the positions of entering particles.
% oScaling - Scaling factor which should multiply a Gaussian distribution
%            with the variance aVar, to give the appropriate particle
%            density inside the image. The particle density outside the
%            image is assumed to be 1 particle per pixel.
%
% See also:
% AppearanceCovLinear

stdX = sqrt(aQ);

oMean = 0;

% Integrate the number of entering particles.
fun_count = @(x) normcdf(-x, 0, stdX);
count = integral(fun_count, 0, 10*stdX);

% Integrate the variance of the entering particles.
fun_sigma = @(x) x.^2 .* normcdf(-x, 0, stdX);
oVar = integral(fun_sigma, 0, 10) / count;

% The Gaussian integrates to 0.5 inside the image and we want it to
% integrate to count.
oScaling = count / 0.5;
end