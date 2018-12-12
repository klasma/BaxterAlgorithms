function ApplyOffsets(aCells, aOffset)
% Adds an offset to object centroids, in the direction of motion.
%
% The function is used to make the position error smaller for the
% MICROTUBULE data set in the ISBI Challenge 2012. The direction of motion
% is computed using forward difference for all displacements except the
% last, where backward difference is used.
%
% Inputs:
% aCells - Array of Cell objects for which the centroids should be shifted.
%          The offsets are applied both to the Cell objects and the Blob
%          objects that they contain.
% aOffset - The added offset in pixels.
%
% See also:
% Cell, Blob, Track

for i = 1:length(aCells)
    c = aCells(i);
    ff = c.firstFrame;
    lf = c.lastFrame;
    for t = ff:lf
        if c.lifeTime == 1
            % We do not have a direction of motion, so we cannot apply an
            % offset.
            continue
        end
        
        % Direction of migration. We use forward difference for all
        % displacements except the last, where backward difference is used.
        if t < lf
            xdir = c.cx(t-ff+2) - c.cx(t-ff+1);
            ydir = c.cy(t-ff+2) - c.cy(t-ff+1);
        else
            xdir = c.cx(t-ff+1) - c.cx(t-ff);
            ydir = c.cy(t-ff+1) - c.cy(t-ff);
        end
        
        dirLength = sqrt(xdir^2 + ydir^2);
        
        if dirLength == 0
            % The object did not move in the current time step, so the
            % direction of motion cannot be determined and therefore no
            % offset is added.
            continue
        end
        
        % Normalize to unit length.
        xdir = xdir / dirLength;
        ydir = ydir / dirLength;
        
        % Add the offset.
        c.cx(t-ff+1) = c.cx(t-ff+1) + xdir * aOffset;
        c.cy(t-ff+1) = c.cy(t-ff+1) + ydir * aOffset;
        c.blob(t-ff+1).centroid = [c.cx(t-ff+1) c.cy(t-ff+1)];
    end
end
end