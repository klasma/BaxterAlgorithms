function SavePlots(aSavePath, aSaveName, aPlots, varargin)
% Exports plots to different file formats.
%
% The function can be used to save plots to the file formats pdf, eps, tif,
% and fig. It is also possible to generate latex code for a document where
% each plot is a figure, and compile that pdf document into a pdf. For the
% compilation, you need to have pdflatex installed on your computer. The
% plots can be sent to the function as either figures, or plotting
% functions that take a figure object as input. If plotting functions are
% used, a temporary figure will be created for the plotting, and closed
% once all plots have been saved. The function is normally called from
% SavePlotsGUI, but it can also be executed on its own. The image files are
% saved using SaveFigure, and tex- and pdf-documents are saved using
% WriteTex.
%
% Inputs:
% aSavePath - Path of a folder where all the exported figures are saved.
% aSaveName - Name of tex- and pdf-documents that will be created. No file
%             extensions should be included.
% aPlots - Cell array of figure objects or plotting functions. Both input
%          types can be mixed in the same cell array.
%
% Property/Value inputs:
% FigNames - Cell array of file names, not including file extensions. If no
%            names are given, the files will be named fig0001, fig0002,...
% Title - Title used in tex- and pdf-documents.
% AuthorStr - Author string for the front page of tex- and pdf-documents.
%             Latex formatting can be used.
% Orientation - Orientation used in tex- and pdf-documents. The allowed
%               values are 'portrait' and 'landscape'. The default is
%               'landscape'.
% FigUnits - Unit used for FigPosition. This only changes the unit of the
%            figure temporarily.
% FigPosition - Specifies a size and a location for all plot figures in the
%               format [left bottom width height]. The default unit is
%               'normalized', but other units can be specified in FigUnits.
% NumCols - Number of columns in the tex- and pdf-documents (1 or 2).
% Xlim - Two element array with x-limits for all plot axes.
% Ylim - Two element array with y-limits for all plot axes.
% Captions - Cell array with captions for tex- and pdf-documents.
% Formats - Cell array with file formats to export to. The allowed values
%           are 'pdf', 'eps', 'tif', 'fig', 'pdfdoc', and 'tex'.
% Style - Plotting style that will be applied to the plots.
% PaperSize - Paper size for tex- and pdf-documents (letter is default).
% SaveAxes - If this is set to true, one image is saved for each axes. The
%            filenames are the file names specified in FigNames, followed
%            by '_' and the index of the axes in the list of figure
%            children. Only the plotting regions of the axes are saved.
%            This option makes it possible to save images that are shown in
%            axes, without introducing white margins. Empty axes are not
%            saved. The default value is false.
% Width - Desired image width in inches (see SaveFigure).
% Height - Desired image height in inches (see SaveFigure).
% Dpi - Resolution of raster formats, in dots per inch (see SaveFigure).
%
% See also:
% SavePlotsGUI, SaveFigure, WriteTex

% If no path is specified, the default is to write to the current path.
if isempty(aSavePath)
    aSavePath = pwd;
end

% sfArgs are inputs arguments sent directly to SaveFigure.
[sfArgs, spArgs] = SelectArgs(varargin, {'Width', 'Height', 'Dpi'});

% Names and defaults for property/value inputs.
pnames_dflts = {...
    'FigNames', {}
    'Title', 'Plots'
    'AuthorStr', ''
    'Orientation', 'landscape'
    'FigUnits', 'normalized'
    'FigPosition', []
    'NumCols', 1
    'Xlim', []
    'Ylim', []
    'Captions', {}
    'Formats', {'pdfdoc'}
    'Style', ''
    'PaperSize', 'letter'
    'SaveAxes', true};

% Parse property/value inputs which are not forwarded to SaveFigure.
[...
    aFigNames,...
    aTitle,...
    aAuthorStr,...
    aOrientation,...
    aFigUnits,...
    aFigPosition,...
    aNumCols,...
    aXlim,...
    aYlim,...
    aCaptions,...
    aFormats,...
    aStyle,...
    aPaperSize,...
    aSaveAxes] = GetArgs(pnames_dflts(:,1), pnames_dflts(:,2), true, spArgs);

% If no figure names have been specified, the default figure names are
% fig0001, fig0002, and so forth.
if isempty(aFigNames)
    aFigNames = cellfun(@(x)sprintf('fig%04d',x), num2cell(1:length(aPlots)),...
        'UniformOutput', false)';
    for pIndex = 1:length(aPlots)
        if ~isa(aPlots{pIndex}, 'function_handle') &&...
                ~isempty(get(aPlots{pIndex}, 'Name'))
            aFigNames{pIndex} = get(aPlots{pIndex}, 'Name');
            % Make sure that the figure names are valid file names, by
            % replacing characters that may cause problems by '_'.
            aFigNames{pIndex} = regexprep(aFigNames{pIndex}, '[^\w- (),]', '_');
        end
    end
end

% Extract captions from the figure UserData fields if not give as input.
if isempty(aCaptions)
    aCaptions = repmat({''}, length(aPlots), 1);
    for pIndex = 1:length(aPlots)
        if ~isa(aPlots{pIndex}, 'function_handle') &&...
                ~isempty(get(aPlots{pIndex}, 'UserData'))
            aCaptions{pIndex} = get(aPlots{pIndex}, 'UserData');
        end
    end
