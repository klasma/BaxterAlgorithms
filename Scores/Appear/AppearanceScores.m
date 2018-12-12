function oList = AppearanceScores(aBlobSeq, aImData)
% Computes scores for events where new cells appear in the image.
%
% The cells can either appear in random places in the image or migrate into
% the field of view. In practice, a cell can appear randomly if it falls
% into focus from suspension or if it is washed into the field of view
% after a media change. The score of an appearance event for a cell is the
% logarithm of the probability that the cell will was not present in the
% previous image.
%
% Inputs:
% aBlobSeq - Cell array where element t contains a vector with all Blob
%            objects created through segmentation of frame t.
% aImData - ImageData object for the image sequence.
%
% Outputs:
% oList - N x 4 matrix, where N is the number of returned appearance
%         events. The elements of the matrix are:
%    oList(:,1) - Image index.
%    oList(:,2) - Index of the detection in image oList(:,1).
%    oList(:,3) - Log-probability of the appearance event NOT occurring.
%    oList(:,4) - Log-probability of the appearance event occurring.
%
% Important properties in aImData:
% TrackPAppear - Probability of random appearance.
% TrackMigInOut - If this is set to true, cells are allowed to migrate into
%                 the field of view.
% TrackXSpeedStd - The cell speed in pixels per frame. This is used to
%                  compute the probability that a cell has migrated into
%                  the field of view. The cell is assumed to follow a
%                  Brownian motion model where the PDF is an isotropic
%                  Gaussian centered around the position in the previous
%                  frame.
%
% See also:
% DisappearanceScores, Track

if aImData.Get('TrackPAppear') == 0 && ~aImData.Get('TrackMigInOut')
    % There is no mechanism by which cells can disappear, so an empty list
    % is returned.
    oList = zeros(0,4);
    return
end

pixelStd = aImData.Get('TrackXSpeedStd');

% Pre-allocate a list that may be too long.
oList = nan(length([aBlobSeq{2:end}]), 4);
cnt = 1;
for t = 2:length(aBlobSeq)  % Cells cannot appear in the first image.
    for bIndex = 1:length(aBlobSeq{t})
        b = aBlobSeq{t}(bIndex);
        
        % Random appearance.
        dprob = aImData.Get('TrackPAppear');
        
        % Appearance through migration into the field of view.
        if aImData.Get('TrackMigInOut')
            [x,y] = b.GetPixelCoordinates();
            
            % The probability that a cell in the image was outside the
            % image at the previous time point is the same as the
            % probability that the cell will be outside the image in the
            % following time point. It is assumed that the cell will have
            % the same shape in the following time point. Furthermore, it
            % is assumed that to cross an image border it has to move far
            % enough in that direction that the pixel furthest away from
            % the border ends up on the border. We do not consider cases
            % where a cell exits the image at one of the corners so that
            % there are cell pixels both above (or below) and to the right
            % (or to the left) of the corner.
            dprob = dprob + (1-dprob)*normcdf(1-max(x), 0, pixelStd);
            dprob = dprob + (1-dprob)*normcdf(min(x)-aImData.imageWidth, 0, pixelStd);
            dprob = dprob + (1-dprob)*normcdf(1-max(y), 0, pixelStd);
            dprob = dprob + (1-dprob)*normcdf(min(y)-aImData.imageHeight, 0, pixelStd);
        end
        
        % Add scores to the list.
        if dprob > 0
            oList(cnt,1) = t;
            oList(cnt,2) = bIndex;
            oList(cnt,3) = log(1 - dprob);
            oList(cnt,4) = log(dprob);
            cnt = cnt+1;
        end
    end
end
% Remove the end of the list if the pre-allocated list was too long.
oList = oList(1:cnt-1,:);
end