function WriteEnd(aFid)
% Writes code to end tex-document.
%
% Inputs:
% aFid - File identifier of an open tex-file to \end{document} will be
%        written.
%
% See also:
% SavePlotsGUI, SavePlots, SaveFigure, WriteBeginning, WriteClear,
% WriteFigure, WriteTex

fprintf(aFid,[...
    '\r\n'...
    '\\end{document}']);
end