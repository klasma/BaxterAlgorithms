classdef SEGOptimizerEx < Optimizer
    % Class which optimizes the segmentation i multiple image sequences.
    %
    % The class optimizes parameters for segmentation algorithms for
    % multiple images sequences. The optimization maximizes the average
    % performance for all image sequences jointly. The scoring metric is
    % either the SEG measure, or the mean of the SEG measure and the TRA
    % measure, from the ISBI 2015 Cell Tracking Challenge. The optimization
    % requires ground truth folders of the type used in the challenge, in
    % the Analysis folders of the experiments. The optimization is
    % performed for the current segmentation algorithm, with the current
    % parameters as starting point. All image sequences must be using the
    % same segmentation algorithm. The initial parameters are taken from
    % the first image sequence. Each time the optimization algorithm finds
    % a better set of parameters, the parameters are saved to the settings
    % files of the image sequences. The optimization can be performed using
    % coordinate ascent, the built-in function fminsearch, or golden
    % section search. Golden section search can however only be used for
    % optimization of a single variable. Coordinate ascent is usually the
    % preferred algorithm. The class can optimize any numeric segmentation
    % parameters. Segmentation parameters which are arrays with multiple
    % elements can also be optimized. In that case, each element is treated
    % as a separate variable in the optimization. Most of the processing is
    % done in SEGOptimizerSeq-objects for the individual image sequences.
    %
    % See also:
    % SegOptimizerSeq, Optimizer, CoordinateDescent, GoldenSectionSearch
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
        exPath              % Full path of the experiment folder. Used only for identification.
        seqOptimizers       % Array of SEGOptimizerSeq-objects for the image sequences.
        plotFigure = [];    % Figure where optimization results are plotted.
        plotResults = [];   % Optimization results are plotted if this is true.
        optimizerSavePath = [];
    end
    
    methods
        function this = SEGOptimizerEx(aPath, aSettings, varargin)
            % Creates an optimization object for a set of image sequences.
            %
            % The image sequences and options for the optimization are
            % specified. The optimization is started by calling one of the
            % optimization functions. The constructor creates
            % SEGOptimizerSeq-objects for all of the image sequences, and
            % makes it possible to optimize the performance for all
            % sequences jointly.
            %
            % Inputs:
            % aPath - This input can be either the full path of an
            %         experiment folder, or a cell array with full paths of
            %         image sequence folders. If the input is an experiment
            %         folder, the segmentation is optimized for all image
            %         sequences in the experiment folder.
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
            %                   '(SEG+TRA)/2'. The SEG and TRA
            %                   measures are the performance measures that
            %                   were used to evaluate segmentation and
            %                   tracking performance in the ISBI 2015 Cell
            %                   Tracking Challenge publication [1]. All
            %                   images in the sequences have to be
            %                   segmented to compute TRA, but for the SEG
            %                   measure it is enough to segment the images
            %                   which have ground truth segmentations. For
            %                   SEG it is also possible to use only a
            %                   subset of the images with segmentation
            %                   ground truths. The default is 'SEG'.
            % Grids - Cell array with grids that define allowed values for
            %         discrete parameters. There is one cell for each
            %         parameter. The cells of discrete parameters contain
            %         arrays with grid values while the cells of continuous
            %         parameters are empty.
            % Plot - If this is true, the optimization results will be
            %        plotted during the optimization.
            
            % Parse property/value inputs.
            [...
                aNumImages,...
                aMostCells,...
                aScoringFunction,...
                aGrids,...
                aSavePaths,...
                aInitialImData,...
                this.plotResults,...
                this.optimizerSavePath...
                ] = GetArgs(...
                {...
                'NumImages',...
                'MostCells',...
                'ScoringFunction',...
                'Grids',...
                'SavePaths',...
                'InitialImData',...
                'Plot',...
                'OptimizerSavePath'...
                },...
                {nan, false, 'SEG', cell(size(aSettings)), [], [], false, []},...
                true,...
                varargin);
            
            if ischar(aPath)
                % An experiment path was given as input.
                this.exPath = aPath;
                seqDirs = GetSeqDirs(aPath);
                seqPaths = strcat(aPath, filesep, seqDirs);
            else
                % A cell array with paths of individual image sequences was
                % given as input.
                this.exPath = '';
                seqPaths = aPath;
                seqDirs = FileEnd(seqPaths);
            end
            
            this.grids = aGrids;
            
            % Create SEGOptimizerSeq-objects for the image sequences.
            this.seqOptimizers = [];
            for i = 1:length(seqDirs)
                this.seqOptimizers = [this.seqOptimizers...
                    SEGOptimizerSeq(seqPaths{i},...
                    aSettings,...
                    'NumImages', aNumImages,...
                    'MostCells', aMostCells,...
                    'ScoringFunction', aScoringFunction,...
                    'Grids', aGrids,...
                    'SaveBestSettings', false,...
                    'SavePath', aSavePaths{i},...
                    'InitialImData', aInitialImData(i))];
            end
            
            % Take the initial value and the bounds from the first
            % sequence.
            this.x0 = mean(cat(2,this.seqOptimizers.x0),2);
            this.xMin = this.seqOptimizers(1).xMin;
            this.xMax = this.seqOptimizers(1).xMax;
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
            if ~isempty(fBest_old) && oF < fBest_old
                for i = 1:length(this.seqOptimizers)
                    this.seqOptimizers(i).SaveSettings(aX);
                end
            end
            
            if ~isempty(this.optimizerSavePath)
                tmpFigure = this.plotFigure;
                this.plotFigure = []; % Do not save the figure.
                optimizer = this;
                if ~exist(fileparts(this.optimizerSavePath), 'dir')
                    mkdir(fileparts(this.optimizerSavePath))
                end
                save(this.optimizerSavePath, 'optimizer')
                this.plotFigure = tmpFigure; % Put the figure back.
            end
            
            if this.plotResults
                this.Plot()
            end
        end
        
        function oF = Objective(this, aX)
            % Computes the utility for a set of parameter values.
            %
            % The function computes segmentation results for all image
            % sequences, saves them in the CTC format, computes the average
            % SEG performance and possibly the average TRA performance, and
            % then removes the saved segmentation results. The returned
            % value is 1-SEG or 1-(SEG+TRA)/2, depending on which scoring
            % function is used. The objective is minimized, and therefore
            % the returned value must have a minimum for the optimal
            % parameters.
            %
            % Inputs:
            % aX - Column vector with parameter values.
            %
            % Outputs:
            % oF - The objective value for the parameters in aX.
            
            % Evaluate the objective values for the individual sequences.
            errors = zeros(length(this.seqOptimizers),1);
            for i = 1:length(this.seqOptimizers)
                errors(i) = this.seqOptimizers(i).EvaluateObjective(aX);
            end
            
            % Compute the average objective value.
            oF = mean(errors);
        end
        
        function Plot(this)
            % Plots how the parameters and the objective value evolve
            % throughout the optimization.
            
            if isempty(this.plotFigure)
                % Create a figure for plotting if one does not exist.
                seqDirs = arrayfun(@(x)FileEnd(x.seqPath), this.seqOptimizers,...
                    'UniformOutput', false);
                this.plotFigure = figure(...
                    'Name', sprintf('Optimizing segmentation for %s', strjoin(seqDirs, ', ')),...
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
            ylabel(scoreAxes, this.seqOptimizers(1).scoringFunction)
            grid(scoreAxes, 'on')
            
            % Plots how the segmentation parameters evolve over time.
            % The best parameters are marked by asterisks.
            settingsNames = this.seqOptimizers(1).settingsNames;
            for i = 1:length(settingsNames)
                settingsAxes = subplot(length(settingsNames), 2, 2*i,...
                    'Parent', this.plotFigure);
                plot(settingsAxes, 1:size(this.xAll,2), this.xAll(i,:))
                hold(settingsAxes, 'on')
                plot(settingsAxes, minIndex, this.xAll(i,minIndex), '*')
                % Allow the plot to be overwritten in the next
                % function evaluation.
                hold(settingsAxes, 'off')
                title(settingsAxes, settingsNames{i})
                grid(settingsAxes, 'on')
                % All parameter axes share the same x-axis, so only the
                % bottom axes needs an x-label.
                if i < length(settingsNames)
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
end