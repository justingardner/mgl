function varargout = mglTestGammaGUI(varargin)
% mglTestGammaGUI M-file for mglTestGammaGUI.fig
%      mglTestGammaGUI, by itself, creates a new mglTestGammaGUI or raises the existing
%      singleton*.
%
%      H = mglTestGammaGUI returns the handle to a new mglTestGammaGUI or the handle to
%      the existing singleton*.
%
%      mglTestGammaGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in mglTestGammaGUI.M with the given input arguments.
%
%      mglTestGammaGUI('Property','Value',...) creates a new mglTestGammaGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before mglTestGammaGUI_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to mglTestGammaGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help mglTestGammaGUI

% Last Modified by GUIDE v2.5 30-Jun-2006 09:07:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @mglTestGammaGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @mglTestGammaGUI_OutputFcn, ...
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


% --- Executes just before mglTestGammaGUI is made visible.
function mglTestGammaGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to mglTestGammaGUI (see VARARGIN)

% Choose default command line output for mglTestGammaGUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes mglTestGammaGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = mglTestGammaGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% set the edit box to display gamma
set(handles.edit1,'String',num2str(get(hObject,'Value')));
gammaValue = get(hObject,'Value');
mglSetGammaTable(0,1,gammaValue,0,1,gammaValue,0,1,gammaValue);
% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function edit1_Callback(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit1 as text
%        str2double(get(hObject,'String')) returns contents of edit1 as a double
val = str2double(get(hObject,'String'));
% Determine whether val is a number in range of slider
if isnumeric(val) && length(val)==1 && ...
   val >= get(handles.slider1,'Min') && ...
   val <= get(handles.slider1,'Max')
   % set the slider
   set(handles.slider1,'Value',val);
   % and change the monitor gamma
   mglSetGammaTable(0,1,val,0,1,val,0,1,val);
else
  %set edit back to slider value
  set(hObject,'String',num2str(get(handles.slider1,'Value')));

end

% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% reset gamma and close screen

mglClose;

delete(handles.figure1);
