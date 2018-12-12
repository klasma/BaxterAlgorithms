function AOGMR(aResPath, aGtPath, aCosts)
% Saves the AOGM measure and the errors needed to compute it to a file.
%
% The AOGM measure is an unnormalized version of the TRA measure that was
% used in the cell tracking challenges. It is a weighted sum of different
% tracking errors. The measure is described in [1]. The different tracking
% errors and the final AOGM measure is saved to a file named AOGMR_log.txt
% in the aResPath folder. The format of the log file is the same as in the
% log files produced by the stand-alone application provided together with
% [1].
%
% Inputs:
% aResPath - Folder with tracking results in the format of the cell
%            tracking challenges.
% aGtPath - Folder with ground truth tracks in the format of the cell
%           tracking challenges.
% aCosts - Array with costs of the different error types. If this input is
%          omitted, the default cost array [5 10 1 1 1.5 1] is used. The
%          error types are:
%          merged regions = 5
%          false negative regions = 10
%          false positive regions = 1
%          false positive links = 1
%          false negative links = 1.5
%          links with incorrect semantics = 1
%
% References:
% [1] Matula, P., Maška, M., Matula, P., Sorokin, D., de Solorzano, C. O.,
%     & Kozubek, M. (2014). Cell tracking accuracy measurement based on
%     comparison of acyclic oriented graphs.
%
% See also:
% AOGMR_BLACK, PerformanceTRA

if nargin == 2
    % Use the costs from the challenges.
    aCosts = [5 10 1 1 1.5 1];
end

% Find the names of all tif-files with label images.
resFiles = GetNames(aResPath, 'tif');
gtFiles = GetNames(aGtPath, 'tif');

% Read track information for computed tracks.
resTracks = readtable(fullfile(aResPath, 'res_track.txt'),....
    'Delimiter', ' ',...
    'ReadVariableNames', false);
if height(resTracks) > 0
    resTracks.Properties.VariableNames = {'index', 'start', 'stop', 'parent'};
    resMat = nan(max(resTracks.index), 4);
    for i = 1:length(resTracks.index)
        resMat(resTracks.index(i),:) =...
            [resTracks.index(i), resTracks.start(i) resTracks.stop(i) resTracks.parent(i)];
    end
    resTracks = array2table(resMat,...
        'VariableNames', {'index', 'start', 'stop', 'parent'});
    
    % Create a cell array to keep track of ground truth tracks that have been
    % matched to the regions in the computer generated tracks. There is one
    % cell for each computer generated track. The cells contain arrays with
    % ground truth track indices for all frames that the computer generated
    % track is present in. Frames with no match get the value nan.
    resMatches = cell(1,resTracks.index(end));
    for i = 1:length(resMatches)
        if ~isnan(resTracks.index(i))
            resMatches{i} = nan(1,resTracks.stop(i)-resTracks.start(i)+1);
        end
    end
else
    % Empty tracking result.
    resMatches = cell(1,0);
end

% Read track information for ground truth tracks.
gtTracks = readtable(fullfile(aGtPath, 'man_track.txt'),....
    'Delimiter', ' ',...
    'ReadVariableNames', false);
if height(gtTracks) > 0
    gtTracks.Properties.VariableNames = {'index', 'start', 'stop', 'parent'};
    gtMat = nan(max(gtTracks.index), 4);
    for i = 1:length(gtTracks.index)
        gtMat(gtTracks.index(i),:) =...
            [gtTracks.index(i), gtTracks.start(i) gtTracks.stop(i) gtTracks.parent(i)];
    end
    gtTracks = array2table(gtMat,...
        'VariableNames', {'index', 'start', 'stop', 'parent'});
    
    % Create a cell array to keep track of computer generated tracks that have
    % been matched to the regions in the ground truth tracks. There is one cell
    % for each ground truth track. The cells contain arrays with computer
    % generated track indices for all frames that the ground truth track is
    % present in. Frames with no match get the value nan.
    gtMatches = cell(1,gtTracks.index(end));
    for i = 1:length(gtMatches)
        if ~isnan(gtTracks.index(i))
            gtMatches{i} = nan(1,gtTracks.stop(i)-gtTracks.start(i)+1);
        end
    end
