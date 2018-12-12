function RecordGUI(aPlayer, varargin)
% GUI which records png image sequences in a SequencePlayer.
%
% The function will change the image sequence and the displayed time point
% of the player and perform screen capture in the player window to generate
% an image sequence which corresponds exactly to what the player displays.
% The function works for all players. The function can only record
% png-images, as that seems to be what video-encoding softwares use as
% input.
%
% The GUI has a check box for each image sequence, where recording of that
% image sequence can be turned on and off. The GUI also has fields where
% the folder names of the saved sequences can be altered. The user can
% select the folder where the image sequences are saved using a text field
% and a browse button.
%
% Inputs:
% aPlayer - Sequence player object.
%
% Property/Value inputs:
% RecordAll - If this is set to true, the function will record all image
%             sequences which are open in the player. Otherwise, the
%             function will only record the image sequence currently
%             displayed by the player.
%
% See also:
% SequencePlayer

% Get property/value inputs.
aRecordAll = GetArgs({'RecordAll'}, {false}, true, varargin);

if aRecordAll
    % Record all sequences of the player.
    numSeq = length(aPlayer.seqPaths);
    seqIndices = 1:numSeq;
else
    % Record the sequence currently open in the player.
    numSeq = 1;
    seqIndices = aPlayer.seqIndex;
end

mainFigure = figure(...
    'Name', 'Record image sequences',...
    'NumberTitle', 'off',...
    'Menubar', 'none',...
    'Units', 'normalized',...
    'Position', [0.2 0.1 0.4 min(0.8, 0.03*(numSeq+2))]);

% Create the table with settings for different image sequences. Each image
% sequence has its own row of settings.
tablePanel = uipanel(...
    'Parent', mainFigure,...
    'Units', 'normalized',...
    'Position', [0 2/(numSeq+2) 1 numSeq/(numSeq+2)],...
    'BackgroundColor', get(mainFigure, 'Color'));
% Checkboxes which turn recording on and off.
recordCheckboxes = zeros(numSeq,1);
% Text boxes to specify folder names of the recorded sequences.
nameTextboxes = zeros(numSeq,1);
% Add controls for the different image sequences.
for i = 1:numSeq
    recordCheckboxes(i) = uicontrol(...
        'Parent', tablePanel,...
        'Style', 'checkbox',...
        'Value', 1,...
        'Tooltip', 'Check to record sequence.',...
        'Units', 'normalized',...
        'Position', [1/80 (numSeq-i)/numSeq 1/20 1/numSeq],...
        'BackgroundColor', get(mainFigure, 'Color'));
    % Use a disabled text box instead of a label because it looks nicer.
    uicontrol(...
        'Parent', tablePanel,...
        'Style', 'edit',...
        'Enable', 'off',...
        'String', aPlayer.GetSeqDir(seqIndices(i)),...
        'Tooltip', 'Current folder name of image sequence.',...
        'Units', 'normalized',...
        'Position', [1/20 (numSeq-i)/numSeq 19/40 1/numSeq],...
        'BackgroundColor', get(mainFigure, 'Color'))
    nameTextboxes(i) = uicontrol(...
        'Parent', tablePanel,...
        'Style', 'edit',...
        'String', aPlayer.GetSeqDir(seqIndices(i)),...
        'Tooltip', 'Folder name of image sequence to be saved.',...
        'Units', 'normalized',...
        'Position', [21/40 (numSeq-i)/numSeq 19/40 1/numSeq],...
        'BackgroundColor', 'w');
end

% Create text box with a browse button to select an output location.
info.Output_path = Setting(...
    'name', 'Output path',...
    'type', 'path',...
    'tooltip', 'Full path of folder where saved image sequence folders will be placed.',...
    'default', fullfile(aPlayer.GetImData(1).GetAnalysisPath(), 'Videos'));
sPanel = SettingsPanel(info,...
    'Parent', mainFigure,...
    'Position', [0 1/(numSeq+2) 1 1/(numSeq+2)],...
    'Split', 0.15);

% Button that starts recording.
uicontrol(...
    'Parent', mainFigure,...
    'Style', 'pushbutton',...
    'Units', 'normalized',...
    'Position', [0 0 1 1/(numSeq+2)],...
    'String', 'Start',...
    'Tooltip', 'Records all selected image sequences.',...
    'BackgroundColor', get(mainFigure, 'Color'),...
    'Callback', @StartCallback)

    function StartCallback(~, ~)
        % Records image sequences when the start button is pressed.
        
        outputPath = sPanel.GetValue('Output_path');
        
        % Record image sequences.
        for j = 1:numSeq
            % Folder where png-images for sequence j will be saved.
            savePath = fullfile(outputPath, get(nameTextboxes(j), 'String'));

            % Save png-images for all frames of image sequence j.
            if get(recordCheckboxes(j), 'Value')
                fprintf('Recording sequence %d / %d.\n', j, numSeq)
                RecordSequence(seqIndices(j), savePath)
                fprintf('Done recording sequence %d / %d.\n', j, numSeq)
            end
        end
        fprintf('Done exporting videos.\n')
    end

    function RecordSequence(aIndex, aSavePath)
        % Records in image sequence.
        %
        % Inputs:
        % aIndex - Index of the image sequence in the player.
        % aSavePath - Full path of the folder where the recorded image
        %             sequence will be saved.
        
        if aPlayer.seqIndex ~= aIndex
            % Don't switch to the sequence if it is currently displayed.
            aPlayer.SwitchSequence(aIndex)
        end
        
        if ~exist(aSavePath, 'dir')
            mkdir(aSavePath)
        end
        
        for t = 1:aPlayer.GetImData().sequenceLength
            fprintf('Recording image %d / %d.\n',...
                t, aPlayer.GetImData().sequenceLength)
            
            aPlayer.frame = t;  % Change the displayed time point.
            aPlayer.Draw();  % Redraw what is plotted in the player.
            
            % Perform screen capture.
            im = aPlayer.GetFrame('FFDshow', true);
            
            % Save the captured image.
            imName = sprintf('image%05d.png', t);
            imwrite(im, fullfile(aSavePath, imName))
        end
    end
end