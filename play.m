%% Preprocessing
img = importdata('Indian_pines.mat');

% make the patches and display them first
patch_size = 9; % must always be odd numbered
[height, width, dims] = size(img);
patch_padding = floor(patch_size/2);

% this is only the number of patches within the search window
num_patches = (height - 2 * patch_padding) * (width - 2 * patch_padding);

fprintf('Number of patches %i\n', num_patches);

%% make patch matrix
% patches = zeros((width - 2 * patch_padding) * (height - 2 * patch_padding), patch_size * patch_size * dims);
patches_mat = zeros(width - 2 * patch_padding, height - 2 * patch_padding, patch_size * patch_size * dims);

for j = patch_padding + 1: height - patch_padding
    for i = patch_padding + 1: width - patch_padding
        patches_mat(i, j, :) = get_patch(img, i, j, patch_padding, patch_size, dims);
    end
end

%%
tic 
for i=1:1000
patch = patches_mat(11, 11, :);
end
toc

tic
for i=1:1000
patch = get_patch(img, 15, 15, patch_padding, patch_size, dims);
end
toc
%%
function patch = get_patch(img, center_x, center_y, padding, patch_size, dims)
    % Returns a patch from the image
    % Args: img          - the image
    %       center_pixel - the pixel in the center of the patch
    %       patch_size   - the length of a side of the patch
    %
    % patch_size is always odd
    % It is assumed that the patch is within the dimensions of the image
    raw_patch = img(center_x - padding: center_x + padding, ...
                center_y - padding: center_y + padding, ...
                :);
    patch = double(reshape(raw_patch, [patch_size * patch_size * dims, 1]));
end