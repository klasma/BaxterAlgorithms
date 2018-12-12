function oOptimum = GoldenSectionSearch(aFun, aLowerLimit, aUpperLimit, varargin)
% Minimizes a function using golden section search.
%
% The algorithm can find the minimum of a strictly unimodal function, and
% can be used to optimize the performance of an algorithm by automatically
% tweaking a single parameter. If the performance is not strictly unimodal
% as a function of the parameter, the optimization will find a local
% minima. The optimization is performed by evaluating the objective
% function at two test points between the lower and upper limits. That
% separates the search interval into 3 regions. Given that the objective
% function is strictly unimodal, the minimum must be in one of the regions
% next to the test point with the lowest value. The remaining region is
% discarded. The other test point becomes a new limit for the search
% interval, and two new points are computed. The test points are however
% placed inside the search interval according to the golden ratio, and
% therefore the best test point can be reused, and only one new test point
% needs to be evaluated in each iteration. This function is an extension of
% traditional golden section search, which allows the upper limit to be
% increased. The function has been used only to optimize positive
% variables, and therefore it cannot decrease the lower limit.
%
% Inputs:
% aFun - Function handle of the function to be optimized. The function
%        should take the optimization variable as input and output the
%        corresponding objective value.
% aLowerLimit - Lower limit for the optimization variable. The optimum is
%               assumed to lie above this value.
% aUpperLimit - Upper limit for the optimization variable. The algorithm
%               will start looking for an optimum below this value, but can
%               increase the upper limit if it is necessary for finding the
%               optimum.
%
% Property/Value inputs:
% Tolerance - Absolute error tolerance. The default is 1E-6.
%
% Outputs:
% oOptimum - The optimal value of the optimization variable.
%
% See also:
% CoordinateDescent, Optimizer, SEGOptimizerSeq, SEGOptimizerEx

% Parse property/value inputs.
tol = GetArgs({'Tolerance'}, {1E-6}, true, varargin);

r = (sqrt(5) - 1)/2;
q = 1-r;

x1 = aLowerLimit + q*(aUpperLimit-aLowerLimit);  % Lower test point.
x2 = aLowerLimit + r*(aUpperLimit-aLowerLimit);  % Upper test point.
Fupper = feval(aFun, aUpperLimit);  % Function value at upper limit.
F1 = feval(aFun, x1);  % Function value at lower test point.
F2 = feval(aFun, x2);  % Function value at upper test point.

% Increase the upper limit until the upper test point gets a lower value.
while Fupper < F2
    % The previous upper limit is reused as lower test point.
    x1 = aUpperLimit;
    % New upper limit.
    aUpperLimit = (aUpperLimit-aLowerLimit)/q;
    % New upper test point.
    x2 = aLowerLimit + r*(aUpperLimit-aLowerLimit);
    
    fprintf('Increasing the upper limit to %f\n', aUpperLimit)
    
    % Evaluate missing function values.
    F1 = Fupper;
    Fupper = feval(aFun, aUpperLimit);
    F2 = feval(aFun, x2);
end

while aUpperLimit - aLowerLimit > 2*tol
    if F1 < F2
        % The lower test point has the best value, so the optimum must lie
        % between the lower limit and the upper test point. The upper test
        % point becomes the new upper limit and the lower test point
        % becomes the new upper test point.
        aUpperLimit = x2;
        x2 = x1;
        F2 = F1;
        x1 = aLowerLimit + q*(aUpperLimit-aLowerLimit);
        F1 = feval(aFun, x1);
    else
        % The upper test point has the best value, so the optimum must lie
        % between the lower test point and the upper limit. The lower test
        % point becomes the new lower limit and the upper test point
        % becomes the new lower test point.
        aLowerLimit = x1;
        x1 = x2;
        F1 = F2;
        x2 = aLowerLimit + r*(aUpperLimit-aLowerLimit);
        F2 = feval(aFun, x2);
    end
end
% Return the average between the upper and lower limits when the interval
% between them is less than or equal to two times the error tolerance.
oOptimum = (aLowerLimit+aUpperLimit)/2;
end