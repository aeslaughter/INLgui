function INLplot(input, varargin)
%INLPLOT Tool for plotting INL data
%
% Syntax
%   INLplot(input, 'PropertyName', PropertyValue,...)
%
% Description
%   INLplot(input, 'PropertyName', PropertyValue,...) plots the column of
%   data identified by the strings in left and right property pairings (see
%   description below). The input may be char or a cell array of char.
%
% Examples
%   INLplot('08152012_1st_ORC_Run.xlsx','left',{'dP_Exhaust','P_Abs_Subcool'},'right','dP_Eco'); 
%   INLplot({'08152012_1st_ORC_Run.xlsx','09172012_27th_ORC_Run.xlsx'},'left',{'dP_Exhaust','P_Abs_Subcool'},'right','dP_Eco','prefix',{'1st','27th'}); 
%
% INLPLOT Property Descriptions
%
%   Left (Required)
%       char | cell array of char
%       A list of the desired variables to be plotted on the left-hand axis
%
%   Right
%       char | cell array of char
%       A list of the desired variables to be plotted on the left-hand axis
%
%   OverLay
%       true | {false}
%       Setting this value to true removes the time stamping and begins all
%       plots at the same time.
%
%   Prefix
%       cell arra of char
%       If mulitple data sets are given (i.e., cell array of filenames) the
%       corresponding string in this array are append to the legend
%       entries.


% Gather the options from the user
opt.left = {};
opt.right = {};
opt.overlay = false;
opt.prefix = {};
opt = gather_user_options(opt, varargin{:});

% Report an error if left-hand data not defined
if isempty(opt.left);
    error('INLplot','Variables must be defined for plotting on the left.');
end

% Make sure the filename input is a cell array, so the loop below is valid
if ~iscell(input); input = {input}; end

% Initilize the data and legend storage
left = {};
right = {};
lgnd_left = {};
lgnd_right = {};

% Read the file(s) or use raw data
for i = 1:length(input);
    if ischar(input{i});
        str = sprintf('Loading %s, this may take several minutes, please wait...', input{i});
        disp(str);
        
        [~,~,ext] = fileparts(input{i});
        if strcmpi(ext,'.csv');
            R = csvread(input{i});
        elseif strcmpi(ext,'.xlsx');
            [~,~,R] = xlsread(input{i});
        end
    else
        R = input{i};
    end

    % Extract the date information
    t = cellstr(extract_data(R,'asciitime'));
    x = datenum(t,'ddd mmm dd HH:MM:SS YYYY');
    
    % Normalize the data to the start of the test, if desired
    if opt.overlay; x = x - x(1); end
    
    % Append the x-data to the storage cell array
    left{end+1} = x;
    
    % Extract the desired data for the left-side plot (required)
    [left{end+1}, L0] = extract_data(R, opt.left);
    
    % Add filenames to legend
    if ~isempty(opt.prefix);
        for j = 1:length(L0);
            L0{j} = [opt.prefix{i},':',L0{j}];
        end
    end
    lgnd_left = [lgnd_left, L0];
    
    % Add the right-hand data
    if ~isempty(opt.right);
        right{end+1} = x;
        [right{end+1}, L1] = extract_data(R, opt.right);
        if ~isempty(opt.prefix);
            for j = 1:length(L1);
                L1{j} = [opt.prefix{i},':',L1{j}];
            end
        end
        lgnd_right = [lgnd_right, L1];
    end
   
end

% Build the graph (left-hand axis)
plot(left{:});                              % plots the data
ax(1) = gca;                                % left-side axes handle
datetick('x');                              % use date/time marks
xlabel('Time');                             % label the x-axis
legend(lgnd_left,'interpreter','none',...   % adds the legend
    'location','northwest');

% Build the graph (right-hand axis)
if ~isempty(right)
   ax(2) = axes('Position',get(ax(1),'Position'));  % create axes
   plot(ax(2), right{:},'--');                      % plot the data
   datetick(ax(1),'x');                             % use date/time marks
   datetick(ax(2),'x');                             % use date/time marks
   linkaxes(ax,'x');                                % links the time axis
   legend(lgnd_right,'interpreter','none',...       % build the legend
       'location','northeast');            
   set(ax(2),'YAxisLocation','right',...            % set axes properties
       'XTickLabel',{}, 'Color', 'none'); 
end

function [Y,L] = extract_data(raw, var)
%EXTRACT_DATA extracts desired variable from raw Excel data
%
% Syntax
%   y = extract_data(raw, var)
%
% Description

% Make var a cell array, if it is not
if ~iscell(var); var = {var}; end;

% Extract the complete list of variables from the top row
var_list = raw(1,:);

% Loop through the desired variables and gathe the data into y
Y = []; % data
L = {}; % legend
for i = 1:length(var);
    
   % Locate the variable
   TF = strcmpi(var{i},var_list);
   idx = find(TF); 
   
   % Extract the data
   if ~isempty(idx);
        Y = [Y, cell2mat(raw(3:end,idx))];
        L = [L, var{i}];
   end
end
