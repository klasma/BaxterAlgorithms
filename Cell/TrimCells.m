function [oCells, oTrimmedStart, oTrimmedEnd] = TrimCells(aCells)
% Trims tracking results, so that they all start and end at the same time.
%
% If different image sequences have different values on the setting
% 'startT', meaning that the acquisition was started at different time
% points relative to the start of the experiment, the tracking results will
% be trimmed in the beginning. After that, all image sequences will start
% at the same point in time and have the same value for startT. If the
% image sequences have different lengths after that, they will be trimmed
% at the end, so that they have the same number of frames. The changes are
% only applied to the Cell objects in the inputs, and to the ImageData
% objects that they point to. No changes are made to the image sequences,
% the settings for the image sequences, or the saved tracking results.
% Image sequences are allowed to be shorter than other image sequences if
% all the cells die or leave the field of view before the end of the
% sequence. This function is meant to be used before plotting functions are
% executed, and it requires that the image sequences have the same time
% between images.
%
% Inputs:
% aCells - Array of cells from different image sequences.
%
% Outputs:
% oCells - Array with cells in the trimmed tracking results.
% oTrimmedStart - True if cells were trimmed at the beginning.
% oTrimmedEnd - True if cells were trimmed at the end.
%
% See also:
% Cell

oCells = aCells;

dTs = [oCells.dT];
if ~all(dTs == dTs(1))
    error('All cells must have the same time between images.')
end

% Align the starts of the image sequences.
startTimes = [oCells.startT];
newStartTime = max(startTimes);
cropTimes = newStartTime - startTimes;
newStartFrames = round(cropTimes .* (3600./dTs)) + 1;
if any(newStartFrames > 1)
    % Trim the cells at the beginning.
    keep = true(size(oCells));  % Binary array indicating which cells to keep.
    for i = 1:length(oCells)
        newStart = newStartFrames(i);
        if newStart == 1
            % No trimming is required for this cell.
            continue
        end
        
        c = oCells(i);
        if c.firstFrame < newStart
            if c.lastFrame < newStart
                % The whole cells is removed.
                c.RemoveChildren();
                keep(i) = false;
            else
                % Replace the cell by a trimmed version.
                newCell = c.Split(newStart);
                oCells(i) = newCell;
            end
        end
    end
    for i = 1:length(oCells)
        % Modify firstFrame at the end to avoid problems in Cell.Split.
        oCells(i).firstFrame = oCells(i).firstFrame - newStartFrames(i) + 1;
    end
    oCells = oCells(keep);
    
    % Update the ImageData objects based on the trimming at the beginning.
    imDatas = unique([oCells.imageData]);
    for i = 1:length(imDatas)
        imDatas(i).sequenceLength = imDatas(i).sequenceLength -...
            round((newStartTime - imDatas(i).Get('startT')) .* (3600./imDatas(i).dT));
        imDatas(i).Set('startT', newStartTime)
    end
    
    oTrimmedStart = true;
else
    oTrimmedStart = false;
end

% Align the ends of the image sequences. We look at cells that make it to
% the end of the image sequences, as the sequences where all cells die or
% disappear before the last frame are allowed to be shorter than the
% others.
survivingCells = oCells([oCells.survived]);
endFrames = [survivingCells.lastFrame];
newEndFrame = min(endFrames);
if any(endFrames > newEndFrame)
    % Trim the cells at the end.
    keep = true(size(oCells));  % Binary array indicating which cells to keep.
    for i = 1:length(oCells)
        c = oCells(i);
        if c.lastFrame > newEndFrame
            if c.firstFrame > newEndFrame
                % The whole cell is removed.
                keep(i) = false;
                if ~isempty(c.parent)
                    c.parent.RemoveChildren()
                end
            else
                % The cell is trimmed.
                c.Split(newEndFrame+1);
            end
        end
    end
    oCells = oCells(keep);
    
    % Update the ImageData objects based on the trimming at the end.
    imDatas = unique([oCells.imageData]);
    for i = 1:length(imDatas)
        imDatas(i).sequenceLength = min(imDatas(i).sequenceLength, newEndFrame);
    end
    
    oTrimmedEnd = true;
else
    oTrimmedEnd = false;
end
end