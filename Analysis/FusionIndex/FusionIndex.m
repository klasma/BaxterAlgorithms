function [oIndex, oTubes, oCells, oNucleiInTubes, oNucleiOutsideTubes] =...
    FusionIndex(aSeqPath, aNucleiVersion, aTubeVersion, varargin)
% Computes the fusion index of muscle cells fusing into myotubes.
%
% The fusion index is defined as the number of nuclei in myotubes divided
% by the total number of nuclei. A myotube is defined as a region of
% cytoplasm containing 2 or more nuclei, and a nucleus is said to be inside
% a region of cytoplasm if a certain fraction of the nucleus pixels overlap
% with the myotube. The fraction can be defined by the user but is 0.25 by
% default. If a nucleus meet the criteria to be inside multiple tubes, it
% is said to be inside the tube with which it overlaps the most (ties are
% broken randomly). The function requires that the nuclei and the myotubes
% have been segmented into two different segmentation results (tracking
% versions) by the Baxter Algorithms.
%
% Inputs:
% aSeqPath - Full path name of a image folder containing the fluorescent
%            images of the nuclei channel and the cytoplasm channel.
% aNucleiVersion - Label of the segmentation/tracking result for the
%                  nuclei.
% aTubeVersion - Label of the segmentation/tracking result for the
%                cytoplasm.
%
% Property/Value inputs:
% aMinOverlap - The fraction of the nuclei pixels which need to be inside a
%               myotube for the nucleus to be inside the myotube. The
%               default is 0.25.
% aPlot - Set this to true to display the segmentation results and the
%         classification of nuclei and myotubes in a figure. Myotubes and
%         the nuclei inside them are outlined in white. Single cells and
%         nuclei outside of myotubes are outlined in gray.'
%
% Outputs:
% oIndex - Fusion index.
% oTubes - Array of Cell objects representing myotubes.
% oCells - Array of Cell objects representing individual cells.
% oNucleiInTubes - Array of Cell objects representing nuclei in myotubes.
% oNucleiOutsideTubes - Array of Cell objects representing nuclei outside
%                       myotubes.
%
% See also:
% BaxterAlgorithms, Cell

% Get additional inputs.
[aMinOverlap, aPlot] = GetArgs(...
    {'MinOverlap', 'Plot'},...
    {0.25, false},...
    true, varargin);

nuclei = LoadCells(aSeqPath, aNucleiVersion);
cytoplasm = LoadCells(aSeqPath, aTubeVersion);

% Find the fraction of the nuclei which lie in the different cytoplasm
% regions.
overlaps = zeros(length(nuclei), length(cytoplasm));
for i = 1:length(nuclei)
    nucleusBlob = nuclei(i).blob;
    area = nucleusBlob.GetArea();
    for j = 1:length(cytoplasm)
        tubeBlob = cytoplasm(j).blob;
        intersection = Overlap(tubeBlob, nucleusBlob);
        overlaps(i,j) = intersection / area;
    end
end

[~, maxIndices] = max(overlaps,[],2);
% Matrix where element (i,j) is 1 if cell i is inside tube j.
assignments = false(size(overlaps));
assignments(sub2ind(size(assignments), 1:size(assignments,1), maxIndices')) = true;
assignments = assignments & overlaps >= aMinOverlap;

% Compute the fusion index.
numNuclei = sum(assignments,1);  % The number of nuclei in each myotube.
% The number of nuclei which are inside myotubes.
fused = sum(sum(assignments(:, numNuclei > 1)));
total = length(nuclei);  % The total number of nuclei.
oIndex = fused / total;  % The fusion index.

% Find the Cell objects corresponding to the cells, myotubes, nuclei in
% myotubes and nuclei outside myotubes. The Cell objects are colored for
% plotting even if plotting is not specified.
if nargout > 1 || aPlot
    % The colors used to outline different object types.
    colorTubes = ones(3,1);
    colorCells = 0.25*ones(3,1);
    colorInTubes = ones(3,1);
    colorOutsideTubes = 0.25*ones(3,1);
    
    % Alternative colorings.
    
    % colorTubes = [1 0 0];
    % colorCells = [0.5 0 0];
    % colorInTubes = [0 0 1];
    % colorOutsideTubes = [0 0 0.5];
    
    % colorTubes = [0 1 0];
    % colorCells = [0 0.35 0];
    % colorInTubes = [0 1 0];
    % colorOutsideTubes = [0 0.35 0];
    
    % colorTubes = [0 1 0];
    % colorCells = 0.25*ones(1,3);
    % colorInTubes = [0 1 0];
    % colorOutsideTubes = 0.25*ones(1,3);
    
    areTubes = numNuclei > 1;  % Indices of cytoplasm regions which are myotubes.
    inside = false(size(nuclei));
    for i = 1:length(nuclei)
        if areTubes(assignments(i,:))
            inside(i) = true;
            nuclei(i).color = colorInTubes;
        else
            nuclei(i).color = colorOutsideTubes;
        end
    end
    oNucleiInTubes = nuclei(inside);
    oNucleiOutsideTubes = nuclei(~inside);
    oCells = cytoplasm(~areTubes);
    for i = 1:length(oCells)
        oCells(i).color = colorCells;
    end
    oTubes = cytoplasm(areTubes);
    for i = 1:length(oTubes)
        oTubes(i).color = colorTubes;
    end
end

% Plot the results.
if aPlot
    % Create the image on which the outlines will be drawn.
    imData = ImageData(aSeqPath);
    im = imData.GetShownImage(1, 'Channels', [1 2]);
    
    f = figure('Name', imData.GetSeqDir(), 'InvertHardcopy', 'off');
    ax = axes('Parent', f);
    imshow(im, 'Parent', ax)
    hold(ax, 'on')
    
    PlotOutlines(ax, oNucleiInTubes, 1, 1)
    PlotOutlines(ax, oTubes, 1, 1)
    PlotOutlines(ax, oNucleiOutsideTubes, 1, 1)
    PlotOutlines(ax, oCells, 1, 1)
end
end