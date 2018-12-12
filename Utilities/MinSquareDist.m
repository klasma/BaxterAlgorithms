function oOrder = MinSquareDist(aStart, aGoal)
% Performs bipartite matching which minimizes the sum of squared distances.
%
% MinSquareDist finds the matching between two sets of points that
% minimizes the sum of the squared distances between matched points. The
% sets of point can have coordinate vectors of arbitrary length, and they
% can have different numbers of points. The matching is done using the
% Hungarian algorithm. Dummy nodes are introduced if the sets have
% different numbers of points, but the function still minimizes the sum of
% squared distances between matched points. All points in the set with
% fewest points will be matched.
%
% Inputs:
% aStart - m x r matrix with the coordinates of the m r-dimensional points
%          in the first set of points.
% aGoal - n x r matrix with the coordinates of the n r-dimensional points
%         the second set of points.
%
% Outputs:
% oOrder - Indices of the points in the second set of points that are
%          matched to the sorted list of points in the first set. Point
%          oOrder(i) in the  second set is matched to point i in the first
%          set.
%
% See also:
% Hungarian

m = size(aStart,1);
n = size(aGoal,1);

% Distances from all starting points to all goal points.
dist = zeros(m, n);
for i = 1:m
    for j = 1:n
        dist(i,j) = norm(aGoal(j,:) - aStart(i,:));
    end
end

% Pad the distance matrix with zeros, so that it becomes square.
% Corresponds to introducing dummy nodes with zero cost of matching. The
% matching cost can be set to any value, as the number of unmatched points
% is the same no matter how the matching is done.
if m > n
    dist = [dist zeros(m,m-n)];
elseif n > m
    dist = [dist; zeros(n-m,n)];
end

% Solve assignment problem.
oOrder = Hungarian(dist);
end