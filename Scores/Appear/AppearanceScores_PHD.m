function oList = AppearanceScores_PHD(aPHD, aImData)
% Uses a GM-PHD to compute scores for events where new objects appear.
%
% Probabilities of migration into the field of view are computed by
% propagating all components in the GM-PHD one time step backwards in time
% and then integrating the Gaussian distributions over the image. The
% probability of appearance is 1 minus the integral. The integration is
% taken care of by mvncdf. The function can handle Brownian motion,
% constant velocity motion and an IMM model which switches between the two.
% The function also incorporates the user specified probability of random
% appearance anywhere in the image. The returned scores are the logarithms
% of the event probabilities. It is assumed that the Gaussian components in
% the GM-PHDs that are given as input are ordered in the same way as the
% corresponding blobs that are used for tracking in Track.
%
% Inputs:
% aPHD - Array where each element is a measurement updated GM-PHD for one
%        time point. The GM-PHDs can be either CellPHD objects or
%        CellPHD_IMM objects.
% aImData - ImageData object of the image sequence.
%
% Outputs:
% oList - N x 4 matrix, where N is the number of returned appearance
%         events. The elements of the matrix are:
%    oList(:,1) - Image index.
%    oList(:,2) - Index of the Gaussian component in image oList(:,1).
%    oList(:,3) - Log likelihood of the appearance event NOT occurring.
%    oList(:,4) - Log likelihood of the appearance event occurring.
%
% See also:
% AppearanceScores, DisappearanceScores_PHD, ComputeGMPH, ComputeGMPHD_IMM,
% Track

if aImData.Get('TrackPAppear') == 0 && ~aImData.Get('TrackMigInOut')
    % There is no mechanism by which cells can disappear, so an empty list
    % is returned.
    oList = zeros(0,4);
    return
end

if contains(aImData.Get('TrackMigLogLikeList'), 'IMM')
    % Some of the components in the GM-PHD follow the constant position
    % motion model and some come from the constant velocity motion model.
    % We start by creating a separate GM-PHD for each motion model. Then we
    % compute appearance scores separately for the two GM-PHDs and compile
    % the scores into a single list. The components associated with the
    % first model appear first in the GM-PHD.
    
    % Create a separate GM-PHD for each motion model.
    phd1(length(aPHD)) = CellPHD();  % Pre-allocation.
    phd2(length(aPHD)) = CellPHD();  % Pre-allocation.
    for t = 1:length(aPHD)
        phd1(t) = aPHD(t).GetPHD(1);
        phd2(t) = aPHD(t).GetPHD(2);
    end
    
    % Compute lists with appearance scores for the two GM-PHDs.
    list1 = ComputeList(aImData, phd1, aPHD.GetParams(1));
    list2 = ComputeList(aImData, phd2, aPHD.GetParams(2));
    
    % Shift the indices of the Gaussian components in the second GM-PHD and
    % then concatenate the lists.
    J = arrayfun(@(x)x.J, phd1)';
    list2(:,2) = list2(:,2) + J(list2(:,1));
    oList = [list1; list2];
else
    % All components in the GM-PHD follow the same motion model.
    params = Parameters_GMPHD(aImData);
    oList = ComputeList(aImData, aPHD, params);
end
end

function oList = ComputeList(aImData, aPHD, aParams)
% Computes probabilities of appearance based on a single motion model.
%
% Inputs:
% aImData - ImageData object for the image sequence.
% aPHD - CellPHD object.
% aParams - Parameters of the motion model of the GM-PHD.
%
% Outputs:
% oList - Matrix with appearance scores for the components in aPHD.

aParams.F = inv(aParams.F);  % Propagate the PHD backwards in time.
H = aParams.H;

% Define the boundaries of the image, to be used as integration limits.
if aImData.GetDim() == 2
    xl = ones(2,1) - 0.5;
    xu = [aImData.imageWidth; aImData.imageHeight] + 0.5;
else
    xl = ones(3,1) - 0.5;
    xu = [aImData.imageWidth; aImData.imageHeight; aImData.numZ] + 0.5;
end

oList = nan(sum([aPHD(2:end).J]), 4);  % Pre-allocate.
cnt = 1;

% Cells cannot appear randomly in the first image.
for t = 2:length(aPHD)
    if aPHD(t).J == 0
        continue
    end
    phd = aPHD(t).Propagate(aParams);  % Propagate backwards in time.
    for bIndex = 1:aPHD(t).J
        
        % Random appearance with uniform probability over the image.
        dprob = aImData.Get('TrackPAppear');
        
        % Cells migrating into the image.
        if aImData.Get('TrackMigInOut')
            mu = H * phd.m(:,bIndex);
            SIGMA = H * phd.P(:,:,bIndex) * H';
            dprob = dprob + (1-dprob)*(1-mvncdf(xl,xu,mu,SIGMA));
        end
        
        % Only add events with a non-zero probability.
        if dprob > 0
            oList(cnt,1) = t;
            oList(cnt,2) = bIndex;
            oList(cnt,3) = 0;
            oList(cnt,4) = log(dprob);
            cnt = cnt+1;
        end
    end
end
% Remove empty rows at the end of the list if all GM-PHD components did not
% give rise to entries in the list.
oList = oList(1:cnt-1,:);
end