parfor i= 1:size(StructOut,1)
   [StructOut(i).regionProps_Data.Well]=deal(StructOut(i).Well);
   [StructOut(i).regionProps_Data.TP]=deal(StructOut(i).Timepoint);
   [StructOut(i).regionProps_Data.AF]=deal(StructOut(i).AnalysisFunction);
   [StructOut(i).regionProps_Data.ImPlane]=deal(StructOut(i).ImagePlane);
end    