function oCells = Matrix2Cell(...
    aMatrix,...
    aChildMatrix,...
    aDeathMatrix,...
    aBlobSeq,...
    aImData)
% Creates cells from a set of blobs and matrices with linking information.
%
% Inputs:
% aMatrix - Matrix which specifies in which blob each cell is in each
%           frame. The matrix has one row for each frame and one column for
%           each cell. Element (i,j) of the matrix has the index of the
%           blob that cell j is in in frame i.
% aChildMatrix - Matrix which defines mother-daughter relationships between
%                cells. The matrix has one row for each cell and two
%                columns with indices of daughter cells. The rows for cells
%                without daughter cells have the value NaN.
% aDeathMarix - Array which marks which cells undergo apoptosis. The array
%               has one element per cell. Cells that undergo apoptosis have
%               the value 1 and the other cells have the value 0.
% aBlobSeq - Cell array with blob objects. The cell array has one cell for
%            each time point. Each cell contains an array of Blob objects
%            which were segmented in that frame.
% aImData - ImageData object for the image sequence.
%
% Outputs:
% oCells - Array of Cell objects that was created from the inputs.
%
% See also:
% Track, ViterbiTrackLinking.cpp, Blob, Cell

% Create all cells.
if isempty(aMatrix)
    oCells = [];
else
    oCells(size(aMatrix,2)) = Cell();  % Pre-allocation.
    for cIndex = 1:size(aMatrix,2)
        fprintf('Creating cell %d / %d\n', cIndex, size(aMatrix, 2))
        firstFrame = find(aMatrix(:, cIndex) ~= 0, 1, 'first');
        lastFrame = find(aMatrix(:, cIndex) ~= 0, 1, 'last');
        % Create an empty Cell object.
        c = Cell(...
            'imageData', aImData,...
            'firstFrame', firstFrame,...
            'blob', []);
        % Add blobs to the Cell object one at a time.
        for t = firstFrame:lastFrame
            b = aBlobSeq{t}(aMatrix(t, cIndex));
            if isempty(b.super)
                b = b.CreateSub();
            end
            c.AddFrame(b);
        end
        oCells(cIndex) = c;
    end
end

% Link mother and daughter cells.
for cIndex = 1:size(aChildMatrix, 1)
    if all(aChildMatrix(cIndex, :) ~= 0)
        index1 = aChildMatrix(cIndex, 1);
        index2 = aChildMatrix(cIndex, 2);
        oCells(cIndex).AddChild(oCells(index1))
        oCells(cIndex).AddChild(oCells(index2))
    end
end

% Mark cells which disappear without undergoing apoptosis.
for cIndex = 1:length(oCells)
    if ~oCells(cIndex).divided &&...
            oCells(cIndex).lastFrame < length(aBlobSeq) &&...
            ~aDeathMatrix(cIndex)
        oCells(cIndex).disappeared =  true; %#ok<AGROW>
    end
end
end