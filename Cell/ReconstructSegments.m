function oImage = ReconstructSegments(aImData, aCells, aFrame)
% Creates a segmentation label image from a set of tracks.
%
% ReconstructSegments generates an image where segmented cell pixels in a
% particular frame are labeled with the indices of the cells. The
% background consists of zeros, and the image has the same size as the
% microscope images. Cells that do not have regions in the frame will not
% give rise to any labeled pixels. If multiple cells share the same pixel,
% the cell with the highest index will label the pixel. False positive
% cells are not removed.
%
% Inputs:
% aImData - ImageData object associated with the image sequence.
% aCells - Array of cell objects.
% aFrame - Index of the image in the sequence.
%
% Outputs:
% oImage - Image with labels.
%
% See also:
% ReconstructSegmentsBlob, Cell, Blob

oImage = zeros(aImData.imageHeight, aImData.imageWidth, aImData.numZ);
for i = 1:length(aCells)
    if aCells(i).HasSegment(aFrame)
        blob = aCells(i).GetBlob(aFrame);
        bb = blob.boundingBox;
        im = blob.image;
        
        if aImData.numZ == 1  % 2D data.
            x1 = bb(1) + 0.5;
            x2 = bb(1) + bb(3) - 0.5;
            y1 = bb(2) + 0.5;
            y2 = bb(2) + bb(4) - 0.5;
            
            oImage(y1:y2, x1:x2) = max(oImage(y1:y2, x1:x2), im*i);
        else  % 3D data.
            x1 = bb(1) + 0.5;
            x2 = bb(1) + bb(4) - 0.5;
            y1 = bb(2) + 0.5;
            y2 = bb(2) + bb(5) - 0.5;
            z1 = bb(3) + 0.5;
            z2 = bb(3) + bb(6) - 0.5;
            
            oImage(y1:y2, x1:x2, z1:z2) = max(oImage(y1:y2, x1:x2, z1:z2), im*i);
        end
    end
end
end