function nms_img = nms(corner_img)

[rows, cols] = size(corner_img);

% Output image
nms_img = zeros(rows, cols);

for y = 4:rows-3

    for x = 4:cols-3

        % Check corner
        if corner_img(y,x) == 255

            % Keep current corner
            nms_img(y,x) = 255;

            % Suppress nearby corners
            corner_img(y-3:y+3, x-3:x+3) = 0;

        end

    end

end

end