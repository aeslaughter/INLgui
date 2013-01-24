function R = readData(filename)
    %READDATA Extracts the raaw data from the specified data
    %
    % Syntax
    %   R = readData('FileName')
    %   R = readData({'FileName1','FileName2'})
    %
    % Description
    %   R = readData('FileName') read a single file and returns the raw
    %   data
    %
    %   R = readData({'FileName1','FileName2'}) reads multiple data files
    %   and returns a cell array of the raw data
    
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