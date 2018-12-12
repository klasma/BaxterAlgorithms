function WriteClear(aFid)
% Writes code for a page break to a tex-file.
%
% Inputs:
% aFid - File identifier of an open tex-file to which \clearpage will be
%        written.
%
% See also:
% SavePlotsGUI, SavePlots, SaveFigure, WriteBeginning, WriteEnd,
% WriteFigure, WriteTex

fprintf(aFid,[...
    '\r\n'...
    '\\clearpage\r\n']);
end