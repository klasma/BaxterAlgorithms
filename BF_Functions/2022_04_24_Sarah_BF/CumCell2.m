function [out] = CumCell2(AllData4)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here


    out=AllData4;
    out3=[];

    while iscell(out{1}{1});
        out=horzcat(out{:});
    end
    out=vertcat(out{:});

end
