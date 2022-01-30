  %%Rhodamine Code 
  
function [RhodBright,areaRhod, Rhodsum, RhodAvgInCell, RhodAvgOutCell,rhod_eq,RhodMask] = Rhoda(drug, Rhoda_threshold, cyt_bw4)

    rhod_eq =imadjust(drug,[0 0.4],[]);
       
    Rhoda_threshold = Rhoda_threshold *intmax(class(drug));
    
    rhodaweiner=wiener2(drug);
    RhodMask=rhodaweiner>Rhoda_threshold;
    areaRhod = sum(RhodMask,'all');
    
    rhoda_in_cell = drug(cyt_bw4);
    rhoda_out_cell = drug(cyt_bw4 == 0);
    
    cell_area = sum(sum(cyt_bw4));
    not_cell_area = size(cyt_bw4,1) * size(cyt_bw4, 2) - cell_area;
    
    Rhodsum = sum(rhod_eq(RhodMask));
    RhodBright=drug;
    RhodBright(~RhodMask)=0;
    RhodAvgInCell = sum(rhoda_in_cell) / cell_area;
    RhodAvgOutCell = sum(rhoda_out_cell) / not_cell_area;
    
  