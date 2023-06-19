% 파일 경로 가져오기
clc; clear; close all;

data_folder = 'G:\공유 드라이브\Battery Software Lab\Processed_data\Hyundai_dataset\GITT\AHC_(5)_GITT';
save_path = data_folder;
I_1C = 0.000477; %[A]
id_cfa = 3; % 1 for cathode, 2 for fullcell , 3 for anode 

% MAT 파일 가져오기
slash = filesep;
files = dir([data_folder slash '*.mat']);

for i = 1:length(files)
   fullpath_now = [data_folder slash files(i).name];% path for i-th file in the folder
   load(fullpath_now);
   data(1)= [];

end
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

% % cumsumQ 필드 추가
% for i = 1:length(data)
%     if i == 1
%         data(i).cumsumQ = data(i).cumQ;
%     else
%         data(i).cumsumQ = data(i-1).cumsumQ(end) + data(i).cumQ;
%     end
% end
% 
% for i = 1 : length(data)
%     % CATODE, FCC -- > data(i).SOC = data(i).cumsumQ/total_QC\
%     data(i).SOC = data(i).cumsumQ/total_QC; % Anode
% end

% cumsumQ 필드 추가
for i = 1:length(data)
    if i == 1
        data(i).cumsumQ = data(i).cumQ;
    else
        data(i).cumsumQ = data(i-1).cumsumQ(end) + data(i).cumQ;
    end
end

for i = 1 : length(data)
    if id_cfa == 1 || id_cfa == 2 % FCC, Cathode
        data(i).SOC = data(i).cumsumQ/total_QC; 

    elseif id_cfa == 3 % Anode
        data(i).SOC = 1 + data(i).cumsumQ/total_QD;
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

SOC001sc = [];
R001sc = [];
SOC1sc = [];
R1sc = [];
SOC10sc = [];
R10sc = [];
SOC30sc = [];
R30sc = [];
SOC900sc = [];
R900sc = [];
SOC001sd = [];
R001sd = [];
SOC1sd = [];
R1sd = [];
SOC10sd = [];
R10sd = [];
SOC30sd = [];
R30sd = [];
SOC900sd = [];
R900sd = [];


% 1s , 10s, 30s 에서 Resistance 
for i = 1:length(step_chg)-1
   data(step_chg(i)).R001s = data(step_chg(i)).R(1);
   data(step_chg(i)).R1s = data(step_chg(i)).R(10);
   data(step_chg(i)).R10s = data(step_chg(i)).R(56);
   data(step_chg(i)).R30s = data(step_chg(i)).R(76);
   data(step_chg(i)).R900s = data(step_chg(i)).R(end);
end


% 충전
for i = 1:length(step_chg)-1
    SOC001sc = [SOC001sc, data(step_chg(i)).SOC(1)];
    R001sc = [R001sc, data(step_chg(i)).R(1)];
    SOC1sc = [SOC1sc, data(step_chg(i)).SOC(10)];
    R1sc = [R1sc, data(step_chg(i)).R(10)];
    SOC10sc = [SOC10sc, data(step_chg(i)).SOC(56)];
    R10sc = [R10sc, data(step_chg(i)).R(56)];
    SOC30sc = [SOC30sc, data(step_chg(i)).SOC(76)];
    R30sc = [R30sc, data(step_chg(i)).R(76)];
    SOC900sc = [SOC900sc, data(step_chg(i)).SOC(end)];
    R900sc = [R900sc, data(step_chg(i)).R(end)];
end
% 방전
for i = 1:length(step_dis)
    SOC001sd = [SOC001sd, data(step_dis(i)).SOC(1)];
    R001sd = [R001sd, data(step_dis(i)).R(1)];
    SOC1sd = [SOC1sd, data(step_dis(i)).SOC(10)];
    R1sd = [R1sd, data(step_dis(i)).R(10)];
    SOC10sd = [SOC10sd, data(step_dis(i)).SOC(56)];
    R10sd = [R10sd, data(step_dis(i)).R(56)];
    SOC30sd = [SOC30sd, data(step_dis(i)).SOC(76)];
    R30sd = [R30sd, data(step_dis(i)).R(76)];
    SOC900sd = [SOC900sd, data(step_dis(i)).SOC(end)];
    R900sd = [R900sd, data(step_dis(i)).R(end)];
