function oBlobs = GetGTBlobs(aImData, aT)
% Reads ground truth blobs in the CTC format.
%
% The function is used for the Drosophila embryos of the ISBI 2015 Cell
% Tracking Challenge, where only the manually tracked nuclei from the first
% image should be tracked. The function is written to work both with the
% folder structure that I use for development, and the folder structure
% used by the organizers when they verify the tracking results.
%
% Inputs:
% aImData - ImageData object of the image sequence.
% aT - Frame index. The frame index should be 1 when the function is used
%      for tracking in the Drosophila embryos of the CTC.
%
% Outputs:
% oBlobs - Blobs loaded for image aT.
%
% See also:
% SaveSelectedGTCells, SelectCellsFromGTPixels

seqDir = aImData.GetSeqDir();
labelSeq = fullfile(aImData.GetAnalysisPath(),...
    [seqDir(end-1:end) '_GT'], 'TRA');
if ~exist(labelSeq, 'dir')
    % The program is executed by the organizers of the CTC.
    labelSeq = fullfile(aImData.GetExPath(),...
        [seqDir(end-1:end) '_GT'], 'TRA');
end

% ImageData of a folder with ground truth for the first image.
labelImData = ImageData(labelSeq);
labelImData.Set('bits', 8);
labelImData.Set('numZ', aImData.Get('numZ'))
labelImData.Set('zStacked', aImData.Get('zStacked'))

% Create ground truth blobs for the first image.
if labelImData.GetDim() == 2
    mask = labelImData.GetImage(aT);
else
    mask = labelImData.GetZStack(aT);
end
rawProps = regionprops(...
    mask,...
    'BoundingBox',...
    'Image',...
    'Centroid',...
    'Area');
oBlobs = [];
for i = 1:length(rawProps)
    if rawProps(i).Area > 0
        oBlobs = [oBlobs Blob(rawProps(i), 'index', i)]; %#ok<AGROW>
    end
end
end