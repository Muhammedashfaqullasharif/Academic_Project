
% Define a function to create the GUI
function image_processing_gui()
    % Create figure and axes
    scrsz = get(groot,"ScreenSize");
    fig = figure('Name', 'Image Processing GUI','Position', scrsz,'Color',[.2,.4,.8] );
    ax = axes('Parent', fig, 'Position', [0.1, 0.2, 0.6, 0.7]);

    % Load an example image
    img = imread("Xray.jpg");% Provide the path to your example image
   
    imshow(img, 'Parent', ax);
    
    % Create buttons for each processing step
      uicontrol('Style', 'pushbutton', 'String', 'Denoise Image', ...
                             'Position', [20, 20, 120, 30], 'Callback', @denoiseImage);
      uicontrol('Style', 'pushbutton', 'String', 'Edge Detection', ...
                                    'Position', [160, 20, 120, 30], 'Callback', @edgeDetection);
      uicontrol('Style', 'pushbutton', 'String', 'Rotate Image', ...
                            'Position', [300, 20, 120, 30], 'Callback', @rotateImage);
      uicontrol('Style', 'pushbutton', 'String', 'Intensity Peak Search', ...
                                'Position', [440, 20, 150, 30], 'Callback', @peakSearch);
      uicontrol('Style', 'pushbutton', 'String', 'Local Maxima Extraction', ...
                                'Position', [600, 20, 180, 30], 'Callback', @localMaximaExtraction);

    % Callback functions for each button
    function denoiseImage(~,~)
        % Denoise the image using guided filter;
        
        % Example: Perform guided filter denoising with given parameters
       denoised_img = imguidedfilter(img, 'DegreeOfSmoothing', 0.2, 'NeighborhoodSize', [8 8]);
        
        % Update displayed image
        imshow(denoised_img, 'Parent', ax);
        title("Denoised Image");
    end

    function edgeDetection(~,~)
        % Edge detection using multi-scale Canny edge detector
        
        % Example: Perform multi-scale Canny edge detection with given parameters
        edged_img = edge(img, 'Canny', [0.1 0.8], 1:0.5:4.5);
        
        % Update displayed image
        imshow(edged_img, 'Parent', ax);
        title("EdgeDetected Image");
    end

    function rotateImage(~,~)
        % Rotate the image to align prominent edges vertically
        
        % Example: Rotate the image by 90 degrees
        rotated_img = imrotate(img, 90);
        
        % Update displayed image
        imshow(rotated_img, 'Parent', ax);
        title("rotated image");
    end

    function peakSearch(~,~)
        % Search along each row of the image to find intensity peaks
        
        % Example: Search for local maxima in intensity
        % You need to implement your own peak search algorithm
        
        % Update displayed image
        imshow(img, 'Parent', ax);
        title("intensity peaks");
    end

    function localMaximaExtraction(~,~)
        % Identify local maxima in intensity to extract boundaries
        
        % Example: Implement local maxima extraction method
        
        % Update displayed image
        imshow(img, 'Parent', ax);
        title("local maxima extraction");
    end
end

% Call the function to create the GUI
%image_processing_gui();
