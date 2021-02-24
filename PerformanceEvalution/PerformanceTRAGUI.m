function PerformanceTRAGUI(aSeqPaths, aQueue)
% GUI for evaluation of the tracking performance measure TRA.
%
% The TRA measure was used in the cell tracking challenge of 2015 [1]. The
% TRA measure is a normalized version of the AOGM measure described in [2].
% The AOGM measure is a weighted sum of different tracking errors. The
% un-normalized AOGM measure described in [1] can be found in the column
% labeled 'Total penalty', when the checkbox for AOGM penalties is checked.
%
% This GUI lets the user select a tracking version to evaluate the
% performance of, and the number of processor cores that should be used in
% the performance evaluation. The user can also select what outputs should
% be printed. By default, only the TRA measure is printed. When certain
% checkboxes are checked, the function will also print out how different
% tracking errors contribute to the AOGM value, and what the results would
% be for an empty set of tracks.
%
% Inputs:
% aSeqPaths - Cell array of strings with the paths of all the tracked image
%             sequences.
% aQueue - Queue object that lets the user put the computations in a
%          processing queue, so that they can be started later.
%
% References:
% [1] Ulman, V.; Maška, M.; Magnusson, K. E. G.; Ronneberger, O.; Haubold,
%     C.; Harder, N.; Matula, P.; Matula, P.; Svoboda, D.; Radojevic, M.;
%     Smal, I.; Rohr, K.; Jaldén, J.; Blau, H. M.; Dzyubachyk, O.;
%     Lelieveldt, B.; Xiao, P.; Li, Y.; Cho, S.-Y.; Dufour, A. C.;
%     Olivo-Marin, J.-C.; Reyes-Aldasoro, C. C.; Solis-Lemus, J. A.;
%     Bensch, R.; Brox, T.; Stegmaier, J.; Mikut, R.; Wolf, S.; Hamprecht,
%     F. A.; Esteves, T.; Quelhas, P.; Demirel, Ö.; Malmström, L.; Jug, F.;
%     Tomancak, P.; Meijering, E.; Muñoz-Barrutia, A.; Kozubek, M. &
%     Ortiz-de-Solorzano, C., An objective comparison of cell-tracking
%     algorithms, Nature methods, 2017, 14, 1141–1152
%
% [2] Matula, P.; Maška, M.; Sorokin, D. V.; Matula, P.;
%     Ortiz-de-Solórzano, C. & Kozubek, M. Cell Tracking Accuracy
%     Measurement Based on Comparison of Acyclic Oriented Graphs, PLOS ONE,
%     2015, 10, 1-19
%
% See also:
% PerformanceTRA

% GUI figure.
mainFigure = figure('Name', 'Evaluate TRA tracking performance.',...
    'NumberTitle', 'off',...
    'MenuBar', 'none',...
    'ToolBar', 'none',...
    'Units', 'pixels',...
    'Position', [200 200 500, 200],...
    'Resize', 'off');

% Find the tracking versions for which the performance can be evaluated.
versions = GetVersions(aSeqPaths);
versions = unique([versions{:}]);

% Data used to generate ui-controls in a SettingsPanel.
info.Tracking = Setting(...
    'name', 'Automatically generated tracking version.',...
    'type', 'choice',...
    'default', versions{1},...
    'alternatives_basic', versions,...
    'tooltip', ['Automatically generated tracking version to evaluate '...
    'the performance for.']);
coreAlts = arrayfun(@num2str, 1:MaxWorkers(), 'UniformOutput', false);
info.AOGM_errors = Setting(...
    'name', 'AOGM errors',...
    'type', 'check',...
    'default', false,...
    'tooltip', 'Print the number of errors in each category.');
info.AOGM_errors_black = Setting(...
    'name', 'AOGM errors (no tracks)',...
    'type', 'check',...
    'default', false,...
    'tooltip', ['Print the number or errors in each category for an '...
    'empty tracking result.']);
