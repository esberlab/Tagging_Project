function varargout = Manual_auto_update2(varargin)
% MANUAL_AUTO_UPDATE2 MATLAB code for Manual_auto_update2.fig
%      MANUAL_AUTO_UPDATE2, by itself, creates a new MANUAL_AUTO_UPDATE2 or raises the existing
%      singleton*.
%
%      H = MANUAL_AUTO_UPDATE2 returns the handle to a new MANUAL_AUTO_UPDATE2 or the handle to
%      the existing singleton*.
%
%      MANUAL_AUTO_UPDATE2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MANUAL_AUTO_UPDATE2.M with the given input arguments.
%
%      MANUAL_AUTO_UPDATE2('Property','Value',...) creates a new MANUAL_AUTO_UPDATE2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Manual_auto_update2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Manual_auto_update2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Manual_auto_update2

% Last Modified by GUIDE v2.5 06-Feb-2020 15:54:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Manual_auto_update2_OpeningFcn, ...
    'gui_OutputFcn',  @Manual_auto_update2_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before Manual_auto_update2 is made visible.
function Manual_auto_update2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Manual_auto_update2 (see VARARGIN)
handles.Box = [handles.Box1, handles.Box2, handles.Box3, ...
    handles.Box4, handles.Box5, handles.Box6, handles.Box7, handles.Box8];
set(handles.certifyButton, 'enable', 'off');
set(handles.manualPanel, 'visible', 'off');
set(handles.autoPanel, 'visible', 'off');
set(handles.manualButton, 'enable', 'off');
set(handles.AutoButton, 'enable', 'off');
% Choose default command line output for Manual_auto_update2
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Manual_auto_update2 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Manual_auto_update2_OutputFcn(hObject, eventdata, handles)
addpath('RFID chip reader\RfidChipData');
filename = 'CorrectedRFIDValues.xlsx';
[~, sheets] = xlsfinfo(filename);
% decision = fscanf(tags{portidx});
% [decision, receivedcount] = fscanf(tags{portidx});
delete(instrfind());
deciding_port = serialport('COM3', 9600);
deciding_data = readline(deciding_port)
while strlength(deciding_data) < 24
   deciding_data = readline(deciding_port)
   pause(.2)
end
% decision = waitfor(readline(deciding_port), strlength(readline(deciding_port)), 24);
% if receivedcount < 24
%     error('Received less data than expected. Received data was: %s', decision)
% end
%now we know we've got at least 24 characters. 
extracted_data = extractAfter(deciding_data, 10);
extracted_data = extractBefore(extracted_data, 13);
extracted_data = regexprep(extracted_data,'[\n\r]+','');
extracted_data = regexp(extracted_data, '[ -~]+', 'match', 'once');
extracted_data = strtrim(extracted_data);
extracted_data = char(extracted_data);
rows_found = [];
sheets_found = {};
for K = 1 : length(sheets)
    this_sheet = sheets{K};
    [~, ~, raw] = xlsread(filename, this_sheet);
    [rowNum, colNum] = find( strcmp(extracted_data, raw));
    if ~isempty(rowNum)
        rows_found = [rows_found; rowNum];
        sheets_found = [sheets_found; repmat({this_sheet}, length(rowNum), 1)];
    end
end

clear deciding_port
instrreset;
delete(instrfind());
portlist = {'COM3', 'COM4', 'COM5', 'COM6'}; % , 'COM4', 'COM5', 'COM6'
nport = length(portlist);
tags = cell(1, nport);
cleanups = cell(1, nport);
for portidx = 1 : nport
    delete(instrfind('Port', portlist{portidx})); % removes possibility for 'Port not available' error
    tags{portidx} = serial(portlist{portidx}); %initializes the port to be used
    fopen(tags{portidx}); %opens th eport
    %     cleanups{portidx} = onCleanup(@() fclose(portlist{portidx}));
    cleanups{portidx} = onCleanup(@() fclose('all'));
end
BOX = char(zeros(8,12)); % matrix to be populated with incoming serial data
addpath('RFID chip reader\RfidChipData');
% location of stored master tags
[~, ~, TrueValMat] = xlsread(filename, char(sheets_found));
% Creates matrix filled with the correct values
% indexed by box, which is the first row
% all proceeding rows are the master value
for i=1:inf
    pause(0.01)
    %     for n = 1:2
    for portidx = 1 : nport
        nbase = portidx * 2 - 1;
        for n = nbase:nbase+1
            if i>10 % positive reading
                %             readData = fscanf(tag);
                readData = fscanf(tags{portidx});
                if length(readData)>12
                    BOX(str2double(readData(8)),1:12)= readData(11:22);
                    if strcmp(TrueValMat{2,n}, BOX(n,:)) %cannot sub-index to CELL types normally, must use this method
                        set(handles.Box(n), 'BackgroundColor', 'g');
                    else
                        set(handles.Box(n), 'BackgroundColor', 'r');
                    end
                    drawnow % allows GUI to update the appearance whenever the loop completes.
                    if ~( strcmp(TrueValMat{2,1}, BOX(1,:))...
                            && strcmp(TrueValMat{2,2}, BOX(2,:))...
                            && strcmp(TrueValMat{2,3}, BOX(3,:))...
                            && strcmp(TrueValMat{2,4}, BOX(4,:))...
                            && strcmp(TrueValMat{2,5}, BOX(5,:))...
                            && strcmp(TrueValMat{2,6}, BOX(6,:))...
                            && strcmp(TrueValMat{2,7}, BOX(7,:))...
                            && strcmp(TrueValMat{2,8}, BOX(8,:)))
                        set(handles.certifyButton, 'enable', 'on');
                    end
                end
            end
        end
    end
