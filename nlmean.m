%% Preprocessing
% img = importdata('Indian_pines.mat');
% modified_img = importdata('Indian_pines.mat');
% loadlibrary('get_dist.dll','get_dist.h')
img = imread('lena.png');
img = imnoise(img,'gaussian');
modified_img = imread('lena.png');
% crop the img to have a reasonable weight matrix

% make the patches and display them first
patch_size = 1; % must always be odd numbered
[height, width, dims] = size(img);

% search window
window_size = 3; 

% padding is the distance (in num pixels) from the center pixel to the 
% boundary of the patch
patch_padding = floor(patch_size/2);
search_padding = floor(window_size/2);

% this is only the number of patches within the search window
num_patches = (height - 2 * patch_padding) * (width - 2 * patch_padding);
patches = load(strcat(num2str(patch_size), '_patch_size.mat'));
patches = double(patches.patches);

fprintf('Number of patches %i\n', num_patches);

%% Building the weight matrix
fprintf('Building weight matrix ...\n');

dists = Inf(num_patches, window_size);
h = 1;
row = 0;

tic
profile on

for j = patch_padding + 1: height - patch_padding
    for i = patch_padding + 1: width - patch_padding
        % get the main patch
%         main_center = [i,j];
        row = row + 1;
        main_patch = patches(row, :);
       
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
                     continue % ignore out of bounds patches
                 end
 
                 compare_patch = get_patch(img, k, l, patch_padding, patch_size);
                
                % get the distance between patches
                dist = get_distance(main_patch, compare_patch, patch_size, dims); 
%                  dist = get_dist(main_patch, int_compare_patch, patch_size^2);
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
function pixel = get_weighted_pixel(window, weights_vec, window_size, dims)
    pixel = weights_vec * reshape(window, [window_size * window_size, dims]) ;
end

function patch = get_patch(img, center_x, center_y, padding, patch_size)
    % Returns a patch from the image
    % Args: img          - the image
    %       center_pixel - the pixel in the center of the patch
    %       patch_size   - the length of a side of the patch
    %
    % patch_size is always odd
    % It is assumed that the patch is withing the dimensions of the image

    patch = img(center_x - padding: center_x + padding, ...
                center_y - padding: center_y + padding, ...
                :);
end

function dist = get_distance(main_patch, uint_patch2, patch_size, dims)
    % Returns the euclidean distance between two patches 
    int_patch2 = double(reshape(uint_patch2, [patch_size * patch_size * dims, 1]));
    
    % dist = pdist2(main_patch, int_patch2');
    squared = ((main_patch - int_patch2).^2);              
    dist = sqrt(sum(squared(:)));        
end
