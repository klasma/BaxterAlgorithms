function oCells = CropCells(aCells, aFrame1, aFrame2, aX1, aX2, aY1, aY2, aZ1, aZ2)
% Selects all cells which are inside a 3D volume and a time interval.
%
% Point blobs are considered to be inside the volume if they are inside any
% of the pixels in the defined bounding box. Blobs with a segmentation mask
% are considered to be inside the volume if any of their pixels are in the
% bounding box.
%
% Inputs:
% aCells - Array of cells to select from.
% aFrame1 - First time point in time interval.
% aFrame2 - Last time point in time interval.
% aX1 - Smallest x-value (horizontal dimension).
% aX2 - Largest x-value (horizontal dimension).
% aY1 - Smallest y-value (vertical dimension).
% aY2 - Largest y-value (vertical dimension).
% aZ1 - Smallest z-value (depth dimension in 3D data).
% aZ2 - Smallest z-value (depth dimension in 3D data).
%
% Outputs:
% oCells - Array with selected cells. The cells are not modified or cloned.
%
% See also:
% CropBlobs

oCells = [];
cells = AliveCells(aCells, [aFrame1 aFrame2]);

for i = 1:length(cells)
    c = cells(i);
    for t = max(c.firstFrame,aFrame1) : min(c.lastFrame,aFrame2)
        b = c.GetBlob(t);
        
        if any(isnan(b.boundingBox))
            % Point blob.
            
            if length(b.boundingBox) == 4
                % Don't look at the z-dimension for 2D data.
                x = c.GetCx(t);
                y = c.GetCy(t);
                if x >= aX1-0.5 && x <= aX2+0.5 &&...
                        y >= aY1-0.5 && y <= aY2+0.5
                    oCells = [oCells c]; %#ok<AGROW>
                    break
                end
            else
                x = c.GetCx(t);
                y = c.GetCy(t);
                z = c.GetCz(t);
                if x >= aX1-0.5 && x <= aX2+0.5 &&...
                        y >= aY1-0.5 && y <= aY2+0.5 &&...
                        z >= aZ1-0.5 && z <= aZ2+0.5
                    oCells = [oCells c]; %#ok<AGROW>
                    break
                end
            end
        else
            % Blob with a pixel region.
            
            [y1, y2, x1, x2, z1, z2] = b.GetBoundaryCoordinates();
            [h, w, d] = size(b.image);
            
            % The number of pixels outside the volume on each side.
            dx1 = max(aX1-x1,0);
            dx2 = max(x2-aX2,0);
            dy1 = max(aY1-y1,0);
            dy2 = max(y2-aY2,0);
            dz1 = max(aZ1-z1,0);
            dz2 = max(z2-aZ2,0);
            
            if dx1 < w && dx2 < w && dy1 < h && dy2 < h && dz1 < d && dz2 < d
                oCells = [oCells c]; %#ok<AGROW>
                break
            end
        end
    end
end
end