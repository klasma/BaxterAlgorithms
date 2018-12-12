classdef (Abstract) Optimizer < handle
    % Base class for classes that perform automated parameter optimization.
    %
    % This class provides a framework to perform automated parameter
    % optimization, using derivative free optimization. The class is
    % abstract. To perform optimization, you need to create a sub-class,
    % which defines a constructor and the function Objective, which
    % computes the performance for a given set of parameters. The objective
    % function is minimized, so smaller values must correspond to better
    % performance. The parameters to be optimized are placed in a column
    % vector of optimization variables. The variables can be continuous or
    % discrete, and they can have upper and/or lower bounds. The
    % optimization can be performed using coordinate descent, the built-in
    % function fminsearch, or golden section search. Golden section search
    % does however only work for optimization of a single variable.
    %
    % See also:
    % SEGOptimizerSeq, SegOptimizerEx, CoordinateDescent, GoldenSectionSearch
    
    properties
        x0 = [];        % Initial guess.
        grids = [];     % Cell array with grid points for discrete variables.
        xMax = inf;     % Array with upper bounds for the variables.
        xMin = -inf;    % Array with lower bounds for the variables.
        xBest = [];     % Array with the current best point.
        xAll = [];      % Matrix where each column is an evaluated point.
        f0 = [];        % Function value for the initial guess.
        fBest = [];     % Current best function value.
        fAll = [];      % Array with the function values for all points in xAll.
    end
    
    methods
        function this = Optimizer()
            % Empty constructor.
            %
            % The class is abstract, so objects of the class will never be
            % created.
        end
        
        function oF = EvaluateObjective(this, aX)
            % Evaluates the objective (function value) for a point.
            %
            % The function executes the objective function and stores the
            % point (variable values) in xAll and the corresponding
            % function value in fAll. xBest and fBest are updated if the
            % function value is better than all earlier function values.
            %
            % Inputs:
            % aX - Column vector with the point that the objective function
            %      should be evaluated for.
            
            fprintf('Function evaluation %d\n', length(this.fAll)+1)
            
            this.xAll = [this.xAll aX];
            
            % Assign values to x0 and f0, if this is the first point to be
            % evaluated.
            if isempty(this.f0) && ~isempty(this.x0)
                this.f0 = this.Objective(this.x0);
                this.xBest = this.x0;
                this.fBest = this.f0;
                fprintf('f(x0) = %.8f\n', 1-this.f0)
                if aX == this.x0
                    oF = this.f0;
                    this.fAll = [this.fAll oF];
                    return
                end
            end
            
            % Compute the function value.
            oF = this.Objective(aX);
            this.fAll = [this.fAll oF];
            
            % Update the best solution if the current point is better than
            % the previous best solution.
            if isempty(this.fBest) || oF < this.fBest
                this.xBest = aX;
                this.fBest = oF;
                fprintf('f(xBest) = %.8f\n', 1-this.fBest)
            end
        end
        
        function Optimize_fminsearch(this)
            % Performs optimization using the built in function fminsearch.
            
            this.Clear()
            options = optimset('TolX', 1E-6, 'MaxFunEvals', 100);
            fminsearch(@this.EvaluateObjective, this.x0, options);
        end
        
        function Optimize_coordinatedescent(this, varargin)
            % Performs optimization using coordinate descent.
            %
            % Parameter/Value inputs:
            % Increase - The increase of the step length when a better
            %            value was found by altering a variable. The
            %            default is 0.2 and means that the step length for
            %            the altered variable is increased by 20%.
            % Decrease - The decrease of the step length when no better
            %            values can be found by altering a variable. The
            %            default is 0.2 and means that the step length for
            %            the considered variable is decreased by 20%.
            % MaxIter - The maximum number of iterations. The maximum
            %           number is usually reached, because the algorithm
            %           requires many iterations to converge. The default
            %           value is 25.
            % ResumePath -  The full path of a mat-file, to which
            %               intermediate optimization results will be
            %               saved, so that the optimization can be resumed
            %               later if it is stopped by the user.
            
            [aIncrease, aDecrease, aMaxIter, aResumePath] = GetArgs(...
                {'Increase', 'Decrease', 'MaxIter', 'ResumePath'},...
                {0.2, 0.2, 25, ''},...
                true,...
                varargin);
            
            this.Clear()
            CoordinateDescent(@this.EvaluateObjective, this.x0, this.xMin, this.xMax,...
                'Increase', aIncrease,...
                'Decrease', aDecrease,...
                'MaxIter', aMaxIter,...
                'Grids', this.grids,...
                'ResumePath', aResumePath);
        end
        
        function Optimize_goldensection(this, varargin)
            % Performs optimization using golden section search.
            %
            % This optimization algorithm can only be used when there is a
            % single optimization variable.
            %
            % Property/Value inputs:
            % Tolerance - Absolute error tolerance in the optimized
            %             variable. The optimization terminates when the
            %             accuracy reaches this tolerance. The default
            %             value is 1E-3.
            
            aTolerance = GetArgs({'Tolerance'}, {1E-3}, true, varargin);
            this.Clear()
            GoldenSectionSearch(@this.EvaluateObjective, this.xMin, this.xMax,...
                'Tolerance', aTolerance);
        end
        
        function Clear(this)
            % Clears the lists of previous points and their values.
            
            this.xBest = [];
            this.fBest = [];
            this.xAll = [];
            this.fAll = [];
        end
    end
    
    methods (Abstract)
        oF = Objective(this, aX)
        % Computes the objective function values or points in sub-classes.
        %
        % This abstract method ensures that all sub-classes define an
        % objective function.
        %
        % Inputs:
        % aX - Column array with variable values that the objective value
        %      should be computed for.
        %
        % Outputs:
        % oF - The objective function value corresponding to aX.
    end
end