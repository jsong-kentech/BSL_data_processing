% BSL OCV Code
clc; clear; close all;

%% Interface

% data folder
data_folder = 'G:\공유 드라이브\Battery Software Lab\Data\Hyundai_dataset\OCV\FCC_(5)_OCV_C20';
[save_folder,save_name] = fileparts(data_folder); % fileparts 함수는 지정된 파일의 경로 이름, 파일 이름, 확장자를 반환
% save_folder와 save_name 변수에 폴더 경로와 기본 파일 이름이 각각 할당

% cathode, fullcell, or anode
id_cfa = 2; % 1 for cathode, 2 for fullcell, 3 for anode, 0 for automatic (not yet implemented)

% OCV steps
    % chg/dis sub notation : with respect to the full cell operation, 충전/방전 서브 표기: 풀셀 동작을 기준으로 함
step_ocv_chg = 4;
step_ocv_dis = 6;

% parameters
y1 = 0.215685; % cathode stoic at soc = 100% (soc=1 일때 양극 y1만큼 채워져 있음), reference : AVL NMC811
x_golden = 0.5;

%% Engine
slash = filesep; % filesep은 경로에서 폴더와 파일 이름을 각각으로 구분
files = dir([data_folder slash '*.mat']);  % dir 함수를 사용해서 data_folder 내의 모든 .mat 파일을 가져옴

for i = 1:length(files) % .mat 파일 개수
    fullpath_now = [data_folder slash files(i).name]; % path for i-th file in the folder
    load(fullpath_now);

    for j = 1:length(data) % data field의 개수
    % calculate capabilities, 용량 계산
        if length(data(j).t) > 1 % data field에 data가 1개보다 많을 때
            data(j).Q = abs(trapz(data(j).t,data(j).I))/3600; %[Ah]
            % trapz은 적분 함수, Q = Integral(Idt), 적분값에 절댓값 씌운 후 3600s를 나눠서 Ah로 단위 변환
            % data(j).Q는 total capacity
            data(j).cumQ = abs(cumtrapz(data(j).t,data(j).I))/3600; %[Ah]
            % data(j).cumQ는 해당 시점까지의 전체 누적 용량
        end
    end

    data(step_ocv_chg).soc = data(step_ocv_chg).cumQ/data(step_ocv_chg).Q; % SOC = cumQ/Q, charge soc는 0에서 1
    data(step_ocv_dis).soc = 1-data(step_ocv_dis).cumQ/data(step_ocv_dis).Q; % SOC = 1 - cumQ/Q, discharge soc는 1에서 0

    % stoichiometry for cathode and anode (not for fullcell)
    if id_cfa == 1 % cathode
        data(step_ocv_chg).stoic = 1-(1-y1)*data(step_ocv_chg).soc;
        data(step_ocv_dis).stoic = 1-(1-y1)*data(step_ocv_dis).soc;
        % 충전 : soc=0->1, stoic=1->y1  % 방전 : soc=1->0, stoic=y1->1 
        % 양극에서는 충전시에 리튬 이온 적어지고, 방전시에 리튬 이온 많아진다
    elseif id_cfa == 3 % anode
        data(step_ocv_chg).stoic = data(step_ocv_chg).soc;
        data(step_ocv_dis).stoic = data(step_ocv_dis).soc;
        % 충전 : soc=0->1, stoic=0->1  % 방전 : soc=1->0, stoic=1->0
        % 음극에서는 충전시에 리튬 이온 많아지고, 방전시에 리튬 이온 적어진다
    elseif id_cfa == 2 % full cell
        % stoic is not defined for full cell.
    end

    % make an overall OCV struct
    if id_cfa == 1 || id_cfa == 3 % cathode or anode halfcell
        x_chg = data(step_ocv_chg).stoic;  
        y_chg = data(step_ocv_chg).V;
        z_chg = data(step_ocv_chg).cumQ;
        x_dis = data(step_ocv_dis).stoic;
        y_dis = data(step_ocv_dis).V;
        z_dis = data(step_ocv_dis).cumQ;
    elseif id_cfa == 2 % fullcell
        x_chg = data(step_ocv_chg).soc; % fullcell일때 stoic는 정의를 안했음
        y_chg = data(step_ocv_chg).V;
        z_chg = data(step_ocv_chg).cumQ;
        x_dis = data(step_ocv_dis).soc;
        y_dis = data(step_ocv_dis).V;
        z_dis = data(step_ocv_dis).cumQ;
    end

    OCV_all(i).OCVchg = [x_chg y_chg z_chg]; % [stoic V cumQ] or [soc V cumQ]
    OCV_all(i).OCVdis = [x_dis y_dis z_dis];

    OCV_all(i).Qchg = data(step_ocv_chg).Q;
    OCV_all(i).Qdis = data(step_ocv_dis).Q;


    % golden criteria
    OCV_all(i).y_golden = (interp1(x_chg,y_chg,0.5)+ interp1(x_dis,y_dis,0.5))/2; 
    % 충전 및 방전 OCV의 soc=0.5에서의 OCV 평균값을 골든 기준으로 정함
    % interp1(x,v,xq)은 선형 보간을 사용하여 특정 쿼리 점에서 1차원 함수의 보간된 값을 반환
    % 벡터 x는 샘플 점을 포함하며 v는 대응값 v(x)를 포함합니다. 벡터 xq는 쿼리 점의 좌표를 포함

    % plot
    color_mat=lines(4); % 4개의 다른 색상을 생성하여 color_mat 변수에 할당
    if i == 1 % n번째 파일에 대한 그래프를 그리기 위해 figure 생성
    figure
    end
    hold on; box on; % 그래프를 그릴 때 이전 그래프를 유지하고 겹쳐서 그리기 위해 hold on 사용
    % box on은 그래프의 축에 대한 박스를 그리기 위해 사용
    plot(x_chg,y_chg,'-',"Color",color_mat(1,:))
    % x_chg를 x음축으로, y_chg를 y축으로 하는 선 그래프를 그립니다. 선 스타일은 '-'로 설정, 색상은 color_mat의 첫 번째 색상을 사용
    plot(x_dis,y_dis,'-','Color',color_mat(2,:))
    % axis([0 1 3 4.2]) % stoic(soc)범위는 0에서 1, V의 범위는 3에서 4.2 ??
    xlim([0 1]) % x축의 범위를 0부터 1까지로 설정
    set(gca,'FontSize',12) % 그래프 축의 글꼴크기를 12로 설정

