%% freq_to_mass_converter.m
% 
% Converts cylcotron frequencies of an ion of interest and known reference
% ion into a mass value for the ion of interest. A part of PhIAT.
%
% Language: MATLAB
%
% Sam Porter (wporter@triumf.ca)
% University of British Columbia
% TRIUMF, on behalf of the TITAN Collaboration
% 
% v1.0 -- Completed by W.S. Porter
%
% last updated on 4/16/2021
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function varargout = freq_to_mass_converter(varargin)
% FREQ_TO_MASS_CONVERTER MATLAB code for freq_to_mass_converter.fig
%      FREQ_TO_MASS_CONVERTER, by itself, creates a new FREQ_TO_MASS_CONVERTER or raises the existing
%      singleton*.
%
%      H = FREQ_TO_MASS_CONVERTER returns the handle to a new FREQ_TO_MASS_CONVERTER or the handle to
%      the existing singleton*.
%
%      FREQ_TO_MASS_CONVERTER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in FREQ_TO_MASS_CONVERTER.M with the given input arguments.
%
%      FREQ_TO_MASS_CONVERTER('Property','Value',...) creates a new FREQ_TO_MASS_CONVERTER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before freq_to_mass_converter_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to freq_to_mass_converter_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help freq_to_mass_converter

% Last Modified by GUIDE v2.5 24-Apr-2020 11:16:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @freq_to_mass_converter_OpeningFcn, ...
                   'gui_OutputFcn',  @freq_to_mass_converter_OutputFcn, ...
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


% --- Executes just before freq_to_mass_converter is made visible.
function freq_to_mass_converter_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to freq_to_mass_converter (see VARARGIN)

% Choose default command line output for freq_to_mass_converter
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes freq_to_mass_converter wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = freq_to_mass_converter_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Functions In Use
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% --- Executes on button press in convert.
function convert_Callback(hObject, eventdata, handles)
% hObject    handle to convert (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

va = str2double(get(handles.ioi_wc,'String'));; %Unknown Frequency -- varies
da = str2double(get(handles.ioi_error,'String'));; %Error of Unknown Frequency -- varies

%mea = -61338

vb = str2double(get(handles.calib_wc,'String'));; %Known Frequency -- varies
db = str2double(get(handles.calib_error,'String'));; %Error of Known Frequency -- varies

qa = str2double(get(handles.ioi_q,'String'));; %Unknown Mass Charge -- varies
qb = str2double(get(handles.calib_q,'String'));; % Known Mass Charge -- varies

me = .000548579909067; % Electron Mass AMU
mb = str2double(get(handles.calib_mass,'String'));; %Known Mass AMU -- varies
mb = mb*10^-6;

dme = 0; %Error Mass of an Electron AMU
dmb = str2double(get(handles.calib_mass_error,'String')); %Error Mass of Known Mass AMU -- varies
dmb = dmb*10^-6;

iso = str2double(get(handles.ioi_A,'String'));; %Unknown Isotope number -- varies
amu2mev=931.4940954; %Converts AMU to MeV
mev2kev=1000; %Converts MeV to KeV


%Mass and Error Calculation

ma = (qa * (mb - qb * me) * vb)/(qb * va)
mea = ma *amu2mev*mev2kev  - (amu2mev*mev2kev * iso);

% Finding Unknown Frequency va %

%ma = (mea + (amu2mev*mev2kev * iso))/(amu2mev*mev2kev)
%va = (qa * (mb - qb * me) * vb)/(qb*(ma-qa*me))

dma = amu2mev* mev2kev * sqrt(  ((qa*vb)/(qb*va))^2 * dmb^2 +  ( (qa*(mb - qb * me ) / (qb* va))^2 * db^2) + ( (qa*(mb - qb * me ) * vb / (qb* va^2))^2 * da^2) + ( (qa - vb/va)^2 * dme^2));

ma = 10^6 * ma
ma_unc = dma/(amu2mev* mev2kev)*10^6

set(handles.ioi_me,'String',num2str(mea));
set(handles.ioi_me_error,'String',num2str(dma));

function ioi_wc_Callback(hObject, eventdata, handles)
% hObject    handle to ioi_wc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ioi_wc as text
%        str2double(get(hObject,'String')) returns contents of ioi_wc as a double


% --- Executes during object creation, after setting all properties.
function ioi_wc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ioi_wc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ioi_error_Callback(hObject, eventdata, handles)
% hObject    handle to ioi_error (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ioi_error as text
%        str2double(get(hObject,'String')) returns contents of ioi_error as a double


% --- Executes during object creation, after setting all properties.
function ioi_error_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ioi_error (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ioi_q_Callback(hObject, eventdata, handles)
% hObject    handle to ioi_q (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ioi_q as text
%        str2double(get(hObject,'String')) returns contents of ioi_q as a double


% --- Executes during object creation, after setting all properties.
function ioi_q_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ioi_q (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ioi_A_Callback(hObject, eventdata, handles)
% hObject    handle to ioi_A (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ioi_A as text
%        str2double(get(hObject,'String')) returns contents of ioi_A as a double


% --- Executes during object creation, after setting all properties.
function ioi_A_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ioi_A (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ioi_me_Callback(hObject, eventdata, handles)
% hObject    handle to ioi_me (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ioi_me as text
%        str2double(get(hObject,'String')) returns contents of ioi_me as a double


% --- Executes during object creation, after setting all properties.
function ioi_me_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ioi_me (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ioi_me_error_Callback(hObject, eventdata, handles)
% hObject    handle to ioi_me_error (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ioi_me_error as text
%        str2double(get(hObject,'String')) returns contents of ioi_me_error as a double


% --- Executes during object creation, after setting all properties.
function ioi_me_error_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ioi_me_error (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function calib_wc_Callback(hObject, eventdata, handles)
% hObject    handle to calib_wc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of calib_wc as text
%        str2double(get(hObject,'String')) returns contents of calib_wc as a double


% --- Executes during object creation, after setting all properties.
function calib_wc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to calib_wc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function calib_error_Callback(hObject, eventdata, handles)
% hObject    handle to calib_error (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of calib_error as text
%        str2double(get(hObject,'String')) returns contents of calib_error as a double


% --- Executes during object creation, after setting all properties.
function calib_error_CreateFcn(hObject, eventdata, handles)
% hObject    handle to calib_error (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function calib_q_Callback(hObject, eventdata, handles)
% hObject    handle to calib_q (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of calib_q as text
%        str2double(get(hObject,'String')) returns contents of calib_q as a double


% --- Executes during object creation, after setting all properties.
function calib_q_CreateFcn(hObject, eventdata, handles)
% hObject    handle to calib_q (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function calib_mass_Callback(hObject, eventdata, handles)
% hObject    handle to calib_mass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of calib_mass as text
%        str2double(get(hObject,'String')) returns contents of calib_mass as a double


% --- Executes during object creation, after setting all properties.
function calib_mass_CreateFcn(hObject, eventdata, handles)
% hObject    handle to calib_mass (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function calib_mass_error_Callback(hObject, eventdata, handles)
% hObject    handle to calib_mass_error (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of calib_mass_error as text
%        str2double(get(hObject,'String')) returns contents of calib_mass_error as a double


% --- Executes during object creation, after setting all properties.
function calib_mass_error_CreateFcn(hObject, eventdata, handles)
% hObject    handle to calib_mass_error (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
