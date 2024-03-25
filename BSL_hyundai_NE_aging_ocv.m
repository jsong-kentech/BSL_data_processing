clc; clear; close all;

folder_path = 'H:\공유 드라이브\BSL-Data\Processed_data\Hyundai_dataset\현대차파우치셀 (rOCV,Crate)\NE_Aging';

% 해당 폴더의 파일 정보를 가져온 후 데이터 load
files = dir([folder_path filesep '*Cell*.mat']);

% 통합할 파일 숫자 찾기
for i = 1:length(files)
    nums_incellname = regexp(files(i).name,'\d+','match');
    files(i).cellnum = str2double(nums_incellname{end-2});
end

% 폴더내 셀넘버의 리스트 만들기
cellnum_list = unique([files.cellnum]);

merged_data = [];
I_1C = 55.6; %[A]
Vmin = 2.5; %[V]
Vmax = 4.2;  %[V]
cutoff_min = -0.05; %[C]
cutoff_max = 0.05;  %[C]
t_add = 0;
cycle = [1 400 600 800 1000];

for n = 1:length(cellnum_list)
    
    % 각 셀에 해당하는 파일리스트
    cellfile_list = files([files.cellnum] == cellnum_list(n));
    
     
    for k = 1:length(cellfile_list) 
        allnum = regexp(cellfile_list(k).name,'\d+','match');
        
        % Expnum 에서 해당하는 숫자 가져오기 
        cellfile_list(k).expnum = str2double(allnum{end-3});

        % Sort priority 계산
        cellfile_list(k).order = cellfile_list(k).expnum;
    end
    
    % 각셀에 해당하는 파일을 sort 
    [~, sortedIndex] = sort([cellfile_list.order]);
    cellfile_list_sorted = cellfile_list(sortedIndex);

    for k = 1:length(cellfile_list_sorted)
        
        % filepath로 데이터 로드
        fullpath_now = fullfile(folder_path,cellfile_list_sorted(k).name);
        data_now = load(fullpath_now);
 
        data = data_now.data;
       
        for l = 1:length(data)
            data(l).Q  = [];
            data(l).cumQ = [];
            data(l).soc =[];
            data(l).OCVflag = 0;
            data(l).Iavg = mean(data(l).I);  

            % charge OCVflag
            if abs(Vmax - data(l).V(end)) < 10e-3 && abs(cutoff_max - data(l).Iavg/I_1C) < 10e-2 && data(l+2).type == 'D'
                data(l).OCVflag = 1;

            % discharge OCVflag
            elseif abs(Vmin - data(l).V(end)) < 10e-3 && abs(cutoff_min - data(l).Iavg/I_1C) < 10e-2 && data(l-2).type == 'C'
                data(l).OCVflag = 2;

            end

             if length(data(l).t) > 2
                %cumQ,Q,soc생성
                data(l).Q = trapz(data(l).t,data(l).I)/3600;  %[Ah]
                data(l).cumQ = cumtrapz(data(l).t,data(l).I)/3600; %[Ah]
                data(l).soc = data(l).cumQ/data(l).Q;

                if data(l).OCVflag ==2 

                    data(l).Q = trapz(data(l).t,data(l).I)/3600;  %[Ah]
                    data(l).cumQ = cumtrapz(data(l).t,data(l).I)/3600; %[Ah]    
                    data(l).soc = 1-abs(data(l).cumQ)/abs(data(l).Q);

                end
                 
             end             
            data(l).t = data(l).t + t_add;
            data(l).cycle = cycle(n);           
        end
                 
       %t이어주기
       t_add = data(end).t(end);
       %Merge
       merged_data = [merged_data; data];   
      
   end          
end

% OCV 인덱스에 해당하는 merged data 추출
data_merged = [];
idx = find([merged_data.OCVflag] == 2);
idx(2) = [];

for j = 1:length(idx)   

     start_idx = max(1, idx(j) - 5);
     final_idx = min(length(merged_data), idx(j) + 1);
     data_merged = [data_merged; merged_data(start_idx:final_idx)];

end


save_path = fullfile(folder_path, 'NE_OCV_Merged');
save(save_path,'data_merged');
