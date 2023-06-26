% BSL Parsing Code
clc; clear; close all;


%% Interface

% Path 지정
data_folder = 'G:\공유 드라이브\Battery Software Lab\Data\Hyundai_dataset\OCV\FCC_(5)_OCV_C100';
save_path = data_folder;

I_1C = 0.00382; % [A], 0.01C에서 3.81986E-005이므로 1C에서는 0.00382
n_hd = 14; % headline number used in 'readtable' option
sample_plot = 1;


%% Engine 
slash = filesep; % slash를 filesep으로 지정함, filesep은 파일 경로 구분자
files = dir([data_folder slash '*.txt']); % select only txt files (raw data)
% dir 함수는 지정된 디렉토리에서 파일 및 하위 디렉토리의 정보를 검색하는 데 사용되는 함수

for i = 1:length(files)
    fullpath_now = [data_folder slash files(i).name]; % path for i-th file in the folder
    % files(i).name 은 구조체의 'i'번째 요소에 저장된 파일이나 폴더의 이름을 나타냄
    % .name을 붙이면 파일이나 폴더의 이름을 추출할 수 있음
    data_now = readtable(fullpath_now,'FileType','text','NumHeaderLines',n_hd,'ReadVariableNames',0) % load the data
    % readtable은 텍스트 파일이나 스프레드시트 파일을 읽어들여 table 형식으로 반환하는 함수
    % FileType은 파일의 유형 또는 확장자를 나타내는 용어
    % NumHeaderLines은 건너뛸 라인 수
    % ReadVariableNames은 파일을 읽을 때 첫 번째 행을 변수 이름으로 사용할지 여부를 지정하는 데 사용됨. false일 경우 디폴트 변수 이름인 Var1, Var2, ...로 설정됨
    % ReadVariableNames 옵션을 0으로 설정하는 경우, 파일의 첫 번째 행은 데이터로 처리되고 변수 이름을 따로 지정해주어야 함

    % struct.field = value; struct : 구조체 변수의 이름, field : 구조체 내의 필드 이름, value : 할당하려는 값 
    data1.I = data_now.Var7; % 왼쪽에서 7번째 변수(전류)를 'data1'이라는 struct 내의 'I'라는 field에 저장하겠어
    data1.V = data_now.Var8; 
    data1.t2 = data_now.Var2; % experiment time, format in duration(시간)
    data1.t1 = data_now.Var4; % step time, format in duration(시간)
    data1.cycle = data_now.Var3;
    data1.T = data_now.Var13; 

    % datetime
    if isduration(data1.t2(1)) == true % isduration 함수는 주어진 변수가 시간(duration) 데이터인지 확인하는 데 사용됨. duration(0, 3, 30)은 3분 30초를 나타냄
        data1.t = seconds(data1.t2); % seconds 함수는 시간을 초 단위로 반환하는 데 사용함
    else 
        data1.t = data1.t2;
    end

    % absolute current 
    data1.I_abs = abs(data1.I);

    % type
    data1.type = char(zeros(size(data1.t))); % zeros 함수 사용해서 메모리 미리 지정 % char 함수는 다양한 데이터 유형을 문자열 형식으로 변환하는 데 사용됨
    data1.type(data1.I>0) = 'C'; % Charge
    data1.type(data1.I==0) = 'R'; % Rest
    data1.type(data1.I<0) = 'D'; % Discharge 

    % step
    data1_length = length(data1.t);
    data1.step = zeros(data1_length,1); % 메모리 지정
    m = 1; 
    data1.step(1) = m;
       for j = 2 : data1_length 
           if data1.type(j) ~= data1.type(j-1)
               m = m+1;
           end
           data1.step(j) = m;
       end



       % check for error, if any step has more than one types
       vec_step = unique(data1.step); % unique 함수는 배열 또는 벡터에서 중복된 요소를 제거하고 고유한 요소만을 변환하는 데 사용됨. 1 1 1 2 2 2 2 3 3  -> 1 2 3 
       num_step = length(vec_step) % m의 개수
       for i_step = 1 : num_step
           type_in_step = unique(data1.type(data1.step == vec_step(i_step)));

           if size(type_in_step,1) ~=1 || size(type_in_step,2)~=1
               disp('ERROR: step assignment is not unique for a step')
               return
               % size 함수의 첫 번째 차원(행)이 1이 아니면 바로 disp으로 가고, size 함수의 첫 번째 차원(행)이 1이면 두 번째 차원(열)까지 확인 후 1이 아니면 disp로 감
               % return은 함수 내에서 함수 실행을 중단하고 함수 외부로 돌아가는 데 사용되고 break는 반복문 내에서 현재 실행 중인 반복문을 조기 종료하는 데 사용됨
           end
       end
       
       % plot for selected samples
       if any(ismember(sample_plot,i)) % ismember(A,B)는 A의 데이터를 B에서 찾은 경우 논리값 1(true), 아니면 논리값 0(false). ismember(A,B)의 크기는 A와 동일
           % result = any(A) : result는 A의 요소 중 하나 이상이 true인 경우 true로 설정되고, 모든 요소가 false인 경우에만 false로 설정됨
           figure
           title(strjoin(strsplit(files(i).name,'_'),' '))
           % strsplit는 문자열을 특정 구분자를 기준으로 분할하는 데 사용되는 함수. strsplit(files(i).name,'_') : files(i).name을 _를 기준으로 분할함
           % strjoin은 문자열들을 구분자로 구분하여 하나의 문자열로 결합할 수 있음
           plot(data1.t/3600, data1.V, 'r-') % 시간에 대한 전압 그래프, x축 : 총 실험시간(s)/3600 -> 단위를 hr로 바꿈
           xlabel('time (hours)')
           ylabel('voltage (V)')

           yyaxis right % 두 개의 y축이 있는 차트 생성
           plot(data1.t/3600, data1.I/I_1C, 'b-') % I_1C로 나누어주면 3.82012E-004/0.00382=0.1C로 정리됨
           ylabel('current (C)')
       end


       % make struct (output format)
       data_line = struct('V', zeros(1,1), 'I', zeros(1,1), 't', zeros(1,1), 'indx', zeros(1,1), 'type', zeros(1,1),...
           'steptime', zeros(1,1), 'T', zeros(1,1), 'cycle', zeros(1,1)); % 1x1 struct with 8 fields
       data = repmat(data_line, num_step, 1); % repmat은 함수의 배열을 반복하여 크기를 확장하는 데 사용되는 함수
       % data_line을 반복하여 num_step x 1 행렬로 만들어 줌

       % fill in the struct
       n=1;
       for i_step = 1 : num_step

           range = find(data1.step == vec_step(i_step)); % C, R, D의 범위를 찾아줌 ex) 1-4, 5-244, 245-1420, ...
           data(i_step).V = data1.V(range); % 1번째 필드의 전압 = , 2번째 필드의 전압 = , ... 
           data(i_step).I = data1.I(range); % 1번째 필드의 전류 = , 2번째 필드의 전류 = , ...
           data(i_step).t = data1.t(range); % 1번째 필드의 실험시간  = , 2번째 필드의 실험시간 = , ...
           data(i_step).indx = range; % 1-4, 5-244, 245-1420, ...
           data(i_step).type = data1.type(range(1)); % 'R', 'C', 'R', 'D', ...
           data(i_step).steptime = data1.t1(range); % 1번째 필드의 사이클 시간 = , 2번째 필드의 사이클 시간 = , ...
           data(i_step).T = data1.T(range); % 1번째 필드의 온도 = , 2번째 필드의 온도 = , ...
           data(i_step).cycle = data1.cycle(range(1)); % 1번째 필드의 사이클 번호 = , 2번째 필드의 사이클 번호 = , ...

           % display progress 현재 처리 중인 데이터 파일의 진행 상황이 백분율로 표시됨
           if i_step > num_step/10*n % i_step은 현재 처리 중인 단계의 인덱스를 나타내며, num_step은 전체 단계 수
               fprintf('%6.1f%%\n', round(i_step/num_step*100)); % fprintf 함수는 형식화된 데이터를 파일에 쓰는 함수
               % '%6.1f' : 실수 값을 소수점 아래 한 자리까지 출력하는 부동 소수점 형식. 숫자 6은 전체 필드의 너비를 나타내며, 소수점 아래 숫자 1은 소수점 아래 자리수를 나타냄
               % '%%' : '%'기호를 출력하는 서식 지정자. '%' 기호를 출력하려면 두 개의 '%'기호를 연속해서 사용해야 함
               % '\n' : 줄바꿈 문자  
               % round(i_step/num_step*100)는 진행 상황의 백분율 값을 계산
               % i_step이 10% 단위로 증가할 때마다 진행 상황이 표시됨. 10%, 20%, 30%, ..., 100%
               n = n+1;
           end
       end

       % save output data
       if ~isfolder(save_path) % isfolder는 지정된 경로가 폴더인지 확인하는 함수. 주어진 경로가 폴더이면 true를 반환하고, 그렇지 않은 경우 false를 반환함
           mkdir(save_path) % mkdir은 새로운 디렉토리(폴더)를 생성하는 함수
       end % save_path가 지정된 경로 또는 현재 폴더에 위치한 경우가 아니면 새 폴더 save_path를 만든다

       save_fullpath = [save_path slash files(i).name(1:end-4) '.mat'];
       % save_fullpath에 저장 경로와 파일 이름을 할당함
       % (1:end-4) : 파일 이름에서 마지막 4개 문자(확장자)를 제외한 부분을 선택함. .mat : .mat 확장자를 추가함
       save(save_fullpath, 'data') % data를 .mat 형식으로 저장
       
end

