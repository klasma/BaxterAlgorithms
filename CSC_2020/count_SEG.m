segFolder = 'C:\CTC2020\Training\Fluo-N3DL-TRIF\Analysis\01_GT\SEG';
tifs = GetNames(segFolder, 'tif');

frames = zeros(size(tifs));
counts = zeros(size(tifs));
for i = 1:length(frames)
    fprintf('Processig image % d / %d\n', i, length(frames))
    frameStr = regexpi(tifs{i}, '(?<=man_seg_?)\d+', 'match', 'once');
    frames(i) = str2double(frameStr);
    im = imread(fullfile(segFolder, tifs{i}));
    counts(i) = numel(unique(im(im ~= 0)));
end

uniqueFrames = unique(frames);
frameCounts = zeros(size(uniqueFrames));
frameSums = zeros(size(uniqueFrames));
for i = 1:length(uniqueFrames)
    frameSums(i) = sum(counts(frames == uniqueFrames(i)));
    frameCounts(i) = sum(frames == uniqueFrames(i));
end

[frameSums, order] = sort(frameSums, 'descend');
uniqueFrames = uniqueFrames(order);
frameCounts = frameCounts(order);

for i = 1:length(uniqueFrames)
    fprintf('frame %-03d has %-02d images and %-02d cells\n', uniqueFrames(i), frameCounts(i), frameSums(i))
end