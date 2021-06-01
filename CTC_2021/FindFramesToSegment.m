function oFrames = FindFramesToSegment(aFrames, aSequenceLength, aCount)

if aCount <= length(aFrames)
    oFrames = aFrames;
    return
end

distances = zeros(length(aFrames), aSequenceLength);
frameIndices = 1:aSequenceLength;
for i = 1:length(aFrames)
    distances(i,:) = abs(frameIndices - aFrames(i));
end

distances = sort(distances, 1);

candidates = true(1, aSequenceLength);
for i = 1:length(aFrames)
    distances_i = distances(i,:);
    candidates = candidates & (distances_i == max(distances_i(candidates)));
    if sum(candidates) == 1
        break
    end
end

newFrame = find(candidates, 1);
frames = sort([aFrames(:); newFrame]);
oFrames = FindFramesToSegment(frames, aSequenceLength, aCount);
end