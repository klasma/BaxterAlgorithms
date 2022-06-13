  %%Drugmine Code 
  
function [DrugBright,areaDrug, Drugsum, DrugAvgInCell, DrugAvgOutCell,Drug_eq,DrugMask] = Drug(Img, Drug_threshold, cyt_bw4)

    Drug_eq =imadjust(Img,[0 0.4],[]);
       
    Drug_threshold = Drug_threshold *intmax(class(drug));
    
    Drugweiner=wiener2(Img);
    RhodMask=Drugweiner>Drug_threshold;
    areaDrug = sum(RhodMask,'all');
    if 
    Drug_in_cell = drug(cyt_bw4);
    Drug_out_cell = drug(cyt_bw4 == 0);
    
    cell_area = sum(sum(cyt_bw4));
    not_cell_area = size(cyt_bw4,1) * size(cyt_bw4, 2) - cell_area;
    
    Rhodsum = sum(rhod_eq(RhodMask));
    RhodBright=drug;
    RhodBright(~RhodMask)=0;
    DrugvgInCell = sum(Drug_in_cell) / cell_area;
    DrugvgOutCell = sum(Drug_out_cell) / not_cell_area;
    
  