function [cellstack cellnamestack]=flattenStruct2Cell(I) 
%  Extention of struct2cell 
%  Takes a (possibly) nested structure and returns a linear cell array 
%  containing all the elements of the structure and another cell array
%  containing the names of elements
%   usage I is a structure
%   Input
%   cellstack is the array of non-structure elements
%
%   Output
%   cellnamestack is the name of the element including the path through the
%   hirearchy
[C] = struct2cell(I);
tmpnames=fieldnames(I); 
cellstack={};
cellnamestack={};
n=1;   
tempCell=C;
tmpNames=fieldnames(I);
done=0;
while done==0
    
         tmp={};
         oldtmpnames=tmpnames;
         tmpnames={};
    for i=1:length(tempCell)
        if isstruct(tempCell{i})==0
            cellstack{n}=tempCell{i};
             cellnamestack{n}=tmpNames{i};
            n=n+1;
            tempCell{i}=[];tmpNames{i}=[];
        end
        
        if isstruct(tempCell{i})
            tmp=[tmp; struct2cell(tempCell{i})];
            nn=fieldnames(tempCell{i});
            for k=1:length(nn)
               nn{k}= [oldtmpnames{i} '_' char(nn{k})  ];
            end
            tmpnames=[tmpnames; nn];
        end
    end
    
    
tempCell=tmp;
tmpNames=tmpnames;
if length(tempCell)==0
    done=1;
end
    
    
end