end

% Convert strings specifying formats into boolean variables.
pdfdoc = any(strcmpi(aFormats, 'pdfdoc'));
tex = any(strcmpi(aFormats, 'tex'));
pdf = any(strcmpi(aFormats, 'pdf'));
eps = any(strcmpi(aFormats, 'eps'));
tif = any(strcmpi(aFormats, 'tif'));
fig = any(strcmpi(aFormats, 'fig'));

% Create the destination folder if necessary.
if ~exist(aSavePath, 'dir')
    mkdir(aSavePath)
end

% If any of the inputs are plotting functions, a temporary figure is
% created. The plotting functions will plot in that figure and the figure
% is closed at the end of this function.
tmpFig = [];
if any(cellfun(@(x)isa(x, 'function_handle'), aPlots))
    tmpFig = figure('Name', 'Temporary figure showing the plot being saved');
end

% Save the plots one by one.
wbar = waitbar(0, 'Saving figures', 'Name', 'Exporting');
for pIndex = 1:length(aPlots)
    if isa(aPlots{pIndex}, 'function_handle')
        % Plot needs to be made by executing a function.
        f = tmpFig;
    else
        % Existing plot in figure.
        f = aPlots{pIndex};
    end
    
    % Resize the figure if requested in input arguments.
    if ~isempty(aFigPosition)
        units = get(f, 'Units');
        set(f, 'Units', aFigUnits, 'Position', aFigPosition);
        set(f, 'Units', units);
    end
    
    if isa(aPlots{pIndex}, 'function_handle')
        % Create plot by calling plotting function.
        % Must be after the figure is resized.
        feval(aPlots{pIndex}, tmpFig)
        drawnow()
    end
    
    if ~isempty(aStyle)
        % Change the plotting style.
        FormatFigure(f, aStyle)
    end
    
    % Change axis limits on all axes in the figure.
    if ~isempty(aXlim) && ~any(isnan(aXlim))
        FormatFigure(f, @(a)set(a, 'xlim', aXlim))
    end
    if ~isempty(aYlim) && ~any(isnan(aYlim))
        FormatFigure(f, @(a)set(a, 'ylim', aYlim))
    end
    
    % Call SaveFigure to save the plots to files.
    if pdf || tex || pdfdoc
        SaveFigure(f, fullfile(aSavePath, aFigNames{pIndex}), '-dpdf', sfArgs{:})
    end
    if eps
        SaveFigure(f, fullfile(aSavePath, aFigNames{pIndex}), '-depsc', sfArgs{:})
    end
    if tif
        if aSaveAxes
            % Save the contents of the axes individually, using screen
            % capture.
            children = get(f, 'Children');
            index = 1;
            for chIndex = 1:length(children)
                if strcmp(get(children(chIndex), 'Type'), 'axes') &&...
                        ~isempty(get(children(chIndex), 'Children'))
                    im = RecordAxes(children(chIndex));
                    imPath = fullfile(aSavePath,...
                        [aFigNames{pIndex} '_ ' num2str(index) '.tif']);
                    imwrite(im,imPath, 'Compression', 'lzw')
                    index = index + 1;
                end
            end
        else
            SaveFigure(f, fullfile(aSavePath, aFigNames{pIndex}), '-dtiff', sfArgs{:})
        end
    end
    if fig
        saveas(f, fullfile(aSavePath, aFigNames{pIndex}), 'fig')
    end
    waitbar(pIndex/(length(aPlots)+(tex || pdfdoc)), wbar);
end

% Close temporary figure used by plotting functions, if one was created.
if ~isempty(tmpFig)
    close(tmpFig)
end

% Create a latex document with plots as figures and compile it to pdf. The
% pdf files used to created the figures in the pdf were created in the main
% loop. To compile the pdf document, you must have pdflatex installed.
if tex || pdfdoc
    waitbar(pIndex/(length(aPlots)+1), wbar, 'Creating documents');
    if pdfdoc
        pdfdocFile = fullfile(aSavePath, [aSaveName '.pdf']);
    else
        % The tex-file will not be compiled into a pdf.
        pdfdocFile = '';
    end
    
    % Create the tex-file and possibly compile it to pdf.
    WriteTex(...
        fullfile(aSavePath, [aSaveName '.tex']),...
        strcat(aSavePath, filesep, aFigNames),...
        'Title', aTitle,...
        'AuthorStr', aAuthorStr,...
        'Orientation', aOrientation,...
        'NumCols', aNumCols,...
        'Captions', aCaptions,...
        'Pdfdoc', pdfdocFile,...
        'PaperSize', aPaperSize);
    
    % Remove the tex-file if that format was not requested.
    try
        texPath = fullfile(aSavePath, [aSaveName '.tex']);
        if ~tex && exist(texPath, 'file')
            delete(texPath)
        end
    catch
        errordlg(sprintf('Unable to remove %s', [aSaveName '.tex']),...
            'Error removing file')
    end
    
    % Remove the figure pdf-files if that format was not requested.
    for i = 1:length(aFigNames)
        try
            if ~pdf
                delete(fullfile(aSavePath, filesep, [aFigNames{i} '.pdf']))
            end
        catch
            errordlg(sprintf('Unable to remove %s', [aFigNames{i} '.pdf']),...
                'Error removing file')
        end
    end
end
delete(wbar)
end