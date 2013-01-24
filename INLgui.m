function fig = INLgui
    %INLGUI opens an interactive window for plotting INL Excel data
    %
    % Syntax
    %   INLgui;
    %   fig = INLgui;
    %
    % Description
    %   INLgui opens the GUI for graphing the INL data from Excel spreadsheets.
    %
    %   fig = INLgui opens GUI and returns the the figure handle of the GUI.
    %
    % See Also
    %   INLplot

    % Open the GUI (created with GUIDE)
    fig = open('INLgui.fig');

    % Get the handles associated with the GUI
    h = guihandles(fig);

    % Set the various callbacks
    set(h.load, 'Callback', @callbackLoad, 'BusyAction','cancel');
    set(h.filename, 'Max', 10, 'Min', 1, 'Callback', @callbackFilename);
    set(h.folder, 'Callback', @callbackFolder);
    set([h.right,h.left],'Max', 10, 'Min', 1,'Callback',@callbackListbox);
    set(h.plot,'Callback',@callbackPlot);
    set(h.figure1,'HandleVisibility', 'Callback');
    set([h.overlay, h.sort, h.prefix], 'Value', 0);
    set(h.location, 'Value', 10); 

    % Initilize
    callbackFolder(h.folder,[],'init');
    set([h.plot,h.left,h.right],'Enable','off');
end

function callbackFilename(hObject, ~)
    %CALLBACK_FILENAME operates when a file is selected from the list

    h = guihandles(hObject);
    set(h.load,'enable','on');
    set([h.right,h.left],'enable','off');
end

function callbackLoad(hObject, ~)
    %CALLBACK_LOAD operates when load button is selected

    % Get the list of files and the location of the selected file
    h = guihandles(hObject);
    filename = get(h.filename,'String');
    folder = getpref('INLgui_pref','folder');
    idx = get(h.filename,'Value');

    % Open the file
    w = msgbox('Loading data, this may take several minutes, please wait...',...
        'Please wait...','help');
    wh = guihandles(w);
    set(wh.OKButton,'Visible','off');
    pause(0.0001);

    % Storage array's for available variables
    var = {};

    % Loop through the files
    for i = 1:length(idx);

        % Determine the filename

        % Read the raw data
        [~,~,R{i}] = xlsread(fullfile(folder,filename{idx(i)}));

        % Locate the time vector
        TF = strcmpi('ExcelTime',R{i}(1,:));
        x = find(TF);

        % Extract variables
        var = [var,R{i}(1,x+1:end)]; 
    end
    close(w); % close the please wait

    % Store the data in the GUI
    guidata(hObject,R);

    % Get the unique variables
    var = ['none',unique(var)];

    % Update the listboxs with the available data
    set(h.left,'String',var,'Value',1);
    set(h.right,'String',var,'Value',1);
    set([h.left,h.right],'Enable','on');
    set(h.load,'enable','off');
end
   
function callbackFolder(hObject, ~, varargin)
    %CALLBACKFOLDER operates when folder button is selected

    % Get the previously used folder (uses current directory initially)
    if ispref('INLgui_pref','folder');
        folder = getpref('INLgui_pref','folder');
        if isnumeric(folder);
            folder = cd;
        end
    else
        folder = cd;
    end

    % Prompts the user for a new directory ('init' flag skips this)
    if nargin == 2;
        folder = uigetdir(folder, 'Select directory...');
        setpref('INLgui_pref','folder',folder);
    end

    % Updates the filename list
    h = guihandles(hObject);
    d = dir(fullfile(folder,'*.xlsx'));
    c = struct2cell(d);
    set(h.filename, 'String',c(1,:));
    set(h.folder, 'Value', 1);
end

function callbackListbox(hObject, ~)
    %CALLBACKLISTBOX operates when an item in a listbox is selected
    % This function simply toggles the enable status of the plot button, if no
    % data is selected you can not press the button

    h = guihandles(hObject);
    idx = get(h.left,'Value');

    if idx == 1; 
        set(h.plot,'Enable','off');
    else
        set(h.plot,'Enable','on');
    end
end

function callbackPlot(hObject, ~)
    %CALLBACKPLOT creates the graph of selected data

    % Get the handles
    h = guihandles(hObject);

    % Get the variable lists
    left_list = get(h.left,'String');
    left_idx = get(h.left,'Value');
    right_list = get(h.right,'String');
    right_idx = get(h.right,'Value');

    % Get the data
    R = guidata(hObject);

    % Create the graph
    pref = getSettings(hObject);
    if length(right_idx) == 1 && right_idx == 1;
        INLplot(R, 'left', left_list(left_idx), pref{:}, '-raw');
    else
        INLplot(R, 'left', left_list(left_idx), ...
            'right', right_list(right_idx), pref{:}, '-raw');
    end
end

function pref = getSettings(hObject)
    %GETSETTINGS Extract the settings from the GUI
    
    % Get the handles
    h = guihandles(hObject);
    
    % Apply toggle preferences
    pref = {'OverLay', get(h.overlay, 'value'), ...
            'Sort', get(h.sort, 'value'), ...
            'HidePrefix', ~get(h.prefix, 'value')};
            
    % Apply filename prefix
    names = get(h.filename, 'String');
    idx = get(h.filename, 'Value');
    pref = [pref, 'Prefix', names(idx)];
    
    % Apply legend location
    locations = get(h.location, 'String');
    idx = get(h.location, 'Value');
    [~,~,~,loc] = regexp(locations{idx}, '([^:]*)');
    pref = [pref, 'location', loc{1}];
 
end
