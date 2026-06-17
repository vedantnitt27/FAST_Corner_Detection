function corner_img = fast_algorithm(gray)
% function corner_img = fast_algorithm(gray,fast_factor)

[rows, cols] = size(gray);

%Optimum Fast factor
 fast_factor=0.150;

% Output image
corner_img = zeros(rows, cols);

% Number of contiguous pixels required
N = 9;

% FAST circle coordinates
circle = [
     0 -3;
     1 -3;
     2 -2;
     3 -1;
     3  0;
     3  1;
     2  2;
     1  3;
     0  3;
    -1  3;
    -2  2;
    -3  1;
    -3  0;
    -3 -1;
    -2 -2;
    -1 -3
];

% Ignore image boundary
for y = 4:rows-3

    for x = 4:cols-3

        % Center pixel
        Ip = double(gray(y,x));

        %% Adaptive Threshold

        % Local 7x7 window
        local_window = double(gray(y-3:y+3, x-3:x+3));

        % Local standard deviation
        local_std = std(local_window(:));

        % Adaptive threshold
        t = fast_factor* local_std;

      
        if t < 7
            t =7;
        end

        %% FAST states

        states = strings(1,16);

        % Check all circle pixels
        for k = 1:16

            xk = x + circle(k,1);
            yk = y + circle(k,2);

            Ik = double(gray(yk,xk));

            % Bright pixel
            if Ik >= Ip + t

                states(k) = "B";

            % Dark pixel
            elseif Ik <= Ip - t

                states(k) = "D";

            % Similar pixel
            else

                states(k) = "S";

            end

        end

        %% Circular wraparound

        states_extended = [states states];

        max_bright = 0;
        max_dark = 0;

        bright_count = 0;
        dark_count = 0;

        %% Check contiguous sequence

        for k = 1:32

            % Bright sequence
            if states_extended(k) == "B"

                bright_count = bright_count + 1;

                if bright_count > max_bright
                    max_bright = bright_count;
                end

            else

                bright_count = 0;

            end

            % Dark sequence
            if states_extended(k) == "D"

                dark_count = dark_count + 1;

                if dark_count > max_dark
                    max_dark = dark_count;
                end

            else

                dark_count = 0;

            end

        end

        %% FAST corner condition

        if max_bright >= N || max_dark >= N

         
            corner_img(y,x) = 255;

        end

    end

end

end