function oOverlap = Overlap(aBlob1, aBlob2)
% Calculates the amount of overlap in pixels or voxels between two blobs.
%
% First the function checks if the boundingboxes of the blobs overlap. If
% they don't 0 is returned without further computation. If one of the blobs
% does not have a region associated with it, the overlap is defined to be
% 0. The function works for blobs in both 2 and 3 dimensions.
%
% Inputs:
% aBlob1 - First blob object.
% aBlob2 - Second blob object.
%
% Oputs:
% oOverlap - Amount of overlap measured in pixels or voxels.
%
% See also:
% Blob


bb1 = aBlob1.boundingBox;
bb2 = aBlob2.boundingBox;

if any(isnan(bb1)) || any(isnan(bb2))
    % At least one blob does not have a region.
    oOverlap = 0;
    return
end


% Cut out the pieces that overlap. x1 and x2 define the beginning and the
% end of the x-overlap between the blobs, in image coordinates.
if length(bb1) == 4 % 2D data.
    x1 = max(bb1(1), bb2(1));
    x2 = min(bb1(1)+bb1(3)-1, bb2(1)+bb2(3)-1);
    if x2 < x1 % No overlap in x.
        oOverlap = 0;
        return
    end
    
    y1 = max(bb1(2), bb2(2));
    y2 = min(bb1(2)+bb1(4)-1, bb2(2)+bb2(4)-1);
    if y2 < y1 % No overlap in y.
        oOverlap = 0;
        return
    end
    
    % The part of the fist blob image that overlaps with the second.
    subIm1 = aBlob1.image(y1-bb1(2)+1 : y2-bb1(2)+1, x1-bb1(1)+1 : x2-bb1(1)+1);
    % The part of the second blob image that overlaps with the first.
    subIm2 = aBlob2.image(y1-bb2(2)+1 : y2-bb2(2)+1, x1-bb2(1)+1 : x2-bb2(1)+1);
else  % 3D data.
    x1 = max(bb1(1), bb2(1));
    x2 = min(bb1(1)+bb1(4)-1, bb2(1)+bb2(4)-1);
    if x2 < x1 % No overlap in x.
        oOverlap = 0;
        return
    end
    
    y1 = max(bb1(2), bb2(2));
    y2 = min(bb1(2)+bb1(5)-1, bb2(2)+bb2(5)-1);
    if y2 < y1 % No overlap in y.
        oOverlap = 0;
        return
    end
    
    z1 = max(bb1(3), bb2(3));
    z2 = min(bb1(3)+bb1(6)-1, bb2(3)+bb2(6)-1);
    if z2 < z1 % No overlap in z.
        oOverlap = 0;
        return
    end
    
    % The part of the fist blob image that overlaps with the second.
    subIm1 = aBlob1.image(...
        y1-bb1(2)+1 : y2-bb1(2)+1,...
        x1-bb1(1)+1 : x2-bb1(1)+1,...
        z1-bb1(3)+1 : z2-bb1(3)+1);
    % The part of the second blob image that overlaps with the first.
    subIm2 = aBlob2.image(...
        y1-bb2(2)+1 : y2-bb2(2)+1,...
        x1-bb2(1)+1 : x2-bb2(1)+1,...
        z1-bb2(3)+1 : z2-bb2(3)+1);
end

oOverlap = sum(subIm1(:) & subIm2(:));
end