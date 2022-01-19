  %%Rhodamine Code 
  
function [area,Thresh_eq,DrugMask,ThreshHigh] = ThreshSeg(Img, threshold)

    Thresh_eq =imadjust(Img,[0 0.4],[]);
       
    threshold = threshold *intmax(class(Img));
    
    rhodaweiner=wiener2(Img);
    DrugMask=rhodaweiner>threshold;
    
    area = sum(DrugMask,'all');
    
  