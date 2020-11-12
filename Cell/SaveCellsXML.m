function SaveCellsXML(aCells, aSeqPath, aVer)
% Saves particles (Cell objects) in the format used in the ISBI 2012 PTC.
%
% The function saves particle information to an XML-file that can be read
% by the performance evaluation functions in the ISBI 2012 Particle
% Tracking Challenge.
%
% Note that false positive cells, for which the isCell field is false, will
% not be saved to the XML file. The file is saved in a subfolder to the
% CellData-folder, named 'xml'.
%
% Inputs:
% aCells - Cell objects representing particles to be saved.
% aSeqPath - The path of the image sequence.
% aVer - Name of the tracking version (appended to CellData in the name of
%        the data folder).
%
% See also:
% SaveCells, SaveCellsTif

% Read the image data instead of trusting what is in the cell objects.
imData = ImageData(aSeqPath);

% Remove false positive cells.
cells = AreCells(aCells);

[exPath, seqDir] = FileParts2(aSeqPath);

savePath = fullfile(exPath, 'Analysis', ['CellData' aVer], 'xml');
% Path of the XML-file that the data will be saved to.
xmlFile = fullfile(savePath, [seqDir '.xml']);

% Create XML object.
xDoc = com.mathworks.xml.XMLUtils.createDocument('root');
xRoot = xDoc.getDocumentElement;
xChallenge = xDoc.createElement('TrackContestISBI2012');

% Set attributes of the file.
[scenario, snr, density] = PTC12parameters(imData.GetSeqDir());
xChallenge.setAttribute('snr', num2str(snr))
xChallenge.setAttribute('density', density)
xChallenge.setAttribute('generationDateTime',...
    [datestr(clock, 'ddd ') datestr(clock, 'mmm dd HH:MM:SS CET yyyy')])
xChallenge.setAttribute('info', 'klasma@kth.se')
xChallenge.setAttribute('scenario', scenario)
xRoot.appendChild(xChallenge);

% Go through all cells.
for i = 1:length(cells)
    c = cells(i);
    blobs = c.blob;
    % Create particle.
    particle = xDoc.createElement('particle');
    % Go through all detections (blobs).
    for j = 1:length(blobs)
        b = blobs(j);
        
        % Create detection.
        detection = xDoc.createElement('detection');
        
        % Set coordinates of detection.
        detection.setAttribute('t', sprintf('%d', c.firstFrame+j-2))
        detection.setAttribute('x', sprintf('%.3f', b.centroid(1)-1))
        detection.setAttribute('y', sprintf('%.3f', b.centroid(2)-1))
        
        if imData.numZ == 1  % 2D data.
            detection.setAttribute('z', '0')
        else  % 3D data.
            detection.setAttribute('z', sprintf('%.3f', b.centroid(3)-1))
        end
        
        particle.appendChild(detection);
    end
    xChallenge.appendChild(particle);
end

% Create XML-file.
xmlwrite(xmlFile, xDoc)
end