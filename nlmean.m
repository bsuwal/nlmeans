%% Preprocessing
img = importdata('Indian_pines.mat');
% modified_img = importdata('Indian_pines.mat');
% loadlibrary('get_dist.dll','get_dist.h')
% img = imread('lena.png');
% img = imnoise(img,'gaussian', 0, 0.05);
% imwrite(img, 'lena_noised.png')
% crop the img to have a reasonable weight matrix

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

fprintf('Number of patches %i\n', num_patches);

%% Build the patches matrix
patches = zeros(width - 2 * patch_padding, height - 2 * patch_padding, patch_size * patch_size * dims);

for j = patch_padding + 1: height - patch_padding
    for i = patch_padding + 1: width - patch_padding
        raw_patch = get_patch(img, i, j, patch_padding, patch_size);
        patch = double(reshape(raw_patch, [patch_size * patch_size * dims, 1]));
        patches(i, j, :) = patch;
    end
end
%% Building the weight matrix
fprintf('Building weight matrix ...\n');

weights = zeros(num_patches, window_size);
h = 3;
row = 0;

tic
profile on

for j = patch_padding + 1: height - patch_padding
    for i = patch_padding + 1: width - patch_padding
        % get the main patch
        row = row + 1;
        main_patch = get_patch(img, i, j, patch_padding, patch_size, dims);
        
        col = 0;
        % compare other patches with patch
        for l = j - search_padding: j + search_padding
            for k = i - search_padding: i + search_padding
                % get the compare patch
                 col = col + 1; 
                 % boundary checks for search window
                 if k < patch_padding + 1 ...             % left bound
                     || l < patch_padding + 1 ...         % up bound
                     || k > width - patch_padding ...     % right bound
                     || l > height - patch_padding        % down bound
                     continue   % ignore out of bounds patches
                 end
 
                compare_patch = get_patch(img, k, l, patch_padding, patch_size, dims);
                
                % get the distance between patches
                dist = get_distance(main_patch, compare_patch); 
                weights(row, col) = exp(-dist./(h^2));       
            end            
        end 
    end
end

% normalize the weights
weight_sums = sum(weights,2);
D = spdiags(weight_sums(:),0,length(weight_sums),length(weight_sums));
weights_scaled = inv(D)*weights;

fprintf('Finished building weight matrix\n');
profile viewer
toc

%% Modifying the pixels based on the weights
fprintf('Modifying pixels based on the weights...\n');
pixel_count = 0;
for j = patch_padding + 1: height - patch_padding
    for i = patch_padding + 1: width - patch_padding
        % get the search_window around a pixel
        window = get_search_window(img, i, j, window_size, patch_padding, search_padding, dims);
        
        pixel_count = pixel_count + 1;
        % get the weight of the patch around the pixel
        img(i,j,:) = get_weighted_pixel(window, weights_scaled(pixel_count,:), ...
            window_size, dims);
    end
end

fprintf('Finished modifying pixels.\n');
imshow(img);
imwrite(img, 'modified_lena.png')


%%
function pixel = get_weighted_pixel(window, weights_vec, window_size, dims)
    pixel = weights_vec * reshape(window, [window_size * window_size, dims]);
end

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

function dist = get_distance(main_patch, compare_patch)
    % Returns the euclidean distance between two patches 
    squared = ((main_patch - compare_patch).^2);              
    dist = sqrt(sum(squared(:)));        
end

function window = get_search_window(img, center_x, center_y, window_size, patch_padding, search_padding, dims)
    % the only valid pixels within the search window are the ones
    % that are the center of patches.
    [width, height, dims] = size(img);
    window = zeros(window_size * window_size, dims);
    pixel_count = 0;
    % compare other patches with patch
    for k = center_x - search_padding: center_x + search_padding
        for l = center_y - search_padding: center_y + search_padding
            pixel_count = pixel_count + 1;
            % boundary checks for search window
            if k < patch_padding + 1 ...             % left bound
                || l < patch_padding + 1 ...         % up bound
                || k > width - patch_padding ...     % right bound
                || l > height - patch_padding        % down bound
                continue % ignore out of bounds patches
            end      
            window(pixel_count, :) = img(k,l, :);
        end
    end
end
