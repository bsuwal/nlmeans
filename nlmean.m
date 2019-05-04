%% Developer-defined variables
filename = 'lena.png';
patch_size = 7;         % must always be odd numbered
window_size = 9;        % search window, must always be odd numbered
h = 8; 

%% Preprocessing
% img = importdata('Indian_pines.mat');
img = imread(filename);
img = imnoise(img,'gaussian', 0, 0.05);

% make the patches and display them first
[height, width, dims] = size(img);

% padding is the distance (in num pixels) from the center pixel to the 
% boundary of the patch
patch_padding = floor(patch_size/2);
search_padding = floor(window_size/2);

% this is only the number of patches within the search window
num_patches = (height - 2 * patch_padding) * (width - 2 * patch_padding);
fprintf('Number of patches %i\n', num_patches);

%% Building the weight matrix
fprintf('Building weight matrix ...\n');

weights = zeros(num_patches, window_size);
row = 0;  
for j = patch_padding + 1: height - patch_padding
    for i = patch_padding + 1: width - patch_padding
        % get the main patch
        main_patch = get_patch(img, i, j, patch_padding, patch_size, dims);
        
        row = row + 1;
        col = 0;
        % compare other patches with patch
        for l = j - search_padding:j + search_padding
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

%% Modifying the pixels based on the weights
fprintf('Modifying pixels based on the weights...\n');
pixel_count = 0;
for j = patch_padding + 1: height - patch_padding
    for i = patch_padding + 1: width - patch_padding
        % get the search_window around a pixel
        window = get_search_window(img, i, j, window_size, patch_size);
        
        pixel_count = pixel_count + 1;
        % get the weight of the patch around the pixel
        img(i,j,:) = get_weighted_pixel(window, weights_scaled(pixel_count,:), ...
            window_size, dims);
    end
end

fprintf('Finished modifying pixels.\n');
imshow(img);
imwrite(img, 'modified_lena.png')

%% Helper functions

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

function window = get_search_window(img, center_x, center_y, window_size, patch_size)
    % the only valid pixels within the search window are the ones
    % that are the center of patches.
    [width, height, dims] = size(img);
    patch_padding = floor(patch_size/2);
    search_padding = floor(window_size/2);

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
