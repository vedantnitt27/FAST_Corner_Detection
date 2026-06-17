function gray = grayscale_conversion(img)

% Check if image is RGB
if size(img,3) == 3

    % Extract RGB channels
    R = double(img(:,:,1));
    G = double(img(:,:,2));
    B = double(img(:,:,3));

    % Manual grayscale conversion
    gray = uint8(0.299*R + 0.587*G + 0.114*B);

else

    % Image already grayscale
    gray = img;

end

end