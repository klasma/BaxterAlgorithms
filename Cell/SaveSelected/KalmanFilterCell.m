function oPosition = KalmanFilterCell(aCell, aFrame, aImData)
% Predicts the position of a cell in the next frame using Kalman filtering.
%
% This function starts from the first frame and tracks the cell to a
% specified frame using a Kalman filter. The centroids of the blobs are
% used as position measurements in each frame. No measurement update is
% performed in the specified frame. Usually, the function is used to
% predict the position of a cell in the frame after the last frame of the
% track, but it can also be used to predict the position in earlier frames.
% The parameters of the Kalman filter are taken from the parameters for
% GM-PHD tracking that have been specified for the image sequence.
%
% Inputs:
% aCell - The Cell object for which the position should be predicted.
% aFrame - The frame for which the position should be predicted.
% aImData - ImageData object for the image sequence.
%
% Outputs:
% oPosition - Row vector with the predicted position in the specified
%             frame.
%
% See also:
% Parameters_GMPHD

% Get parameters for the Kalman filter.
parameters = Parameters_GMPHD(aImData);
F = parameters.F;
H = parameters.H;
Q = parameters.Q;
R = parameters.R;
d = aImData.GetDim();

% Initialize states and covariances. It is assumed that the staring
% intensity consists of a single Gaussian component.
m = parameters.gamma_start.m;
P = parameters.gamma_start.P;

for t = aCell.firstFrame : aFrame-1
    % Kalman filter update.
    y = aCell.GetBlob(t).centroid';
    eta = H * m;
    S = H * P * H' + R;
    m = m + P * H' * (S \ (y - eta));
    P = ( eye(2*d) - P * H' * (S\H) ) * P;
    P = (P + P') / 2;  % Ensure exact symmetry.
    
    % Kalman filter propagation.
    m = F * m;
    P = F * P * F' + Q;
    P = (P + P') / 2;  % Ensure exact symmetry.
end

oPosition = m(1:d)';
end