info.AOGM_penalties = Setting(...
    'name', 'AOGM penalties',...
    'type', 'check',...
    'default', false,...
    'tooltip', 'Print the penalty in each error category.');
info.AOGM_penalties_black = Setting(...
    'name', 'AOGM penalties (no tracks)',...
    'type', 'check',...
    'default', false,...
    'tooltip', ['Print the penalty in each error category for an empty '...
    'tracking result.']);
info.AOGM_relative_penalties = Setting(...
    'name', 'AOGM relative penalties',...
    'type', 'check',...
    'default', false,...
    'tooltip', ['Print the fraction of the total penalty that comes '...
    'from each error category.']);
info.Number_of_cores = Setting(...
    'name', 'Number of cores',...
    'type', 'choice',...
    'default', '1',...
    'alternatives_basic', coreAlts,...
    'tooltip', 'The number of processor cores used for parallel processing.');

% Create a panel with all ui-objects.
sPanel = SettingsPanel(info,...
    'Parent', mainFigure,...
    'Position', [0 0.30 1 0.70]);

% Button to start computation.
uicontrol(...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Style', 'pushbutton',...
    'Units', 'normalized',...
    'Position', [0 0 0.5 0.30],...
    'String', 'Start',...
    'Tooltip', 'Start computing the TRA measure.',...
    'Callback', @StartButton_Callback);

