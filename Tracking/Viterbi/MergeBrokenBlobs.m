function oBlobSeq = MergeBrokenBlobs(aBlobSeq, aMaxArea, aRatio)
% Merges blobs which overlap enough with a blob in an adjacent frame.
%
% This function can be used to reduce over-segmentation, caused by for
% example a watershed transform, when the cells are relatively stationary
% over time. I have used it on the HeLa DIC dataset of the cell tracking
% challenges, and therefore I include it for reproducibility. I do not
% recommend this function, because the possible performance gain is small,
% and it makes it harder to analyze tracking errors.
%
% The function first goes through the image sequence frame by frame and
% looks for blobs which are below a size threshold and overlap enough with
% the same blob in the previous image. Such groups of blobs are merged into
% larger blobs. When the function reaches the end of the image sequence, it
% goes through the image sequence backwards and looks for groups of blobs
% that overlap with blobs in the following image. These steps are then
% repeated until no more blobs can be merged.
%
% Inputs:
% aBlobSeq - Cell array where element t contains an array of blobs that
%            were created through segmentation of frame t.
% aMaxArea - Area threshold in pixels. Smaller blobs are not merged.
% aRatio - Overlap threshold. To be included in a merge, more than this
%          proportion of the blob must be covered by the overlapping blob
%          in the previous or following frame.
%
% Outputs:
% oBlobSeq - Cell array of the same structure as aBlobSeq, where blobs have
%            been merged.
%
% See also:
% MergeFPWatersheds, MergeFPWatersheds3D

oBlobSeq = aBlobSeq;
merged = true;
while merged
    % Merge blobs which overlap with the same blob in the previous image.
    [oBlobSeq, m1] = MergeForward(oBlobSeq, aMaxArea, aRatio);
    
    % Flip the cell array and merge blobs which overlap with the same blob
    % in the following image.
    [oBlobSeq, m2] = MergeForward(fliplr(oBlobSeq), aMaxArea, aRatio);
    
    % Flip the cell array back to the original order.
    oBlobSeq = fliplr(oBlobSeq);
    
    % Do another round of merging if any merges were performed.
    merged = m1 || m2;
end
fprintf('Done merging blobs\n')
end

function [oBlobSeq, oMerged] = MergeForward(aBlobSeq, aMaxArea, aRatio)
% Merges blobs which overlap with the same blob in the following frame.
%
% The function only performs one iteration of merging.
%
% Inputs:
% aBlobSeq - Cell array where element t contains an array of blobs that
%            were created through segmentation of frame t.
% aMaxArea - Area threshold in pixels. Smaller blobs are not merged.
% aRatio - Overlap threshold. To be included in a merge, more than this
%          proportion of the blob must be covered by the overlapping blob
%          in the previous frame.
%
% Outputs:
% oBlobSeq - Cell array of the same structure as aBlobSeq, where blobs have
%            been merged.
% oMerged - Boolean variable which indicates if a merge was performed

oBlobSeq = aBlobSeq;
oMerged = false;
for t = 1:length(oBlobSeq)-1
    fprintf('Merging blobs in image %d / %d\n', t, length(oBlobSeq))
    for i = 1:length(oBlobSeq{t})
        b1 = oBlobSeq{t}(i);
        
        % Find indices of blobs in the following frame that are small
        % enough and overlap enough with b1.
        mergeIndices = [];
        for j = 1:length(oBlobSeq{t+1})
            b2 = oBlobSeq{t+1}(j);
            area2 = b2.GetArea();
            if area2 < aMaxArea
                if Overlap(b1,b2) > aRatio * area2
                    mergeIndices = [mergeIndices; j]; %#ok<AGROW>
                end
            end
        end
        
        % Merge the blobs.
        if length(mergeIndices) > 1
            fprintf('Merged %d blobs in image %d\n', length(mergeIndices), t)
            
            % Combine the blobs.
            mergeBlob = oBlobSeq{t+1}(mergeIndices(1));
            for k = 2:length(mergeIndices)
                CombineBlobs(mergeBlob, oBlobSeq{t+1}(mergeIndices(k)));
            end
            
            % Remove the old blobs from the output.
            oBlobSeq{t+1}(mergeIndices) = [];
            
            % Add the new blob to the output.
            oBlobSeq{t+1} = [oBlobSeq{t+1} mergeBlob];
            
            oMerged = true;
        end
    end
end
end