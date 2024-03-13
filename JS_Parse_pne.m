% BSL Parsing Code
clc; clear; close all;


%% Interface

data_folder = 'G:\Shared drives\EE6211_2024\Data\rOCV';


save_path = data_folder;
I_1C = 55.5; %[A]
n_hd = 1; % **PNE headline number used in 'readtable' option. WonA: 14, Maccor: 3.
sample_plot = 1;

%% Engine
slash = filesep;
files = dir([data_folder slash '*.csv']); % select only txt files (raw data)

for i = 1:1%length(files)
    fullpath_now = [data_folder slash files(i).name]; % path for i-th file in the folder
    data_now = readtable(fullpath_now,'FileType','text',...
                    'NumHeaderLines',n_hd,'readVariableNames',0); % load the data
    % **PNE
    data1.I = data_now.Var9;
    data1.V= data_now.Var8;
    data1.t2 = data_now.Var7; % experiment time, format in duration
    data1.t1 = data_now.Var6; % step time, format in duration
    data1.cycle = data_now.Var14; 
    data1.T = data_now.Var21;

     % datetime
     if isduration(data1.t2(1))
        data1.t = seconds(data1.t2);
     else
        data1.t = data1.t2;
     end

     % absolute current
     data1.I_abs = abs(data1.I);

     % type
     data1.type = char(zeros([length(data1.t),1]));
     data1.type(data1.I>0) = 'C';
     data1.type(data1.I==0) = 'R';
     data1.type(data1.I<0) = 'D';

     % step
     data1_length = length(data1.t);
     data1.step = zeros(data1_length,1);
     m  =1;
     data1.step(1) = m;
        for j = 2:data1_length
            if data1.type(j) ~= data1.type(j-1)
                m = m+1;
            end
            data1.step(j) = m;
        end



     %  check for error, if any step has more than one types
     vec_step = unique(data1.step);
     num_step = length(vec_step);
     for i_step = 1:num_step
          type_in_step = unique(data1.type(data1.step == vec_step(i_step)));
          
          if size(type_in_step,1) ~=1 || size(type_in_step,2) ~=1
              disp('ERROR: step assignent is not unique for a step')
              return
          end
     end


    % plot for selected samples
    if any(ismember(sample_plot,i))
        figure(1)
        title(strjoin(strsplit(files(i).name,'_'),' '))
        hold on
        plot(data1.t/3600,data1.V,'-')
        xlabel('time (hours)')
        ylabel('voltage (V)')

        yyaxis right
        plot(data1.t/3600,data1.I/I_1C,'-')
        yyaxis right
        ylabel('current (C)')

    end

    % make struct (output format)
    data_line = struct('V',zeros(1,1),'I',zeros(1,1),'t',zeros(1,1),'indx',zeros(1,1),'type',char('R'),...
    'steptime',zeros(1,1),'T',zeros(1,1),'cycle',0);
    data = repmat(data_line,num_step,1);

    % fill in the struc
    n =1; 
    for i_step = 1:num_step

        range = find(data1.step == vec_step(i_step));
        data(i_step).V = data1.V(range);
        data(i_step).I = data1.I(range);
        data(i_step).t = data1.t(range);
        data(i_step).indx = range;
        data(i_step).type = data1.type(range(1));
        data(i_step).steptime = data1.t1(range);
        data(i_step).T = data1.T(range);
        data(i_step).cycle = data1.cycle(range(1));
        data(i_step).step = ones(size(data1.t(range)))*vec_step(i_step);

        % display progress
            if i_step> num_step/10*n
                 fprintf('%6.1f%%\n', round(i_step/num_step*100));
                 n = n+1;
            end

            figure(2)
            subplot(2,1,1)
            hold on
            plot(data(i_step).t,data(i_step).V)
            subplot(2,1,2); hold on
            plot(data(i_step).t,data(i_step).step)


    end

    % save output data
    if ~isfolder(save_path)
        mkdir(save_path)
    end
    save_fullpath = [save_path slash files(i).name(1:end-4) '.mat'];
    save(save_fullpath,'data')

end



