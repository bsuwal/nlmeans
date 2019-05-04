% pdist running slow??
num_iters = 1000;
patch_size = 41;

% get two random patches
img = importdata('Indian_pines.mat');
[height, width, dims] = size(img);
patch_padding = floor(patch_size/2);

patch1 = get_patch(img, 50, 50, patch_padding, patch_size, dims);
patch2 = get_patch(img, 55, 55, patch_padding, patch_size, dims);

tic 
for i = 1:num_iters
    dist = pdist([patch1'; patch2'], 'euclidean');
end
toc

tic 
for i = 1:num_iters
    dist = get_distance(patch1, patch2);
end
toc

%%
function patch = get_patch(img, center_x, center_y, padding, patch_size, dims)
    raw_patch = img(center_x - padding: center_x + padding, ...
                center_y - padding: center_y + padding, ...
                :);
    patch = double(reshape(raw_patch, [patch_size * patch_size * dims, 1]));
end

function dist = get_distance(main_patch, compare_patch)
    % Returns the euclidean distance between two patches 
    squared = ((main_patch - compare_patch).^2);              
    dist = sqrt(sum(squared(:)));        
end