end


% spline을 사용하여 점들을 부드럽게 이어주기

smoothed_SOC_001sc = linspace(min(SOC001sc), max(SOC001sc), 100); % 보다 부드러운 곡선을 위해 임의의 구간을 생성합니다.
smoothed_R_001sc = spline(SOC001sc, R001sc, smoothed_SOC_001sc); % spline 함수를 사용하여 점들을 부드럽게 이어줍니다.

smoothed_SOC_1sc = linspace(min(SOC1sc), max(SOC1sc), 100); 
smoothed_R_1sc = spline(SOC1sc, R1sc, smoothed_SOC_1sc); 

smoothed_SOC_10sc = linspace(min(SOC10sc), max(SOC10sc), 100);
smoothed_R_10sc = spline(SOC10sc, R10sc, smoothed_SOC_10sc);

smoothed_SOC_30sc = linspace(min(SOC30sc), max(SOC30sc), 100); 
smoothed_R_30sc = spline(SOC30sc, R30sc, smoothed_SOC_30sc); 

smoothed_SOC_900sc = linspace(min(SOC900sc), max(SOC900sc), 100); 
smoothed_R_900sc = spline(SOC900sc, R900sc, smoothed_SOC_900sc);

% Generate smoothed data for 'sd' case

smoothed_SOC_001sd = linspace(min(SOC001sd), max(SOC001sd), 100);
smoothed_R_001sd = spline(SOC001sd, R001sd, smoothed_SOC_001sd);

smoothed_SOC_1sd = linspace(min(SOC1sd), max(SOC1sd), 100); 
smoothed_R_1sd = spline(SOC1sd, R1sd, smoothed_SOC_1sd); 

smoothed_SOC_10sd = linspace(min(SOC10sd), max(SOC10sd), 100);
smoothed_R_10sd = spline(SOC10sd, R10sd, smoothed_SOC_10sd);

smoothed_SOC_30sd = linspace(min(SOC30sd), max(SOC30sd), 100); 
smoothed_R_30sd = spline(SOC30sd, R30sd, smoothed_SOC_30sd); 

smoothed_SOC_900sd = linspace(min(SOC900sd), max(SOC900sd), 100); 
smoothed_R_900sd = spline(SOC900sd, R900sd, smoothed_SOC_900sd);


% 그래프 그리기
figure;
hold on;
plot(SOC001sc, R001sc, 'o');
plot(smoothed_SOC_001sc, smoothed_R_001sc);
plot(SOC1sc, R1sc, 'o');
plot(smoothed_SOC_1sc, smoothed_R_1sc);
plot(SOC10sc, R10sc, 'o');
plot(smoothed_SOC_10sc, smoothed_R_10sc);
plot(SOC30sc, R30sc, 'o');
plot(smoothed_SOC_30sc, smoothed_R_30sc);
plot(SOC900sc, R900sc, 'o');
plot(smoothed_SOC_900sc, smoothed_R_900sc);
hold off;

xlabel('SOC');
ylabel('Resistance (\Omega )', 'fontsize', 12);
title('SOC vs Resistance (charge)');
legend('100ms', '100ms (line)', '1s', '1s (line)', '10s', '10s (line)', '30s', '30s (line)', '900s', '900s (line)'); 
legend('100ms', '100ms (line)', '1s', '1s (line)', '10s', '10s (line)', '30s', '30s (line)'); 
xlim([0 1])

% 방전 그래프
% 그래프 그리기
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
plot(SOC900sd, R900sd, 'o');
plot(smoothed_SOC_900sd, smoothed_R_900sd);
hold off;

xlabel('SOC');
ylabel('Resistance (\Omega)', 'fontsize', 12);
title('SOC vs Resistance (Discharge)');
legend('100ms', '100ms (line)', '1s', '1s (line)', '10s', '10s (line)', '30s', '30s (line)', '900s', '900s (line)');
% legend('100ms', '100ms (line)', '1s', '1s (line)', '10s', '10s (line)', '30s', '30s (line)');
xlim([0 1]);


% 시간 초기화
for i = 1 : length(data)
    initialTime = data(i).t(1); % 초기 시간 저장
    data(i).t = data(i).t - initialTime; % 초기 시간을 빼서 시간 초기화
end
 

save('gitt_fit.mat','data')