else
    % Empty ground truth.
    gtMatches = cell(1,0);
end

% Matrices that hold information about all errors. Each row corresponds to
% one error.
splits = zeros(0,2);                % T, Label
false_negatives = zeros(0,2);       % T, GT_Label
false_positives = zeros(0,2);       % T, Label
false_positive_links = zeros(0,4);  % T_1, Label_1, T_2, Label_2
false_negative_links = zeros(0,4);  % T_1, GT_Label_1, T_2, GT_Label_2
wrong_type_links = zeros(0,4);      % T_1, Label_1, T_2, Label_2

wbar = waitbar(0, '', 'Name', 'Computing tracking performance');

% Extract information that is necessary to pre-allocate arrays for 3D data.
% It is assumed that all frames have voxel volumes of the same size and
% that the computer generated volumes have the same size as the ground
% truth volumes.
gtInfo = imfinfo(fullfile(aGtPath, gtFiles{1}));
numZ = length(gtInfo);
w = gtInfo(1).Width;
h = gtInfo(1).Height;

t1 = str2double(regexp(gtFiles{1}, '(?<=man_track)\d+', 'match', 'once')) + 1;
for t = t1 : t1 + length(gtFiles) - 1
    waitbar(t/length(gtFiles), wbar)
    
    % Read uint16 label images.
    if numZ == 1
        gtIm = imread(fullfile(aGtPath, gtFiles{t-t1+1}));
        resIm = imread(fullfile(aResPath, resFiles{t}));
    else
        gtIm = zeros(h, w, numZ);
        for i = 1:numZ
            gtIm(:,:,i) = imread(fullfile(aGtPath, gtFiles{t-t1+1}), i);
        end
        resIm = zeros(h, w, numZ);
        for i = 1:numZ
            resIm(:,:,i) = imread(fullfile(aResPath, resFiles{t}), i);
        end
    end
    
    % Arrays of labels in this frame.
    resLabels = [0; unique(resIm(resIm ~= 0))];
    gtLabels = [0; unique(gtIm(gtIm ~= 0))];
    
    % The number of labels in this frame.
    resNum = length(resLabels);
    gtNum = length(gtLabels);
    
    % Mappings from labels to indices.
    resMap(resLabels+1) = 1:resNum; %#ok<AGROW>
    gtMap(gtLabels+1) = 1:gtNum; %#ok<AGROW>
    
    % Matrix which keeps track of overlaps between ground truth regions and
    % computer generated regions. The background regions are included as
    % region 1.
    overlaps = zeros(gtNum, resNum);
    
    % Count the overlaps. Background pixels in the ground truth do not
    % affect the results and are therefore excluded from the calculations
    % to save time.
    nz = find(gtIm > 0);
    for i = 1:length(nz)
        res = resMap(resIm(nz(i))+1);
        gt = gtMap(gtIm(nz(i))+1);
        overlaps(gt, res) = overlaps(gt, res) + 1;
    end
    
    % Sum to get the number of pixels in each ground truth region.
    gtCounts = sum(overlaps,2);
    
    % Remove the background counts from the ground truth.
    overlaps = overlaps(2:end,:);
    gtCounts = gtCounts(2:end);
    gtNum = gtNum - 1;
    gtLabels = gtLabels(2:end);
    
    % Remove the background counts from the computer generated tracks.
    overlaps = overlaps(:,2:end);
    resNum = resNum - 1;
    resLabels = resLabels(2:end);
    
    % The computer generated regions need to cover more than half of a
    % ground truth region to be considered matching.
    if isempty(overlaps)
        % A special cases is used to avoid comparing empty arrays with
        % different dimensions.
        matches = zeros(size(overlaps));
    else
        matches = overlaps > repmat(gtCounts, 1, resNum) / 2;
    end
    
    % Insert matching region indices into gtMatches and resMatches.
    % Computed regions which cover more than one ground truth region are
    % not considered matching here, because the corresponding edges are
    % considered to be incorrect.
    resMatchSum = sum(matches,1);
    for i = 1:gtNum
        match = find(matches(i,:));
        if ~isempty(match) && resMatchSum(match) == 1
            r = resLabels(match);
            g = gtLabels(i);
            gtMatches{g}(t-gtTracks.start(g)) = r;
            resMatches{r}(t-resTracks.start(r)) = g;
        end
    end
    
    gtMatchSum = sum(matches,2);
    
    % Add false negatives.
    fn = gtLabels(gtMatchSum == 0);
    false_negatives = [false_negatives; t*ones(size(fn))-1 fn]; %#ok<AGROW>
    
    % Add false positives.
    fp = resLabels(resMatchSum == 0);
    false_positives = [false_positives; t*ones(size(fp))-1 fp]; %#ok<AGROW>
    
    % Add clusters that need to be split. Clusters with more than two cells
    % are added once for each split that needs to be performed.
    numSplits = sum(max(sum(matches,1)-1,0));
    s = zeros(numSplits,2);  % Pre-allocate the right size.
    index = 1;
    for i = 1:resNum
        for j = 2:resMatchSum(i)
            s(index,1) = t-1;
            s(index,2) = resLabels(i);
            index = index + 1;
        end
    end
    splits = [splits; s]; %#ok<AGROW>
