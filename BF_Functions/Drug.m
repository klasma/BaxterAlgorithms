  %%BasicThresh Code 
  
function [DrugBright,areaDrug, Drugsum, DrugMask,Img_Eq] = Drug(Img, Drug_threshold)
    Img_Eq=imadjust(Img,[0 0.25],[]);
    Drug_threshold = Drug_threshold *intmax(class(Img));
    DrugMask=Img>Drug_threshold;
    areaDrug = sum(DrugMask,'all');
    Drugsum = sum(Img(DrugMask));
    DrugBright(~DrugMask)=0;
   
    
  