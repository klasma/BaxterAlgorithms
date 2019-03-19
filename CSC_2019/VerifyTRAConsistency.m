function VerifyTRAConsistency(aResPath)

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
end

resFiles = GetNames(aResPath, 'tif');

inconsistentTracks = [];
for t = 1:length(resFiles)
   fprintf('Checking track consistentcy in frame %d / %d\n', t, length(resFiles))
   im = ReadTifStack(fullfile(aResPath, resFiles{t}));
   tracksInIm = unique(im);
   tracksInIm = setdiff(tracksInIm, 0);
   
   tracksPresent = false(height(resTracks),1);
   for i = 1:height(resTracks)
       if resTracks.start(i)+1 <= t && resTracks.stop(i)+1 >= t
           tracksPresent(resTracks.index(i)) = true;
       end
   end
   tracksInTextFile = find(tracksPresent);
   
   inconsistentTracks = [inconsistentTracks; setxor(tracksInIm, tracksInTextFile)];
end
inconsistentTracks = unique(inconsistentTracks);

for i = 1:length(inconsistentTracks)
    fprintf('Track %d is not consistent\n', inconsistentTracks(i))
end

if isempty(inconsistentTracks)
    fprintf('All tracks are consistent\n')
end
end