function filtered = edge_rejection(gray, corner_img)

%Optimum Harris Factor

 harris_factor=0.006;

[rows, cols] = size(gray);

filtered = zeros(rows, cols);

% Store Harris responses
Rmap = zeros(rows, cols);

% Sobel gradients
Ix = [-1 0 1;
     -2 0 2;
     -1 0 1];

Iy = [-1 -2 -1;
      0  0  0;
      1  2  1];

Gx = conv2(double(gray), Ix, 'same');
Gy = conv2(double(gray), Iy, 'same');

window = 1;

%% PASS 1
% Compute Harris responses

for y = 2:rows-1

    for x = 2:cols-1

        if corner_img(y,x) > 0

            gx = Gx(y-window:y+window, ...
                    x-window:x+window);

            gy = Gy(y-window:y+window, ...
                    x-window:x+window);

            A = sum(gx(:).^2);

            B = sum(gx(:).*gy(:));

            C = sum(gy(:).^2);

            detM = A*C - B^2;

            traceM = A + C;

            R = detM - 0.04*(traceM^2);

            % Store response
            Rmap(y,x) = R;

        end

    end

end

%% Adaptive threshold

Rmax = max(Rmap(:));

threshold = harris_factor * Rmax;


%% PASS 2
% Keep strong corners

for y = 1:rows

    for x = 1:cols

        if Rmap(y,x) > threshold

            filtered(y,x) = 255;

        end

    end

end

end