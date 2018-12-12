function oNum = MaxWorkers()
% Returns the maximum number of workers in parallel processing.
%
% The returned number is the number of workers in the local parallel
% processing profile and it may be larger than the number of cores in the
% processor. It is usually best to use as many cores as there are processor
% cores.
%
% Outputs:
% oNum - The maximum number of workers.

% The maximum number of parallel MATLAB workers.
if ~verLessThan('matlab', '7.14')
    % New command from 2012a.
    myCluster = parcluster('local');
    oNum = myCluster.NumWorkers;
else
    % Old command that will be removed in a future release of MATLAB.
    myScheduler = findResource('scheduler', 'configuration', 'local'); %#ok<DFNDR>
    oNum = myScheduler.clusterSize;
end
end