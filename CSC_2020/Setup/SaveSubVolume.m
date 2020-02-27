function SaveSubVolume(aSeqPath, aNewSeqPath, aX, aY, aZ, aT, aRenameFunction)
% Saves a z-stack with a small portion of a z-stack sequence.

if exist(aNewSeqPath, 'dir')
    rmdir(aNewSeqPath, 's')
end
mkdir(aNewSeqPath)

tifs = GetNames(aSeqPath, 'tif');
for t = aT(1):aT(2)
    fprintf('Saving time point %d / %d.\n', t, aT(2)-aT(1)+1)
    oldPath = fullfile(aSeqPath, tifs{t});
    if nargin > 6
        newPath = fullfile(aNewSeqPath, aRenameFunction(tifs{t}));
    else
        newPath = fullfile(aNewSeqPath, tifs{t});
    end
    for z = aZ(1):aZ(2)
        im = imread(oldPath, z);
        im = im(aY(1):aY(2), aX(1):aX(2));
        imwrite(im, newPath, 'WriteMode','append')
    end
end
fprintf('Done cropping images.\n')
end