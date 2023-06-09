% BSL OCV Code
clc; clear; close all;

%% Interface

% data folder
% data_folder = 'C:\Users\jsong\Documents\MATLAB\Data\OCP\OCP0.05C_Full cell(half)(5)';
 data_folder = 'G:\공유 드라이브\Battery Software Lab\Data\Hyundai_dataset\OCV\FCC_(5)_OCV_C100';
 [save_folder,save_name] = fileparts(data_folder);

% cathode, fullcell, or anode
id_cfa = 2; % 1 for cathode, 2 for fullcell, 3 for anode, 0 for automatic (not yet implemented)

% OCV steps
    % chg/dis sub notation: with respect to the full cell operation
step_ocv_chg = 4;
step_ocv_dis = 6;

% parameters
y1 = 0.215685; % cathode stoic at soc = 100%. reference: AVL NMC811
x_golden=0.5; %



%% Engine
slash = filesep;
files = dir([data_folder slash '*.mat']);

for i = 1:length(files)
    fullpath_now = [data_folder slash files(i).name];% path for i-th file in the folder
    load(fullpath_now);
    
    for j = 1:length(data)
    % calculate capacities
        if length(data(j).t) >1
            data(j).Q = abs(trapz(data(j).t,data(j).I))/3600; %[Ah]
            data(j).cumQ = abs(cumtrapz(data(j).t,data(j).I))/3600; %[Ah]
        end
    end
    
   data(step_ocv_chg).soc = data(step_ocv_chg).cumQ/data(step_ocv_chg).Q;
   data(step_ocv_dis).soc = 1-data(step_ocv_dis).cumQ/data(step_ocv_dis).Q;

   % stoichiometry for cathode and anode (not for fullcell)
   if id_cfa == 1 % cathode
        data(step_ocv_chg).stoic = 1-(1-y1)*data(step_ocv_chg).soc;
        data(step_ocv_dis).stoic = 1-(1-y1)*data(step_ocv_dis).soc; 
   elseif id_cfa ==3 % anode
        data(step_ocv_chg).stoic = data(step_ocv_chg).soc;
        data(step_ocv_dis).stoic = data(step_ocv_dis).soc; 
   elseif id_cfa == 2 % full cell
       % stoic is not defined for full cell.
   end


   % make an overall OCV struct
   if id_cfa == 1 || id_cfa == 3 % cathode or anode halfcell
        x_chg = data(step_ocv_chg).stoic;
        y_chg = data(step_ocv_chg).V;
        x_dis = data(step_ocv_dis).stoic;
        y_dis = data(step_ocv_dis).V;
   elseif id_cfa == 2 % fullcell
        x_chg = data(step_ocv_chg).soc;
        y_chg = data(step_ocv_chg).V;
        x_dis = data(step_ocv_dis).soc;
        y_dis = data(step_ocv_dis).V;

   end
    OCV_all(i).OCVchg = [x_chg y_chg];
    OCV_all(i).OCVdis = [x_dis y_dis];

    OCV_all(i).Qchg = data(step_ocv_chg).Q;
    OCV_all(i).Qdis = data(step_ocv_dis).Q;

    % golden criteria
    OCV_all(i).y_golden = (interp1(x_chg,y_chg,0.5)+interp1(x_dis,y_dis,0.5))/2;
    

    % plot
    color_mat=lines(4);
    if i ==1
    figure
    end
    hold on; box on;
    plot(x_chg,y_chg,'-',"Color",color_mat(1,:))
    plot(x_dis,y_dis,'-',"Color",color_mat(2,:))
    %axis([0 1 3 4.2])
    xlim([0 1])
    set(gca,'FontSize',12)


    
end



% select an golden OCV
[~,i_golden] = min(abs([OCV_all.y_golden]-median([OCV_all.y_golden])));
OCV_golden.i_golden = i_golden;

% save OCV struct
OCV_golden.OCVchg = OCV_all(1,i_golden).OCVchg; 
OCV_golden.OCVdis = OCV_all(1,i_golden).OCVdis;


% plot
title_str = strjoin(strsplit(save_name,'_'),' ');
title(title_str)
plot(OCV_golden.OCVchg(:,1),OCV_golden.OCVchg(:,2),'--','color',color_mat(3,:))
plot(OCV_golden.OCVdis(:,1),OCV_golden.OCVdis(:,2),'--','color',color_mat(4,:))


% save
save_fullpath = [save_folder filesep save_name '.mat'];
save(save_fullpath,'OCV_golden','OCV_all')
