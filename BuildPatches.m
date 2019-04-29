%% Preprocessing
% img = importdata('Indian_pines.mat');
% modified_img = importdata('Indian_pines.mat');

img = imread('lena.png');

% make the patches and display them first
patch_size = 7; % must always be odd numbered
[height, width, dims] = size(img);

% search window
window_size = 21; 

% padding is the distance (in num pixels) from the center pixel to the 
% boundary of the patch
patch_padding = floor(patch_size/2);
search_padding = floor(window_size/2);

% this is only the number of patches within the search window
num_patches = (height - 2 * patch_padding) * (width - 2 * patch_padding);

% number of search patches in the search window
num_search_patches = (window_size - 2 * patch_padding) * (window_size - 2 * patch_padding);

fprintf('Number of patches %i\n', num_patches);

%%
patches = zeros(num_patches, patch_size * patch_size * dims);
search_patches = zeros(num_patches * num_search_patches, patch_size * patch_size * dims);
patch_iter = 1;
search_iter = 1;

% loop over each column first, then move on to next row
for j = patch_padding + 1: height - patch_padding
    for i = patch_padding + 1: width - patch_padding
        patch = get_patch(img, i, j, patch_padding, patch_size, dims);
        patches(patch_iter, :) = patch;
        patch_iter = patch_iter + 1;
        
        % compare other patches with patch
        for k = i - search_padding: i + search_padding
            for l = j - search_padding: j + search_padding
                 % boundary checks for search window
                 if k < patch_padding + 1 ...             % left bound
                     || l < patch_padding + 1 ...         % up bound
                     || k > width - patch_padding ...     % right bound
                     || l > height - patch_padding        % down bound
                     continue % ignore out of bounds patches
                 end
                 compare_patch = get_patch(img, k, l, patch_padding, patch_size, dims);
                 search_patches(search_iter, :) = compare_patch;
                 search_iter = search_iter + 1;
            end
        end 
    end
end

% save the file
save(strcat(num2str(patch_size), '_patch_size.mat'),'patches');
save(strcat(num2str(patch_size), '_patch_', num2str(window_size), 'size.mat'),'search_patches');

%%
function patch = get_patch(img, center_x, center_y, padding, patch_size, dims)
    % Returns a patch from the image
    % Args: img          - the image
    %       center_x     - x coord of center pixel
    %       center_y     - y coord of center pixel
    %       padding      - padding is on either side
    %
    % It is assumed that the patch is withing the dimensions of the image
    raw_patch = img(center_x - padding: center_x + padding, ...
                center_y - padding: center_y + padding, ...
                :);
    
    % convert to int16 because we have to do subtraction with these patches
    % that can take us to below 0
    % also int16 because int8 has a max value of 127 and our pixel values
    % are upto 255
    patch = int16(reshape(raw_patch, [patch_size * patch_size * dims, 1]));
end