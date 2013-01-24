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
    %   Location
    %       char
    %       Set the location of the legend, this uses the available
    %       location from the MATLAB legend command (see doc legend), the
    %       default is 'BestOutside'
    %
    %   Sort
    %       true | {false}
    %       Setting this to true sorts the data according to the timestamp,
    %       ignoring the order of the data in the file.
    %
    %   ClearFigure
    %       true | {false}
    %       If set to true this overwrites the existing figure, otherwise a
    %       new figure is created.
    %
    %   Prefix
    %       char | cell array of char
    %       A prefix that is added to the beginning of the legend entries.
    %       If a single filename is given this should be a character string
    %       otherwise it should be a cell array of character strings with
    %       one value corresponding to each filename.
    %
    %   HidePrefix
    %       true | {false}
    %       A flag for hidding the prefix, regardless values are given.
    %
    %   Raw
    %       true | {false}
    %       Allows for direct data input, used for testing. 
    %       See test_INLplot.m.

    % Gather the options from the user
    opt.left = {};
    opt.right = {};
    opt.overlay = false;
    opt.prefix = {};
    opt.hideprefix = false;
    opt.sort = false;
    opt.location = 'bestoutside';
    opt.clearfigure = false;
    opt.raw = false;
    opt = gather_user_options(opt, varargin{:});

    % Report an error if left-hand data not defined
    if isempty(opt.left);
        error('INLplot:NoLeftSideData', 'Variables must be defined for plotting on the left.');
    end

    % Make sure the filename input is a cell array, so the loop below is valid
    if opt.raw;
        R = input;
    else
        R = readData(input);
    end

    % Create new figure if desire
    if ~opt.clearfigure;
        figure;
    end
    
    % Build left-hand side only plot
    if isempty(opt.right);
        [X1, Y1, L1] = extractData(R, opt.left, opt);
        plot(X1,Y1);
        datetick('x');
        lgnd = L1;
        
    % Build dual axis plot    
    else
        [X1, Y1, L1] = extractData(R, opt.left, opt);
        [X2, Y2, L2] = extractData(R, opt.right, opt);
        ax = plotyy(X1,Y1,X2,Y2);
        datetick(ax(1),'x');
        datetick(ax(2),'x');
        lgnd = [L1,L2];
    end
    
    % Add labels and legend
    xlabel('Time');                            
    legend(lgnd, 'interpreter', 'none', 'location', opt.location);
end

function R = readData(filename)
    %READDATA Extracts the raaw data from the specified data
    
    % Make filename a cell array so the loop below if valid
    if ischar(filename);
        filename = {filename};
    end

    % Loop through each file and extract the data
    for i = 1:length(filename)
        
        % Display a message
        str = sprintf('Loading %s, this may take several minutes, please wait...', input{i});
        disp(str);
        
        % Extract the file extension
        [~,~,ext] = fileparts(filename{i});
        
        % Read the file based on the extension
        if strcmpi(ext,'.csv');
            R{i} = csvread(input{i});
        elseif strcmpi(ext,'.xlsx');
            [~, ~, R{i}] = xlsread(input{i});
        end
    end

end

function [X,Y,L] = extractData(R, variables, opt)
    %EXTRACTDATA gets specific variables from the raw data
    
    % Make sure that the variables is a cell array for looping
    if ischar(variables);
        variables = {variables};
    end

    % Initialize cell storage structures
    X = {}; Y = {}; L = {};

    % Loop through teach set of raw data
    for r = 1:length(R)
        
        % Extract the time data
        t = cellstr(extractVariable(R{r}, 'asciitime'));
        x = datenum(t, 'ddd mmm dd HH:MM:SS YYYY');

        % Loop through each variable and get the data
        for v = 1:length(variables)
            y = extractVariable(R{r}, variables{v});
            
            % If data exists, append the storage structures
            if ~isempty(y);
                Y{end+1} = y;
                X{end+1} = x;
                
                % Append legend, including prefix if specified
                if ~opt.hideprefix && ~isempty(opt.prefix) && length(R) == length(opt.prefix);
                    L{end+1} = [opt.prefix{r}, variables{v}];
                else
                    L{end+1} = variables{v};
                end
            else
                warning('INLplot:extraxtData', 'Variable %s not found.', variables{v});
            end
        end
    end
    
    % Covert the data from a cell array to numeric array padded with NaN
    [X,Y] = prepData(X,Y);
end

function data = extractVariable(raw, variable)
    %EXTRACTVARIABLE gets a single variable from the raw data
    
    % Initilize output
    data = [];

    % List of available variables
    var_list = raw(1,:);

    % Locate the variable
    TF = strcmpi(variable, var_list);
    idx = find(TF); 

    % Extract the data
    if ~isempty(idx);
        data = cell2mat(raw(3:end,idx));
    end
end

function [X,Y] = prepData(x,y)
    %PREPDATA Converts cell array inputs to a NaN padded numeric array

    % Determine the length of each column
    for i = 1:length(x);
        len(i) = length(x{i});
    end

    % Initilize the numeric arrays
    X = nan(max(len),length(x));
    Y = X;

    % Insert the data
    for i = 1:length(x);
        X(1:length(x{i}),i) = x{i};
        Y(1:length(y{i}),i) = y{i};
    end
end