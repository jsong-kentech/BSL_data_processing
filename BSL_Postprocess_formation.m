% BSL Formation Code
clc; clear; close all;


%% Interface
% data_folder = 'C:\Users\jsong\Documents\MATLAB\Data\OCP\OCP0.05C_Cathode Half cell(5)';
data_folder = 'C:\Users\jsong\Documents\MATLAB\Data\Formation\FC(Half)_11';
% data_folder = 'C:\Users\jsong\Documents\MATLAB\Data\Formation\CHC_10';
% data_folder = 'C:\Users\jsong\Documents\MATLAB\Data\Formation\AHC_10';
save_path = data_folder;
I_1C = 0.00382; %[A]
sample_plot =1;





%% Engine
slash = filesep;
files = dir([data_folder slash '*.mat']);

for i = 1:length(files)
    fullpath_now = [data_folder slash files(i).name];% path for i-th file in the folder
    load(fullpath_now);
    
    for j = 1:length(data)
    % calculate capacities
    data(j).Q = abs(trapz(data(j).t,data(j).I))/3600; %[Ah]
    end
    
    % cycle data
    vec_cycle = unique([data.cycle]');
    num_cycle = length(vec_cycle);
    for k = 1:num_cycle
        cycle_data = data([data.cycle]'==vec_cycle(k));
        
        if contains([cycle_data.type],'C') && contains([cycle_data.type],'D') 
        Q_chg = cycle_data([cycle_data.type] =='C').Q;
        Q_dis = cycle_data([cycle_data.type] =='D').Q;

        data_cycle(i,k).cycle = vec_cycle(k);
        data_cycle(i,k).Q_chg = Q_chg;
        data_cycle(i,k).Q_dis = Q_dis;
        data_cycle(i,k).eff = Q_dis/Q_chg;
        
        % cycle capacity matrix
        capacity_chg(i,k) = Q_chg;
        capacity_dis(i,k) = Q_dis;
        end
    end

    
    % plot
    if max([data_cycle(i,:).cycle]) >3
    color_mat=lines(3);
        if i ==1
        figure
        hold on
        box on
        end
    yyaxis left
    plot([data_cycle(i,:).cycle], [data_cycle(i,:).Q_chg],'o-',"Color",color_mat(1,:))
    axis([0 4 0 0.006])

    plot([data_cycle(i,:).cycle], [data_cycle(i,:).Q_dis],'o-',"Color",color_mat(2,:))
    axis([0 4 0 0.006])

    yyaxis right
    plot([data_cycle(i,2:end).cycle], [data_cycle(i,2:end).eff],'o-',"Color",color_mat(3,:))
    axis([0 4 0 1.5])

    set(gca,'FontSize',18)
    end

    % save output data
    % save_fullpath = [save_path slash files(i).name];
    % save(save_fullpath,'data','data_cycle')

end