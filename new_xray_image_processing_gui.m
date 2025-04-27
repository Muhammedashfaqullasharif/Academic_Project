function new_xray_image_processing_gui()
    % Create figure and axes
    fig = figure('Name', 'X-ray Image Processing App', 'Position', [100, 100, 1000, 800]);
    ax1 = axes('Parent', fig, 'Position', [0.05, 0.55, 0.4, 0.4]);
    ax2 = axes('Parent', fig, 'Position', [0.55, 0.55, 0.2, 0.2], 'XAxisLocation', 'top', 'YAxisLocation', 'right');
    ax3 = axes('Parent', fig, 'Position', [0.75, 0.55, 0.2, 0.2], 'XAxisLocation', 'top', 'YAxisLocation', 'right');
    ax4 = axes('Parent', fig, 'Position', [0.05, 0.05, 0.4, 0.4]);
    ax5 = axes('Parent', fig, 'Position', [0.55, 0.05, 0.4, 0.4]);
    
    % Create buttons for each processing step
    btn_import = uicontrol('Style', 'pushbutton', 'String', 'Import X-ray Image', ...
                            'Position', [20, 50, 150, 30]);
    btn_guided_filter = uicontrol('Style', 'pushbutton', 'String', 'Apply Guided Filter', ...
                            'Position', [200, 50, 150, 30]);
    btn_canny = uicontrol('Style', 'pushbutton', 'String', 'Apply Canny Edge Detector', ...
                            'Position', [380, 50, 150, 30]);
    btn_rotate = uicontrol('Style', 'pushbutton', 'String', 'Rotate Image', ...
                            'Position', [560, 50, 150, 30]);
    btn_angle_change = uicontrol('Style', 'pushbutton', 'String', 'Change Angle', ...
                            'Position', [740, 50, 150, 30]);
    btn_peak_detection = uicontrol('Style', 'pushbutton', 'String', 'Peak Detection', ...
                            'Position', [920, 50, 150, 30]);
    btn_plot_histogram = uicontrol('Style', 'pushbutton', 'String', 'Plot Histogram', ...
                            'Position', [1100, 50, 150, 30]);
    btn_plot_3d = uicontrol('Style', 'pushbutton', 'String', 'Plot 3D Peaks', ...
                            'Position', [1280, 50, 150, 30]);
    
    % Set callback functions for each button
    set(btn_import, 'Callback', @importImage);
    set(btn_guided_filter, 'Callback', @applyGuidedFilter);
    set(btn_canny, 'Callback', @applyCanny);
    set(btn_rotate, 'Callback', @rotateImage);
    set(btn_angle_change, 'Callback', @changeAngle);
    set(btn_peak_detection, 'Callback', @detectPeaks);
    set(btn_plot_histogram, 'Callback', @plotHistogram);
    set(btn_plot_3d, 'Callback', @plot3DPeaks);
    
    % Initialize variables
    img = [];
    guided_img = [];
    canny_img = [];
    rotated_img = [];
    histogram_data = [];
    peaks_3d = [];
    boundary_img = [];
    green_lines = [];
    angle = 0; % Initialize angle
    
    % Callback function for importing X-ray image
    function importImage(~, ~)
        [filename, pathname] = uigetfile({'*.jpg;*.png;*.bmp', 'Image Files (*.jpg, *.png, *.bmp)'});
        if isequal(filename, 0) || isequal(pathname, 0)
            return;
        else
            img = imread(fullfile(pathname, filename));
            imshow(img, 'Parent', ax1);
            title(ax1, 'Original X-ray Image');
        end
    end

    % Callback function for applying guided filter
    function applyGuidedFilter(~, ~)
        if isempty(img)
            return;
        else
            % Implement guided filter denoising with parameters
            guided_img1 = imguidedfilter(img, 'DegreeOfSmoothing', 0.2, 'NeighborhoodSize', [8 8]);
            guided_img = rgb2gray(guided_img1);
            imshow(guided_img, 'Parent', ax2);
            title(ax2, 'Guided Filter Applied Image');
        end
    end

  % Callback function for applying Canny edge detector