end

% Go through all ground truth edges and add false negatives and edges with
% incorrect semantics.
for i = 1:length(gtMatches)
    if isempty(gtMatches{i})
        continue
    end
    
    % Look at parent edges in the ground truth.
    gp = gtTracks.parent(i);
    r = gtMatches{i}(1);
    if gp ~= 0
        gt1 = gtTracks.stop(gp);
        gt2 = gtTracks.start(i);
        if isnan(r)
            % The start of the ground truth track is not matched.
            false_negative_links = [false_negative_links; gt1 gp gt2 i]; %#ok<AGROW>
        else
            rp = resTracks.parent(r);
            if rp == 0 || rp ~= gtMatches{gp}(end) ||...
                    resTracks.stop(rp) ~= gt1 || resTracks.start(r) ~= gt2
                % The parent edge is not correct.
                if gtMatches{gp}(end) == r && gt2 == gt1+1
                    % The mitosis is replaced by a migration.
                    wrong_type_links = [wrong_type_links;  gt1 r gt2 r]; %#ok<AGROW>
                else
                    % The edge is not present at all.
                    false_negative_links = [false_negative_links; gt1 gp gt2 i]; %#ok<AGROW>
                end
            end
        end
    end
    
    % Look at migration edges in the ground truth.
    for j = 1:length(gtMatches{i})-1
        r1 = gtMatches{i}(j);
        t1 = gtTracks.start(i)+j-1;
        r2 = gtMatches{i}(j+1);
        t2 = t1 + 1;
        if r1 ~= r2
            if isnan(r2) || resTracks.parent(r2) ~= r1
                false_negative_links = [false_negative_links; t1 i t2 i]; %#ok<AGROW>
            end
        end
    end
end

