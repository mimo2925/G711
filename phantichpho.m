
% --- 1. Khai báo tên file và đọc file âm thanh ---
audioFilename = 'original_audio_8khz.wav'; % !!! THAY ĐỔI TÊN FILE NÀY !!! Đảm bảo tên file chính xác và có trong thư mục làm việc!
try
    % Đọc dữ liệu âm thanh (y) và tần số lấy mẫu (Fs)
    [y, Fs] = audioread(audioFilename);
    % Hiển thị thông tin cơ bản
    fprintf('Đã đọc thành công file: %s\n', audioFilename);
    fprintf('- Tần số lấy mẫu (Fs): %d Hz\n', Fs);
    fprintf('- Số lượng mẫu (chiều dài tín hiệu): %d\n', length(y));
    fprintf('- Số kênh: %d\n', size(y, 2));

    % Kiểm tra Fs (G.711 chuẩn là 8000 Hz)
    if Fs ~= 8000
        fprintf('*** Cảnh báo: Tần số lấy mẫu không phải 8000 Hz. G.711 có thể không hoạt động đúng chuẩn.\n');
        fprintf('*** Bạn có thể cần resample lại tín hiệu về 8000 Hz trước khi thực hiện Bước 3 (G.711).\n');
    end

catch ME % Bắt lỗi nếu không đọc được file
    fprintf('!!! Lỗi khi đọc file âm thanh "%s" !!!\n', audioFilename);
    fprintf('Lý do: %s\n', ME.message);
    fprintf('=> Hãy kiểm tra lại:\n');
    fprintf('   1. Tên file "%s" có đúng không?\n', audioFilename);
    fprintf('   2. File có nằm trong thư mục làm việc hiện tại của Matlab không?\n');
    fprintf('      (Thư mục hiện tại: %s)\n', pwd); % Hiển thị thư mục hiện tại
    fprintf('   3. File có phải là định dạng WAV chuẩn không?\n');
    return; % Dừng script nếu có lỗi đọc file
end

% --- 2. Xử lý tín hiệu Stereo (nếu có) ---
% Phân tích phổ và vẽ dạng sóng thường làm trên tín hiệu đơn kênh (mono).
if size(y, 2) > 1
    disp('Tín hiệu đầu vào là stereo. Đang chuyển thành mono bằng cách lấy kênh trái...');
    y = y(:, 1); % Lấy dữ liệu của kênh đầu tiên (hoặc bạn có thể tính trung bình: y = mean(y, 2);)
end

% --- 2.5. Vẽ dạng sóng (Waveform) của tín hiệu ---
L = length(y);     % Lấy lại số lượng mẫu của tín hiệu (đã là mono)
t = (0:L-1) / Fs;  % Tạo vector thời gian (giây)

figure; % Mở một cửa sổ đồ thị mới cho dạng sóng
plot(t, y);
title(['Dạng Sóng (Waveform) của Tín Hiệu Âm Thanh (' audioFilename ')']); % Thêm tên file vào tiêu đề
xlabel('Thời gian (giây)');
ylabel('Biên độ');
grid on;
xlim([0 t(end)]); % Giới hạn trục x từ 0 đến hết thời gian tín hiệu
disp('--------------------------------------------------------');
disp('Đã vẽ xong biểu đồ dạng sóng.');
disp('--------------------------------------------------------');

% --- 3. Tính toán Biến đổi Fourier Nhanh (FFT) cho phổ tổng thể ---
% L = length(y); % Đã tính ở trên
Y = fft(y);        % Tính FFT, kết quả Y là một vector các số phức

% --- 4. Tính Phổ Biên Độ Một Phía (Single-Sided Amplitude Spectrum) ---
P2 = abs(Y / L);     % Tính biên độ (lấy mô-đun của số phức) và chuẩn hóa bằng cách chia cho L.
P1 = P2(1:floor(L/2) + 1); % Lấy nửa đầu tiên của phổ (từ tần số 0 đến Fs/2).
P1(2:end-1) = 2 * P1(2:end-1); % Nhân đôi biên độ các thành phần bên trong để bảo toàn năng lượng.

% --- 5. Tạo Vector Tần số (trục x cho đồ thị phổ) ---
f = Fs * (0:(L/2)) / L;

% --- 6. Vẽ Đồ thị Phổ Biên Độ Tổng Thể ---
figure;                 % Mở một cửa sổ đồ thị (Figure) mới cho phổ
plot(f, P1);            % Vẽ đồ thị với trục x là tần số (f), trục y là biên độ (P1)
title(['Phổ Biên Độ Tín Hiệu Âm Thanh (' audioFilename ')']); % Thêm tên file vào tiêu đề
xlabel('Tần số (Hz)');           % Nhãn trục x
ylabel('Biên độ |P1(f)|');      % Nhãn trục y
grid on;                        % Hiển thị lưới để dễ đọc giá trị
xlim([0 Fs/2]);                 % Giới hạn trục x đến tần số Nyquist (Fs/2)
disp('--------------------------------------------------------');
disp('Đã vẽ xong biểu đồ phổ biên độ tổng thể.');
disp('--------------------------------------------------------');

% --- 6.5. Tính toán và Vẽ Spectrogram ---
% Spectrogram cho thấy sự thay đổi của phổ theo thời gian.
% --- Các tham số cho spectrogram ---
window_len_ms = 30; % Độ dài cửa sổ phân tích (ms) - Thường từ 20-30ms cho tiếng nói
window_len_samples = round(Fs * window_len_ms / 1000); % Đổi sang số mẫu
window = hamming(window_len_samples); % Chọn cửa sổ Hamming (phổ biến)

noverlap_percent = 50; % Phần trăm chồng lấp giữa các cửa sổ - Thường là 50%
noverlap_samples = floor(window_len_samples * noverlap_percent / 100); % Số mẫu chồng lấp

nfft = window_len_samples; % Số điểm FFT, thường bằng độ dài cửa sổ hoặc lũy thừa gần nhất của 2

% --- Vẽ spectrogram ---
figure; % Mở cửa sổ đồ thị mới cho spectrogram
spectrogram(y, window, noverlap_samples, nfft, Fs, 'yaxis');
% 'yaxis' đảm bảo trục tần số nằm ở trục y (thông thường)
title(['Spectrogram của Tín Hiệu Âm Thanh (' audioFilename ')']);
xlabel('Thời gian (giây)'); % Trục x đã là thời gian do hàm spectrogram tạo ra
ylabel('Tần số (Hz)');   % Trục y là tần số
colorbar; % Hiển thị thanh màu thể hiện mức năng lượng (dB)

