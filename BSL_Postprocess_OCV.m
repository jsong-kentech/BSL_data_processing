% BSL OCV Code
clc; clear; close all;


%% Interface
data_folder = 'C:\Users\jsong\Documents\MATLAB\Data\OCP\OCP0.01C_Anode Half cell(5)';
%data_folder = 'C:\Users\jsong\Documents\MATLAB\Data\Formation\FC(Half)_11';
% data_folder = 'C:\Users\jsong\Documents\MATLAB\Data\OCP\OCP0.01C_Cathode Half cell(5)';

% cathode and fullcell
    % chg/dis with respect to the full cell operation
step_ocv_chg = 4;
step_ocv_dis = 6;


save_path = data_folder;
I_1C = 0.00382; %[A]
sample_plot =2;





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

    % plot
    color_mat=lines(3);
    figure
    hold on; box on;
    plot(data(step_ocv_chg).soc,data(step_ocv_chg).V,'-',"Color",color_mat(1,:))
    plot(data(step_ocv_dis).soc,data(step_ocv_dis).V,'-',"Color",color_mat(2,:))
    %axis([0 1 3 4.2])
    xlim([0 1])
    set(gca,'FontSize',12)


   % make an overall OCV struc
   % save the OCV struc

end