% Go through all computer generated tracks and add false positives and more
% edges with incorrect semantics.
for i = 1:length(resMatches)
    if isempty(resMatches{i})
        continue
    end
    
    % Look at parent edges in the computer generated tracks.
    rp = resTracks.parent(i);
    g = resMatches{i}(1);
    if rp ~= 0
        rt1 = resTracks.stop(rp);
        rt2 = resTracks.start(i);
        if ~isnan(g) && ~isnan(resMatches{rp}(end))
            gp = gtTracks.parent(g);
            if gp == 0 || gp ~= resMatches{rp}(end) ||...
                    gtTracks.stop(gp) ~= rt1 || gtTracks.start(g) ~= rt2
                % The parent edge is not correct.
                if resMatches{rp}(end) == g && rt2 == rt1+1
                    % The mitosis is replaced by a migration.
                    wrong_type_links = [wrong_type_links;  rt1 rp rt2 i]; %#ok<AGROW>
                else
                    % The edge is not present at all.
                    false_positive_links = [false_positive_links; rt1 rp rt2 i]; %#ok<AGROW>
                end
            end
        end
    end
    
    % Look at migration edges in the computer generated tracks.
    for j = 1:length(resMatches{i})-1
        g1 = resMatches{i}(j);
        t1 = resTracks.start(i)+j-1;
        g2 = resMatches{i}(j+1);
        t2 = t1 + 1;
        if g1 ~= g2
            if ~isnan(g1) && ~isnan(g2) &&...
                    g1 ~= g2 &&...
                    gtTracks.parent(g2) ~= g1
                false_positive_links = [false_positive_links; t1 i t2 i]; %#ok<AGROW>
            end
        end
    end
end

% Create a log file of the same type as in the stand-alone AOGM software.

fid = fopen(fullfile(aResPath, 'AOGMR_log.txt'), 'w');

fprintf(fid, '----------Splitting Operations (Penalty=%g)----------\r\n', aCosts(1));
for i = 1:size(splits,1)
    fprintf(fid, 'T=%d Label=%d\r\n', splits(i,1), splits(i,2));
end

fprintf(fid, '----------False Negative Vertices (Penalty=%g)----------\r\n', aCosts(2));
for i = 1:size(false_negatives,1)
    fprintf(fid, 'T=%d GT_label=%d\r\n', false_negatives(i,1), false_negatives(i,2));
end

fprintf(fid, '----------False Positive Vertices (Penalty=%g)----------\r\n', aCosts(3));
for i = 1:size(false_positives,1)
    fprintf(fid, 'T=%d Label=%d\r\n', false_positives(i,1), false_positives(i,2));
end

fprintf(fid, '----------Redundant Edges To Be Deleted (Penalty=%g)----------\r\n', aCosts(4));
for i = 1:size(false_positive_links,1)
    fprintf(fid, '[T=%d Label=%d] -> [T=%d Label=%d]\r\n',...
        false_positive_links(i,1),...
        false_positive_links(i,2),...
        false_positive_links(i,3),...
        false_positive_links(i,4));
end

fprintf(fid, '----------Edges To Be Added (Penalty=%g)----------\r\n', aCosts(5));
for i = 1:size(false_negative_links,1)
    fprintf(fid, '[T=%d GT_label=%d] -> [T=%d GT_label=%d]\r\n',...
        false_negative_links(i,1),...
        false_negative_links(i,2),...
        false_negative_links(i,3),...
        false_negative_links(i,4));
end

fprintf(fid, '----------Edges with Wrong Semantics (Penalty=%g)----------\r\n', aCosts(6));
for i = 1:size(wrong_type_links,1)
    fprintf(fid, '[T=%d Label=%d] -> [T=%d Label=%d]\r\n',...
        wrong_type_links(i,1),...
        wrong_type_links(i,2),...
        wrong_type_links(i,3),...
        wrong_type_links(i,4));
end

fprintf(fid, '=================================================================================\r\n');

aogm = size(splits,1) * aCosts(1) +...
    size(false_negatives,1) * aCosts(2) +...
    size(false_positives,1) * aCosts(3) +...
    size(false_positive_links,1) * aCosts(4) +...
    size(false_negative_links,1) * aCosts(5) +...
    size(wrong_type_links,1) * aCosts(6);

fprintf(fid, 'AOGM value: %g\r\n', aogm);
fclose(fid);
delete(wbar)
end