function oCells = SaveCellsTif(aImData, aCells, aVer, aForEvaluation, varargin)
% Saves tracks in the format used in the ISBI 2015 Cell Tracking Challenge.
%
% The cell outlines are saved as tif images with cell labels where the
% background is 0 and cell pixels have the index of the cell that they
% belong to. Relationships between cells are stored in a txt-file named
% res_track.txt in the same folder as the images. If the tracking results
% have already been saved in the cell tracking challenge format, the
% existing files are removed before they are created again. Note that point
% blobs in cell tracks are removed before the tracks are saved, as there is
% no way to represent a point blob in the cell tracking challenge format.
% Therefore, the cell tracks that are given as input can be broken up into
% fragments. All files are saved in a folder with the name of the image
% sequence folder followed by '_RES'.
%
% Inputs:
% aImData - ImageData object associated with the image sequence.
% aCells - Array of cell objects.
% aVer - Name of the tracking version, without the prefix "CellData".
% aForEvaluation - If this is true, the data will be saved in the directory
%                  that the organizers of the competition specified.
%                  Otherwise the data will be saved in s sub-directory to
%                  the CellData-directory.
%
% Property/Value inputs:
% SaveDeaths - If this is set to true, information about which cells died
%              will be saved to a file named deaths.txt. The text file
%              has two columns. The first column gives the index of the
%              cell and the second column has 1s indicating death and zeros
%              indicating no death. By default, no file is saved and it is
%              assumed that no cells die, as in the cell tracking
%              challenges.
% SaveFP - Set this to true if you want to save false positive tracks in a
%          separate folder named false_positives, inside the main folder.
%
% Outputs:
% oCells - The function will remove point blobs from the tracks that are
%          saved, as a point blob cannot be converted into a pixel mask.
%          This output is an array with the modified Cell objects.
%
% See also:
% LoadCellsTif, SaveCells

% Parse property/value inputs.
[aSaveDeaths, aSaveFP] =...
    GetArgs({'SaveDeaths' 'SaveFP'}, {false false}, true, varargin);

% Point blobs can not be represented in the pixel labels.
areCells = AreCells(aCells);
notCells = NotCells(aCells);
[~, areCells] = PointSegmentCells(areCells);

% Creates a directory where the track data will be saved.
seqDir = aImData.GetSeqDir();

if aForEvaluation
    % Save the data in correct directory for the competition.
    exPath = aImData.GetExPath();
    writeDir = fullfile(exPath, [seqDir, '_RES']);
else
    % Save the data in a sub-directory of the CellData-directory.
    writeDir = fullfile(....
        aImData.GetCellDataDir('Version', aVer),...
        'RES',...
        [seqDir, '_RES']);
end

WriteCellsTif(aImData, areCells, writeDir, aSaveDeaths)

% Save false positive tracks in a separate image sequence.
if aSaveFP
    [~, notCells] = PointSegmentCells(notCells);
    notCellsPath = fullfile(writeDir, 'false_positives');
    WriteCellsTif(aImData, notCells, notCellsPath, aSaveDeaths);
end

oCells = [areCells, notCells];
end

function WriteCellsTif(aImData, aCells, aPath, aSaveDeaths)
% Sub-routine which saves cells to file.
%
% Inputs:
% aImData - ImageData object for the image sequence.
% aCells - Array of Cell objects to be saved.
% aPath - Path that the tif- and txt-files will be saved to.
% aSaveDeaths - If this is true, information about dead cells will be
%               saved to deaths.txt.

if exist(aPath, 'file')
    % Remove old files.
    rmdir(aPath, 's')
end
mkdir(aPath)

% Save the tif images.
for t = 1:aImData.sequenceLength
    if aImData.sequenceLength <= 1000
        fmt = 'mask%03d.tif';
    else
        digits = ceil(log10(aImData.sequenceLength));
        fmt = ['mask%0' num2str(digits) 'd.tif'];
    end
    imPath = fullfile(aPath, sprintf(fmt, t-1));
    im = ReconstructSegments(aImData, aCells, t);
    if size(im,3) == 1  % 2D data.
        imwrite(uint16(im), imPath, 'Compression', 'lzw')
    else  % 3D data.
        for i = 1:size(im,3)
            imwrite(uint16(squeeze(im(:,:,i))), imPath,...
                'WriteMode', 'append',...
                'Compression', 'lzw')
        end
    end
end

% Write information about parent-daughter relationships to a txt-file.
fid = fopen(fullfile(aPath, 'res_track.txt'), 'w');
for i = 1:length(aCells)
    c = aCells(i);
    if ~isempty(c.parent)
        parentIndex = find(aCells == c.parent);
    else
        parentIndex = 0;
    end
    fprintf(fid,...
        '%d %d %d %d\r\n',...
        i, c.firstFrame-1, c.lastFrame-1, parentIndex);
end
fclose(fid);

% Write information about which cells died to a text file. The text file
% has two columns. The first column gives the index of the cell and the
% second column has 1s indicating death and zeros indicating no death.
if aSaveDeaths
    fid_death = fopen(fullfile(aPath, 'deaths.txt'), 'w');
    for i = 1:length(aCells)
        fprintf(fid_death, '%d %d\r\n', i, double(aCells(i).died));
    end
    fclose(fid_death);
end
end