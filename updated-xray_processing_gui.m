function xray_processing_gui()
    % Create figure and axes
    fig = figure('Name', 'X-ray Image Processing App', 'Position', [100, 100, 1000, 800]);
    ax1 = axes('Parent', fig, 'Position', [0.05, 0.55, 0.4, 0.4]);
    ax2 = axes('Parent', fig, 'Position', [0.55, 0.55, 0.2, 0.2], 'XAxisLocation', 'top', 'YAxisLocation', 'right');
    ax3 = axes('Parent', fig, 'Position', [0.75, 0.55, 0.2, 0.2], 'XAxisLocation', 'top', 'YAxisLocation', 'right');
    ax4 = axes('Parent', fig, 'Position', [0.05, 0.05, 0.9, 0.4]);

    % Load an example X-ray image
    img = imread('Xray.jpg'); % Provide the path to your example image
    imshow(img, 'Parent', ax1);
    title(ax1, 'Original X-ray Image');
    
    % Initialize variables
    denoised_img = [];
    edged_img = [];
    rotated_img = [];
    peaks_3d = [];
    green_lines = [];
    
    % Create buttons for each processing step
    btn1 = uicontrol('Style', 'pushbutton', 'String', 'Denoise Image', ...
                            'Position', [250, 460, 120, 30]);
    btn2 = uicontrol('Style', 'pushbutton', 'String', 'Edge Detection', ...
                                    'Position', [430, 460, 120, 30]);
    btn3 = uicontrol('Style', 'pushbutton', 'String', 'Rotate Image', ...
                            'Position', [610, 460, 120, 30]);
    btn4 = uicontrol('Style', 'pushbutton', 'String', 'Intensity Peak Search', ...
                                'Position', [790, 460, 150, 30]);
    btn5 = uicontrol('Style', 'pushbutton', 'String', '3D Visualization', ...
                                'Position', [250, 20, 150, 30]);

    % Callback functions for each button
    set(btn1, 'Callback', @denoiseImage);
    set(btn2, 'Callback', @edgeDetection);
    set(btn3, 'Callback', @rotateImage);
    set(btn4, 'Callback', @peakSearch);
    set(btn5, 'Callback', @visualization);

    % Callback functions for each button
    function denoiseImage(~,~)
        % Denoise the image using guided filter
        % Implement guided filter denoising with given parameters
        denoised_img = imguidedfilter(img, 'DegreeOfSmoothing', 0.2, 'NeighborhoodSize', [8 8]);
        
        % Update displayed image
        cla(ax2);
        axes(ax2);
        imshow(denoised_img);
        title(ax2, 'Denoised Image');
        axis(ax2, 'equal');
    end

   function edgeDetection(~, ~)
        % Initialize variables
        max_probability = -1;
        optimal_edges = [];
        
        % Loop through different standard deviations
        for sigma = 1:0.5:4.5
            % Loop through different thresholds
            for threshold = 0.1:0.1:0.8
                % Edge detection using Canny algorithm
                edges = edge(denoised_img, 'Canny', threshold, sigma);
                
                % Compute probability for edges
                probability = mean(edges(:)); % Assuming edges are binary
                
                % Update maximum probability and optimal edges
                if probability > max_probability
                    max_probability = probability;
                    optimal_edges = edges;
                end
            end
        end
        
        % Update displayed image with optimal edges
        cla(ax3);
        axes(ax3);
        imshow(optimal_edges);
        title(ax3, 'Edge Detected Image');
        axis(ax3, 'equal');
        
        % Draw green lines over detected edges
        green_lines = drawEdges(optimal_edges);
    end

   function rotateImage(~, ~)
        % Rotate the image to align prominent edges vertically
        % Rotate the image by 90 degrees
        rotated_img = imrotate(denoised_img, 90);
        
        % Perform Sobel operator on the result of Canny edge detector
        [Gmag, Gdir] = imgradient(denoised_img, 'sobel');
        
        % Calculate gradient magnitudes and sort them
        [sorted_Gmag, idx] = sort(Gmag(:), 'descend');
        
        % Select the upper 20 percent of gradient magnitudes
        num_pixels = round(0.2 * numel(sorted_Gmag));
        top_20_percent_idx = idx(1:num_pixels);
        
        % Extract gradient directions corresponding to the selected pixels
        selected_Gdir = Gdir(top_20_percent_idx);
        
        % Draw histogram of gradient directions
        figure('Name', 'Gradient Directions-HISTOGRAM');
        histogram(selected_Gdir, 180); % 180 bins for angles from -90 to 90 degrees
        xlabel('Gradient Direction');
        ylabel('Frequency');
        title('Histogram of Gradient Directions');
        
        % Update displayed image
        cla(ax2);
        axes(ax2);
        imshow(rotated_img);
        title(ax2, 'Rotated Image');
        axis(ax2, 'equal');
    end

    function green_lines = drawEdges(edges)
        % Draw green lines over detected edges
        [row, col] = find(edges);
        axes(ax3);
        hold on;
        green_lines = plot(ax3, col, row, 'g.');
        hold off;
    end

    function peakSearch(~, ~)
        % Search along each row of the image to find intensity peaks
        
        % Apply median filter with window size of 5
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
        
        % Update displayed image
        surf(ax4, peaks_3d);
        xlabel(ax4, 'Column');
        ylabel(ax4, 'Row');
        zlabel(ax4, 'Intensity');
        title(ax4, 'Search of Intensity Peaks');
    end

    function visualization(~, ~)
        % Visualize intensity peaks in 3D
        if ~isempty(peaks_3d)
            figure;
            surf(peaks_3d);
            xlabel('Column');
            ylabel('Row');
            zlabel('Intensity');
            title('3D Visualization of Intensity Peaks');
        else
            disp('Please perform intensity peak search first.');
        end
    end
end
