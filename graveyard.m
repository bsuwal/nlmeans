%% This file is where I keep my dead ideas

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

% patches = load(strcat(num2str(patch_size), '_patch_size.mat'));
% patches = double(patches.patches);

function dist = get_dist(main_patch, compare_patch, arr_len)  %#codegen
    % Executing in generated code, call C function foo
    coder.updateBuildInfo('addSourceFiles','get_dist.c');
    coder.cinclude('get_dist.h');
%     dist = coder.ceval('euclidean_dist', main_patch, compare_patch, arr_len);
end

%% make patch matrix
patches_mat = zeros(width - 2 * patch_padding, height - 2 * patch_padding, patch_size * patch_size * dims);

for j = patch_padding + 1: height - patch_padding
    for i = patch_padding + 1: width - patch_padding
        patches_mat(i, j, :) = get_patch(img, i, j, patch_padding, patch_size, dims);
    end
end