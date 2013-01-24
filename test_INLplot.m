%test

if ~exist('R1','var') || ~exist('R2','var');
    [~,~,R1] = xlsread('data/08152012_1st_ORC_Run.xlsx');
    [~,~,R2] = xlsread('data/08302012_11th_ORC_Run.xlsx');
end

%INLplot({R1,R2},'left',{'TC_Superheat_B', 'TC_Water_Inlet'},'-raw');
INLplot({R1,R2},'left',{'TC_Superheat_B', 'TC_Water_Inlet'},...
    'right',{'TC_Water_Exit'}, '-raw');