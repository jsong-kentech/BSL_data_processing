% 파일 경로 가져오기
clc; clear; close all;

data_folder = 'G:\공유 드라이브\Battery Software Lab\Processed_data\Hyundai_dataset\DCIR(1,2)\HNE_(5)_FC_DCIR';
save_path = data_folder;
I_1C = 0.00382; %[A]
id_cfa = 2; % 1 for cathode, 2 for fullcell , 3 for anode 

% MAT 파일 가져오기
slash = filesep;
files = dir([data_folder slash '*.mat']);

% 선택할 파일의 인덱스
selected_file_index = 1; % 첫 번째 파일 선택

% 선택한 파일 load
fullpath_now = [data_folder slash files(selected_file_index).name];
load(fullpath_now);
data(1) = [];

% 충전, 방전 스텝(필드) 구하기 

step_chg = [];
step_dis = [];

for i = 1:length(data)
    % type 필드가 C인지 확인
    if strcmp(data(i).type, 'C')
        % C가 맞으면 idx 1 추가
        step_chg(end+1) = i;
    % type 필드가 D인지 확인
    elseif strcmp(data(i).type, 'D')

        % 맞으면 idx 1 추가
        step_dis(end+1) = i;
    end
end



% STEP 내부에서의 전하량 구하기

for j = 1:length(data)
     %calculate capacities
     data(j).Q = trapz(data(j).t,data(j).I)/3600; %[Ah]
     data(j).cumQ = cumtrapz(data(j).t,data(j).I)/3600; %[Ah]
     

     % data(j).cumQ = abs(cumtrapz(data(j).t,data(j).I))/3600; %[Ah]
     
end

% Total QC, QD값 구하기 ( 전체 전하량 구하기) 
total_QC = sum(abs([data(step_chg).Q]));  % charge 상태 전체 Q값
total_QD = sum(abs([data(step_dis).Q])); % discharge 상태 전체 Q값



% cumsumQ 필드 추가
for i = 1:length(data)
    if i == 1
        data(i).cumsumQ = data(i).cumQ;
    else
        data(i).cumsumQ = data(i-1).cumsumQ(end) + data(i).cumQ;
    end
end

for i = 1 : length(data)
    if id_cfa == 1 || id_cfa == 2
        if id_cfa == 1
            
             data(i).SOC = data(i).cumsumQ/total_QC; % Cathode
            

          
        elseif id_cfa == 2
           
             data(i).SOC = data(i).cumsumQ/total_QC; % FCC
            
            
            
        end
        % 큰 I 가지는 index 추출
        BigI = [];
        for i = 1:length(data)
            if abs(data(i).I) > (1/3 * I_1C)
               BigI = [BigI , i];
            end
        end
        
        if id_cfa == 1 || id_cfa == 2
            % BigIC, BigID 계산
            BigIC = BigI(BigI < step_chg(end));
            BigID = BigI(BigI >= step_chg(end));
        end
    elseif id_cfa == 3 % Anode
        BigI = [];
        for i = 1:length(data)
            data(i).SOC = 1 + data(i).cumsumQ/total_QD;
            if abs(data(i).I) > (1/3 * I_1C)
               BigI = [BigI , i];
               
            end
        end
        % BigI 계산
         BigI = BigI;
       
    else
        error('Invalid id_cfa value. Please choose 1 for cathode, 2 for FCC, or 3 for anode.');
    end
end


% I의 평균을 필드에 저장하기 

for i = 1:length(data)
    data(i).avgI = mean(data(i).I);
end

% V 변화량 구하기
for i = 1 : length(data)
    if i == 1
       data(i).deltaV = zeros(size(data(i).V));
    else
       data(i).deltaV = data(i).V() - data(i-1).V(end);
    end
end

% Resistance 구하기 
for i = 1 : length(data)
    if data(i).avgI == 0
        data(i).R = zeros(size(data(i).V));
    else 
        data(i).R = (data(i).deltaV / data(i).avgI) .* ones(size(data(i).V));
    end
end

