  %%BasicThresh Code 
  
function [DrugBright,areaDrug, Drugsum, DrugMask] = Drug(Img, Drug_threshold)

    Drug_threshold = Drug_threshold *intmax(class(drug));
    DrugMask=Img>Drug_threshold;
    areaDrug = sum(DrugMask,'all');
    Drugsum = sum(Img(DrugMask));
    DrugBright(~DrugMask)=0;
   
    
  