end
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in certifyButton.
function certifyButton_Callback(hObject, eventdata, handles)
set(handles.manualButton, 'enable', 'on');
set(handles.AutoButton, 'enable', 'on');
% hObject    handle to certifyButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in manualButton.
function manualButton_Callback(hObject, eventdata, handles)
set(handles.manualPanel, 'visible', 'on');
set(handles.autoPanel, 'visible', 'off');
% hObject    handle to manualButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in AutoButton.
function AutoButton_Callback(hObject, eventdata, handles)
set(handles.autoPanel, 'visible', 'on');
set(handles.manualPanel, 'visible', 'off');
% hObject    handle to AutoButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


function stage_edit_Callback(hObject, eventdata, handles)
% hObject    handle to stage_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of stage_edit as text
%        str2double(get(hObject,'String')) returns contents of stage_edit as a double


% --- Executes during object creation, after setting all properties.
function stage_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to stage_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function session_edit_Callback(hObject, eventdata, handles)
% hObject    handle to session_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of session_edit as text
%        str2double(get(hObject,'String')) returns contents of session_edit as a double


% --- Executes during object creation, after setting all properties.
function session_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to session_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function list_edit_Callback(hObject, eventdata, handles)
% hObject    handle to list_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of list_edit as text
%        str2double(get(hObject,'String')) returns contents of list_edit as a double


% --- Executes during object creation, after setting all properties.
function list_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to list_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in manualCreation.
function manualCreation_Callback(hObject, eventdata, handles)
addpath('RFID chip reader\EXPT1\1',...
    'RFID chip reader\EXPT1\2',...
    'RFID chip reader\EXPT1\3',...
    'RFID chip reader\EXPT1\4',...
    'RFID chip reader\EXPT2\1',...
    'RFID chip reader\EXPT2\2',...
    'RFID chip reader\EXPT2\3',...
    'RFID chip reader\EXPT2\4');
root = 'RFID chip reader';
%ensure you are entering just the number, and nothing else, including
%spaces before or after, as this will throw an error.
user_input_exp = char(sheets_found);
user_input_squad = char(rows_found);
filepath = fullfile(root, sprintf('EXPT%s', user_input_exp), user_input_squad, sprintf('EXP%s_SQ%s_Template.txt', user_input_exp, user_input_squad));
% the line baove is the full path, allowing for user input. it goes:
% root\EXPT(user_input_exp)\(user_input_squad)\EXPT(user_input_exp)_SQ(user_input_squad)_Template.txt
if isempty(user_input_exp)|| isempty(user_input_squad)
    return
end
if ~exist(filepath, 'file')
    errordlg(sprintf('file location does not exist, "%s"', filepath), 'Error Dialog', 'modal')
    return
end
Mac_Templ = importdata(filepath);
user_input_stage = handles.stage_edit.String;
todaysMac = Mac_Templ;
todaysMac = strrep(todaysMac, '(m)', user_input_stage);
user_input_session = handles.session_edit.String;
todaysMac = strrep(todaysMac, '(n)', user_input_session);
user_input_list = handles.list_edit.String;
todaysMac = strrep(todaysMac, '(x)', user_input_list);
todaysMac = string(todaysMac); % RAMI: this is the troublesome line. Rami successfully fixed it. "I am proud of you, Rami." "Thanks, Rami."
todaysMac = compose(todaysMac); % There was an issue with the files, where
% the output would be in a single line. this fixes it, by using the escape
% characters located at the end of each lin in the templae (\n), compose
% basically reads those as a command, placing each box into a new line.
fid = fopen(fullfile('RFID chip reader\Completed_Macros', sprintf('squad%s_1910_EXP%s_St%s_Se%s.mac', user_input_exp, user_input_squad, user_input_stage, user_input_session)), 'wt'); % Makes a new file in
%specified directory, with specified name and format at the end. saving a
%second file with the same name will overwrite older file.
fprintf(fid, '%s', todaysMac);
fclose(fid);
disp('Done');
% hObject    handle to manualCreation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in auto_update.
function auto_update_Callback(hObject, eventdata, handles)
root = 'RFID chip reader\Completed_Macros';
user_input_squad = char(rows_found);
user_input_experiment = char(sheets_found);
user_input_stage = input('please enter stage: ', 's');
user_input_session = input('please enter session: ', 's');
file = fullfile(root, sprintf('squad%s_1910_EXP%s_St%s_Se%s.mac', user_input_squad, user_input_experiment, user_input_stage, user_input_session));
%update display with yesterdays macro
used_macro = sprintf('squad%s_1910_EXP%s_St%s_Se%s.mac', user_input_squad, user_input_experiment, user_input_stage, user_input_session);
handles.macro_display.String = used_macro;
drawnow;
%get raw content of file as text
filetext = fileread(file);
%increase number after Se by 1, and increase last number modulo 5.
newtext = regexprep(filetext, '(?<=Se)(\d+)(.*)(\d+)(?=[\n\r]|$)', ...
    '${num2str(str2double($1)+1)}$2${num2str(mod(str2double($3), 5)+1)}', ...
    'dotexceptnewline');
%generate new file name
newfile = fullfile(root, sprintf('squad%s_1910_EXP%s_St%s_Se%s.mac', user_input_squad, user_input_experiment, user_input_stage, user_input_session+1));
%and write new text
fid = fopen(newfile, 'w');
fwrite(fid, newtext);
fclose(fid);
% delete(file);
% hObject    handle to auto_update (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
