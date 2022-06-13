function [ExportParams] = DrugParams(CytMask,NucMask,Gal8Mask,CytImg,DrugImg)
%Cytosol area
CytArea = sum(CytMask,'all');

%Drug in cytosol
CytDrug = sum(DrugImg(CytMask));

%Drug out of cytosol
ECMask = logical(1-CytMask);
ECDrug = sum(DrugImg(ECMask));

%Nuclear Area
NucArea = sum(NucMask,'all');

%Drug in nucleus
NucDrug = sum(DrugImg(NucMask));

%Gal8Area
Gal8Area = sum(Gal8Mask,'all');

%Drug in Gal8
Gal8Drug = sum(DrugImg(Gal8Mask));

%Gal8 intensity
Gal8Sum = sum(CytImg(Gal8Mask));

ExportParams = {CytArea,CytDrug,ECDrug,NucArea,NucDrug,Gal8Area,Gal8Drug,Gal8Sum};

end