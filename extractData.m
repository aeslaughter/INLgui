function [X,Y,L] = extractData(R, variables, varargin)
    %EXTRACTDATA gets specific variables from the raw data
    %
    % Syntax
    %   [X,Y,L] = extractData(R, variables, 'PropertyName', PropertyValue, ...)
    %
    % Descrition
    %   [X,Y,L] = extractData(R, variables, 'PropertyName', PropertyValue, ...)
    %   Given the raw data (see readData.m) and the items listed in the
    %   variables input (single character or a cell array of characters)
    %   the x- and y-data is extracted. L contains the names for use with
    %   the legend function. The following property pairings are also
    %   available.
    %
    % INLPLOT Property Descriptions
    %   OverLay
    %       true | {false}
    %       Setting this value to true removes the time stamping and begins all
    %       plots at the same time.
    %
    %   Sort
    %       true | {false}
    %       Setting this to true sorts the data according to the timestamp,
    %       ignoring the order of the data in the file.
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
    
    % Gather the options from the user
    opt.overlay = false;
    opt.prefix = {};
    opt.hideprefix = false;
    opt.sort = false;
    opt = gatherUserOptions(opt, varargin{:}, {'-disableWarn'});
    
    % Make sure that the variables is a cell array for looping
    if ischar(variables);
        variables = {variables};
    end

    % Make sure the prefix is a cell
    if ischar(opt.prefix);
        opt.prefix = {opt.prefix};
    end
    
    % Initialize cell storage structures
    X = {}; Y = {}; L = {};

    % Loop through teach set of raw data
    for r = 1:length(R)
        
        % Extract the time data
        t = cellstr(extractVariable(R{r}, 'asciitime'));
        x = datenum(t, 'ddd mmm dd HH:MM:SS YYYY');
        if opt.overlay;
            x = x - x(1);
        end

        % Loop through each variable and get the data
        for v = 1:length(variables)
            y = extractVariable(R{r}, variables{v});
            
            % If data exists, append the storage structures
            if ~isempty(y);
                if opt.sort;
                    [~,idx] = sort(x);
                else
                    idx = 1:length(x);
                end
                Y{end+1} = y(idx);
                X{end+1} = x(idx);
                
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