% Button to put the computation in the execution queue.
uicontrol(...
    'BackgroundColor', get(mainFigure, 'color'),...
    'Style', 'pushbutton',...
    'Units', 'normalized',...
    'Position', [0.5 0 0.5 0.30],...
    'String', 'Queue',...
    'Tooltip', ['Put the computation of the TRA measure in a '...
    'processing queue.'],...
    'Callback', @QueueButton_Callback);

    function TestPerformance(aVersion, aNumCores, aErrors, aErrorsBlack,...
            aPenalties, aPenaltiesBlack, aRelativePenalties)
        % Evaluates the tracking performance.
        %
        % The function then displays the results in tables.
        %
        % Inputs:
        % aVersion - Tracking version to evaluate the performance of.
        % aNumCores - The number of processor cores to use.
        % aErrors - If this is true, the number of errors of each type is
        %           printed.
        % aErrorsBlack - If this is true, the number of errors of each type
        %                for black images is printed.
        % aPenalties - If this is true, the total penalty associated with
        %              each error type is printed.
        % aPenaltiesBlack - If this is true, the total penalty associated
        %                   with each error type for black images is
        %                   printed.
        % aRelativePenalties - If this is true, the fraction of the total
        %                      penalty that comes from each error type is
        %                      printed.
        
        % Names of the different types of tracking errors.
        titles = {...
            'Splitting Ops.'
            'False Negatives'
            'False Positives'
            'Redundant Edges'
            'Missing Edges'
            'Incorrect Edges'};
        
        % Penalties for the different types of tracking errors.
        AOGMpenalties = [5 10 1 1 1.5 1];
        
        % Evaluate the performance.
        [TRAmeasures, AOGMerrors, ~, blackAOGMerrors] =...
            PerformanceTRA(aSeqPaths, aVersion, 'NumCores', aNumCores);
        
        [~, seqDirs] = FileParts2(aSeqPaths);
        
        % Print the TRA measures for the different sequences.
        fprintf('\nTRA measures:\n')
        for i = 1:length(seqDirs)
            fprintf('%-20s %-.4f\n', seqDirs{i}, TRAmeasures(i))
        end
        
        % Print the number of errors of each type.
        if aErrors
            fprintf('\nAOGM errors:\n')
            fprintf('%-20s %20s %20s %20s %20s %20s %20s\n', 'Sequence', titles{:})
            for i = 1:length(seqDirs)
                err = AOGMerrors(i,:);
                fprintf('%-20s %20d %20d %20d %20d %20d %20d\n', seqDirs{i},...
                    err(1), err(2), err(3), err(4), err(5), err(6))
            end
        end
        
        % Print the number of errors of each type for black images.
        if aErrorsBlack
            fprintf('\nAOGM errors for black images (no tracks):\n')
            fprintf('%-20s %20s %20s %20s %20s %20s %20s\n', 'Sequence', titles{:})
            for i = 1:length(seqDirs)
                err = blackAOGMerrors(i,:);
                fprintf('%-20s %20d %20d %20d %20d %20d %20d\n', seqDirs{i},...
                    err(1), err(2), err(3), err(4), err(5), err(6))
            end
        end
        
        % Print the total penalty associated with each error type.
        if aPenalties
            fprintf('\nAOGM penalties:\n')
            fprintf('%-20s %20s %20s %20s %20s %20s %20s %20s\n',...
                'Sequence', titles{:}, 'Total penalty')
            for i = 1:length(seqDirs)
                pen = AOGMerrors(i,:) .* AOGMpenalties;
                fprintf('%-20s %20d %20d %20d %20.1f %20d %20d %20.1f\n', seqDirs{i},...
                    pen(1), pen(2), pen(3), pen(4), pen(5), pen(6), sum(pen))
            end
        end
        
        % Print the total penalty associated with each error type for black
        % images.
        if aPenaltiesBlack
            fprintf('\nAOGM penalties for black images (no tracks):\n')
            fprintf('%-20s %20s %20s %20s %20s %20s %20s %20s\n',...
                'Sequence', titles{:}, 'Total penalty')
            for i = 1:length(seqDirs)
                pen = blackAOGMerrors(i,:) .* AOGMpenalties;
                fprintf('%-20s %20d %20d %20d %20.1f %20d %20d %20.1f\n', seqDirs{i},...
                    pen(1), pen(2), pen(3), pen(4), pen(5), pen(6), sum(pen))
            end
        end
        
        % Print the fraction of the total penalty that comes from each
        % error type.
        if aRelativePenalties
            fprintf('\nAOGM relative penalties:\n')
            fprintf('%-20s %20s %20s %20s %20s %20s %20s\n', 'Sequence', titles{:})
            for i = 1:length(seqDirs)
                pen = AOGMerrors(i,:) .* AOGMpenalties;
                pen = pen / sum(pen);
                fprintf('%-20s %20.3f %20.3f %20.3f %20.3f %20.3f %20.3f \n', seqDirs{i},...
                    pen(1), pen(2), pen(3), pen(4), pen(5), pen(6))
            end
        end
    end

    function StartButton_Callback(~, ~)
        % Starts the computation of performance measures.
        
        version = sPanel.GetValue('Tracking');
        numCores = str2double(sPanel.GetValue('Number_of_cores'));
        errors = sPanel.GetValue('AOGM_errors');
        errorsBlack = sPanel.GetValue('AOGM_errors_black');
        penalties = sPanel.GetValue('AOGM_penalties');
        penaltiesBlack = sPanel.GetValue('AOGM_penalties_black');
        relativePenalties = sPanel.GetValue('AOGM_relative_penalties');
        
        TestPerformance(version, numCores, errors, errorsBlack,...
            penalties, penaltiesBlack, relativePenalties)
    end

    function QueueButton_Callback(~, ~)
        % Puts the computation of performance measures in a queue.
        
        version = sPanel.GetValue('Tracking');
        numCores = str2double(sPanel.GetValue('Number_of_cores'));
        errors = sPanel.GetValue('AOGM_errors');
        errorsBlack = sPanel.GetValue('AOGM_errors_black');
        penalties = sPanel.GetValue('AOGM_penalties');
        penaltiesBlack = sPanel.GetValue('AOGM_penalties_black');
        relativePenalties = sPanel.GetValue('AOGM_relative_penalties');
        
        aQueue.Add(@()TestPerformance(version, numCores, errors,...
            errorsBlack, penalties, penaltiesBlack, relativePenalties));
    end
end