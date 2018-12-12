function oCells = ErodeFOI(aCells, aBorder, aImData, varargin)
% Removes cells outside the field of interest.
%
% The function removes all cell regions that don't have any pixels inside
% the field of interest (FOI). The time points where the cells leave the
% FOI completely are removed from the cell trajectories. If a cell moves
% out of the field of view and then comes back, it will be split into two
% cells.
%
% Inputs:
% aCells - Cells that might have outlines that lie completely outside the
%          FOI.
% aBorder - The number of pixels on each side of the image that don't
%           belong to the FOI. The function effectively erodes all the
%           image borders by aBorder pixels.
% aImData - ImageData object associated with the image sequence.
%
% Property/Value inputs:
% DeleteFP - If this is set to true, all cell track fragments will be
%            erased instead of be turned into false positive tracks. The
%            default is false.
%
% Outputs:
% oCells - Cells where all regions without pixels in the FOI have been
%          removed.

% Parse property/value inputs.
aDeleteFP = GetArgs({'DeleteFP'}, {false}, true, varargin);

if aBorder == 0
    % No border erosion.
    oCells = aCells;
    return
end

% Don't change cell objects outside this file.
cells = CopyCellVec(aCells);

oCells = [];        % Cell tracks in the field of interest.
newFPCells = [];    % Cell tracks outside the field of interest.

% Define the field of interest.
xmin = 1 + aBorder;
ymin = 1 + aBorder;
xmax = aImData.imageWidth - aBorder;
ymax = aImData.imageHeight - aBorder;

% Remove blobs that are outside the field of interest.
for i = 1:length(cells)
    c = cells(i);
    ff = c.firstFrame;
    lf = c.lastFrame;
    inFOI = false;
    for t = ff : lf
        b = c.GetBlob(t);
        x0 = b.boundingBox(1);
        y0 = b.boundingBox(2);
        ind = find(b.image);
        [dy,dx,~] = ind2sub(size(b.image), ind);
        x = x0 - 0.5 + dx;  % x-coordinates of blob pixels.
        y = y0 - 0.5 + dy;  % y-coordinates of blob pixels.
        
        % True if at least one pixel was in the FOI in previous time point.
        inFOI_prev = inFOI;
        % True if at least one pixel was in the FOI in current time point.
        inFOI = ~all(x < xmin | x > xmax | y < ymin | y > ymax);
        
        if t == ff
            if inFOI
                % The first frame lies in the FOI.
                oCells = [oCells c]; %#ok<AGROW>
            else
                if ~isempty(c.parent)
                    % Break the parent-child link if the child is outside.
                    c.parent.children(c.parent.children == c) = [];
                    c.parent = [];
                end
                newFPCells = [newFPCells c]; %#ok<AGROW>
            end
        elseif inFOI_prev && ~inFOI
            % Found a track that leaves the FOI.
            tmp = c;
            c = c.Split(t);
            tmp.disappeared = true;
            newFPCells = [newFPCells c]; %#ok<AGROW>
        elseif ~inFOI_prev && inFOI
            % Found a track that enters the FOI.
            tmp = c;
            c = c.Split(t);
            tmp.disappeared = true;
            oCells = [oCells c]; %#ok<AGROW>
        end
        
        if t == lf && ~inFOI
            c.RemoveChildren();
        end
    end
end

for i = 1:length(newFPCells)
    newFPCells(i).isCell = false; %#ok<AGROW>
end

if ~aDeleteFP
    oCells = [oCells newFPCells];
end
end