function applyCanny(~, ~)
    if isempty(guided_img)
        return;
    else
        % Apply Canny edge detector with specified parameters
        thresholds = 0.1:0.1:0.8;
        sigmas = 1:0.5:4.5;
        max_probability = -1;
        for sigma = sigmas
            for threshold = thresholds
                edges = edge(guided_img, 'Canny', threshold, sigma);
                probability = mean(edges(:));
                if probability > max_probability
                    max_probability = probability;
                    canny_img = edges;
                end
            end
        end
        
        % Find the local maxima in intensity values
        smoothed_img = medfilt2(guided_img, [1 5]);
        peaks = imregionalmax(smoothed_img);
        
        % Consider only peaks above a certain threshold
        threshold = 2/3 * max(smoothed_img(:));
        peaks(smoothed_img < threshold) = 0;
        
        % Use the peaks as a guide to select the edges
        canny_img = canny_img & peaks;
        
        % Plot output image
        imshow(canny_img, 'Parent', ax3);
        title(ax3, 'Canny Edge Detection Output (Bone Boundaries Only)');
    end
end


    % Callback function for rotating image
    function rotateImage(~, ~)
        if isempty(canny_img)
            return;
        else
            % Rotate the image based on edge direction
            [Gmag, Gdir] = imgradient(canny_img, 'sobel');
            [~, sorted_idx] = sort(Gmag(:), 'descend');
            num_pixels = round(0.2 * numel(sorted_idx));
            top_pixels_idx = sorted_idx(1:num_pixels);
            selected_Gdir = Gdir(top_pixels_idx);
            angle = mode(selected_Gdir(:)); % Angle corresponds to direction of prominent edges
            rotated_img = imrotate(canny_img, -angle, 'crop');
            imshow(rotated_img, 'Parent', ax4);
            title(ax4, 'Rotated Image');
        end
    end

    % Callback function for changing angle
    function changeAngle(~, ~)
        if isempty(rotated_img)
            return;
        else
            % Change the angle of the image
            angle = angle + 10; % Increase angle by 10 degrees
            rotated_img = imrotate(rotated_img, angle, 'crop');
            imshow(rotated_img, 'Parent', ax4);
            title(ax4, 'Rotated Image');
        end
    end

    % Callback function for detecting intensity peaks
    function detectPeaks(~, ~)
        if isempty(rotated_img)
            return;
        else
            % Search for intensity peaks
            % Apply median filter
            smoothed_img = medfilt2(rotated_img, [1 5]);
            % Find local maxima in intensity values
            peaks_3d = zeros(size(rotated_img));
            for i = 1:size(rotated_img, 1)
                row_intensity = smoothed_img(i, :);
                max_intensity = max(row_intensity);
                threshold = 2/3 * max_intensity;
                peaks_indices = find(row_intensity > threshold);
                peaks_3d(i, peaks_indices) = row_intensity(peaks_indices);
            end
            % Plot 3D peaks
            surf(ax5, peaks_3d);
            xlabel(ax5, 'Column');
            ylabel(ax5, 'Row');
            zlabel(ax5, 'Intensity');
            title(ax5, 'Intensity Peaks');
        end
    end

    % Callback function for plotting the histogram
    function plotHistogram(~, ~)
        if isempty(rotated_img)
            return;
        else
            % Plot histogram of gradient directions
            [Gmag, ~] = imgradient(rotated_img, 'sobel');
            histogram_data = Gmag(:);
            figure;
            histogram(ax6, histogram_data, 'BinWidth', 1);
            xlabel(ax6, 'Gradient Magnitude');
            ylabel(ax6, 'Frequency');
            title(ax6, 'Histogram of Gradient Magnitudes');
        end
    end

    % Callback function for plotting 3D peaks
    function plot3DPeaks(~, ~)
        if isempty(peaks_3d)
            return;
        else
            % Plot 3D peaks
            surf(ax5, peaks_3d);
            xlabel(ax5, 'Column');
            ylabel(ax5, 'Row');
            zlabel(ax5, 'Intensity');
            title(ax5, '3D Intensity Peaks');
        end
    end
end