end

% select an golden OCV
[~,i_golden] = min(abs([OCV_all.y_golden]-median([OCV_all.y_golden])));
% |(y_golden 값)-(i개의 y_golden 값 중에 중앙값)|->이 값들 중 min값 찾기
% ~는 값 자체는 무시하고 인덱스만 가져오는 것을 의미.
OCV_golden.i_golden = i_golden;

% save OCV struct
OCV_golden.OCVchg = OCV_all(1,i_golden).OCVchg;
OCV_golden.OCVdis = OCV_all(1,i_golden).OCVdis;

% plot
title_str = strjoin(strsplit(save_name,'_'),' ');
% strsplit(save_name,'_') -> 언더바 뺌 {'FCC'}  {'(5)'}  {'OCV'}  {'C100'} 1×4 cell array 
% strjoin(strsplit(save_name,'_'),' ') ->  'FCC 5 OCV C100'
title(title_str)
plot(OCV_golden.OCVchg(:,1),OCV_golden.OCVchg(:,2),'--','Color',color_mat(3,:))
% x축은 stoic, y축은 V
hold on
plot(OCV_golden.OCVdis(:,1),OCV_golden.OCVdis(:,2),'--','Color',color_mat(4,:))

% save
save_fullpath = [save_folder filesep save_name '.mat'];
% save_fullpath 변수에 저장 경로와 파일 이름을 할당하고 .mat 확장자 추가
save(save_fullpath,'OCV_golden','OCV_all') % OCV_golden과 OCV_all을 .mat 형식으로 저장
