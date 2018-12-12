function StartWorkers(aNumber)
% Opens the specified number of workers for parallel processing.
%
% If the specified number of workers is already open (no more and no less),
% the function will not do anything. Otherwise the function will first
% close the worker pool currently open and open a new pool of the correct
% size.
%
% Inputs:
% aNumber - The desired number of workers.

% Check how many workers are running.
pool = gcp('nocreate');
if isempty(pool)
    poolSize = 0;
else
    poolSize = pool.NumWorkers;
end

if poolSize ~= aNumber
    if poolSize ~= 0
        % The existing pool has to be closed before a new pool is
        % opened.
        delete(pool)
    end
    if aNumber > 0
        parpool(aNumber);
    end
end
end