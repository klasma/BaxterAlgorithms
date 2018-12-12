function oStack = StretchZ(aStack, aRatio)
% Adds virtual z-planes between exiting z-planes in 3D data.
%
% The function will copy the values of existing z-planes to virtual
% z-planes above and below. This is an alternative to UpSampleZ, which
% works better for binary images. If the number of planes to be added is
% odd, there will be more planes added  above. No planes will be added
% below the first plane or above the last plane.
%
% Inputs:
% aStack - Stack that virtual planes will be inserted into.
% aRatio - The up-sampling ratio. aRatio-1 virtual planes will be inserted
%          between every pair of planes.
%
% Outputs:
% oStack - Stack with inserted virtual planes.
%
% See also:
% UpsampleZ, DownSampleZ

% Make aRatio copies of each plane.
oStack = zeros(size(aStack,1), size(aStack,2), size(aStack,3)*aRatio);
for i = 1:size(aStack,3)
    oStack(:,:,(i-1)*aRatio+1:i*aRatio) = repmat(aStack(:,:,i),[1 1 aRatio]);
end

% Trim planes at the top and the bottom to get the desired stack.
cut1 = floor((aRatio-1)/2);
cut2 = ceil((aRatio-1)/2);
oStack = oStack(:,:,1+cut1:end-cut2);
end