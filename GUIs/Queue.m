classdef Queue < handle
    % Execution queue with a GUI.
    %
    % Processing tasks can be added to the Queue, from other processing
    % GUIs. The tasks can then be executed by pressing the start button in
    % the queue GUI. The queue GUI appears when the first processing task
    % is added to the queue. Closing the GUI empties the queue. When the
    % start button is pressed, all tasks will be in the order they were
    % added to the queue.
    
    properties
        functions = {};     % Cell array of function handles for the queued tasks.
        window = -1;        % Figure with the queue GUI (created when the first task is added).
        functionList = [];  % List box with names of the queued tasks.
        startButton = [];   % Button which starts processing of the queued tasks.
    end
    
    methods
        function this = Queue()
            % Creates an empty queue.
            %
            % No GUI is created before the first task is added.
        end
        
        function CreateWindow(this)
            % Creates the GUI for the Queue object.
            
            cf = get(0, 'currentfigure');
            this.window = figure(...
                'Name', 'Queue',...
                'NumberTitle', 'off',...
                'MenuBar', 'none',...
                'ToolBar', 'none',...
                'Units', 'normalized',...
                'Position', [0.2 0.2 0.25 0.25],...
                'CloseRequestFcn', {@CloseRequestFunction, this});
            this.functionList = uicontrol(...
                'Style', 'listbox',...
                'Parent', this.window,...
                'BackgroundColor', 'white',...
                'HorizontalAlignment', 'left',...
                'Units', 'Normalized',...
                'Tooltip', 'Processing tasks in the queue',...
                'Position', [0 0.2 1 0.8]);
            this.startButton = uicontrol(....
                'Style', 'pushbutton',...
                'String', 'Start',...
                'Parent', this.window,...
                'HorizontalAlignment', 'left',...
                'Units', 'Normalized',...
                'Position', [0 0 1 0.2],...
                'Tooltip', 'Start processing the tasks in the queue',...
                'Callback', {@StartButton_Callback, this});
            set(0, 'currentfigure', cf) % Don't alter the current figure property
        end
        
        function Add(this, aFunction)
            % Adds a task to the queue.
            %
            % Inputs:
            % aFunction - Function handle of the task to be added.
            
            if ~ishandle(this.window)
                % Create a queue GUI if there is no GUI already.
                this.CreateWindow()
            end
            
            this.functions = [this.functions; {aFunction}];
            functionNames = cellfun(@func2str, this.functions,...
                'UniformOutput', false);
            set(this.functionList, 'String', functionNames)
        end
        
        function Remove(this, aNum)
            % Removes a task from the queue.
            %
            % Inputs:
            % aNum - Index of the task to be removed. The tasks are indexed
            %        in the order they were added.
            
            this.functions(aNum) = [];
            functionNames = cellfun(@func2str, this.functions,...
                'UniformOutput', false);
            set(this.functionList, 'String', functionNames)
        end
        
        function Empty(this)
            % Removes all tasks from the queue.
            
            this.functions = {};
            set(this.functionList, 'String', {})
        end
        
        function Execute(this)
            % Executes all tasks in the queue.
            %
            % The execution is put in a try-catch block, so that the
            % remaining tasks in the queue can be executed even if one or
            % more tasks cause errors. Tasks are removed from the queue if
            % they are completed successfully, but not if they cause
            % errors. Error messages are displayed when errors occur and
            % after all tasks have been attempted.
            
            errorStructs = [];
            i = 1;
            while i <= length(this.functions)
                try
                    feval(this.functions{i})
                    this.Remove(i)
                    drawnow()
                catch ME
                    disp(getReport(ME))
                    errorStructs = [errorStructs ME]; %#ok<AGROW>
                    i = i + 1;
                end
            end
            
            % Display all errors.
            for err = 1:length(errorStructs)
                disp(getReport(errorStructs(err)))
            end
        end
    end
end

function StartButton_Callback(~, ~, aQueue)
% Callback which starts execution of all tasks in the queue.

aQueue.Execute()
end

function CloseRequestFunction(aObj, ~, aQueue)
% Empties the queue when the user closes the GUI.

aQueue.Empty()
delete(aObj)
end