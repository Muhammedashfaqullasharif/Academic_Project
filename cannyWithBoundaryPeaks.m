function cannyWithBoundaryPeaks()
    % Create figure and axes
    fig = figure('Name', 'X-ray Edge Detection', 'Position', [100, 100, 800, 600]);
    ax = axes('Parent', fig, 'Position', [0.05, 0.1, 0.9, 0.8]);
    
    % Initialize variables
    img = [];
    filtered_img = [];
    edges_img = [];
    rotated_img = [];
    peaks_3d = [];
    
    % Import Image button
    btn_import = uicontrol('Style', 'pushbutton', 'String', 'Import Image', ...
        'Position', [20, 550, 120, 30], 'Callback', @importImage);
    
    % Guided Filter button
    btn_guided_filter = uicontrol('Style', 'pushbutton', 'String', 'Guided Filter', ...
        'Position', [150, 550, 120, 30], 'Callback', @applyGuidedFilter);
    
    % Canny Edge Detection button
    btn_canny = uicontrol('Style', 'pushbutton', 'String', 'Canny Edge Detection', ...
        'Position', [280, 550, 180, 30], 'Callback', @applyCanny);
    
    % Rotate Image button
    btn_rotate = uicontrol('Style', 'pushbutton', 'String', 'Rotate Image', ...
        'Position', [470, 550, 120, 30], 'Callback', @rotateImage);
    
    % Find Intensity Peaks button
    btn_intensity_peaks = uicontrol('Style', 'pushbutton', 'String', 'Intensity Peaks', ...
        'Position', [600, 550, 120, 30], 'Callback', @findIntensityPeaks);
    
    % Draw Boundary Lines button
    btn_draw_lines = uicontrol('Style', 'pushbutton', 'String', 'Draw Boundary Lines', ...
        'Position', [730, 550, 150, 30], 'Callback', @drawBoundaryLines);
    
    % Callback function to import image
    function importImage(~, ~)
        [filename, pathname] = uigetfile({'*.jpg;*.png;*.bmp', 'Image Files'}, 'Select an image');
        if isequal(filename, 0) || isequal(pathname, 0)
            disp('Image selection canceled');
        else
            img = imread(fullfile(pathname, filename));
            imshow(img, 'Parent', ax);
        end
    end

    % Callback function to apply guided filter
    function applyGuidedFilter(~, ~)
        if isempty(img)
            disp('Please import an image first');
            return;
        end
        filtered_img = imguidedfilter(img, 'DegreeOfSmoothing', 0.2, 'NeighborhoodSize', [8 8]);
        figure;
        imshow(filtered_img);
        title('Filtered Image');
    end

    % Callback function to apply Canny edge detection
    function applyCanny(~, ~)
        if isempty(filtered_img)
            disp('Please apply guided filter first');
            return;
        end
        thresholds = 0.1:0.1:0.8;
        sigmas = 1:0.5:4.5;
        max_probability = -1;
        for sigma = sigmas
            for threshold = thresholds
                edges = edge(filtered_img, 'Canny', threshold, sigma);
                probability = mean(edges(:));
                if probability > max_probability
                    max_probability = probability;
                    edges_img = edges;
                end
            end
        end
        level = graythresh(edges_img);
        edges_img = imbinarize(edges_img, level);
        figure;
        imshow(edges_img);
        title('Canny Edge Detected Image');
    end

    % Callback function to rotate image
    function rotateImage(~, ~)
        if isempty(filtered_img)
            disp('Please apply guided filter first');
            return;
        end
        % Rotate the image based on the direction of prominent edges
        % Sobel operator
        [Gmag, Gdir] = imgradient(filtered_img, 'sobel');
        % Sort gradient magnitudes
        [sorted_Gmag, idx] = sort(Gmag(:), 'descend');
        num_pixels = round(0.2 * numel(sorted_Gmag));
        top_20_percent_idx = idx(1:num_pixels);
        selected_Gdir = Gdir(top_20_percent_idx);
        % Rotate the image based on the mode of gradient directions
        rotation_angle = mode(selected_Gdir);
        rotated_img = imrotate(filtered_img, rotation_angle);
        figure;
        imshow(rotated_img);
        title('Rotated Image');
    end

    % Callback function to find intensity peaks
    function findIntensityPeaks(~, ~)
        if isempty(rotated_img)
            disp('Please rotate the image first');
            return;
        end
        % Find local maxima in intensity values
        smoothed_img = medfilt2(rotated_img, [1 5]);
        peaks_3d = zeros(size(rotated_img));
        max_intensity = max(smoothed_img(:));
        threshold = 2/3 * max_intensity;
        for i = 1:size(rotated_img, 1)
            row_intensity = smoothed_img(i, :);
            peaks_indices = find(row_intensity > threshold);
            peaks_3d(i, peaks_indices) = row_intensity(peaks_indices);
        end
        % Plot 3D plot for resulted intensities
        [X, Y] = meshgrid(1:size(rotated_img, 2), 1:size(rotated_img, 1));
        figure;
        surf(X, Y, peaks_3d);
        xlabel('Column');
        ylabel('Row');
        zlabel('Intensity');
        title('3D Plot for Intensity Peaks');
    end

    % Callback function to draw boundary lines
    function drawBoundaryLines(~, ~)
        if isempty(peaks_3d)
            disp('Please find intensity peaks first');
            return;
        end
        % Draw colored lines on the boundaries detected with higher intensities
        [rows, cols] = find(peaks_3d > 0);
        figure;
        imshow(rotated_img);
        hold on;
        for i = 1:numel(rows)
            plot(cols(i), rows(i), 'r.'); % Red dots at boundary points
        end
        title('Boundary Lines');
        hold off;
    end
end
