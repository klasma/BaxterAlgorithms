function oOnBorder = IsCellOnBorder(aCells, aImData)
% Determines which cells touch the image border.
%
% The function returns a boolean vector that specifies if cells touch the
% image border in at least one image of the image sequence. The function
% only uses the bounding box of the cell Blobs, so it assumes that the
% boundingboxes are tight. Point blobs are never considered to be adjacent
% to the image boundary.
%
% Inputs:
% aCells - Array of Cells.
% aImData - ImageData object associated with the image sequence.
%
% Outputs:
% oOnBorder - Boolean vector specifying what cells touch the image
%             boundary.

oOnBorder = false(size(aCells));

for cIndex = 1:length(aCells)
    blobs = aCells(cIndex).blob;
    for bIndex = 1:length(blobs)
        bb = blobs(bIndex).boundingBox;
        if any(isnan(bb))
            % Point blob.
            continue
        end
        if bb(1) == 0.5 ||...
                bb(2) == 0.5 ||...
                bb(1)+bb(3)-0.5 == aImData.imageWidth ||...
                bb(2)+bb(4)-0.5 == aImData.imageHeight
            % The bounding box is adjacent to the image boundary.
            oOnBorder(cIndex) = true;
            break;
        end
    end
end
end