% R 부분은 저항 0으로 하기, BigI에 해당하는 data번호만 그리기

plot(data(6).t, data(6).R)

xlabel('time (sec)')
ylabel('Resistance')

% x 값이 30초일 때의 y 값을 얻기
x_value = 7201;
y_value = interp1(data(2).t, data(2).R, x_value);

disp(y_value); % 결과 출력

% 1s , 10s, 30s 에서 Resistance 
for i = 1:length(BigI)
   data((BigI(i))).R001s = data(BigI(i)).R(1);
   data(BigI(i)).R1s = data(BigI(i)).R(10);
   data(BigI(i)).R10s = data(BigI(i)).R(55);
   data(BigI(i)).R30s = data(BigI(i)).R(end);
end

SOC001sc = [];
R001sc = [];
SOC1sc = [];
R1sc = [];
SOC10sc = [];
R10sc = [];
SOC30sc = [];
R30sc = [];
SOC001sd = [];
R001sd = [];
SOC1sd = [];
R1sd = [];
SOC10sd = [];
R10sd = [];
SOC30sd = [];
R30sd = [];


if id_cfa == 1 || id_cfa == 2
    for i = 1:length(BigIC)
        SOC001sc = [SOC001sc, data(BigIC(i)).SOC(2)];
        R001sc = [R001sc, data(BigIC(i)).R001s];
        SOC1sc = [SOC1sc, data(BigIC(i)).SOC(11)];
        R1sc = [R1sc, data(BigIC(i)).R1s];
        SOC10sc = [SOC10sc, data(BigIC(i)).SOC(56)];
        R10sc = [R10sc, data(BigIC(i)).R10s];
        SOC30sc = [SOC30sc, data(BigIC(i)).SOC(end)];
        R30sc = [R30sc, data(BigIC(i)).R(end)];
    end
    for i = 1 : length(BigID)
        SOC001sd = [SOC001sd, data(BigID(i)).SOC(2)];
        R001sd = [R001sd, data(BigID(i)).R001s];
        SOC1sd = [SOC1sd, data(BigID(i)).SOC(11)];
        R1sd = [R1sd, data(BigID(i)).R1s];
        SOC10sd = [SOC10sd, data(BigID(i)).SOC(56)];
        R10sd = [R10sd, data(BigID(i)).R10s];
        SOC30sd = [SOC30sd, data(BigID(i)).SOC(end)];
        R30sd = [R30sd, data(BigID(i)).R(end)];
    end
elseif id_cfa == 3
    for i = 1:length(BigI)
        SOC001sc = [SOC001sc, data(BigI(i)).SOC(2)];
        R001s = [R001s, data(BigI(i)).R001s];
        SOC1s = [SOC1s, data(BigI(i)).SOC(11)];
        R1s = [R1s, data(BigI(i)).R1s];
        SOC10s = [SOC10s, data(BigI(i)).SOC(56)];
        R10s = [R10s, data(BigI(i)).R10s];
        SOC30s = [SOC30s, data(BigI(i)).SOC(end)];
        R30s = [R30s, data(BigI(i)).R(end)];
    end
end

% Generate smoothed data for 'sc' case
smoothed_SOC_001sc = linspace(min(SOC001sc), max(SOC001sc), 100);
smoothed_R_001sc = spline(SOC001sc, R001sc, smoothed_SOC_001sc);

smoothed_SOC_1sc = linspace(min(SOC1sc), max(SOC1sc), 100);
smoothed_R_1sc = spline(SOC1sc, R1sc, smoothed_SOC_1sc);

smoothed_SOC_10sc = linspace(min(SOC10sc), max(SOC10sc), 100);
smoothed_R_10sc = spline(SOC10sc, R10sc, smoothed_SOC_10sc);

smoothed_SOC_30sc = linspace(min(SOC30sc), max(SOC30sc), 100);
smoothed_R_30sc = spline(SOC30sc, R30sc, smoothed_SOC_30sc);

