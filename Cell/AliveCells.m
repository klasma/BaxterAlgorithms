function oCells = AliveCells(aCells, aTime)
% Find cells which are present in certain frames.
%
% Inputs:
% aCells - Cells that might or might not exist at the specified time-point.
% aTime - Time point or time-points when we want to find live cells. It can
%         be either a scalar for a single time-point or a two element
%         vector for a time interval. The time points are specified as
%         frames since the start of the experiment.
%
% Outputs:
% oCells - Cells that exist at the specified time.
%
% See also:
% AreCells, Cell

if isempty(aCells)
    oCells = [];
    return
end

if length(aTime) == 2
    start = aTime(1);
    stop = aTime(2);
else
    start = aTime;
    stop = aTime;
end

firstFrames = [aCells.firstFrame];
lifeTimes = [aCells.lifeTime];
lastFrames = firstFrames + lifeTimes - 1;

oCells = aCells(firstFrames <= stop & lastFrames >= start);
end