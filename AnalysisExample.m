% This is a simple example of an analysis script which plots the number of
% cells in an image sequence as a function of time. Before this script can
% be used, the image sequence needs to be tracked using the Baxter
% Algorithms. There is no sample data included with the program, so the
% function is not meant to be executed. The function serves only as
% guidance when users start writing their own functions.
%
% See also:
% BaxterAlgorithms

% Path of the image sequence folder. In this example, the experiment folder
% is 'C:/Dropbox/Demos/MuSC', and the name of the image sequence is
% '3 min aquisition__C02_10_001'. The folder "seqPath" contains individual
% tif-images for the different time points of the image sequence.
seqPath = 'C:/Dropbox/Demos/MuSC/3 min aquisition__C02_10_001';

% Object with information about the image sequence.
imData = ImageData(seqPath);
% Load outlines and tracks of cells saved with the label '_demo'.
cells = LoadCells(seqPath, '_demo');
% Remove detected objects that are not cells.
cells = AreCells(cells);

% Time points in hours.
t = (0:imData.sequenceLength-1) * imData.dT / 3600;
% The number of cells at each time point.
numberOfCells = zeros(imData.sequenceLength, 1);
for i = 1:length(cells)
    ff = cells(i).firstFrame;  % First time point of the cell.
    lf = cells(i).lastFrame;   % Last time point of the cell.
    % Increase the cell count.
    numberOfCells(ff:lf) = numberOfCells(ff:lf) + 1;
end

% Plot the cell counts.
figure
plot(t, numberOfCells, 'LineWidth', 2)
xlabel('time (hours)')
ylabel('number of cells')
ylim([0 16])  % Change the limits on the y-axis.