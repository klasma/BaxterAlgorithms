function SaveSegmentationCSB(aImData, aBlobSeq, aVersion, aForEvaluation)

if aForEvaluation
    % Save the data in correct directory for the competition.
    exPath = aImData.GetExPath();
    writeDir = fullfile(exPath, [seqDir, '_RES']);
else
    % Save the data in a sub-directory of the CellData-directory.
    writeDir = fullfile(....
        aImData.GetCellDataDir('Version', aVersion),...
        'RES',...
        [aImData.GetSeqDir(), '_RES']);
end

if exist(writeDir, 'dir')
    % Remove old files.
    rmdir(writeDir, 's')
end
mkdir(writeDir)

if aImData.sequenceLength <= 1000
    fmt = 'mask%03d.tif';
else
    digits = ceil(log10(aImData.sequenceLength));
    fmt = ['mask%0' num2str(digits) 'd.tif'];
end

for t = 1:length(aBlobSeq)
    imPath = fullfile(writeDir, sprintf(fmt, t-1));
    imageSize = [aImData.imageHeight, aImData.imageWidth, aImData.numZ];
    im = ReconstructSegmentsBlob(aBlobSeq{t}, imageSize);
    if size(im,3) == 1  % 2D data.
        imwrite(uint16(im), imPath, 'Compression', 'lzw')
    else  % 3D data.
        for slice = 1:size(im,3)
            imwrite(uint16(squeeze(im(:,:,slice))), imPath,...
                'WriteMode', 'append',...
                'Compression', 'lzw')
        end
    end
end
end