function [oPointCells, oSegmentCells] = PointSegmentCells(aCells, varargin)
% Splits cells into cells with and without segments.
%
% Splits cells into one set of cells where all frames have segments and one
% set where no frames have segments. Cells with both frames with and frames
% without segments are split into multiple cell so that all parts have
% either all frames or no frames with segments. Parent cells and child
% cells are separated if they do not belong to the same category.
%
% Inputs:
% aCells - Array with the cell objects that are supposed to be processed.
%
% Outputs:
% oPointCells - Array of cell objects where no frames have segments.
% oSegmentCells - Array of cell objects where all frames have segments.
%
% Parameter/Value inputs:
% EndWithDeath - If this parameter is set to true, all new track ends will
%                have a death event. Otherwise the cells are classified as
%                disappearing.
%
% See also:
% Cell, Blob

% Parse property/value inputs.
aEndWithDeath = GetArgs({'EndWithDeath'}, {false}, true, varargin);

oPointCells = [];
oSegmentCells = [];

if isempty(aCells)
    return % empty input - empty output.
end

startCells = aCells;

% Go through all cells and add fragments to oPointsCells and oSegmentCells.
while ~isempty(startCells)
    c = startCells(1);
    ChangeRelations(c);
    
    % Which frames have segments?
    hasSegment = zeros(c.lifeTime, 1);
    for frame = c.firstFrame : c.lastFrame
        hasSegment(frame - c.firstFrame + 1) = c.HasSegment(frame);
    end
    
    % Breakpoints between segments and no segments.
    hasDiff = diff(hasSegment);
    
    % Split the cells at the breakpoints.
    dIndex = find(hasDiff);
    for i = length(dIndex) : -1 : 1  % Start from the end and chop off parts.
        newCell = c.Split(c.firstFrame + dIndex(i));
        c.disappeared = ~aEndWithDeath;  % Avoids introducing new death events.
        if hasDiff(dIndex(i)) == 1
            oSegmentCells = [oSegmentCells newCell]; %#ok<AGROW>
        else
            oPointCells = [oPointCells newCell]; %#ok<AGROW>
        end
    end
    
    % The cell left over after chopping off parts.
    if hasSegment(1)
        oSegmentCells = [oSegmentCells c]; %#ok<AGROW>
    else
        oPointCells = [oPointCells c]; %#ok<AGROW>
    end
    
    startCells(1) = [];
end

    function ChangeRelations(aC)
        % Break connections between parents and children.
        %
        % Cuts connections between parents and children if the last frame
        % of the parent has a segment and the first frame of the child has
        % no segment, or the other way around. When a child is removed from
        % a parent, the other child is appended as a continuation of the
        % parent track.
        %
        % Inputs:
        % aC - Cell for which links to the parent and the children may be
        %      broken.
        
        firstSeg = aC.HasSegment(aC.firstFrame);
        lastSeg = aC.HasSegment(aC.lastFrame);
        
        % The cell differs from its parent.
        p = aC.parent;
        if ~isempty(p)
            pSeg = p.HasSegment(p.lastFrame);
            if firstSeg ~= pSeg
                otherChild = aC.parent.OtherChild(aC);
                p.RemoveChildren()
                if ~isempty(otherChild)
                    otherSeg = otherChild.HasSegment(otherChild.firstFrame);
                    if otherSeg == pSeg
                        % CutBranch removes the other child from
                        % startCells, but not from the output arrays. If
                        % there is a time gap between the parent and the
                        % other child, that child becomes the only child
                        % and should not be removed.
                        if otherChild.firstFrame == p.lastFrame + 1
                            oSegmentCells(oSegmentCells == otherChild) = [];
                            oPointCells(oPointCells == otherChild) = [];
                        end
                        startCells = aC.CutBranch(startCells);
                    end
                end
            end
        end
        
        if ~isempty(aC.children)
            ch1 = aC.children(1);
            ch1Seg = ch1.HasSegment(ch1.firstFrame);
            if length(aC.children) > 1
                ch2 = aC.children(2);
                ch2Seg = ch2.HasSegment(ch2.firstFrame);
                if ch1Seg ~= lastSeg && ch2Seg ~= lastSeg
                    % Both children differ from the cell.
                    aC.RemoveChildren()
                elseif ch1Seg ~= lastSeg
                    % The first child differs from the cell.
                    if ch2.firstFrame == aC.lastFrame + 1
                        oSegmentCells(oSegmentCells == ch2) = [];
                        oPointCells(oPointCells == ch2) = [];
                    end
                    startCells = ch1.CutBranch(startCells);
                elseif ch2Seg ~= lastSeg
                    % The second child differs from the cell.
                    if ch1.firstFrame == aC.lastFrame + 1
                        oSegmentCells(oSegmentCells == ch1) = [];
                        oPointCells(oPointCells == ch1) = [];
                    end
                    startCells = ch2.CutBranch(startCells);
                end
            else
                if ch1Seg ~= lastSeg
                    aC.RemoveChildren()
                end
            end
        end
    end
end