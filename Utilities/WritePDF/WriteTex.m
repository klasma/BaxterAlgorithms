function oSuccessful = WriteTex(aTexFile, aFigFiles, varargin)
% Creates a tex-file with (exported) figures and compiles it to a pdf-file.
%
% In order for the compilation to pdf to work, you need to have pdflatex
% installed. If the compilation fails because pdf-latex is not installed,
% because the tex-file is locked, or for some other reason, a dialog box
% will be opened. In the dialog, the user can select to either cancel the
% compilation or to rerun WriteTex. The pdf-document has a title page and
% figures with imported graphics files. By default the tex-file is kept
% after it has been compiled into pdf, so that you can make changes to the
% document, for example by adding sections with text.
%
% Inputs:
% aTexFile - Full path of the tex-file to be created. The file extension
%            .tex can be omitted.
% aFigFiles - Cell array with relative paths of all graphics files that
%             should become figures in the document. Given that pdflatex is
%             used to compile the tex-file, the graphics files should be
%             png-files or pdf-files. You do not need to include the file
%             extensions of the files.
%
% Property/Value inputs:
% Title - Title used in the document.
% AuthorStr - Author string for the front page of the document. Latex
%             formatting can be used.
% Orientation - Orientation used in the document. The allowed values are
%               'portrait' and 'landscape'. The default is 'landscape'.
% NumCols - Number of columns in the tex- and pdf-documents (1 or 2). The
%           default is 1.
% Captions - Cell array with captions for the figures.
% PaperSize - Paper size for the document (letter is default).
% Pdfdoc - Full path of the pdf-file to be generated, including the file
%          extension. If this inputs is not specified, the tex-file will
%          not be compiled into a pdf-file.
% DelTex - If this parameter is set to true, the tex-file will be deleted
%          at the end of this function.
%
% Outputs:
% oSuccessful - This output is true if the generation of all documents was
%               successful.
%
% See also:
% SavePlotsGUI, SavePlots, SaveFigure, WriteBeginning, WriteClear,
% WriteEnd, WriteFigure

% Names and defaults of property/value inputs.
pnames_dflts = {...
    'Title', ''
    'AuthorStr', ''
    'Orientation', 'landscape'
    'NumCols', 1
    'Captions', {}
    'PaperSize', 'letter'
    'Pdfdoc', ''
    'DelTex', false};

% Parse property/value inputs.
[   aTitle,...
    aAuthorStr,...
    aOrientation,...
    aNumCols,...
    aCaptions,...
    aPaperSize,...
    aPdfdoc,...
    aDelTex] = GetArgs(pnames_dflts(:,1), pnames_dflts(:,2), true, varargin);

% Create empty captions if no captions have been specified.
if isempty(aCaptions)
    aCaptions = repmat({''}, size(aFigFiles,1), size(aFigFiles,2));
end

[texPath, texName] = fileparts(aTexFile);

% Open the tex-file.
texFid = fopen(fullfile(texPath, [texName '.tex']), 'w');

if isequal(texFid, -1)
    errorMessage = sprintf(...
        'The file %s could not be created.',...
        fullfile(texPath, [texName '.tex']));
    errordlg(errorMessage, 'Unable to create tex-file')
    oSuccessful = false;
    return
end

WriteBeginning(texFid, aTitle, aPaperSize, aOrientation, aNumCols, aAuthorStr)

% Define the number of figures that will be put on each page.
switch aOrientation
    case 'landscape'
        if aNumCols == 1
            axesPerPage = 1;
        else
            axesPerPage = 4;
        end
    case 'portrait'
        if aNumCols == 1
            axesPerPage = 2;
        else
            axesPerPage = 6;
        end
end

for i = 1:length(aFigFiles)
    % Define the alignment of each figure based on the column that it will
    % be placed in.
    if aNumCols == 1
        alignment = 'center';
    else
        switch lower(aOrientation)
            case 'portrait'
                if mod(floor((i-1)/3), 2)
                    alignment = 'flushleft';
                else
                    alignment = 'flushright';
                end
            case 'landscape'
                if mod(floor((i-1)/2), 2)
                    alignment = 'flushleft';
                else
                    alignment = 'flushright';
                end
            otherwise
                error('Unknown orientation %s', aOrientation)
        end
    end
    
    % Relative paths must be specified using '/' in latex.
    WriteFigure(texFid, strrep(aFigFiles{i}, '\', '/'),...
        aCaptions{i}, alignment)
    
    if mod(i, axesPerPage) == 0
        WriteClear(texFid)
    end
end
WriteEnd(texFid)
% Close the tex-file when everything has been written to it.
fclose(texFid);

% Compile the tex-file to a pdf-file using pdflatex.
if ~isempty(aPdfdoc)
    % Define the command to pdflatex.
    command = ['pdflatex '...
        '--include-directory="' texPath '" '...
        '--output-directory="' texPath '" '...
        '"' texName '"'];
    
    % Run pdflatex
    output = system(command);
    
    while output ~= 0
        % pdflatex failed.
        choice = questdlg(...
            sprintf(['Make sure that pdflatex is installed and that '...
            '%s is not locked.'], [texName '.tex']),...
            'Unable to create pdf.',...
            'Try again', 'Cancel', 'Try again');
        switch choice
            case 'Try again'
                oSuccessful = WriteTex(aTexFile, aFigFiles, varargin{:});
                return
            case {'Cancel' ''}
                oSuccessful = false;
                return
        end
    end
    
    % Rename the pdf document if necessary.
    if ~strcmpi(fullfile(texPath, [texName '.pdf']), aPdfdoc)
        movefile(fullfile(texPath, [texName '.pdf']), aPdfdoc, 'f');
    end
    
    % Delete other files created by pdflatex.
    delete(fullfile(texPath, [texName '.aux']))
    delete(fullfile(texPath, [texName '.log']))
end

% Delete the tex-file if the caller asked for it.
if aDelTex
    delete(fullfile(texPath, [texName '.tex']))
end

oSuccessful = true;
end