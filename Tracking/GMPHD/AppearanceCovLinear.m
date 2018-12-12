function [oMean, oCov, oScaling] = AppearanceCovLinear(aStdV, aQ)
% Mean and covariance of particles with linear motion entering the image.
%
% The mean position and velocity and their covariance are computed in one
% dimension. The mean position is 0, but the mean velocity is the mean of
% the velocities entering the image. The computations are performed by
% propagating a large number of randomly generated particles outside the
% image border and then computing statistics on the particles which end up
% inside the image. The calculations can also be performed by evaluating a
% quadruple integral, but that method is slower. With 1E8 random particles,
% the errors on the covariance matrix seem to be smaller than 0.1 %.
%
% Inputs:
% aStdV - Standard deviation of the particle velocities outside the image.
% aQ - Process noise in the Kalman filter.
%
% Outputs:
% oMean - Column vector with mean position and velocity of particles
%         entering the image. The mean position is 0.
% oCov - Covariance of the position and the velocity of entering entering
%        particles.
% oScaling - Scaling factor which should multiply the Gaussian distribution
%            to give the appropriate particle density inside the image. The
%            particle density outside the image is assumed to be 1 particle
%            per pixel.
%
% See also:
% AppearanceCovBrownian

s = rng();  % Get the state of the random number generator.
rng(0)  % Specify a seed for reproducibility.

N = 1E7;                            % Number of random particles.
L = aStdV*5;                        % Maximum distance from the border given to random particles.
F = [1 1; 0 1];                     % Propagation matrix in the Kalman filter.
p_samples = rand(1,N)*L-L;          % Positions of the random particles.
v_samples = randn(1,N)*aStdV;       % Velocities of the random particles.
x = [p_samples; v_samples];
h = F*x + (randn(N,2)*chol(aQ))';   % Propagate the distributions of the random particles.
h(:,h(1,:)<0) = [];                 % Remove particles which did not make it into the image.
oMean = [0; mean(h(2,:))];          % Compute the mean velocity.

% Compute the the covariance.
h = h - repmat(oMean, 1, size(h,2));
oCov = zeros(2,2);
for i = 1:2
    for j = 1:2
        oCov(i,j) = mean(h(i,:).*h(j,:));
    end
end

oScaling = 2 * length(h) / (N/L);

rng(s)  % Go back to the old random number generator state.
end