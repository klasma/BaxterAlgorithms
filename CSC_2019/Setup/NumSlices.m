function num = NumSlices(aSeqPath)
% Checks how many z-slices a tif-stack has.

tifs = GetNames(aSeqPath, 'tif');

tifPath = fullfile(aSeqPath, tifs{1});
num = 0;
while(true)
    try
        imread(tifPath, num + 1);
        num = num + 1;
    catch
        break
    end
end
end