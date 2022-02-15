  %%BasicThresh Code 
  
function [Drug_Perim,DrugMask] = Drug(Img, Drug_threshold)
%     Img_Eq=imadjust(Img,[0 0.25],[]);
DilateDisk=strel('disk',round(1*(0.34/MiPerPix)));

Drug_threshold = Drug_threshold *intmax(class(Img));
    DrugMask=Img>Drug_threshold;
    Drug_Perim=imdilate(DrugMask,DilateDisk);
Drug_Perim=imbinarize(Gal8Quant4-Gal8Quant3);
%     areaDrug = sum(DrugMask,'all');
%     Drugsum = sum(Img(DrugMask));
%     DrugBright(~DrugMask)=0;
   
    
  