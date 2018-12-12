function [oX, oAllX] = CoordinateDescent(aFun, aX0, aLowerBound, aUpperBound, varargin)
% Minimizes a function using coordiante descent.
%
% The algorithm is intended for automated parameter tweaking and was
% suggested by Sebastian Thrun. The algorithm goes through the variables to
% be optimized and tests if the performance can be improved by increasing
% or decreasing the parameter by one step length. If the performance gets
% better, the variable value is changed, and the step length is increased.
% Otherwise the step length is decreased. Then the algorithm moves to the
% next variable and does the same thing. The algorithm has completed one
% iteration when all variables have been processed. The algorithm stops
% when all variables have reached a fixed error tolerance, or when it has
% completed a specified number of iterations. The optimization does not use
% any derivatives of the objective function, and requires few function
% evaluations to reach a local optimum. Therefore it is well suited for
% automated optimization of parameters in algorithms. The optimization
% algorithm can handle both continuous and discrete optimization variables.
%
% Inputs:
% aFun - Function handle for the objective function. The function should
%        take an array of optimization variables as input and output a
%        single objective value. When automated parameter optimization is
%        performed, the function takes an array of parameter values and
%        outputs a measure of algorithm performance which has a minimum for
%        the optimal performance.
% aX0 - Array with initial guesses for the optimization variables. The
%       default step lengths are 10% of the absolute values of the initial
%       guesses, and therefore none of the initial guesses must be 0 unless
%       the corresponding step lengths are changed.
% aLowerBound - Array with lower bounds for the optimization variables.
% aUpperBound - Array with upper bounds for the optimization variables.
%
% Property/Value inputs:
% StepSize - Array with initial step sizes for the optimization variables.
% Tolerance - Absolute error tolerance. The tolerance is the same for all
%             variables. The default is 1E-6.
% Increase - The relative increase in the step length, when a better value
%            is found. The default is 0.05.
% Decrease - The relative decrease in the step length, when no better value
%            is found. The default is 0.05.
% Grids - Cell array with grids that define allowed values for discrete
%         optimization variables. There is one cell for each variable. The
%         cells of discrete variables contain arrays with grid values while
%         the cells of continuous parameters are empty. The default is to
%         only have continuous variables.
% MaxIter - The maximum number of iterations that will be performed before
%           the algorithm is terminated. The algorithm can be terminated
%           earlier if the error tolerance is reached for all variables.
%           The default value is inf, meaning that the algorithm is
%           terminated only when the error tolerance is reached.
% ResumePath - Full path of a mat-file where intermediate processing
%              results are saved, so that the optimization can be resumed
%              later.
%
% See also:
% GoldenSectionSearch, Optimizer, SEGOptimizerSeq, SEGOptimizerEx

% Parse property/value inputs.
[aStepSize, aTolerance, aIncrease, aDecrease, aGrids, aMaxIter, aResumePath] = GetArgs(...
    {'StepSize', 'Tolerance', 'Increase', 'Decrease', 'Grids', 'MaxIter', 'ResumePath'},...
    {abs(aX0)*0.25, 1E-6, 0.05, 0.05, cell(size(aX0)), inf, ''},...
    true,...
    varargin);

wbar = waitbar(0, 'Evaluating initial guess',...
    'Name', 'Coordinate descent');

if ~isempty(aResumePath) && exist(aResumePath, 'file')
    % Resume an old processing session that was stopped.
    load(aResumePath)
