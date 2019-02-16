function maxValue = MaxPixelValue(aSeqPath)
% Checks what the maximum pixel value in a tif image sequence is.

tifs = GetNames(aSeqPath, 'tif');
maxValue = -inf;

for i = 1:length(tifs)
    %fprintf('Processing image %d / %d\n', i, length(tifs))
    tifPath = fullfile(aSeqPath, tifs{i});
    j = 1;
    while(true)
        try
            im = imread(tifPath, j);
            maxValue = max(maxValue, max(im(:)));
            j = j + 1;
        catch
            break
        end
    end
end
end