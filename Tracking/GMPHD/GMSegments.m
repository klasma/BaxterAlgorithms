function oBlobSeq = GMSegments(aCells, aBlobSeq, aImData, varargin)
% Adds pixel regions to the blobs produced by GM-PHD tracking.
%
% The blobs and the centroids of the cells are kept, but the blobs get new
% images and bounding boxes. The super-blobs of the GM-PHD blobs are the
% original blobs from the segmentation. The function breaks the super-blobs
% into the correct number of fragments and then matches the fragments to
% the means of the GM-PHD components.
%
% Inputs:
% aCells - Cells with GM-PHD blobs.
% aBlobSeq - Cell array where each cell contains the blobs segmented in one
%            image. The blobs must be sorted according to the index
%            property.
% aImData - ImageData object associated with the image sequence.
%
% Property/Value inputs:
% ChangeCentroids - If this is set to true, the coordinates of blobs will
%                   be changed from the GM-PHD states to the centroids of
%                   the blob regions. The default is false.
%
% Outputs:
% oBlobSeq - Cell array where each cell contains the blobs in the
%            corresponding image. All the blobs from aBlobSeq are included,
%            but the array also contains point blobs for cells that were
%            tracked in frames that they were not detected in.

aChangeCentroids = GetArgs({'ChangeCentroids'}, {false}, true, varargin);

pointBlobSeq = cell(size(aBlobSeq));
cellBlobSeq = Cells2Blobs(aCells, aImData, 'Sub', true);
for t = 1:length(aBlobSeq)
    % Find sub-blobs inside all the super-blobs.
    subBlobs = cell(size(aBlobSeq{t}));
    for i = 1:length(cellBlobSeq{t})
        b = cellBlobSeq{t}(i);
        index = b.super.index;
        if ~isnan(index)
            subBlobs{index} = [subBlobs{index} b];
        else
            pointBlobSeq{t} = [pointBlobSeq{t} b];
        end
    end
    
    % Break the sub-blobs found in each super-blob
    for i = 1:length(aBlobSeq{t})
        if length(subBlobs{i}) == 1
            % There is only one sub-blob.
            b = subBlobs{i};
            b.boundingBox = aBlobSeq{t}(i).boundingBox;
            b.image = aBlobSeq{t}(i).image;
        elseif length(subBlobs{i}) > 1
            % Break the super-blobs into fragments.
            fragments = KMeansSplit(aBlobSeq{t}(i), length(subBlobs{i}));
            % Match the fragments to the cells by minimizing the sum of the
            % squared displacements.
            subCentroids = cat(1, subBlobs{i}.centroid);
            fragmentCentroids = cat(1, fragments.centroid);
            matches = MinSquareDist(subCentroids, fragmentCentroids);
            for j = 1:length(subBlobs{i})
                b = subBlobs{i}(j);
                b.boundingBox = fragments(matches(j)).boundingBox;
                b.image = fragments(matches(j)).image;
                if aChangeCentroids
                    [x, y, z] = b.GetPixelCoordinates();
                    b.centroid = [mean(x) mean(y) mean(z)];
                end
            end
        end
    end
end

oBlobSeq = cell(size(aBlobSeq));
for t = 1:length(aBlobSeq)
    oBlobSeq{t} = [aBlobSeq{t} pointBlobSeq{t}];
end
oBlobSeq = SortBlobs(oBlobSeq);
IndexBlobs(oBlobSeq)
end