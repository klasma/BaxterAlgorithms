classdef TRAOptimizerSeq < Optimizer
    % Class which optimizes cell tracking for the CTCs. 
    
    properties
        seqPath = [];           % Full path of the image sequence.
        settingsNames = [];     % Cell array with the names of the parameters to be optimized.
        settingsLengths = [];   % The number of elements in each parameter.
        scoringFunction = [];   % The performance measure to optimize. 'SEG' or (SEG+TRA)/2.
        plotFigure = [];        % Figure where optimization results are plotted.
        plotResults = [];       % Optimization results are plotted if this is true.
        saveBestSettings = [];
        segmentationCores = [];
    end
    
    methods
        function this = TRAOptimizerSeq(aSeqPath, aSettings, varargin)
            % Creates an optimization object for an image sequence.
            %
            % The image sequence and options for the optimization are
            % specified. The optimization is started by calling one of the
            % optimization functions.
            %
            % Inputs:
            % aSeqPath - Full path of the image sequence.
            % aSettings - Cell array with names of the parameters to be
            %             optimized.
            %
            % Property/Value inputs:
            % NumImages - The maximum number of time points in each image
            %             sequence that will be included in the
            %             optimization. This input is only used if
            %             ScoringFunction is 'SEG'.
            % MostCells - If this is set to true, the optimization will be
            %             performed on the images with most cells, when the
            %             number of time points with a segmentation ground
            %             truth is larger than NumImages. Otherwise the
            %             images will be sampled evenly from the set of
            %             images with ground truth segmentations.
            % ScoringFunction - This parameter specifies the scoring
            %                   function that should be optimized. The
            %                   available options are 'SEG' and
            %                   '(SEG+TRA)/2'. The SEG and TRA measures are
            %                   the performance measures that were used to
            %                   evaluate segmentation and tracking
            %                   performance in the ISBI 2015 Cell Tracking
            %                   Challenge publication [1]. All images in
            %                   the sequences have to be segmented to
            %                   compute TRA, but for the SEG measure it is
            %                   enough to segment the images which have
            %                   ground truth segmentations. For SEG it is
            %                   also possible to use only a subset of the
            %                   images with segmentation ground truths. The
            %                   default is 'SEG'.
            % Grids - Cell array with grids that define allowed values for
            %         discrete parameters. There is one cell for each
            %         parameter. The cells of discrete parameters contain
            %         arrays with grid values while the cells of continuous
            %         parameters are empty.
            % Plot - If this is true, the optimization results will be
            %        plotted during the optimization.
            
            % Parse property/value inputs.
            [...
                this.scoringFunction,...
                this.grids,...
                this.plotResults,...
                this.saveBestSettings,...
                this.segmentationCores] = GetArgs(...
                {'ScoringFunction',...
                'Grids',...
                'Plot',...
                'SaveBestSettings',...
                'SegmentationCores'},...
                {'(SEG+TRA)/2', cell(size(aSettings)), false, true, 1},...
                true,...
                varargin);
            
            this.seqPath = aSeqPath;
            this.settingsNames = aSettings;
            [exPath, seqDir] = FileParts2(this.seqPath);
            
            % Load all settings for the image sequence.
            sett = ReadSettings(exPath, seqDir);
            
            % Set the start guess to the parameters in the settings file.
            this.x0 = zeros(length(this.settingsNames),1);
            for i = 1:length(this.settingsNames)
                val = str2num(GetSeqSettings(...
                    sett, seqDir, this.settingsNames{i})); %#ok<ST2NM>
                this.settingsLengths(i) = length(val);
                for j = 1:this.settingsLengths(i)
                    % A parameter can contain more than one variable to be
                    % optimized. Indexing outside the array just makes it
                    % longer.
                    index = sum(this.settingsLengths(1:i-1)) + j;
                    this.x0(index) = val(j);
                end
            end
            
            % Set the upper and lower limits for all parameters. All
            % parameters are positive, and unbounded from above, except
            % TSegThreshold SegClipping which can take values between 0 and
            % 1.
            this.xMin = zeros(size(this.x0));
            this.xMax = zeros(size(this.x0));
            for i = 1:length(this.settingsNames)
                switch this.settingsNames{i}
                    case {'TSegThreshold' 'SegClipping'}
                        for j = 1:this.settingsLengths(i)
                            % Indexing outside the array just makes it
                            % longer.
                            index = sum(this.settingsLengths(1:i-1)) + j;
                            this.xMax(index) = 1;
                        end
                    otherwise
                        for j = 1:this.settingsLengths(i)
                            % Indexing outside the array just makes it
                            % longer.
                            index = sum(this.settingsLengths(1:i-1)) + j;
                            this.xMax(index) = inf;
                        end
                end
            end
        end
        
        function oF = EvaluateObjective(this, aX)
            % Evaluates the objective and does plotting and bookkeeping.
            %
            % Inputs:
            % aX - Column vector with parameter values.
            %
            % Outputs:
            % oF - Objective value corresponding to aX.
            
            % Evaluating the objective may change fBest.
            fBest_old = this.fBest;
            
            oF = this.EvaluateObjective@Optimizer(aX);
            
            % Save the new parameters to the settings file if they give
            % better performance.
            if this.saveBestSettings && ~isempty(fBest_old) && oF < fBest_old
                this.SaveSettings(aX)
            end
            
            if this.plotResults
                % Plot how the parameters and the objective value evolve
                % throughout the optimization.
                
                if isempty(this.plotFigure) || ~ishandle(this.plotFigure)
                    % Create a figure for plotting if one does not exist.
                    this.plotFigure = figure(...
                        'Name', sprintf('Optimizing segmentation for %s', this.seqPath),...
                        'NumberTitle', 'off');
                end
                
                % Plots how the utility evolves during the optimization.
                % The best utility is marked by an asterisk.
                scoreAxes = subplot(1, 2, 1, 'Parent', this.plotFigure);
                plot(scoreAxes, 1:length(this.fAll), 1-this.fAll)
                [minValue, minIndex] = min(this.fAll);
                hold(scoreAxes, 'on')
                plot(scoreAxes, minIndex, 1-minValue, '*')
                % Allow the plot to be overwritten in the next function
                % evaluation.
                hold(scoreAxes, 'off')
                xlabel(scoreAxes, 'Function evaluation')
                ylabel(scoreAxes, this.scoringFunction)
                grid(scoreAxes, 'on')
                
                % Plots how the segmentation parameters evolve over time.
                % The best parameters are marked by asterisks.
                for i = 1:length(this.settingsNames)
                    settingsAxes = subplot(length(this.settingsNames), 2, 2*i,...
                        'Parent', this.plotFigure);
                    plot(settingsAxes, 1:size(this.xAll,2), this.xAll(i,:))
                    hold(settingsAxes, 'on')
                    plot(settingsAxes, minIndex, this.xAll(i,minIndex), '*')
                    % Allow the plot to be overwritten in the next
                    % function evaluation.
                    hold(settingsAxes, 'off')
                    title(settingsAxes, this.settingsNames{i})
                    grid(settingsAxes, 'on')
                    % All parameter axes share the same x-axis, so only the
                    % bottom axes needs an x-label.
                    if i < length(this.settingsNames)
                        set(settingsAxes, 'XTickLabel', {})
                    else
                        xlabel(settingsAxes, 'Function evaluation')
                    end
                end
                
                % Plot the results after each function evaluation and not
                % just at the end of the optimization.
                drawnow
            end
        end
        
        function oF = Objective(this, aX)
            % Computes the utility for a set of parameter values.
            %
            % The function computes segmentation results, saves them in the
            % CTC format, computes the SEG performance and possibly the TRA
            % performance, and then removes the saved segmentation results.
            % The returned value is 1-SEG or 1-(SEG+TRA)/2, depending on
            % which scoring function is used. The objective is minimized,
            % and therefore the returned value must have a minimum for the
            % optimal parameters.
            %
            % Inputs:
            % aX - Column vector with parameter values.
            %
            % Outputs:
            % oF - The objective value for the parameters in aX.
            
            try
                settingsArgs = this.X2SettingsArgs(aX);
                % The segmentation results will be saved temporarily to a
                % results folder with this label. The segmentation results
                % are only saved in the CTC format, and not as a mat-file.
                verName = sprintf('_optimization%d', length(this.fAll)+1);
                CTCTracking(this.seqPath, verName, settingsArgs{:},...
                    'SegmentationCores', this.segmentationCores)
                
                % Compute the SEG performance.
                SEG = PerformanceSEG(this.seqPath, verName, false);
                
                % Compute the objective value.
                switch this.scoringFunction
                    case 'SEG'
                        oF = 1 - SEG;
                    case '(SEG+TRA)/2'
                        % Compute the TRA performance and take the average
                        % of SEG and TRA.
                        TRA = PerformanceTRA(this.seqPath, verName);
                        oF = 1 - (SEG + TRA) / 2;
                    otherwise
                        error('Unknown scoring function %s',...
                            this.scoringFunction)
                end

                % Remove the temporary segmentation results.
                try
                    % Use a separate try/catch to avoid setting oF to 1.
                    RemoveVersion(fileparts(this.seqPath), verName)
                catch ME
                    getReport(ME)
                    fprintf('Unable to remove %s from %s\n',...
                        verName, fileparts(this.seqPath))
                end
            catch ME
                % Make sure that the optimization can recover from errors
                % caused by strange parameters.
                getReport(ME)
                fprintf(['Segmentation evaluation failed. The '...
                    'segmentation performance is set to 0 for this '...
                    'parameter set.\n'])
                oF = 1;
            end
        end
        
        function oArgs = X2SettingsArgs(this, aX)
            % Converts an array of parameter values to settings arguments.
            %
            % Inputs:
            % aX - Column vector with parameter values.
            %
            % Outputs:
            % oArgs - Cell array with parameter/value arguments that
            %         specify settings values. The odd-numbered cells
            %         contain settings names and the even-numbered cells
            %         contain the corresponding parameter values. Keep in
            %         mind that one setting can be an array that takes up
            %         multiple elements in aX.
            
            oArgs = cell(length(this.settingsNames)*2,1);
            for i = 1:length(this.settingsNames)
                % Settings name.
                oArgs{i*2-1} = this.settingsNames{i};
                for j = 1:this.settingsLengths(i)
                    index = sum(this.settingsLengths(1:i-1)) + j;
                    % Settings value.
                    oArgs{i*2} = [oArgs{i*2} aX(index)];
                end
            end
        end
        
        function SaveSettings(this, aX)
            % Saves parameters to the settings file of the image sequence.
            %
            % Inputs:
            % aX - Array of parameters to be saved.
            
            settArgs = this.X2SettingsArgs(aX);
            
            % Convert numerical parameter values into strings that can be
            % written to the settings file.
            for i = 2 : 2: length(settArgs)
                settArgs{i} = num2str(settArgs{i});
            end
            
            WriteSeqSettings(this.seqPath, settArgs{:})
        end
    end
end