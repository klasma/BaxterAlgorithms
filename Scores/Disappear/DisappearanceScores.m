function oList = DisappearanceScores(aBlobSeq, aImData)
% Computes scores for events where cells disappear from the image.
%
% The cells can either disappear randomly or migrate out of the field of
% view. In practice, a cell can disappear randomly if it is washed out of
% the field of view during a media change or if it becomes impossible to
% detect due to for example photo bleaching. The score of a disappearance
% event for a cell is the logarithm of the probability that the cell will
% not be present in the following image.
%
% Inputs:
% aBlobSeq - Cell array where element t contains a vector with all Blob
%            objects created through segmentation of frame t.
% aImData - ImageData object for the image sequence.
%
% Important properties in aImData:
% TrackPDisappear - Probability of random disappearance.
% TrackMigInOut - If this is set to true, cells are allowed to migrate out
%                 of the field of view.
% TrackXSpeedStd - The cell speed in pixels per frame. This is used to
%                  compute the probability that a cell migrates out of the
%                  field of view. The cell is assumed to follow a Brownian
%                  motion model where the PDF is an isotropic Gaussian
%                  centered around the position in the previous frame.
%
% Outputs:
% oList - N x 4 matrix, where N is the number of returned disappearance
%         events. The elements of the matrix are:
%    oList(:,1) - Image index.
%    oList(:,2) - Index of the detection in image oList(:,1).
%    oList(:,3) - Log-probability of the disappearance event NOT occurring.
%    oList(:,4) - Log-probability of the disappearance event occurring.
%
% See also:
% AppearanceScores, Track

if aImData.Get('TrackPDisappear') == 0 && ~aImData.Get('TrackMigInOut')
    % There is no mechanism by which cells can disappear, so an empty list
    % is returned.
    oList = zeros(0,4);
    return
end

pixelStd = aImData.Get('TrackXSpeedStd');

% Pre-allocate a list that may be too long.
oList = nan(length([aBlobSeq{1:end-1}]), 4);
cnt = 1;
for t = 1:length(aBlobSeq)-1  % Cells cannot appear in the last image.
    for i = 1:length(aBlobSeq{t})
        b = aBlobSeq{t}(i);
        
        % Random disappearance.
        dprob = aImData.Get('TrackPDisappear');
        
        if aImData.Get('TrackMigInOut')
            [x,y] = b.GetPixelCoordinates();
            
            % It is assumed that the cell will have the same shape in the
            % following time point. Furthermore, it is assumed that to
            % cross an image border it has to move far enough in that
            % direction that the pixel furthest away from the border ends
            % up on the border. We do not consider cases where a cell exits
            % the image at one of the corners so that there are cell pixels
            % both above (or below) and to the right (or to the left) of
            % the corner.
            dprob = dprob + (1-dprob)*normcdf(1-max(x), 0, pixelStd);
            dprob = dprob + (1-dprob)*normcdf(min(x)-aImData.imageWidth, 0, pixelStd);
            dprob = dprob + (1-dprob)*normcdf(1-max(y), 0, pixelStd);
            dprob = dprob + (1-dprob)*normcdf(min(y)-aImData.imageHeight, 0, pixelStd);
        end
        
        % Add scores to the list.
        if dprob > 0
            oList(cnt,1) = t;
            oList(cnt,2) = i;
            oList(cnt,3) = log(1 - dprob);
            oList(cnt,4) = log(dprob);
            cnt = cnt+1;
        end
    end
end
% Remove the end of the list if the pre-allocated list was too long.
oList = oList(1:cnt-1,:);
end