else
    % Avoid step sizes of 0.
    aStepSize(aStepSize==0) = 1E-3;
    
    if length(aStepSize) == 1
        % Use the same step size for all parameters.
        aStepSize = aStepSize*ones(size(aX0));
    end
    if length(aTolerance) == 1
        % Use the same tolerance for all parameters.
        aTolerance = aTolerance*ones(size(aX0));
    end
    
    % Initialize variables.
    x = aX0;
    oAllX = aX0;
    f = feval(aFun, x);
    steps = aStepSize;
    unchanged = false(size(x));
    iter = 0;
    
    % Save variables so that the processing session can be resumed later.
    if ~isempty(aResumePath)
        if ~exist(fileparts(aResumePath), 'dir')
            mkdir(fileparts(aResumePath))
        end
        % There are figures for plotting of results in SegOptmizerSeq and
        % SegOptimizerEx, that will be saved as a part of aFun. This causes
        % a warning that the saving of figures to mat-files can give very
        % large files, but that is not the case here.
        warning('off', 'MATLAB:Figure:FigureSavedToMATFile')
        % The progress bar should not be saved, because that causes an
        % error when the progress bar is manipulated after loading.
        save(aResumePath, '-regexp', '^(?!wbar$).')
        warning('on', 'MATLAB:Figure:FigureSavedToMATFile')
    end
end

while any(~unchanged) && iter < aMaxIter
    waitbar(...
        iter/aMaxIter,...
        wbar,...
        sprintf('Running iteration %d / %d', iter+1, aMaxIter),...
        'Name', 'Coordiante descent');
    
    unchanged = false(size(x));
    for i = 1:length(x)
        x_min = x;
        % Decrease the current parameter.
        x_min(i) = max(aLowerBound(i), x(i)-steps(i));
        if ~isempty(aGrids{i})
            % Find the highest grid point below.
            ind_min = find(aGrids{i} <= x_min(i), 1, 'last');
            if ~isempty(ind_min)
                x_min(i) = aGrids{i}(ind_min);
            else
                % There was no grid point below, so the lowest grid point
                % is used.
                x_min(i) = aGrids{i}(1);
            end
        end
        if x(i) > aLowerBound(i)
            f_x_min = feval(aFun, x_min);
        else
            % No need to compute the value if we are below the lower bound.
            f_x_min = inf;
        end
        
        x_max = x;
        % Increase the current parameter.
        x_max(i) = min(aUpperBound(i), x(i)+steps(i));
        if ~isempty(aGrids{i})
            % Find the lowest grid point above.
            ind_max = find(aGrids{i} >= x_max(i), 1, 'first');
            if ~isempty(ind_max)
                x_max(i) = aGrids{i}(ind_max);
            else
                % There was no grid point above, so the highest grid point
                % is used.
                x_max(i) = aGrids{i}(end);
            end
        end
        if x(i) < aUpperBound(i)
            f_x_max = feval(aFun, x_max);
        else
            % No need to compute the value if we are above the upper bound.
            f_x_max = inf;
        end
        
        if f_x_min < f && f_x_min < f_x_max
            % The lower value was better. Update and increase the step
            % length.
            x = x_min;
            f = f_x_min;
            steps(i) = steps(i) * (1+aIncrease);
        elseif f_x_max < f && f_x_max < f_x_min
            % The higher value was better. Update and increase the step
            % length.
            x = x_max;
            f = f_x_max;
            steps(i) = steps(i) * (1+aIncrease);
        elseif steps(i) > aTolerance(i)
            % The lower and higher values were both worse, and the
            % requested accuracy has not been reached. The step length is
            % decreased.
            steps(i) = steps(i) * (1-aDecrease);
        else
            % The lower and higher values were both worse, and the
            % requested accuracy has been reached. The optimization is
            % terminated.
            unchanged(i) = true;
        end
        oAllX = [oAllX x]; %#ok<AGROW>
    end
    iter = iter + 1;
    
    % Save all variables so that the processing can be resumed later.
    if ~isempty(aResumePath)
        % There are figures for plotting of results in SegOptmizerSeq and
        % SegOptimizerEx, that will be saved as a part of aFun. This causes
        % a warning that the saving of figures to mat-files can give very
        % large files, but that is not the case here.
        warning('off', 'MATLAB:Figure:FigureSavedToMATFile')
        % The progress bar should not be saved, because that causes an
        % error when the progress bar is manipulated after loading.
        save(aResumePath, '-regexp', '^(?!wbar$).')
        warning('on', 'MATLAB:Figure:FigureSavedToMATFile')
    end
end
oX = x;
delete(wbar)
fprintf('Done with coordinate descent\n')
end