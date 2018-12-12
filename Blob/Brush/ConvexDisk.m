function oImage = ConvexDisk(aR)
% Creates a circular disk which is "convex" according to bwconvhull.
%
% A disk produced with this function will not change if the built in
% function for convex hulls (bwconvhull) is applied to it. The disk is made
% symmetric, even though the output from bwconvhull is not always
% symmetric. The disk can be used for example as a brush in segmentation
% editing.
%
% Inputs:
% aR - Radius of the disk.
%
% Outputs:
% oImage - Binary image where the disk is 1s and the background is 0s.
%
% See also:
% ConvexEllipse, Ellipse, Brush

oImage = ConvexEllipse([aR aR]);
end