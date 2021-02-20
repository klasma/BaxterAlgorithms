classdef SEGOptimizerSeq < Optimizer
    % Class which optimizes segmentation parameters for one image sequence.
    %
    % The class can be used to optimize the segmentation of cells in one
    % image sequence. The scoring metric is either the SEG measure, or the
    % mean of the SEG measure and the TRA measure, from the ISBI 2015 Cell
    % Tracking Challenge. The optimization requires ground truth folders of
    % the type used in the challenge, in the Analysis folder of the
    % experiment. The optimization is performed for the current
    % segmentation algorithm, with the current parameters as starting
    % point. Each time the optimization algorithm finds a better set of
    % parameters, the parameters are saved to the settings file of the
    % image sequence. The optimization can be performed using coordinate
    % ascent, the built-in function fminsearch, or golden section search.
    % Golden section search can however only be used for optimization of a
    % single variable. Coordinate ascent is usually the preferred
    % algorithm. The class can optimize any numeric segmentation
    % parameters. Segmentation parameters which are arrays with multiple
    % elements can also be optimized. In that case, each element is treated
    % as a separate variable in the optimization.
    %
    % See also:
    % SegOptimizerEx, Optimizer, CoordinateDescent, GoldenSectionSearch
    %
    % References:
    % [1] Ulman, V.; Maška, M.; Magnusson, K. E. G.; Ronneberger, O.;
    %     Haubold, C.; Harder, N.; Matula, P.; Matula, P.; Svoboda, D.;
    %     Radojevic, M.; Smal, I.; Rohr, K.; Jaldén, J.; Blau, H. M.;
    %     Dzyubachyk, O.; Lelieveldt, B.; Xiao, P.; Li, Y.; Cho, S.-Y.;
    %     Dufour, A. C.; Olivo-Marin, J.-C.; Reyes-Aldasoro, C. C.;
    %     Solis-Lemus, J. A.; Bensch, R.; Brox, T.; Stegmaier, J.; Mikut,
    %     R.; Wolf, S.; Hamprecht, F. A.; Esteves, T.; Quelhas, P.;
    %     Demirel, Ö.; Malmström, L.; Jug, F.; Tomancak, P.; Meijering, E.;
    %     Muñoz-Barrutia, A.; Kozubek, M. & Ortiz-de-Solorzano, C., An
    %     objective comparison of cell-tracking algorithms, Nature methods,
    %     2017, 14, 1141–1152
    
    properties
        seqPath = [];           % Full path of the image sequence.
        settingsNames = [];     % Cell array with the names of the parameters to be optimized.
        settingsLengths = [];   % The number of elements in each parameter.
        numImages = [];         % The number of images to be used in the optimization.
        mostCells = [];         % If this is true, the images with most ground truth cells will be used.
        scoringFunction = [];   % The performance measure to optimize. 'SEG' or (SEG+TRA)/2.
        plotFigure = [];        % Figure where optimization results are plotted.
        plotResults = [];       % Optimization results are plotted if this is true.
        saveBestSettings = [];
        savePath = [];
        imData = [];
    end
    
    methods
        function this = SEGOptimizerSeq(aSeqPath, aSettings, varargin)
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
                this.numImages,...
                this.mostCells,...
                this.scoringFunction,...
                this.grids,...
                this.plotResults,...
                this.saveBestSettings,...
                this.savePath,...
                aInitialImData...
                ] = GetArgs(...
                {...
                'NumImages',...
                'MostCells',...
                'ScoringFunction',...
                'Grids',...
                'Plot',...
                'SaveBestSettings',...
                'SavePath',...
                'InitialImData'...
                },...
                {nan, false, 'SEG', cell(size(aSettings)), false, true, [], []},...
                true,...
                varargin);
            
            this.seqPath = aSeqPath;
            this.settingsNames = aSettings;
            
            if isempty(aInitialImData)
                % Load all settings for the image sequence.
                this.imData = ImageData(this.seqPath);
            else
                this.imData = aInitialImData;
            end
            
            % Set the start guess to the parameters in the settings file.
            this.x0 = zeros(length(this.settingsNames),1);
            for i = 1:length(this.settingsNames)
                val = this.imData.Get(this.settingsNames{i});
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
                CTCSegmentation(this.imData, verName,...
                    'NumImages', this.numImages,...
                    'MostCells', this.mostCells,...
                    'ScoringFunction', this.scoringFunction,...
                    settingsArgs{:})
                
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
                RemoveVersion(fileparts(this.seqPath), verName)
            catch ME
                % Make sure that the optimization can recover from errors
                % caused by strange parameters.
                disp(ME)
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
            
            if isempty(this.savePath)
                WriteSeqSettings(this.seqPath, settArgs{:})
            else
                inputs = {};
                for j = 1:this.imData.Size()
                    label = this.imData.GetLabel(j);
                    value = this.imData.Get(j);
                    inputs = [inputs {label; num2str(value)}]; %#ok<AGROW>
                end
            
                seqDir = this.imData.GetSeqDir();
                
                data = {'file'};
                data = SetSeqSettings(data, seqDir, inputs{:});
                data = SetSeqSettings(data, seqDir, settArgs{:});
                
                WriteSettings(this.savePath, data)
            end
        end
    end
end