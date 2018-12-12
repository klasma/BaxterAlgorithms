function AOGMR_BLACK(aGtPath, aCosts)
% Computes the AOGM measure for an empty set of tracks.
%
% The AOGM measure is a performance measure for tracking accuracy which is
% described in [1]. This function computes the AOGM measure on an image
% sequence, for an empty set of tracks. The function operates on tracking
% ground truths in the format that was used in the cell tracking
% challenges, and saves a log file with the computed results. The log file
% uses the same format as the stand-alone application provide together with
% [1]. The log file contains the AOGM measure and information about all
% tracking errors that an empty tracking result would have. The only types
% of errors that occur are false negatives regions and false negative
% links, but the log files contain headings for other error types too. The
% function is fast because it only looks in text files with track
% information, and never opens the tif files with pixel masks.
%
% Inputs:
% aGtPath - Folder with ground truth tracks in the format of the cell
%           tracking challenges.
% aCosts - Array with costs of the different error types. If this input is
%          omitted, the default cost array [5 10 1 1 1.5 1] is used. The
%          error types are:
%          (merged regions = 5)
%          false negative regions = 10
%          (false positive regions = 1)
%          (false positive links = 1)
%          false negative links = 1.5
%          (links with incorrect semantics = 1)
%
% References:
% [1] Matula, P., Maška, M., Matula, P., Sorokin, D., de Solorzano, C. O.,
%     & Kozubek, M. (2014). Cell tracking accuracy measurement based on
%     comparison of acyclic oriented graphs.
%
% See also:
% AOGMR, PerformanceTRA

if nargin == 1
    % Use the costs from the challenges.
    aCosts = [5 10 1 1 1.5 1];
end

% Read track information for ground truth tracks.
gtTracks = readtable(fullfile(aGtPath, 'man_track.txt'),....
    'Delimiter', ' ',...
    'ReadVariableNames', false);
gtTracks.Properties.VariableNames = {'index', 'start', 'stop', 'parent'};

% Matrices that hold information about all errors. Each row corresponds to
% one error. An upper bound on the number of errors is computed so that the
% matrices can be pre-allocated to save time.
maxSize = length(gtTracks.index) * max(gtTracks.stop);
false_negatives = zeros(maxSize,2);       % T, GT_Label
false_negative_links = zeros(maxSize,4);  % T_1, GT_Label_1, T_2, GT_Label_2

% Add errors to the error matrices.
cnt1 = 1;
cnt2 = 1;
for i = 1:length(gtTracks.index)
    % Missing regions.
    for t = gtTracks.start(i) : gtTracks.stop(i)
        false_negatives(cnt1,:) = [t gtTracks.index(i)];
        cnt1 = cnt1 + 1;
    end
    
    % Mitotic events.
    if gtTracks.parent(i) ~= 0
        p = find(gtTracks.index == gtTracks.parent(i), 1, 'first');
        false_negative_links(cnt2,:) =...
            [gtTracks.stop(p) gtTracks.parent(i) gtTracks.start(i) gtTracks.index(i)];
        cnt2 = cnt2 + 1;
    end
    
    % Migrations.
    for t = gtTracks.start(i) : gtTracks.stop(i)-1
        false_negative_links(cnt2,:) =...
            [t gtTracks.index(i) t+1 gtTracks.index(i)];
        cnt2 = cnt2 + 1;
    end
end
% Remove unused rows from the error matrices.
false_negatives = false_negatives(1:cnt1-1,:);
false_negative_links = false_negative_links(1:cnt2-1,:);

% Create a log file of the same type as in the stand-alone AOGM software.

fid = fopen(fullfile(aGtPath, 'AOGMR_BLACK_log.txt'), 'w');

fprintf(fid, '----------Splitting Operations (Penalty=%g)----------\r\n', aCosts(1));

fprintf(fid, '----------False Negative Vertices (Penalty=%g)----------\r\n', aCosts(2));
for i = 1:size(false_negatives,1)
    fprintf(fid, 'T=%d GT_label=%d\r\n', false_negatives(i,1), false_negatives(i,2));
end

fprintf(fid, '----------False Positive Vertices (Penalty=%g)----------\r\n', aCosts(3));

fprintf(fid, '----------Redundant Edges To Be Deleted (Penalty=%g)----------\r\n', aCosts(4));

fprintf(fid, '----------Edges To Be Added (Penalty=%g)----------\r\n', aCosts(5));
for i = 1:size(false_negative_links,1)
    fprintf(fid, '[T=%d GT_label=%d] -> [T=%d GT_label=%d]\r\n',...
        false_negative_links(i,1),...
        false_negative_links(i,2),...
        false_negative_links(i,3),...
        false_negative_links(i,4));
end

fprintf(fid, '----------Edges with Wrong Semantics (Penalty=%g)----------\r\n', aCosts(6));

fprintf(fid, '=================================================================================\r\n');

aogm = size(false_negatives,1) * aCosts(2) +...
    size(false_negative_links,1) * aCosts(5);

fprintf(fid, 'AOGM value: %g\r\n', aogm);
fclose(fid);
end