% Plot the graph for 'sc' case
figure(1);
hold on;
plot(SOC001sc, R001sc, 'o');
plot(smoothed_SOC_001sc, smoothed_R_001sc);
plot(SOC1sc, R1sc, 'o');
plot(smoothed_SOC_1sc, smoothed_R_1sc);
plot(SOC10sc, R10sc, 'o');
plot(smoothed_SOC_10sc, smoothed_R_10sc);
plot(SOC30sc, R30sc, 'o');
plot(smoothed_SOC_30sc, smoothed_R_30sc);
hold off;

xlabel('SOC');
ylabel('Resistance (\Omega)', 'fontsize', 12);
title('SOC vs Resistance (Charge)');
legend('100ms', '100ms (line)', '1s', '1s (line)', '10s', '10s (line)', '30s', '30s (line)');
xlim([0 1]);

% Generate smoothed data for 'sd' case
smoothed_SOC_001sd = linspace(min(SOC001sd), max(SOC001sd), 100);
smoothed_R_001sd = spline(SOC001sd, R001sd, smoothed_SOC_001sd);

smoothed_SOC_1sd = linspace(min(SOC1sd), max(SOC1sd), 100);
smoothed_R_1sd = spline(SOC1sd, R1sd, smoothed_SOC_1sd);

smoothed_SOC_10sd = linspace(min(SOC10sd), max(SOC10sd), 100);
smoothed_R_10sd = spline(SOC10sd, R10sd, smoothed_SOC_10sd);

smoothed_SOC_30sd = linspace(min(SOC30sd), max(SOC30sd), 100);
smoothed_R_30sd = spline(SOC30sd, R30sd, smoothed_SOC_30sd);

% Plot the graph for 'sd' case
figure(2);
hold on;
plot(SOC001sd, R001sd, 'o');
plot(smoothed_SOC_001sd, smoothed_R_001sd);
plot(SOC1sd, R1sd, 'o');
plot(smoothed_SOC_1sd, smoothed_R_1sd);
plot(SOC10sd, R10sd, 'o');
plot(smoothed_SOC_10sd, smoothed_R_10sd);
plot(SOC30sd, R30sd, 'o');
plot(smoothed_SOC_30sd, smoothed_R_30sd);
hold off;

xlabel('SOC');
ylabel('Resistance (\Omega)', 'fontsize', 12);
title('SOC vs Resistance (Discharge)');
legend('100ms', '100ms (line)', '1s', '1s (line)', '10s', '10s (line)', '30s', '30s (line)');
xlim([0 1]);

for i = 1 : length(data)
    data(i).R1 = [];
    data(i).R2 = [];
    data(i).C = [];
    data(i).opR1 = [];
    data(i).opR2 = [];
    data(i).opC = [];
end

% 시간 초기화
for i = 1 : length(BigIC)
    initialTime = data(BigIC(i)).t(1); % 초기 시간 저장
    data(BigIC(i)).t = data(BigIC(i)).t - initialTime; % 초기 시간을 빼서 시간 초기화
end
 
 
% figure(3);
% hold on;
% 
% % for i = 1: length(BigIC)
%     i = 6
%     plot(data(BigIC(i)).t, data(BigIC(i)).V);
% 
%     % 최소값과 최대값 계산
%     minVoltage = min(data(BigIC(i)).V);
%     maxVoltage = max(data(BigIC(i)).V);
% 
%     % 63.2% 값 계산
%     targetVoltage = minVoltage + 0.632 * (maxVoltage - minVoltage);
% 
%     % 63.2%에 가장 가까운 값의 인덱스 찾기
%     [~, idx] = min(abs(data(BigIC(i)).V - targetVoltage));
% 
%     % 해당 시간 찾기
%     timeAt632 = data(BigIC(i)).t(idx);
% 
%     % 해당 시간에 선 그리기
%     line([timeAt632, timeAt632], [minVoltage, maxVoltage], 'Color', 'red', 'LineStyle', '--');
% 
%     xlabel('Time');
%     ylabel('Voltage (V)', 'fontsize', 12);
%     title('Voltage - Time Graph');
% %end
% hold off;


save('dcir_fit.mat','data')
