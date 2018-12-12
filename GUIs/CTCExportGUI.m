function CTCExportGUI(aSeqPaths, aDataType)
% GUI that saves results or ground truths to the formats used in the CTCs.
%
% The user selects tracking versions from a listbox and can then export the
% cell tracks to one of the data formats used in the cell tracking
% challenges. The cell tracks can be exported as a tracking result, a
% tracking ground truth, or a segmentation ground truth. Multiple tracking
% versions can be exported at the same time. That option does however only
% make sense when tracking results are saved. A message box, with paths of
% the folders where the exported data have been saved, is opened when the
% export is finished.
%
% Inputs:
% aSeqPaths - Cell array with full paths of image sequences that results
%             should be exported for.
% aDataType - The type of data that should be exported. The available
%             options are 'RES' for a tracking result, 'TRA' for a tracking
%             ground truth, and 'SEG' for a segmentation ground truth.
%
% See also:
% ExportCellsTif, SaveCellsTif, SaveTRAGT, SaveSEGGT

% Figure for the export dialog.
mainFigure = figure(...
    'Name', ['Export tracking results to the CTC ' aDataType ' format'],...
    'NumberTitle', 'off',...
    'MenuBar', 'none',...
    'ToolBar', 'none',...
    'Units', 'pixels',...
    'Position', [200 200 400 500],...
    'Resize', 'off');

% All available tracking versions.
versions = GetVersions(aSeqPaths);
versions = unique([versions{:}])';

% Settings object used to create the listbox.
info.Version_to_export = Setting(...
    'name', 'Version to export',...
    'type', 'list',...
    'default', {},...
    'alternatives_basic', versions,...
    'tooltip', 'Click on an existing version to select that name.');

% Create a SettingsPanel with the listbox.
sPanel = SettingsPanel(info,...
    'Parent', mainFigure,...
    'Position', [0 0.1 1 0.9],...
    'Split', 0.25,...
    'MinList', 10);

% Export button
uicontrol(...
    'Parent', mainFigure,...
    'Style', 'pushbutton',...
    'Units', 'normalized',...
    'Position', [0 0 1 0.1],...
    'String', 'Export',...
    'Callback', @ExportCallback);

    function ExportCallback(~, ~)
        % Exports all selected tracking versions to the CTC-format.
        
        % Selected tracking versions.
        saveVer = sPanel.GetValue('Version_to_export');
        
        % Open an error message if no tracking versions were selected.
        if isempty(saveVer)
            errordlg('You need to select at least one tracking version.',...
                'No results were exported')
            return
        end
        
        saveDirs = {};  % Folders containing exported tracking results.
        for i = 1:length(saveVer)
            % Extract the image sequences that have the current version.
            hasVersion = cellfun(@(x)HasVersion(x, saveVer{i}), aSeqPaths);
            exportSeqPaths = aSeqPaths(hasVersion);
            
            % Open a new progress bar for each tracking version.
            wbar = waitbar(0, sprintf('Exporting the tracking version %s',...
                SpecChar(saveVer{i}, 'matlab')),...
                'Name', 'Exporting to CTC format');
            
            for j  = 1 : length(exportSeqPaths)
                imData = ImageData(exportSeqPaths{j});
                
                switch lower(aDataType)
                    case 'res'
                        saveDir = fullfile(...
                            imData.GetCellDataDir('Version', saveVer{i}),...
                            'RES');
                        ExportCellsTif(exportSeqPaths{j}, saveVer{i})
                    case 'seg'
                        saveDir = fullfile(...
                            imData.GetAnalysisPath(),...
                            [imData.GetSeqDir() '_GT'],...
                            'SEG');
                        SaveSEGGT(exportSeqPaths{j}, saveVer{i})
                    case 'tra'
                        saveDir = fullfile(...
                            imData.GetAnalysisPath(),...
                            [imData.GetSeqDir() '_GT'],...
                            'TRA');
                        SaveTRAGT(exportSeqPaths{j}, saveVer{i})
                    otherwise
                        error(['The data type has to be ''RES'', '...
                            '''SEG'', or ''TRA'', you gave the input '...
                            '''%s''.'],...
                            aDataType)
                end
                
                % Store the location where the exported data is saved.
                saveDirs = [saveDirs; {saveDir}]; %#ok<AGROW>
                
                % Update the progress bar.
                waitbar(j/length(exportSeqPaths), wbar)
            end
            
            % Close the progress bar.
            delete(wbar)
        end
        
        % Open a dialog to tell the user where the exported results are.
        msgbox([{'The exported tracking results can be found in:'}; unique(saveDirs)],...
            'Finished exporting to CTC format')
    end
end