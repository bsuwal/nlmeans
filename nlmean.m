%% Preprocessing
% img = importdata('Indian_pines.mat');
% modified_img = importdata('Indian_pines.mat');

img = imread('lena.png');
img = imnoise(img,'gaussian');
modified_img = imread('lena.png');
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

%% Building the weight matrix
fprintf('Building weight matrix ...\n');

dists = zeros(num_patches, window_size);
h = 8;
row = 0;

tic
profile on

for i = patch_padding + 1: width - patch_padding
    for j = patch_padding + 1: height - patch_padding
        % get the main patch
        main_center = [i,j];
        main_patch = get_patch(img, main_center, patch_size);
        
        row = row + 1;
        col = 0;
        % compare other patches with patch
        for k = i - search_padding: i + search_padding
            for l = j - search_padding: j + search_padding
                % get the compare patch
                 col = col + 1;
                 
                 % boundary checks for search window
                 if k < patch_padding + 1 ...             % left bound
                     || l < patch_padding + 1 ...         % up bound
                     || k > width - patch_padding ...     % right bound
                     || l > height - patch_padding        % down bound
                     continue % ignore out of bounds patches
                 end
             
                 compare_center = [k,l];
                 compare_patch = get_patch(img, compare_center, patch_size);
                
                % get the distance between patches
                 dist = get_distance(main_patch, compare_patch);                   
                % populate the weights
                 dists(row, col) = exp(-dist./(h^2));       
            end
        end 
    end
end

% normalize the weights
dist_sums = sum(dists,2);
D = spdiags(dist_sums(:),0,length(dist_sums),length(dist_sums));
weights = inv(D)*dists;

fprintf('Finished building weight matrix\n');
profile viewer
toc
%% Modifying the pixels based on the weights

fprintf('Modifying pixels based on the weights...\n');

pixel_count = 0;
for i = patch_padding + 1: width - patch_padding
    for j = patch_padding + 1: height - patch_padding
        % get the search_window around a pixel
        center = [i,j];
        window = get_search_window(img, center, window_size);
        
        pixel_count = pixel_count + 1;
        % get the weight of the patch around the pixel
        modified_img(i,j,:) = get_weighted_pixel(window, weights(pixel_count,:), ...
            window_size, dims);
    end
end

fprintf('Finished modifying pixels.\n');
imshow(modified_img);
imwrite(modified_img, 'modified_lena_noised.png')


%%
function window = get_search_window(img, center_pixel, window_size)
    padding = floor(window_size/2);
    [width, height, dims] = size(img);
    center_x = center_pixel(1);
    center_y = center_pixel(2);
    
    window = zeros(window_size * window_size, dims);
    pixel_count = 0;
    % compare other patches with patch
    for k = center_x - padding: center_x + padding
        for l = center_y - padding: center_y + padding
            
            pixel_count = pixel_count + 1;
            % boundary checks for search window
            if  k < 1 ...             % left bound
                || l <  1 ...         % up bound
                || k > width  ...     % right bound
                || l > height         % down bound
                continue % ignore out of bounds patches
            end

            window(pixel_count, :) = img(k,l, :);
        end
    end
    
end

function pixel = get_weighted_pixel(window, weights_vec, window_size, dims)
    pixel = weights_vec * reshape(window, [window_size * window_size, dims]) ;
end

function patch = get_patch(img, center_pixel, patch_size)
    % Returns a patch from the image
    % Args: img          - the image
    %       center_pixel - the pixel in the center of the patch
    %       patch_size   - the length of a side of the patch
    %
    % patch_size is always odd
    % It is assumed that the patch is withing the dimensions of the image
    
    center_x = center_pixel(1);
    center_y = center_pixel(2);
    padding = (patch_size-1)/2; 

    patch = img(center_x - padding: center_x + padding, ...
                center_y - padding: center_y + padding, ...
                :);
end

function dist = get_distance(uint_patch1, uint_patch2)
    % Returns the euclidean distance between two patches 
    [~, patch_size, dims] = size(uint_patch1);
    % the patches are of dtype uint8, we need to convert them to int8 so 
    % x - y != 0 when x < y
    int_patch1 = int16(reshape(uint_patch1, [patch_size * patch_size * dims, 1]));
    int_patch2 = int16(reshape(uint_patch2, [patch_size * patch_size * dims, 1]));
    % get the euclidean distance between the patches
    squared = ((int_patch1 - int_patch2).^2);              
    dist = sqrt(sum(squared(:)));        
end





