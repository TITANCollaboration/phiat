%% PhIAT.m
% 
% Phase-Imaging Analysis Tool (PhIAT) is an analysis suite that determines the cyclotron frequency of ions in a Penning trap, measured
% through PI-ICR, by fitting Guassians to positions recorded on an PS-MCP.
%
% Language: MATLAB
%
% Created by Sam Porter, Updated by Annabelle Czihaly
% TRIUMF, on behalf of the TITAN Collaboration
% 
% v2.0 -- Completed by Annabelle Czihaly
%
% last updated on 11/10/2024
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initialization Functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% The following functions initialize the GUI created in GUIDE, and are
% constructed by MATLAB. DO NOT EDIT!
%
%%

function varargout = PhIAT(varargin)
% PHIAT MATLAB code for PhIAT.fig
%      PHIAT, by itself, creates a new PHIAT or raises the existing
%      singleton*.
%    
%      H = PHIAT returns the handle to a new PHIAT or the handle to
%      the existing singleton*.
%
%      PHIAT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PHIAT.M with the given input arguments.
%       
%      PHIAT('Property','Value',...) creates a new PHIAT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before PhIAT_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to PhIAT_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PhIAT

% Last Modified by GUIDE v2.5 27-Mar-2024 09:51:25

% Begin initialization code - DO NOT EDIT

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PhIAT_OpeningFcn, ...
                   'gui_OutputFcn',  @PhIAT_OutputFcn, ...
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


% --- Executes just before PhIAT is made visible.
function PhIAT_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to PhIAT (see VARARGIN)

% Choose default command line output for PhIAT
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes PhIAT wait for user response (see UIRESUME)
% uiwait(handles.radialfittingbuttongroup);


% --- Outputs from this function are returned to the command line.
function varargout = PhIAT_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Functions In Use
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% The following functions are GUI object functions that have been manually
% written.
%
% Global Variables
%
% spot_x (array): X positions of the spots in the loaded files.
%
% spot_y (array): Y positions of the spots in the loaded files.
%
% spot_t (array): Accumulation times of the spots in the loaded
% files.
%
% spot_trigger (array): Refers to the time, referenced to the time the file was initialized,
% at which the ions exit the Penning trap and enter the ToF tube.
%
% spot_r (array): Refers to the radial position, from the trap's center, at
% which a spot is.
%
% spot_phi (array): Refers to the angle, in reference to the trap's center,
% at which a spot is.
%
% number_of_files (int): Refers to the total number of files being
% fit (i.e. the total number of files in the list of files CSV).
%
% file_number_counter (index): Refers to which file number is currently
% being fit/analyzed.
% 
% data_files (array): A list of the directories of the files you are
% analyzing.
%
% tacc_list (array): A list of the accumulation times of the files you are
% analyzing.
%
% tacc_list_counter (index): Counts what accumulation time within the list
% of files you're currently analyzing.
%
% angle_list (array): List of the angles of the different spots.
%
% radius_list (array): List of the radii of the different spots.
%
% number_of_ions (int): Total number of ions in a given file.
%
% ion_percent_list (array): List of the ion percentages of the spots in our
% files.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Automatic Fitting Functions %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Functions used in the automatic fitting of spots (via Mean Shift
% Clustering) and subsequent determination of cyclotron frequencies
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Functions for Select File(s) Button
% --- Executes on button press in select file(s) for analysis button.
%added start


centerrorx = 0.02; % Uncertainty on Trap Center
centerrory = 0.02; 


global path
function open_list_of_files_button_Callback(hObject, eventdata, handles) %added

[file, path] = uigetfile({'*.*', 'All files (*.*)'; 
    '*.csv','FileList (simulated data or pre-converted to PhIAT format) (*.csv*)'; 
    '*.mid.lz4','Raw data from MPET (*.mid.lz4*)'}, 'Select file(s) for analysis', 'MultiSelect', 'on');
%disp(file)

py3_path = '\Users\aczihaly\AppData\Local\anaconda3\python.exe';
currentDateTime = datestr(now, 'yyyy-mm-dd_HH-MM-SS');

% Check if user clicked Cancel
if isequal(file,0) || isequal(path,0)
    disp('User clicked Cancel.');
    return;
end

if endsWith(file, '.csv') %check if selected file ends with .csv
    if endsWith(file, 'File_List.csv')
        result = fullfile(path,file);
    else 
        disp('User selected a random .csv file, not that of the form XFile_List.csv. Please try again.');
        return;
    end
    
else %if .csv was not selected...
    %disp('The file does not end with ".csv"');

    if ischar(file) % For compatibility with older MATLAB versions, or isstring for newer ones
        file = {file}; % Wrap the single file path in a cell array
    end
    file_directory = fullfile(path);

    allEndWithMidLz4 = true;
        % Process each file in the cell array
        for i = 1:numel(file)
            if ~endsWith(file{i}, '.mid.lz4')
                allEndWithMidLz4 = false;
                break;
            end
        end
        
        if allEndWithMidLz4
            disp('All selected files end with .mid.lz4');
            file_directory = path;
            disp(file)



            % Create a new subdirectory

                        % Get current date and time
            
            
            % Create directory with current date and time
            %subDir=strcat(file_directory,'results'); % in future, make this a date and time 
            subDir = strcat(file_directory, 'results_', currentDateTime);
            mkdir(subDir);
            
            % Iterate over the files and copy each into the subdirectory
            
            for i = 1:length(file)
            
                copyfile(fullfile(file_directory, file{i}), subDir);
            
            end

            [status,result] = system([py3_path ' midas_to_phiat.py ' subDir]); 
            disp(result)

        else
            disp('Error: Not all selected files end with .mid.lz4. Please retry and only select files ending in .mid.lz4');
            return;
        end

end

%% Functions for Load List of Files Button
% --- Executes on button press in list_of_files_load_button.
%

%function list_of_files_load_button_Callback(hObject, eventdata, handles)
% hObject    handle to list_of_files_load_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global number_of_files data_files file_number_counter tacc_list tacc_list_counter angle_list radius_list ion_percent_list3 path

%file_directory = get(handles.list_of_files_text,'String'); % Either address to directory of MIDAS Files or a File_List.csv
%py3_path = '\Users\aczihaly\AppData\Local\anaconda3\python.exe'; % Local address to python3. NEW USERS NEED TO CHANGE! %

%if file_directory(size(file_directory,2)-3:size(file_directory,2)) == '.csv' % If the string is a path to a TaccList (i.e. .csv ending), skip Midas to PhIAT conversion
%    result = file_directory;
%else
%    [status,result] = system([py3_path ' midas_to_phiat.py ' file_directory])
%end
%disp(result)
list_of_files = result; % For this to function properly, the only thing printed by midas_to_phiat.py must be target_file
%disp(list_of_files)
file_list = fopen(list_of_files);
%disp(file_list)
data_files = textscan(file_list, '%s %f %f', 'delimiter',','); % Scan .csv which contains the directories of the files to be analyzed

length_of_filelist = size(data_files{1});
number_of_files = length_of_filelist(1);

set(handles.filename, 'String', data_files{1}{1});

file_number_counter = 1; % Keeps track of file number for manual fitting process

tacc_list = data_files{2};

tacc_list_counter = 1; % Keeps track of accumulation times for manual fitting

angle_list = []; % List of angles of spots from manual fitting

ion_percent_list = []; % List of percentage of total counts for spots from manual fitting
radius_list = []; % List of radii of spots from manual fitting
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Functions for Load File Button
% --- Executes on button press in load. Loads each individual data file.
%
function load_Callback(hObject, eventdata, handles)
% hObject    handle to load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    global spot_x spot_y spot_t spot_trigger spot_r spot_phi total_ion_time number_of_ions;
    
    files = get(handles.filename,'String'); % Read-in data from a file
    data_file = files; 
    spot_data = csvread(data_file,1);
    spot_x= spot_data(:,1); % X Position Data
    spot_y= spot_data(:,2); % Y Position Data
    spot_t= spot_data(:,3); % ToF data
    spot_trigger= spot_data(:,4); % Data for which trigger cycle a count came during
    center_x = get(handles.tcx,'String'); % Trap Center X
    center_y = get(handles.tcy,'String'); % Trap Center Y
    center_x = str2double(center_x);
    center_y = str2double(center_y);
    centerrorx = 0.002; % Uncertainty on Trap Center
    centerrory = 0.002; 
    
    number_of_ions = length(spot_x); % Total number of counts in the file
    set(handles.ion_number_text,'String',num2str(number_of_ions));
    
    
    
    % Convert X & Y to Phi %%

numcounts_phi = size(spot_t);
snow = 1;
spot_phi= spot_x;
spot_r= spot_x;

while snow <= numcounts_phi(1) % Angles converted into degrees b/t 0 and 360 
    
    spot_r(snow) = sqrt( (spot_x(snow) - center_x)^2 + (spot_y(snow) - center_y)^2); % Radius of spot (distance between trap center and count position)
   
    if spot_y(snow) > center_y
        if spot_x(snow) > center_x
            % Polar Angle b/t 0 to 90
            spot_phi(snow) = atand ( (spot_y(snow)- center_y)/(spot_x(snow) - center_x));
        elseif spot_x(snow) < center_x
            % Polar Angle b/t 90 to 180
            spot_phi(snow) = atand ( (spot_y(snow)- center_y)/(spot_x(snow) - center_x)) + 180;

            
        end
    
    elseif spot_y(snow) < center_y
        if spot_x(snow) < center_x
        % Polar Angle b/t 180 to 270
        spot_phi(snow) = atand ( (spot_y(snow)- center_y)/(spot_x(snow) - center_x)) + 180;

        
        elseif spot_x(snow) > center_x
        % Polar Angle b/t 270 to 360
        spot_phi(snow) = atand ( (spot_y(snow)- center_y)/(spot_x(snow) - center_x)) + 360;
        
        end
    end
    
    snow = snow + 1;
end
   
    % Create Histograms of Data %%
    
    histogram(handles.tofgraph,spot_t,100);
    grid on
    scatter(handles.xygraph,spot_x,spot_y,'filled');
    grid off
    histogram(handles.xgraph,spot_x, 100)
    histogram(handles.ygraph,spot_y, 100)
    histogram(handles.radgraph,spot_r, 10)
    histogram(handles.phigraph,spot_phi,50)
    
    % Determine Rate of Ions %%

if handles.ionrate_onoff.Value % If Sim Ion Rate is checked (i.e. using simulated data with no time information), set dummy rate value.
    total_rate = 0.01;
    set(handles.ion_rate,'String',num2str(total_rate));
    total_ion_time = number_of_ions/total_rate; % Approximate total time over which ion events were recorded
else
    ion_rate_file = char(strcat(data_file(1:length(data_file)-4),'ion_rate.csv'));
    ion_rate_data = csvread(ion_rate_file,1);
    ion_rates = ion_rate_data(:,3); % Approximate ion rate of file in question
    
    total_rate = mean(ion_rates);
    set(handles.ion_rate,'String',num2str(total_rate));
    total_ion_time = number_of_ions/total_rate; % Approximate total time over which ion events were recorded
end 
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Functions for Automatic Fitting Button
% --- Executes on button press in auto. 
%
function auto_Callback(hObject, eventdata, handles)
% hObject    handle to auto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global number_of_files data_files spot_x spot_y spot_r spot_phi spot_t tacc_list spot_trigger total_ion_time number_of_ions path

i = 1;
j = 1;

center_x = get(handles.tcx,'String'); % Spatial center of the trap
center_y = get(handles.tcy,'String');
center_x = str2double(center_x);
center_y = str2double(center_y);
centerrorx = 0.02; % Uncertainty on Trap Center
centerrory = 0.02; 

target_path = uigetdir('', 'Select a folder to save your results'); %added
%disp(target_path) %added
target = fullfile(target_path); %added
%disp(target) %added 
%target = path; % Directory of folder to save results in
% target = get(handles.target,'String'); % Directory of folder to save results in
element = get(handles.isotope,'String'); % Isotope of interest
date = get(handles.date,'String'); % Date file was taken
timeintrap = get(handles.tit,'String'); % Total time spent in the trap
spot = get(handles.ac,'String'); % Gaussian center of angle distribution in degrees
sep = '_';

spot_centers = [];
while i <= number_of_files; % Loop through files in list of files
    set(handles.filename, 'String',data_files{1}{i})
    handles = guidata(hObject);
    cb  = get(handles.load, 'Callback');
    
    % Load File %%
    
    % Run the Load File Button code to load each individual data file %
    
    fake_event = [];
    if ischar(cb)
        evalin('base', cb);
    elseif iscell(cb)
        cb{1}(handles.load, fake_event, cb{2:end});
    elseif isa(cb, 'function_handle')
        cb(handles.load, fake_event);
    else
        error('callback was wrong class, was %s', class(cb));
    end
    
    % ToF Cut %%
    
    % Perform a rough time-of-flight cut on the data as input by the user %
    
     tlb0 = get(handles.tlb,'String');
     tup0 = get(handles.tub,'String');
     tlb0 = str2double(tlb0);
     tup0 = str2double(tup0);
     t_lower = tlb0;
     t_upper = tup0;

    numcounts_tof1 = size(spot_t);
    x = 1;
    counter1 = 1;
    real_tof1 = 0;

    while counter1 <= numcounts_tof1(1)
        if (spot_t(x) >= t_lower) && (spot_t(x) <= t_upper) % If the count's ToF is in our bounds, keep that count
            real_tof1 = real_tof1 + 1;
            x = x + 1;
        else
            spot_x(x) = []; % Otherwise, throw that count away
            spot_y(x) = [];
            spot_t(x) = [];
            spot_trigger(x) = [];
            spot_r(x) = [];
            spot_phi(x) = [];
        end

        counter1 = counter1 + 1;
    end
    
    %% Mean Shift Clustering %%
    
    % Determine spots from data using the Mean Shift Clustering algorithm,
    % contained within MeanShiftCluster.m
    
    data = cat(2,spot_x,spot_y);
    data_t = transpose(data);

    [centers,data2cluster,cluster2dataCell] = MeanShiftCluster(data_t,str2double(get(handles.bandwidth,'String'))); % Cluster data using Mean Shift method

    [dim_cent,len_cent] = size(centers);
    [dim_dataclust,len_dataclust] = size(data2cluster);
    
    k = 1;
    k_color = 1;
    cVec = {'#5DADE2','#9B59B6','#1D8348','#00FFFF','#FFCCFF','#9933FF','#82E0AA','#EB6E60','#000000','#660066','#FFFF99','#732626','#66FF33'};
    color_word = {'Cerulean','Magenta','Green','Cyan','Pink','Indigo','Light Green','Light Red','Black','Dark Purple','Yellow','Brown','Lime Green'};
    
    myClustCen_list = [];
    while k <= len_cent
        myMembers = cluster2dataCell{k}; % Grab all counts corresponding to a cluster
        [dim_mM,len_mM] = size(myMembers);
        figure(i)
        ppc = str2double(get(handles.ppc,'String'));
        
        if len_mM > ppc % If a cluster has ppc or more members, we identify it and consider it a spot. THIS CUTOFF CAN CHANGE!
            myClustCen = centers(:,k);
            myClustCen_T = transpose(myClustCen);
            str = cVec{k_color};
            
            %data(myMembers,1)
            
            [paramx,paramx_CI] = mle(data(myMembers,1),'distribution','norm','alpha',0.32); % Fit a 1D Gaussian to the X/Y coords. of each cluster to determine position via MLE
            [paramy,paramy_CI] = mle(data(myMembers,2),'distribution','norm','alpha',0.32);
            mux = paramx(1);
            sigmax = paramx(2);
            muy = paramy(1);
            sigmay = paramy(2);
            stderrx = (paramx_CI(2) - paramx_CI(1))/2; % Half of our 1sigma confidence interval is our uncertainty on position
            stderry = (paramy_CI(2) - paramy_CI(1))/2;
            
            %stderrx = sigmax/sqrt(len_mM) % In the case of purely Gaussian data distribution, this is also our position uncertainty 
            %stderry = sigmay/sqrt(len_mM)
            
            ion_rate = len_mM/total_ion_time; % Average rate of a given spot
            percentage = len_mM/number_of_ions; % Percentage of total ions of a given spot

            data_line = cat(2,mux,muy,stderrx,stderry,k_color,i,ion_rate,percentage); 
            myClustCen_list = cat(1,myClustCen_list,data_line);
            color = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
            
            scatter(data(myMembers,1),data(myMembers,2),'MarkerEdgeColor',color,'MarkerFaceColor',color,'DisplayName',color_word{k_color}) 
            hold on
            plot(mux,muy,'Marker','o','MarkerEdgeColor','w','MarkerFaceColor','k','MarkerSize',7,'HandleVisibility','off') % Mean from MLE as center instead of Mean Shift centers
            hold on
            %plot(myClustCen(1),myClustCen(2),'Marker','o','MarkerEdgeColor','k','MarkerFaceColor','w','MarkerSize',10,'HandleVisibility','off')
            %hold on % Use this instead of the above if you would like mean
            %shift cluster centers plotted instead
            
            k_color = k_color + 1;
        else
            scatter(data(myMembers,1),data(myMembers,2),'b','filled','HandleVisibility','off') % If a cluster has less than 10 members, we don't consider it a spot but still plot those data
            hold on
        end
    
        k = k + 1;
      
    end
    
    hold off
    
    legend('Location','northeast')
    
    spot_centers = cat(1,spot_centers,myClustCen_list); 
    i = i + 1;
end

%% Data Structuring %%

% Structure our spot position and angle data for future generation into
% frequencies

    % Initializing Data %%
    
centerx = str2double(get(handles.tcx,'String')); % Trap center pulled from GUI
centery = str2double(get(handles.tcy,'String')); 
x_val = spot_centers(:,1); 
y_val = spot_centers(:,2);
x_err = spot_centers(:,3);
y_err = spot_centers(:,4);
spot_colors = spot_centers(:,5);
file_num_list = spot_centers(:,6); % Number of file in which each spot is found
ion_rates = spot_centers(:,7); % Approximate ion rate (# of ions over length of file's time determined from ion rates at n-second intervals w/ n defined in midas_to_phiat.py)
ion_percent = spot_centers(:,8); % Percent of total ions in a given spot (unnormalized)

[len_x_val,dim_x_val] = size(x_val);

    % Spot Angle Creation %%
    
phi_val = zeros(len_x_val,1); % List of angles of spots (w.r.t to the trap center (centerx,centery))
phi_val_err = zeros(len_x_val,1); % added
for kk = 1:len_x_val
    if y_val(kk) > centery
            if x_val(kk) > centerx
                % Spot in between 0 to 90
                phi_val(kk) = atand ((y_val(kk)- centery)/(x_val(kk) - centerx));
                phi_val_err(kk) = sqrt(( (-y_val(kk)+centery)/((x_val(kk)-centerx)^2+(y_val(kk)-centery)^2)*x_err(kk))^2+((x_val(kk)+centerx)/((x_val(kk)-centerx)^2+(y_val(kk)-centery)^2)*y_err(kk))^2)*180/pi;

            elseif x_val(kk) < centerx
                % Spot in between 90 to 180
                phi_val(kk) = atand ((y_val(kk)- centery)/(x_val(kk) - centerx)) + 180;
                phi_val_err(kk) = sqrt(( (-y_val(kk)+centery)/((x_val(kk)-centerx)^2+(y_val(kk)-centery)^2)*x_err(kk))^2+((x_val(kk)+centerx)/((x_val(kk)-centerx)^2+(y_val(kk)-centery)^2)*y_err(kk))^2)*180/pi;

            end

        elseif y_val(kk) < centery
            if x_val(kk) < centerx
            % Spot in between 180 to 270
            phi_val(kk) = atand ( (y_val(kk)- centery)/(x_val(kk) - centerx)) - 180;
            phi_val_err(kk) = sqrt(( (-y_val(kk)+centery)/((x_val(kk)-centerx)^2+(y_val(kk)-centery)^2)*x_err(kk))^2+((x_val(kk)+centerx)/((x_val(kk)-centerx)^2+(y_val(kk)-centery)^2)*y_err(kk))^2)*180/pi;

            elseif x_val(kk) > centerx
            % Spot in between 270 to 360
            phi_val(kk) = atand ( (y_val(kk)- centery)/(x_val(kk) - centerx));
            phi_val_err(kk) = sqrt(( (-y_val(kk)+centery)/((x_val(kk)-centerx)^2+(y_val(kk)-centery)^2)*x_err(kk))^2+((x_val(kk)+centerx)/((x_val(kk)-centerx)^2+(y_val(kk)-centery)^2)*y_err(kk))^2)*180/pi;

            end
        end
end

    % Structure Data %%
list_refID = data_files{3}; % Reference file that is paired with each final file

ctr = 0;
for object = transpose(list_refID)
    if object >= 1
        ctr = ctr + 1; % Determine if the paired reference file number is a valid integer (final file) or NaN (reference file) to get the number of final files
    end
end

[len_listrefID,dim_listrefID] = size(list_refID);
num_act_files = ctr; % Total number of final files 

ref_idx = find(file_num_list == num_act_files + 1); % Find beginning of reference file data in our structures
ref_idx = ref_idx - 1; % ID of end of final file data

% added start
% if size is anything besides 1x1, error message
if length(ref_idx) ~= 1
    fprintf('ERROR: the size of ref_idx is not 1x1. Any other dimensions besides 1x1 indicate that more than 1 spot is being identified as the reference spot which is not ideal. This likely points to poor data, sorry xoxo.')
    return
end

% added end

x_val_act = x_val(1:ref_idx); % Creating final file data structures
y_val_act = y_val(1:ref_idx);
x_err_act = x_err(1:ref_idx);
y_err_act = y_err(1:ref_idx);
spot_colors_act = spot_colors(1:ref_idx);
file_num_list_act = file_num_list(1:ref_idx);
phi_val_act = phi_val(1:ref_idx);
phi_val_err_act = phi_val_err(1:ref_idx); %added

[len_x_val,dim_x_val] = size(x_val);
x_val_ref = x_val(ref_idx + 1:len_x_val); % Creating reference file data structures
y_val_ref = y_val(ref_idx + 1:len_x_val);
x_err_ref = x_err(ref_idx + 1:len_x_val);
y_err_ref = y_err(ref_idx + 1:len_x_val);
spot_colors_ref = spot_colors(ref_idx + 1:len_x_val);
file_num_list_ref = file_num_list(ref_idx + 1:len_x_val);
phi_val_ref = phi_val(ref_idx + 1:len_x_val);

x_val_ref_final = []; % Initializing lists for reference file data for each corresponding final file
y_val_ref_final = [];
x_err_ref_final = [];
y_err_ref_final = [];
spot_colors_ref_final = [];
time_ref_final = [];
time_act = [];
phi_val_ref_final = [];

for item = transpose(file_num_list_act)
    refID = list_refID(item); % Finding the reference file assigned to each final file
    x_val_ref_final = cat(1,x_val_ref_final,x_val_ref(refID)); % Creating a list of reference file data to match the final file data
    y_val_ref_final = cat(1,y_val_ref_final,y_val_ref(refID)); 
    x_err_ref_final = cat(1,x_err_ref_final,x_err_ref(refID));
    y_err_ref_final = cat(1,y_err_ref_final,y_err_ref(refID));
    spot_colors_ref_final = cat(1,spot_colors_ref_final,spot_colors_ref(refID));
    time_act = cat(1,time_act,tacc_list(item)); % Creating list of Tacc for each final file
    time_ref_final = cat(1,time_ref_final,tacc_list(num_act_files + refID)); % List of reference Tacc for each corresponding final Tacc
    phi_val_ref_final = cat(1,phi_val_ref_final,phi_val_ref(refID)); % List of angles of reference file spots
end

%% Frequency Generation %%

% Generate frequencies, radii and angles from spot positions

frequencycs = str2num(get(handles.w_c,'String')); % Guess Cyclotron Frequency

    % Trap Center %%
centerx = str2double(get(handles.tcx,'String')); 
centery = str2double(get(handles.tcy,'String'));
centerrorx = 0.02; % Uncertainty on Trap Center
centerrory = 0.02; 

    % Relevant Data %%

time = time_act;
refx = x_val_ref_final - centerx; % Shift origin to trap center for reference spots
refy = y_val_ref_final - centery; 
errorrx = (x_err_ref_final.^2 + centerrorx^2);
errorry = (y_err_ref_final.^2 + centerrory^2);
errorrx = errorrx.^.5; % Positional uncertainty is center and ref. spot error added in quadrature
errorry = errorry.^.5;
timeref = time_ref_final;
 

spot1x = x_val_act - centerx; % Shift origin to trap center for final spots
spot1y = y_val_act - centery;
error1x = (x_err_act.^2 + centerrorx^2); % Positional uncertainty is center and final spot error in quadrature
error1y = (y_err_act.^2 + centerrory^2);
error1x = error1x.^.5;
error1y = error1y.^.5;
 
centerx = 0; % Shift trap center to origin
centery = 0;

D = spot1x;
C1= spot1x;
Cref= spot1x;
n=spot1x;

A1= spot1x;
   
    % Generate Range of Num. Turns %%
n_range = str2num(get(handles.n_range,'String')); 

freq = zeros(ref_idx,n_range); 
efreq = zeros(ref_idx);

    % Generate List of Angles in Positive Degree Form %%
    
phi_act_pos = phi_val_act;
phi_ref_pos = phi_val_ref_final;

for l = 1:ref_idx
    if phi_val_act(l) < 0
        phi_act_pos(l) = phi_val_act(l) + 360;
    end
    if phi_val_ref_final(l) < 0
        phi_ref_pos(l) = phi_val_ref_final(l) + 360;
    end
end

  
j = 1;

while j <= ref_idx
 gbr = 1;
 letsgo = -(ceil(n_range/2));
 while gbr < n_range + 2
    floor(frequencycs * (time(j)-timeref(j))); % Determine the Num. Turns in our Freq. guess
    n(j,gbr) = floor(frequencycs * (time(j)-timeref(j))) + letsgo; % Determine Num. Turns around the Num. Turns of our Freq. guess
    gbr = gbr + 1;
    letsgo = letsgo + 1;
    
 end

    % Generate Spot Distances %%
    
D(j) = sqrt((spot1x(j)-refx(j))^2+(spot1y(j)-refy(j))^2); % Distance between an final spot and its reference spot

C1(j) = sqrt((centerx-spot1x(j))^2+(centery-spot1y(j))^2); % Distance from trap center to final spot

Cref(j) = sqrt((centerx-refx(j))^2+(centery-refy(j))^2); % Distance from trap center to reference spot

C1_error(j) = ((centerx-spot1x(j))^2 + (centery-spot1y(j))^2)^(-3/4)*sqrt((centerx-spot1x(j))^2*error1x(j)^2 + (centery-spot1y(j))^2*error1y(j)^2); % Uncertainty in radius determined by error propagation from positions
    
    % Generate Spot Angle %%
    
A1(j) = acos((-D(j)^2+C1(j)^2+Cref(j)^2)/(2*C1(j)*Cref(j))); % Angle between final and reference spot

j = j+1;

end

    % Determine Angle b/t Reference and Final Spot %%

k = 1;

while k <= ref_idx
    % w_c %%
    
    if (phi_act_pos(k) - phi_ref_pos(k) < 0) | (phi_act_pos(k) - phi_ref_pos(k) > 180) % Define angles from reference to final given counterclockwise motion  
        A1(k) = -A1(k) + 2*pi;
    end
    
    % w_minus %%
    
   
    %if (phi_ref_pos(k) - phi_act_pos(k) < 0) | (phi_ref_pos(k) - phi_act_pos(k) > 180)
    %    A1(k) = 2*pi - A1(k);
    %end
    
    k = k + 1;
end

    % Cyclotron Frequency from Num. Turns %%

i = 1;
j = 1;

while i <= ref_idx
    while j <= n_range
        freq(i,j) = (A1(i)+(2*pi*n(i,j)))/(2*pi*(time(i)-timeref(i))); % Determine the Freq. for a given Num. Turns
        
        j = j + 1;
    end

j = 1;
 
error1 = sqrt( (Cref(i)^4* ((spot1x(i)^2 * error1y(i)^2) + (spot1y(i)^2 * error1x(i)^2)) + C1(i)^4 * ((refx(i)^2 * errorry(i)^2) + (refy(i)^2 * errorrx(i)^2 ))))/(Cref(i) * C1(i))^2;

efreq(i) = error1/(2*pi*(time(i)-timeref(i))); % Determine frequency error from positional errors

i = i+1;

end

%% Create Spot ID %%

% Create table of potential frequencies for each spot given the range of
% turn numbers identified above.

color_word_act = {};
for i = spot_colors_act
    color_word_act = cat(1,color_word_act,color_word{spot_colors_act}); % Generate list of names of spot colors
end

[len_time,dim_time] = size(time);
[len_freq,dim_freq] = size(freq);

% original start
% ID_list = cell(len_time,dim_freq + 5); % Create table for ID_Frequencies.csv
%for i = 1:len_time
%    ID_list{i,1} = time(i);
%    ID_list{i,2} = color_word_act{i};
%    ID_list{i,3} = phi_val_act(i);
%    ID_list{i,4} = ion_rates(i);
%    ID_list{i,5} = ion_percent(i);
%    for j = 6:dim_freq+5
%        ID_list{i,j} = freq(i,j-5);
%    end
%end

%variable_names = cell(1,dim_freq+5);
%variable_names{1,1} = 'Tacc';
%variable_names{1,2} = 'Spot_Color';
%variable_names{1,3} = 'Angle';
%variable_names{1,4} = 'Ion_Rate';
%variable_names{1,5} = 'Ion_Percentage';
%for i = 6:dim_freq+5
%    str_name = strcat('Cyc_Freq_',num2str(i));
%    variable_names{1,i} = str_name;
%end

% original end

%added start

ID_list = cell(len_time,dim_freq + 6); % Create table for ID_Frequencies.csv
for i = 1:len_time
    ID_list{i,1} = time(i);
    ID_list{i,2} = color_word_act{i};
    ID_list{i,3} = phi_val_act(i);
    ID_list{i,4} = phi_val_err_act(i);
    ID_list{i,5} = ion_rates(i);
    ID_list{i,6} = ion_percent(i);
    for j = 7:dim_freq+6
        ID_list{i,j} = freq(i,j-6);
    end
end

variable_names = cell(1,dim_freq+6);
variable_names{1,1} = 'Tacc';
variable_names{1,2} = 'Spot_Color';
variable_names{1,3} = 'Angle';
variable_names{1,4} = 'Angle Error';
variable_names{1,5} = 'Ion_Rate';
variable_names{1,6} = 'Ion_Percentage';
for i = 7:dim_freq+6
    str_name = strcat('Cyc_Freq_',num2str(i));
    variable_names{1,i} = str_name;
end

% added end 

ID_list = cell2table(ID_list,'VariableNames',variable_names);
target = fullfile(target_path); %added
%target = get(handles.target,'String'); %orig
element = get(handles.isotope,'String');

filename_freq = char(strcat(target,element,'Id_Frequencies.csv'));

if handles.checkbox_spotID.Value % Create Spot ID csv iff Create Freq ID is checked    
    
    writetable(ID_list,filename_freq)

end

%% Finish Analysis %%

% Complete analysis by choosing a spot to fit by its angle and performing a
% sinusoidal fit to generate a final cyclotron frequency.

if handles.checkbox_finish_analysis.Value % Finish analysis iff Finish Analysis is checked

    % Frequency Correction for Impure Beams %%
    
    % Shift reference angle based on the small amounts of mass-dependent
    % phase acquired during excitation, based on species in beam
    
    if handles.angle_correction_impurebeam.Value
        
        cyc_freq_list = [1081187.075,1081165.783,1081193.095]; % List of frequency of all species present in files
        isotope_percentage_list = [0.071544715,0.144715447,0.699186992]; % Normalized percentage of counts in species spots in files (same order as above!)
        cyc_freq_actual = 1081183.638; % Frequency of species of interest
        correction_sum = 0;
        i = 1;
        size_cyc_list = size(cyc_freq_list);

        while i <= size_cyc_list(2)
            correction_sum = correction_sum + isotope_percentage_list(i)*(-cyc_freq_actual + cyc_freq_list(i));
            i = i + 1;
        end

        t_exc = 0.0004904; % t_exc = Dipole Excitation Time + Quadrupole Excitation Time
        angle_shift = 2*pi*t_exc*correction_sum
        
        % Used if applying a global correction or global correction extreme
        A1 = A1 + angle_shift;
        
        % Used if applying a correction to each file 
        % A1(1) = A1(1) + 0.003914499 
        % A1(2) = A1(2) + -0.014409016
        % A1(3) = A1(3) + 0.013170032
    end
    
    % Choosing the Cyclotron Frequency %%
    
    % Select the right cyclotron frequency (i.e. right num. turns) by
    % determining which is closest to the cyclotron frequency guess
    
    j = 1;
    final_freq = [];
    final_n = [];

    while j <= ref_idx;
        freq_diff = [];
        k = 1;
        while k <= n_range
            freq_diff = cat(1,freq_diff,frequencycs-freq(j,k)); % For each found spot, calculate the difference between each num. turns. w_c and the guess w_c
            k = k + 1;
        end
        freq_diff = abs(freq_diff);
        [r,c] = min(freq_diff(:)); % Choose the frequency with the smallest difference (i.e. closest to guess)

        final_freq = cat(1,final_freq,freq(j,c)); % Save closest frequency
        final_n = cat(1,final_n,n(j,c)); % Save num. turns of closest frequency

        j = j + 1;

    end

    anglecs = str2double(get(handles.spot_angle,'String')); % Angle of spot (i.e. species) to be further analyzed.

    freq_act = [];
    n_act = [];
    efreq_act = [];
    R_act = [];
    R_error_act = [];
    angle_act = [];
    angle_not_wrt_ref = [];
    time_final = [];
    color_final = {};

    for jj = 1:num_act_files
        angle_diff = [];
        freq_normal = [];
        n_list = [];
        efreq_list = [];
        R_list = [];
        R_error_list = [];
        angle_list = [];
        time_list = [];
        color_list = {};
        angle_notwrtref_list = [];

        for k = 1:ref_idx
            if file_num_list_act(k) == jj
                if anglecs > 150 && anglecs <= 180 % If the angle spot desired is in between 150 and 180, shift negative angles to positive form
                    if phi_val_act(k) < 0
                        phi_val_act(k) = phi_val_act(k) + 360;
                    end
                end
                if anglecs < -150 && anglecs >= -180 % If the angle spot desired is in between -150 and -180, shift positive angles to negative form
                    if phi_val_act(k) > 0
                        phi_val_act(k) = phi_val_act(k) - 360;
                    end
                end

                angle_diff = cat(1,angle_diff,anglecs-phi_val_act(k)); % Consolidate spot data for just one specific file 
                freq_normal = cat(1,freq_normal,final_freq(k));
                n_list = cat(1,n_list,final_n(k));
                efreq_list = cat(1,efreq_list,efreq(k));
                R_list = cat(1,R_list,C1(k));
                R_error_list = cat(1,R_error_list,C1_error(k));
                angle_list = cat(1,angle_list,A1(k));
                time_list = cat(1,time_list,time(k));
                color_list = cat(1,color_list,color_word_act{k});
                angle_notwrtref_list = cat(1,angle_notwrtref_list,phi_val_act(k));
            end
        end

        angle_diff = abs(angle_diff); % For each file, find the spot closest to the desired angle
        [r,c] = min(angle_diff(:));
        freq_act = cat(1,freq_act,freq_normal(c)); % Save all data for spot closest to desired angle
        n_act = cat(1,n_act,n_list(c));
        efreq_act = cat(1,efreq_act,efreq_list(c));
        R_act = cat(1,R_act,R_list(c));
        R_error_act = cat(1,R_error_act,R_error_list(c)); 
        angle_act = cat(1,angle_act,angle_list(c)); % Angle difference between reference and final
        time_final = cat(1,time_final,time_list(c)); % Accumulation Time
        color_final = cat(1,color_final,color_list{c}); 
        angle_not_wrt_ref = cat(1,angle_not_wrt_ref,angle_notwrtref_list(c)); % Angle of final in polar coordinates
    end



    %if handles.checkbox_sinecurvefitting.Value % Do sine curve fitting iff 'Sine Curve fitting?' is checked
        
            % Sine Curve Fitting %%
        target = fullfile(target_path); %added 
        element = get(handles.isotope,'String');
        date = get(handles.date,'String');
        timeintrap = get(handles.tit,'String');
        sep = '_';
        w_minus = str2double(get(handles.wminus,'String'))*2*pi; % Magnetron Frequency times 2*pi
    
        actual_radii = R_act;
        actual_radii_error = R_error_act; 
    
        Error = efreq_act;
    
        j = 1;
        k = 0;
        
        if handles.phase_cut_check.Value
            phase_cutoff = str2double(get(handles.phase_cut,'String')) ; % Difference between ref and final angles that you want to cutoff at, can change! 
        else
            phase_cutoff = 360;
        end
        
        size_time = size(time_final);
    
        while j <= size_time(1) 
            if angle_act(j)*180/pi > 180
                angle_act(j) = angle_act(j) - 360*pi/180; % Shift angle to between -180 and 180
            end
    
            if abs(angle_act(j)*180/pi) > phase_cutoff % If difference between ref and final angles is greater than phase_cutoff, throw away that data
                %abs(angleactual(j+k) - angleref(j+k))
                time_final(j) = [];
                freq_act(j) = [];
                Error(j) = [];
                actual_radii(j) = [];
                actual_radii_error(j) = [];
                angle_act(j) = [];
                size_time = size(time_final);
                %X = 'I did it'
                j = j - 1;
            end
            j = j + 1;
    
        end
        
        sin_func = @(b,x) b(1) + (b(2))*sin((w_minus)*x + b(3)); % Function for w_c sine fit
        sine_fit = fitnlm(time_final, freq_act, sin_func,[frequencycs,.01,1], 'Weights',Error.^-2); % Perform weighted LM-LS fit for w_c %added ';'
        
        sine_radius_fit = fitnlm(time_final, actual_radii,'y ~ b0 + b1*sin(b2*x1 + b3)',[4,.01,w_minus,1],'Weights',actual_radii_error.^-2); %added ';'
        
        %sine_fit = fitnlm(time_final, freq_act, sin_func,[frequencycs,.01,1], 'Weights',Error.^-2) % Perform weighted LM-LS fit for w_c
        
        %sine_radius_fit = fitnlm(time_final, actual_radii,'y ~ b0 + b1*sin(b2*x1 + b3)',[4,.01,w_minus,1],'Weights',actual_radii_error.^-2)
        
        type0 = 'SineFit.png';
        type1 = 'Data.xlsx';
        type2 = 'RadiusSineFit.png';
        
        filename = char(strcat(target,element,sep,date,sep,timeintrap,sep,type0));
        filename1 = char(strcat(target,element,sep,date,sep,timeintrap,sep,type1));
        filename2 = char(strcat(target,element,sep,date,sep,timeintrap,sep,type2));
    
        coeff = sine_fit.Coefficients.Estimate; % w_c Fit parameter results
        sdev = sine_fit.Coefficients.SE; % w_c Fit parameter uncertainty results
    
        coeff1 = sine_radius_fit.Coefficients.Estimate; % Radius Fit parameter results
        sdev1 = sine_radius_fit.Coefficients.SE; % Radius Fit parameter uncertainty results
    
        x = [time_final(1):.0000001:time_final(length(time_final))];
    
        y = coeff(1) + (coeff(2))*sin((w_minus)*x + coeff(3));
    
        y_model = coeff(1) + (coeff(2))*sin((w_minus)*time_final + coeff(3));
    
        diff = y_model - freq_act;
        ii = 1;
        chi_2 = 0;
    
        while ii <= size_time(1)
            chi_2 = chi_2 + ((diff(ii))^2)/(Error(ii)^2); % Determine chi-squared metric for w_c fit
            ii = ii + 1;
        end
     
        y1 = coeff1(1) + coeff1(2)*sin(coeff1(3)*x + coeff1(4));
        
        r_model = coeff1(1) + coeff1(2)*sin(coeff1(3)*time_final + coeff1(4));
        
        diff_r = r_model - actual_radii;
    
        jj = 1;
        chi_2_r = 0;
    
        while jj <= size_time(1)
            chi_2_r = chi_2_r + ((diff_r(jj))^2)/(actual_radii_error(jj)^2); % Determine chi-squared metric for radius fit
            jj = jj + 1;
        end
    
        dof_cyc = 3;
        dof_radius = 4;
    
        chi_2 = chi_2/(size_time(1)-dof_cyc); % Determine reduced chi-squared metrics
        chi_2_r = chi_2_r/(size_time(1)-dof_radius);
    
    if handles.checkbox_sinecurvefitting.Value % Do sine curve fitting iff 'Sine Curve fitting?' is checked
        figure(1000) % Plot w_c fit
        hold on
        scatter(time_final,freq_act)
        hold on
        errorbar(time_final,freq_act, Error,'LineStyle','None')
        hold on
        plot(x,y)
        xlabel('Accumulation Time (s)')
        ylabel('Cyclotron Frequency (Hz)')
        title('Cyc. Freq. Sine Fit')
        hold off
    
        figure(2000) % Plot radius fit
        hold on
        scatter(time_final,actual_radii)
        hold on
        errorbar(time_final,actual_radii, actual_radii_error,'LineStyle','None') 
        hold on
        plot(x,y1)
        xlabel('Accumulation Time (s)')
        ylabel('Radius (mm)')
        title('Radius Sine Fit')
        hold off
    
        A1_deg = angle_act*180/pi;
        Time = time_final;
        Cyc_Freq = freq_act;
        Number_of_Turns = n_act(1:size_time);
        Angle = angle_act(1:size_time)*180/pi;
        Radius = actual_radii;
        Radius_Error = actual_radii_error;

        T = table(Time,Cyc_Freq,Error,Number_of_Turns,Angle,Radius,Radius_Error); % Data tab with cyclotron frequency data input to fit
        writetable(T,filename1,'Sheet','Cyc. Freq. Data')
        
        Fit_Parameters = coeff; % Data tab with parameter results for cyclotron frequency sine fit
        Uncertainty = sdev;
        T1 = table(Fit_Parameters,Uncertainty);
        writetable(T1,filename1,'Sheet','Cyc. Freq. Fit Parameters')
        
        RadiusFit = coeff1(1); % Data tab with final fit radius
        Uncertainty = sdev1(1);
        Red_Chi2 = chi_2_r;
        writetable(table(RadiusFit,Uncertainty,Red_Chi2),filename1,'Sheet','Radius')
        
        Fit_Parameters = coeff1; % Data tab with parameter results for radius sine fit
        Uncertainty = sdev1;
        T2 = table(Fit_Parameters,Uncertainty);
        writetable(T2,filename1,'Sheet','Radius Fit Parameters')
    
        print(figure(1000),filename, '-dpng');
        print(figure(2000),filename2, '-dpng');
    
    end 


    % writing file that out puts cyclotron frequency 
        
    
    Cyc_Frequency = coeff(1); % Data tab with final fit cyclotron frequency
    Uncertainty = sdev(1);
    Red_Chi2 = chi_2;
    writetable(table(Cyc_Frequency,Uncertainty,Red_Chi2),filename1,'Sheet','Cyc. Freq.')
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Manual Fitting Functions %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Functions used in the manual fitting of spots (via manual gating of data) 
% and subsequent determination of cyclotron frequencies.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Functions for Recalculate Square Fit Button
% --- Executes on button press in go.
%
function go_Callback(hObject, eventdata, handles)
% hObject    handle to go (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global spot_x spot_y spot_t spot_trigger spot_r spot_phi total_ion_time number_of_ions;

% ToF Cut
%Bin on ToF
 tlb0 = get(handles.tlb,'String'); % Get time-of-flight bounds
 tup0 = get(handles.tub,'String');
 tlb0 = str2double(tlb0);
 tup0 = str2double(tup0);
 t_lower = tlb0;
 t_upper = tup0;

%Locked Values
numcounts_tof1 = size(spot_t);
x =1;
counter1 = 1;
real_tof1 = 0;

while counter1 <= numcounts_tof1(1)
    if (spot_t(x) >= t_lower) && (spot_t(x) <= t_upper)  % Cut data away that is outside of ToF bounds
        real_tof1 = real_tof1 + 1;
        x = x + 1;
    else
        spot_x(x) = [];
        spot_y(x) = [];
        spot_t(x) = [];
        spot_trigger(x) = [];
        spot_r(x) = [];
        spot_phi(x) = [];
    end
   
    counter1 = counter1 + 1;
end

% X Bin Cut
%Bin on X
xlb0 = get(handles.lbx,'String'); % Get X bounds
xup0 = get(handles.ubx,'String');
xlb0 = str2double(xlb0);
xup0 = str2double(xup0);
x_lower = xlb0;
x_upper = xup0;

%Locked Values
numcounts_x1 = size(spot_t);
x11 =1;
counterx1 = 1;
real_x1 = 0;
while counterx1 <= numcounts_x1(1)
    if (spot_x(x11) >= x_lower) && (spot_x(x11) <= x_upper) % Cut data away outside of X bounds
        real_x1 = real_x1 + 1;
        x11 = x11 + 1;
    else
        spot_x(x11) = [];
        spot_y(x11) = [];
        spot_t(x11) = [];
        spot_trigger(x11) = [];
        spot_phi(x11) = [];
        spot_r(x11) = [];
    end
    counterx1 = counterx1 + 1;
end

% Y Bin Cut
%Bin on Y
ylb0 = get(handles.ylb,'String'); % Get Y bounds
yup0 = get(handles.yub,'String');
ylb0 = str2double(ylb0);
yup0 = str2double(yup0);
y_lower = ylb0;
y_upper = yup0;

%Locked Valuesf
numcounts_y1 = size(spot_t);
y11 =1;
countery1 = 1;
real_y1 = 0;
while countery1 <= numcounts_y1(1)
    if (spot_y(y11) >= y_lower) && (spot_y(y11) <= y_upper) % Cut data away outside of Y bounds
        real_y1 = real_y1 + 1;
        y11 = y11 + 1;
    else
        spot_x(y11) = [];
        spot_y(y11) = [];
        spot_t(y11) = [];
        spot_trigger(y11) = [];
        spot_phi(y11) = [];
        spot_r(y11) = [];
    end
    countery1 = countery1 + 1;
end

% Phi Cut
%Bin on Phi 
alb0 = get(handles.alb,'String'); % Get angle bounds
aub0 = get(handles.aub,'String');
alb0 = str2double(alb0);
aub0 = str2double(aub0);
phi_lower = alb0;
phi_upper = aub0;

%Locked Values
numcounts_p1 = size(spot_t);
p11 =1;
counterp1 = 1;
real_p1 = 0;
while counterp1 <= numcounts_p1(1)
    if (spot_phi(p11) >= phi_lower) && (spot_phi(p11) <= phi_upper) % Cut data outside of angle bounds
        real_p1 = real_p1 + 1;
        p11 = p11 + 1;
    else
        spot_x(p11) = [];
        spot_y(p11) = [];
        spot_t(p11) = [];
        spot_trigger(p11) = [];
        spot_phi(p11) = [];
        spot_r(p11) = [];
    end
    counterp1 = counterp1 + 1;
end

% Radius Cut
%Bin on R
rlb0 = get(handles.rlb,'String'); % Get radius bounds
rup0 = get(handles.rub,'String');
rlb0 = str2double(rlb0);
rup0 = str2double(rup0);
r_lower = rlb0;
r_upper = rup0;

%Locked Values
numcounts_r1 = size(spot_t);
r11 =1;
counterr1 = 1;
real_r1 = 0;
while counterr1 <= numcounts_r1(1)
    if (spot_r(r11) >= r_lower) && (spot_r(r11) <= r_upper) % Cut data outside radius bounds
        real_r1 = real_r1 + 1;
        r11 = r11 + 1;
    else
        spot_x(r11) = [];
        spot_y(r11) = [];
        spot_t(r11) = [];
        spot_trigger(r11) = [];
        spot_phi(r11) = [];
        spot_r(r11) = [];
    end
    counterr1 = counterr1 + 1;
end

% Update Graphs on GUI after Data Cut
 histogram(handles.tofgraph,spot_t,100);
 grid on
 scatter(handles.xygraph,spot_x,spot_y,'filled');
 grid off
 histogram(handles.xgraph,spot_x, 100)
 histogram(handles.ygraph,spot_y, 100)
 histogram(handles.radgraph,spot_r, 10)
 histogram(handles.phigraph,spot_phi,50)
 
% Distribution Calculations
 [mux,sigmax] = normfit(spot_x);
 [muy,sigmay] = normfit(spot_y);
 [mup,sigmap] = normfit(spot_phi);
 [mur,sigmar] = normfit(spot_r);
 [mut,sigmat] = normfit(spot_t);

% Standard Error Calculation
x_length=length(spot_x);
y_length=length(spot_y);
p_length=length(spot_phi);
r_length=length(spot_r);
t_length=length(spot_t);

stderrx= sigmax/sqrt(x_length);
stderry= sigmay/sqrt(y_length);
stderrp= sigmap/sqrt(p_length);
stderrr= sigmar/sqrt(r_length);
stderrt= sigmat/sqrt(t_length);

% Update Handle Values
set(handles.xc,'string',num2str(mux));
set(handles.yc,'string',num2str(muy));
set(handles.ac,'string',num2str(mup));
set(handles.rc,'string',num2str(mur));
set(handles.tc,'string',num2str(mut));

set(handles.xe,'string',num2str(stderrx));
set(handles.ye,'string',num2str(stderry));
set(handles.ae,'string',num2str(stderrp));
set(handles.re,'string',num2str(stderrr));
set(handles.te,'string',num2str(stderrt));

set(handles.ion_number_text,'String',num2str(length(spot_x))); % Update number of ions within new gates
set(handles.ion_rate,'String',num2str(length(spot_x)/total_ion_time)); % Update rate of ions in gates
percentage = length(spot_x)/number_of_ions;
set(handles.percentage,'String',num2str(percentage));  % Update unnormalized percentage of total for ions in gates

%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Functions for Shift 30 Degrees Counterclockwise Button
% --- Executes on button press in shiftccw.
%
% Shift the angle distribution by 30 degrees in the counterclockwise
% direction
%
function shiftccw_Callback(hObject, eventdata, handles)
% hObject    handle to shiftccw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global spot_phi spot_t
phishift = 30;
spot_phi = spot_phi + phishift;
numcounts_p1 = size(spot_t);
p11 =1;
counterp1 = 1;

while counterp1 <= numcounts_p1(1)
    if (spot_phi(p11) >= 360 ) 
       spot_phi(p11) = spot_phi(p11) - 360;
    elseif (spot_phi(p11) <= 0 ) 
       spot_phi(p11) = spot_phi(p11) + 360;
    end
    p11 = p11 + 1;
    counterp1 = counterp1 + 1;
end

histogram(handles.phigraph,spot_phi,50)
 [mup,sigmap] = normfit(spot_phi);
 p_length=length(spot_phi);
 stderrp= sigmap/sqrt(p_length);
 set(handles.ac,'string',num2str(mup));
 set(handles.ae,'string',num2str(stderrp));
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Functions for Recalculate Radial Fit Button
% --- Executes on button press in go_radial.
%
% Gate based on cutting out data outside a defined center and radius
%
function go_radial_Callback(hObject, eventdata, handles)
% hObject    handle to go_radial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global spot_x spot_y spot_t spot_trigger spot_r spot_phi;


% ToF Cut
% Bin on ToF
 tlb0 = get(handles.tlb,'String');
 tup0 = get(handles.tub,'String');
 tlb0 = str2double(tlb0);
 tup0 = str2double(tup0);
 t_lower = tlb0;
 t_upper = tup0;

% Locked Values
numcounts_tof1 = size(spot_t);
x =1;
counter1 = 1;
real_tof1 = 0;

while counter1 <= numcounts_tof1(1)
    if (spot_t(x) >= t_lower) && (spot_t(x) <= t_upper) 
        real_tof1 = real_tof1 + 1;
        x = x + 1;
    else
        spot_x(x) = [];
        spot_y(x) = [];
        spot_t(x) = [];
        spot_trigger(x) = [];
        spot_r(x) = [];
        spot_phi(x) = [];
    end
   
    counter1 = counter1 + 1;
end

% Radial Cut

x_center_guess = get(handles.spot_center_guess_x,'String');
y_center_guess = get(handles.spot_center_guess_y,'String');
radius_of_fit = get(handles.fit_radius, 'String');
x_center_guess = str2double(x_center_guess);
y_center_guess = str2double(y_center_guess);
radius_of_fit = str2double(radius_of_fit);

numcounts_radial_fit = size(spot_t);
radial_fit_index = 1;
radial_fit_counter = 1;
radial_fit_real = 0;

while radial_fit_counter <= numcounts_radial_fit(1)
    point_radius_x = spot_x(radial_fit_index) - x_center_guess;
    point_radius_y = spot_y(radial_fit_index) - y_center_guess;
    radius_diff = sqrt(point_radius_x^2 + point_radius_y^2);
    if (radius_diff <= radius_of_fit) && (radius_diff >= -1*radius_of_fit)
        radial_fit_real = radial_fit_real + 1;
        radial_fit_index = radial_fit_index + 1;
    else
        spot_x(radial_fit_index) = [];
        spot_y(radial_fit_index) = [];
        spot_t(radial_fit_index) = [];
        spot_trigger(radial_fit_index) = [];
        spot_phi(radial_fit_index) = [];
        spot_r(radial_fit_index) = [];
    end
    radial_fit_counter = radial_fit_counter + 1;
end
    
    

% Phi Cut
% Bin on Phi 
alb0 = get(handles.alb,'String');
aub0 = get(handles.aub,'String');
alb0 = str2double(alb0);
aub0 = str2double(aub0);
phi_lower = alb0;
phi_upper = aub0;

%Locked Values
numcounts_p1 = size(spot_t);
p11 =1;
counterp1 = 1;
real_p1 = 0;
while counterp1 <= numcounts_p1(1)
    if (spot_phi(p11) >= phi_lower) && (spot_phi(p11) <= phi_upper) 
        real_p1 = real_p1 + 1;
        p11 = p11 + 1;
    else
        spot_x(p11) = [];
        spot_y(p11) = [];
        spot_t(p11) = [];
        spot_trigger(p11) = [];
        spot_phi(p11) = [];
        spot_r(p11) = [];
    end
    counterp1 = counterp1 + 1;
end

% Radius Cut
%Bin on Radius
rlb0 = get(handles.rlb,'String');
rup0 = get(handles.rub,'String');
rlb0 = str2double(rlb0);
rup0 = str2double(rup0);
r_lower = rlb0;
r_upper = rup0;

% Locked Values
numcounts_r1 = size(spot_t);
r11 =1;
counterr1 = 1;
real_r1 = 0;
while counterr1 <= numcounts_r1(1)
    if (spot_r(r11) >= r_lower) && (spot_r(r11) <= r_upper) 
        real_r1 = real_r1 + 1;
        r11 = r11 + 1;
    else
        spot_x(r11) = [];
        spot_y(r11) = [];
        spot_t(r11) = [];
        spot_trigger(r11) = [];
        spot_phi(r11) = [];
        spot_r(r11) = [];
    end
    counterr1 = counterr1 + 1;
end
% Update Graphs on GUI after Data Cut
 histogram(handles.tofgraph,spot_t,100);
 grid on
 scatter(handles.xygraph,spot_x,spot_y,'filled');
 grid off
 histogram(handles.xgraph,spot_x, 100)
 histogram(handles.ygraph,spot_y, 100)
 histogram(handles.radgraph,spot_r, 10)
 histogram(handles.phigraph,spot_phi,50)
 
 % Distribution Calculations
 [mux,sigmax] = normfit(spot_x);
 [muy,sigmay] = normfit(spot_y);
 [mup,sigmap] = normfit(spot_phi);
 [mur,sigmar] = normfit(spot_r);
 [mut,sigmat] = normfit(spot_t);

 % Standard Error Calculation
x_length=length(spot_x);
y_length=length(spot_y);
p_length=length(spot_phi);
r_length=length(spot_r);
t_length=length(spot_t);


stderrx= sigmax/sqrt(x_length);
stderry= sigmay/sqrt(y_length);
stderrp= sigmap/sqrt(p_length);
stderrr= sigmar/sqrt(r_length);
stderrt= sigmat/sqrt(t_length);

% Update Handle Values
set(handles.xc,'string',num2str(mux));
set(handles.yc,'string',num2str(muy));
set(handles.ac,'string',num2str(mup));
set(handles.rc,'string',num2str(mur));
set(handles.tc,'string',num2str(mut));

set(handles.xe,'string',num2str(stderrx));
set(handles.ye,'string',num2str(stderry));
set(handles.ae,'string',num2str(stderrp));
set(handles.re,'string',num2str(stderrr));
set(handles.te,'string',num2str(stderrt));

set(handles.ion_number_text,'String',num2str(length(spot_x)));
set(handles.ion_rate,'String',num2str(length(spot_x)/total_ion_time));
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Functions for Shift 30 Degrees Clockwise Button
% --- Executes on button press in shiftcw.
% Shift the angle distribution by 30 degrees in the counterclockwise
% direction
%
function shiftcw_Callback(hObject, eventdata, handles)
% hObject    handle to shiftcw (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global spot_phi spot_t
phishift = -30;
spot_phi = spot_phi + phishift;
numcounts_p1 = size(spot_t);
p11 =1;
counterp1 = 1;

while counterp1 <= numcounts_p1(1)
    if (spot_phi(p11) >= 360 ) 
       spot_phi(p11) = spot_phi(p11) - 360;
    elseif (spot_phi(p11) <= 0 ) 
       spot_phi(p11) = spot_phi(p11) + 360 ;
    end
    p11 = p11 + 1;
    counterp1 = counterp1 + 1;
end

histogram(handles.phigraph,spot_phi,50)
 [mup,sigmap] = normfit(spot_phi);
 p_length=length(spot_phi);
 stderrp= sigmap/sqrt(p_length);
 set(handles.ac,'string',num2str(mup));
 set(handles.ae,'string',num2str(stderrp));
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Functions for Save Fits and Graphs Button
% --- Executes on button press in Save.
%
% Save histograms of X,Y,ToF,Angle and Radius values given the gates
% applied
%
function Save_Callback(hObject, eventdata, handles)
% hObject    handle to Save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global spot_x spot_y spot_t spot_r spot_phi spot_trigger file_number_counter number_of_files data_files tacc_list tacc_list_counter angle_list radius_list number_of_ions ion_percent_list path
target = fullfile(target_path); %added 
%target = get(handles.target,'String'); %orig
element = get(handles.isotope,'String');
time = tacc_list(tacc_list_counter);
date = get(handles.date,'String');
timeintrap = get(handles.tit,'String');
spot = get(handles.ac,'String');
sep = '_';

time_string = num2str(time);
tacc_list_counter_string = num2str(tacc_list_counter);

mkdir(fullfile(target,time_string,tacc_list_counter_string)) % Make a new directory for this file to save data in

figure(1)
hold on
% Create X Fit
pd1 = createFitY(spot_x);
xlabel('X Values (mm)')
ylabel('Normalize Counts')
title('Fit of X Values')
type = 'X_Fit.png';
filename = char(strcat(target,time_string,'/',tacc_list_counter_string,'/',element,sep,time_string,sep,date,sep,timeintrap,sep,spot,sep,type));
hold off
print(figure(1),filename, '-dpng');
[mux,sigmax] = normfit(spot_x);


figure(2)
hold on
% Create Y Fit
pd2 = createFitY(spot_y);
xlabel('Y Values (mm)')
ylabel('Normalize Counts')
title('Fit of Y Values')
type = 'Y_Fit.png';
filename = char(strcat(target,time_string,'/',tacc_list_counter_string,'/',element,sep,time_string,sep,date,sep,timeintrap,sep,spot,sep,type));
print(figure(2),filename, '-dpng');
hold off
[muy,sigmay] = normfit(spot_y);


figure(3)
hold on
% Create Angle Fit
pd3 = createFitY(spot_phi);
xlabel('Phi Values (deg)')
ylabel('Normalize Counts')
title('Fit of Phi Values')
type = 'Phi_Fit.png';
filename = char(strcat(target,time_string,'/',tacc_list_counter_string,'/',element,sep,time_string,sep,date,sep,timeintrap,sep,spot,sep,type));
hold off
print(figure(3),filename, '-dpng');

figure(4)
hold on
% Create Radius Fit
pd4 = createFitY(spot_r);
xlabel('Radius Values (mm)')
ylabel('Normalize Counts')
title('Fit of Radius Values')
type = 'Radius_Fit.png';
filename = char(strcat(target,time_string,'/',tacc_list_counter_string,'/',element,sep,time_string,sep,date,sep,timeintrap,sep,spot,sep,type));
hold off
print(figure(4),filename, '-dpng');
[mur,sigmar] = normfit(spot_r);

figure(5)
hold on
% Create ToF Fit
pd5 = createFitY(spot_t);
xlabel('ToF Values (ns)')
ylabel('Normalize Counts')
title('Fit of ToF Values')
type = 'ToF_Fit.png';
filename = char(strcat(target,time_string,'/',tacc_list_counter_string,'/',element,sep,time_string,sep,date,sep,timeintrap,sep,spot,sep,type));
hold off
print(figure(5),filename, '-dpng');

% Screenshot Image of GUI
type = 'ScreenShare.png';
filename = char(strcat(target,time_string,'/',tacc_list_counter_string,'/',element,sep,time_string,sep,date,sep,timeintrap,sep,spot,sep,type));
print(filename, '-dpng');

% Create data array of gated data
typer = 'GatedArray.csv';
filename = char(strcat(target,time_string,'/',tacc_list_counter_string,'/',element,sep,time_string,sep,date,sep,timeintrap,sep,spot,sep,typer));
m = [spot_x spot_y spot_t spot_trigger];
csvwrite(filename, m)

x_length=length(spot_x);
y_length=length(spot_y);
r_length=length(spot_r);

stderrx= sigmax/sqrt(x_length);
stderry= sigmay/sqrt(y_length);
stderrr = sigmar/sqrt(r_length);

% Create array of relevant positional fit results
typer = 'FrequencyValues.csv';
filename = char(strcat(target,time_string,'/',tacc_list_counter_string,'/',element,sep,time_string,sep,date,sep,timeintrap,sep,typer));
%time=str2double(time);
m = [time mux muy stderrx stderry];
dlmwrite(filename, m,'Precision',20)

tacc_list_counter = tacc_list_counter + 1;

angle_list = cat(1,angle_list,str2double(spot)); % Add spot angle of file to global spot angle list

percentage = length(spot_x)/number_of_ions;

ion_percent_list = cat(1,ion_percent_list,percentage); % Add file spot percentage to global spot percentage list

r_list = [mur stderrr];
radius_list = cat(1,radius_list,r_list); % Add radius fit results to global radius list

if file_number_counter < number_of_files
    file_number_counter = file_number_counter + 1;
    set(handles.csr_csv, 'String', data_files{1}{file_number_counter}); % Move to the next file
else
    set(handles.csr_csv, 'String', 'No More Data Files Left');
end
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Functions for Save Angles and Radii Button
% --- Executes on button press in save_angles.
%
% After all files are fit, saves the global radius, angle and spot
% percentage lists.
%
function save_angles_Callback(hObject, eventdata, handles)
% hObject    handle to save_angles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global angle_list radius_list ion_percent_list

target = fullfile(target_path); %added 
%target = get(handles.target,'String'); %orig
element = get(handles.isotope,'String');
date = get(handles.date,'String');
timeintrap = get(handles.tit,'String');
sep = '_';

type_a = 'Angles.csv';
type_r = 'Radii.csv';
type_i = 'IonPercentage.csv';
filename = char(strcat(target,element,sep,date,sep,timeintrap,sep,type_a));
filename_1 = char(strcat(target,element,sep,date,sep,timeintrap,sep,type_r));
filename_2 = char(strcat(target,element,sep,date,sep,timeintrap,sep,type_i));
csvwrite(filename,angle_list)
dlmwrite(filename_1,radius_list,'Precision',20)
dlmwrite(filename_2,ion_percent_list,'Precision',10)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Finishing Analysis
%
% Once all of our data files have been fit, we can finish the anaylsis by
% calculating cyclotron frequencies from the determined spot positions.
%

% --- Executes on button press in finish_analysis.
function finish_analysis_Callback(hObject, eventdata, handles)
% hObject    handle to finish_analysis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%
global data_files tacc_list number_of_files tacc_list_counter angle_list center_spot_redux
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Cyclotron Frequency Calculation
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Creating the Center_Spot_Redux CSV
%
% Create the CenterSpotRedux file, which is used to generate final analysis
% results
%
freq_file_counter = 1;
center_spot_redux_list = [1,2,3,4,5];
center_spot_redux_ref_list = [6,7,8,9,10];

target = fullfile(target_path); %added
%target = get(handles.target,'String'); %orig
element = get(handles.isotope,'String');
date = get(handles.date,'String');
timeintrap = get(handles.tit,'String');
sep = '_';
typer = 'FrequencyValues.csv';
typea = 'Angles.csv';
tacc_list_counter = 1;

actual_angle_list = [11];
ref_angle_list = [12];

angle_file = char(strcat(target,element,sep,date,sep,timeintrap,sep,typea));
angle_list = csvread(angle_file);

while freq_file_counter <= number_of_files
    time = tacc_list(freq_file_counter);
    time_str = num2str(time);
    tacc_list_counter_string = num2str(tacc_list_counter);
    filename = char(strcat(target,time_str,'/',tacc_list_counter_string,'/',element,sep,time_str,sep,date,sep,timeintrap,sep,typer));
    
    file = csvread(filename);
    file = file(1,:); % Read in data from each FrequencyValues.csv file
    
    if time <= .0001
        center_spot_redux_ref_list = cat(1,center_spot_redux_ref_list, file); % If file has ~0 Tacc, then add its data as reference file data
    else
        center_spot_redux_list = cat(1,center_spot_redux_list, file); % Otherwise, add its data as final file data
    end
    
    freq_file_counter = freq_file_counter + 1;
    
    tacc_list_counter = tacc_list_counter + 1;
end

freq_file_counter = 1;

center_spot_redux_ref_list_size = size(center_spot_redux_ref_list);
center_spot_redux_ref_list_size = center_spot_redux_ref_list_size(1) - 1;

while freq_file_counter <= number_of_files
    if freq_file_counter <= number_of_files - center_spot_redux_ref_list_size
        actual_angle_list = cat(1,actual_angle_list,angle_list(freq_file_counter)); % If an angle of an final file, add it to the final angle list
    else
        ref_angle_list = cat(1,ref_angle_list,angle_list(freq_file_counter)); % Otherwise, it is an angle of a reference file, and add it to the ref angle list
    end
    
    freq_file_counter = freq_file_counter + 1;
end

center_spot_redux_ref = [6,7,8,9,10];
ref_angle = [12];

ref_list = data_files{3}; % Grab data on what reference file is assigned to each final file

ref_list_size = size(ref_list);
ref_list_size = ref_list_size(1) - center_spot_redux_ref_list_size + 1;

ref_list_counter = 1;

while ref_list_counter <= ref_list_size
    ref_number = ref_list(ref_list_counter);
    center_spot_redux_ref_list_counter = 1;
    while center_spot_redux_ref_list_counter <= center_spot_redux_ref_list_size
        if ref_number == center_spot_redux_ref_list_counter
            center_spot_redux_ref = cat(1,center_spot_redux_ref,center_spot_redux_ref_list(ref_number+1,:)); % If the reference number for the final file matches the current reference file, add that reference file data
            ref_angle = cat(1,ref_angle,ref_angle_list(ref_number+1,:));
        end
        center_spot_redux_ref_list_counter = center_spot_redux_ref_list_counter + 1;
    end
    
    ref_list_counter = ref_list_counter + 1;

end

% Create CenterSpotRedux.csv
center_spot_redux = cat(2,center_spot_redux_list,center_spot_redux_ref,actual_angle_list,ref_angle);

new_filename = char(strcat(target,element,'Center_Spot_Redux.csv'));
dlmwrite(new_filename,center_spot_redux,'precision',10);
set(handles.csr_csv,'String',new_filename);


% --- Executes on button press in create_cyc_freq.
function create_cyc_freq_Callback(hObject, eventdata, handles)
% hObject    handle to create_cyc_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Frequency Analysis
%
% Taking an input CenterSpotRedux.csv file, finish analysis and producing a
% cyclotron frequency result.
%
%% Data Input
% Read Data Files 
data_file = get(handles.filename,'String'); % Read CenterSpotRedux.csv 
data = csvread(data_file,1);

frequencycs = str2num(get(handles.w_c,'String'));

 
%Actual Center
centerx = str2double(get(handles.tcx,'String'));
centery = str2double(get(handles.tcy,'String'));
centerrorx = .05;
centerrory = .05;

%Tacc
time = data(:,1);
 
%Ref and Angle Data
refx = data(:,7) - centerx;
refy = data(:,8) - centery;
errorrx = (data(:,9).^2 + centerrorx^2);
errorry = (data(:,10).^2 + centerrory^2);
errorrx = errorrx.^.5;
errorry = errorry.^.5;
timeref = data(:,6);
angleactual = data(:,11);
angleref = data(:,12);
 
%Actual Data 
spot1x = data(:,2) - centerx;
spot1y = data(:,3) - centery;
error1x = (data(:,4).^2 + centerrorx^2);
error1y = (data(:,5).^2 + centerrory^2);
error1x = error1x.^.5;
error1y = error1y.^.5;


%Shift Center
centerx = 0;
centery = 0;
 
husker= length(spot1x);

D = spot1x;
C1= spot1x;
Cref= spot1x;
n=spot1x;

A1= spot1x;

%% Determining Turn Numbers, Spot Distances and Angles 

freq = zeros(husker,11);
efreq = zeros(husker);

j = 1;

while j <=husker
 gbr = 1;
 letsgo = -5;
 while gbr < 12
     
    n(j,gbr) = floor(frequencycs * (time(j)-timeref(j))) + letsgo; % Define range of turn numbers based of w_c guess
    gbr = gbr + 1;
    letsgo = letsgo + 1;
    
 end
 
%Spot Distances
D(j) = sqrt((spot1x(j)-refx(j))^2+(spot1y(j)-refy(j))^2);

%Distances
C1(j) = sqrt((centerx-spot1x(j))^2+(centery-spot1y(j))^2);
Cref(j) = sqrt((centerx-refx(j))^2+(centery-refy(j))^2);
C1_error(j) = ((centerx-spot1x(j))^2 + (centery-spot1y(j))^2)^(-3/4)*sqrt((centerx-spot1x(j))^2*error1x(j)^2 + (centery-spot1y(j))^2*error1y(j)^2);

%Spot Angle
A1(j) = acos((-D(j)^2+C1(j)^2+Cref(j)^2)/(2*C1(j)*Cref(j)));

j = j+1; % Next

end

%% Angle Conversion

k = 1;

while k <= husker
    % w_c %
    
    if (angleactual(k) - angleref(k) < 0) | (angleactual(k) - angleref(k) > 180)
        A1(k) = 2*pi - A1(k);
    end
    
    % w_minus %
    
    %if (angleref(k) - angleactual(k) < 0) | (angleref(k) - angleactual(k) > 180)
    %    A1(k) = 2*pi - A1(k);
    %end
    k = k + 1;
end

%% Frequency Correction for Impure Beams
% 
% cyc_freq_list = [1081187.075,1081165.783,1081193.095];
% isotope_percentage_list = [0.071544715,0.144715447,0.699186992];
% cyc_freq_actual = 1081183.638;
% correction_sum = 0;
% i = 1;
% size_cyc_list = size(cyc_freq_list);
% 
% while i <= size_cyc_list(2)
%     correction_sum = correction_sum + isotope_percentage_list(i)*(-cyc_freq_actual + cyc_freq_list(i));
%     i = i + 1;
% end
%  
% t_exc = 0.0004904;
% angle_shift = 2*pi*t_exc*correction_sum
% A1 = A1 + angle_shift

%% Frequency
% A1(1) = A1(1) + 0.003914499
% A1(2) = A1(2) + -0.014409016
% A1(3) = A1(3) + 0.013170032

i = 1;
irish = 1;


while i <= husker
    while irish <= 11
        freq(i,irish) = (A1(i)+(2*pi*n(i,irish)))/(2*pi*(time(i)-timeref(i))); % Generate frequencies from turn numbers
        %freq(irish) = (A1+(2*pi*n))/(2*pi*time1);
        irish = irish + 1;
    end

irish = 1;


error1 = sqrt( (Cref(i)^4* ((spot1x(i)^2 * error1y(i)^2) + (spot1y(i)^2 * error1x(i)^2)) + C1(i)^4 * ((refx(i)^2 * errorry(i)^2) + (refy(i)^2 * errorrx(i)^2 ))))/(Cref(i) * C1(i))^2;

efreq(i) = error1/(2*pi*(time(i)-timeref(i)));
efreq(i) = error1/(2*pi*(time(i)-timeref(i)));


i = i+1;


end


%% Choosing the Cyclotron Frequency
%
size_time = size(time);
j = 1;
final_freq = [];
final_n = [];
while j <= size_time(1);
    freq_diff = [];
    k = 1;
    while k <= 11
        freq_diff = cat(1,freq_diff,frequencycs-freq(j,k)); % Determine difference between frequencies and guess frequency
        k = k + 1;
    end
    freq_diff = abs(freq_diff);
    [r,c] = min(freq_diff(:)); % Find smallest difference
    
    final_freq = cat(1,final_freq,freq(j,c)); % Add frequency and turn number of smallest distance
    final_n = cat(1,final_n,n(j,c));
    
    j = j + 1;
    
end
        
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Sine Curve Fitting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
target = fullfile(target_path); %added
%target = get(handles.target,'String'); %orig
element = get(handles.isotope,'String');
date = get(handles.date,'String');
timeintrap = get(handles.tit,'String');
sep = '_';
w_minus = str2double(get(handles.wminus,'String'))*2*pi;

rad_file = get(handles.radii_list,'String');
radiuses = csvread(rad_file,1);
radii = radiuses(:,1);
radii_error = radiuses(:,2);
actual_radii = radii(1:size_time(1));
actual_radii_error = sqrt(radii_error(1:size_time(1)).^2 + centerrorx^2 + centerrory^2);

Error = efreq(:,1);

% filename_freqs = char(strcat(target,element,sep,'Freqs.csv'));
% dlmwrite(filename_freqs,freq,'Precision',10)

j = 1;
k = 0;
phase_cutoff = 360; % Difference between ref and final angles that you want to cutoff at, can change! 

while j <= size_time(1) 
    if A1(j)*180/pi > 180
        A1(j) = A1(j) - 360*pi/180;
    end
    
    if abs(A1(j)*180/pi) > phase_cutoff
        %abs(angleactual(j+k) - angleref(j+k))
        time(j) = [];
        final_freq(j) = [];
        Error(j) = [];
        actual_radii(j) = [];
        actual_radii_error(j) = [];
        A1(j) = [];
        size_time = size(time);
        %X = 'I did it'
        j = j - 1;
    end
    j = j + 1;
    
    
end

size_time = size(time);

sin_func = @(b,x) b(1) + (b(2))*sin((w_minus)*x + b(3)) % Function for w_c sine fit

sine_fit = fitnlm(time, final_freq, sin_func,[frequencycs,.01,1], 'Weights',Error.^-2) % Perform weighted LM-LS fit for w_c

sine_radius_fit = fitnlm(time, actual_radii,'y ~ b0 + b1*sin(b2*x1 + b3)',[4,.01,w_minus,1],'Weights',actual_radii_error.^-2)
%sine_radius_fit = fitnlm(time, actual_radii,'y ~ b0 + b1*sin(b2*x1 + b3)',[4,.01,w_minus,1]) % Perform weighted LM-LS fit for radius

type0 = 'SineFit.png';
type1 = 'Data.xlsx';
type2 = 'RadiusSineFit.png';

filename = char(strcat(target,element,sep,date,sep,timeintrap,sep,type0));
filename1 = char(strcat(target,element,sep,date,sep,timeintrap,sep,type1));
filename2 = char(strcat(target,element,sep,date,sep,timeintrap,sep,type2));

coeff = sine_fit.Coefficients.Estimate; % Coefficients and uncertainties for w_c fit
sdev = sine_fit.Coefficients.SE;

coeff1 = sine_radius_fit.Coefficients.Estimate; % Coefficients and uncertainties for radius fit
sdev1 = sine_radius_fit.Coefficients.SE;

x = [time(1):.0000001:time(length(time))];

% Define Model Results for w_c
y = coeff(1) + (coeff(2))*sin((w_minus)*x + coeff(3));

y_model = coeff(1) + (coeff(2))*sin((w_minus)*time + coeff(3));

diff = y_model - final_freq;
ii = 1;
chi_2 = 0;

while ii <= size_time(1)
    chi_2 = chi_2 + ((diff(ii))^2)/(Error(ii)^2);
    ii = ii + 1;
end

% Define Model Results for Radius
y1 = coeff1(1) + coeff1(2)*sin(coeff1(3)*x + coeff1(4));

r_model = coeff1(1) + coeff1(2)*sin(coeff1(3)*time + coeff1(4));

diff_r = r_model - actual_radii;

jj = 1;
chi_2_r = 0;

while jj <= size_time(1)
    chi_2_r = chi_2_r + ((diff_r(jj))^2)/(actual_radii_error(jj)^2); 
    jj = jj + 1;
end

dof_cyc = 3;
dof_radius = 4;

chi_2 = chi_2/(size_time(1)-dof_cyc); % Determine reduced Chi^2 metrics for w_c and radius fits
chi_2_r = chi_2_r/(size_time(1)-dof_radius);

% Plot w_c fit
figure(1000)
hold on
scatter(time,final_freq)
hold on
errorbar(time,final_freq, Error,'LineStyle','None')
hold on
plot(x,y)
xlabel('Accumulation Time (s)')
ylabel('Cyclotron Frequency (Hz)')
title('Cyc. Freq. Sine Fit')
hold off

% Plot radius fit
figure(2000)
hold on
scatter(time,actual_radii)
hold on
errorbar(time,actual_radii, actual_radii_error,'LineStyle','None') 
hold on
plot(x,y1)
xlabel('Accumulation Time (s)')
ylabel('Radius (mm)')
title('Radius Sine Fit')
hold off

A1_deg = A1*180/pi;
Time = time;
Cyc_Freq = final_freq;
Number_of_Turns = final_n(1:size_time);
Angle = A1(1:size_time)*180/pi;
Radius = actual_radii;
Radius_Error = actual_radii_error;

Cyc_Frequency = coeff(1); % Data tab with final fit cyclotron frequency
Uncertainty = sdev(1);
Red_Chi2 = chi_2;
writetable(table(Cyc_Frequency,Uncertainty,Red_Chi2),filename1,'Sheet','Cyc. Freq.')

T = table(Time,Cyc_Freq,Error,Number_of_Turns,Angle,Radius,Radius_Error);
writetable(T,filename1,'Sheet','Cyc. Freq. Data')

Fit_Parameters = coeff; % Data tab with parameter results for cyclotron frequency sine fit
Uncertainty = sdev;
T1 = table(Fit_Parameters,Uncertainty);
writetable(T1,filename1,'Sheet','Cyc. Freq. Fit Parameters')

RadiusFit = coeff1(1); % Data tab with final fit radius
Uncertainty = sdev1(1);
Red_Chi2 = chi_2_r;
writetable(table(RadiusFit,Uncertainty,Red_Chi2),filename1,'Sheet','Radius')

Fit_Parameters = coeff1; % Data tab with parameter results for radius sine fit
Uncertainty = sdev1;
T2 = table(Fit_Parameters,Uncertainty);
writetable(T2,filename1,'Sheet','Radius Fit Parameters')

print(figure(1000),filename, '-dpng');
print(figure(2000),filename2, '-dpng');

coeff(1)

%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ID Spot
% --- Executes on button press in id_spot.
%
% Given a CenterSpotRedux.csv, print out what w_c those spots could have
% given a certain w_c guess
%
function id_spot_Callback(hObject, eventdata, handles)
% hObject    handle to id_spot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global center_spot_redux

frequencycs = str2num(get(handles.w_c,'String'));

the_end = size(center_spot_redux);
the_end = the_end(1);
data = center_spot_redux(2:the_end,:);

% Actual Center
centerx = str2double(get(handles.tcx,'String'));
centery = str2double(get(handles.tcy,'String'));
centerrorx = .05;
centerrory = .05;

% Tacc
time = data(:,1);
 
% Ref and Angle Data
refx = data(:,7) - centerx;
refy = data(:,8) - centery;
errorrx = (data(:,9).^2 + centerrorx^2);
errorry = (data(:,10).^2 + centerrory^2);
errorrx = errorrx.^.5;
errorry = errorry.^.5;
timeref = data(:,6);
angleactual = data(:,11);
angleref = data(:,12);
 
% Actual Data 
spot1x = data(:,2) - centerx;
spot1y = data(:,3) - centery;
error1x = (data(:,4).^2 + centerrorx^2);
error1y = (data(:,5).^2 + centerrory^2);
error1x = error1x.^.5;
error1y = error1y.^.5;


% Shift Center
centerx = 0;
centery = 0;

husker = length(spot1x);

D = spot1x;
C1= spot1x;
Cref= spot1x;
n=spot1x;

A1= spot1x;

%% Determining Turn Numbers, Spot Distances and Angles 

n_range = str2num(get(handles.n_range,'String')); % Pull num. turns range from GUI

freq = zeros(husker,n_range);
efreq = zeros(husker);

j = 1;

while j <=husker
 gbr = 1;
 letsgo = -(ceil(n_range/2));
 while gbr < n_range + 1
    floor(frequencycs * (time(j)-timeref(j)));
    n(j,gbr) = floor(frequencycs * (time(j)-timeref(j))) + letsgo; % Determine turn numbers from guess w_c
    gbr = gbr + 1;
    letsgo = letsgo + 1;
    
 end

% Spot Distances
D(j) = sqrt((spot1x(j)-refx(j))^2+(spot1y(j)-refy(j))^2);

%Distances
C1(j) = sqrt((centerx-spot1x(j))^2+(centery-spot1y(j))^2);
Cref(j) = sqrt((centerx-refx(j))^2+(centery-refy(j))^2);
C1_error(j) = ((centerx-spot1x(j))^2 + (centery-spot1y(j))^2)^(-3/4)*sqrt((centerx-spot1x(j))^2*error1x(j)^2 + (centery-spot1y(j))^2*error1y(j)^2);


% Spot Angle
A1(j) = acos((-D(j)^2+C1(j)^2+Cref(j)^2)/(2*C1(j)*Cref(j)));

j = j+1; % Prochain

end

%% Angle Conversion

k = 1;

while k <= husker
    % w_c %
    
    if (angleactual(k) - angleref(k) < 0) | (angleactual(k) - angleref(k) > 180)
        A1(k) = 2*pi - A1(k);
    end
    
    % w_minus %
    
    %if (angleref(k) - angleactual(k) < 0) | (angleref(k) - angleactual(k) > 180)
    %    A1(k) = 2*pi - A1(k);
    %end
    k = k + 1;
end

%% Frequency

i = 1;
irish = 1;

while i <= husker
    while irish <= n_range
        freq(i,irish) = (A1(i)+(2*pi*n(i,irish)))/(2*pi*(time(i)-timeref(i))) ; % Determine w_c for each possible turn number
        %freq(irish) = (A1+(2*pi*n))/(2*pi*time1);
        irish = irish + 1;
    end

irish = 1;

    
error1 = sqrt( (Cref(i)^4* ((spot1x(i)^2 * error1y(i)^2) + (spot1y(i)^2 * error1x(i)^2)) + C1(i)^4 * ((refx(i)^2 * errorry(i)^2) + (refy(i)^2 * errorrx(i)^2 ))))/(Cref(i) * C1(i))^2;

efreq(i) = error1/(2*pi*(time(i)-timeref(i)));
efreq(i) = error1/(2*pi*(time(i)-timeref(i)));


i = i+1;


end

% Print Frequencies
target = fullfile(target_path); %added
%target = get(handles.target,'String'); %orig
element = get(handles.isotope,'String');

filename_freq = char(strcat(target,element,'Id_Frequencies.csv'));
dlmwrite(filename_freq,freq,'Precision',10)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Functions Not In Use
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% The following functions are for items in the GUI that have no
% sychronicities/manually-written code.
%
function ydfb_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to ydfb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function rlb_Callback(hObject, eventdata, handles)
% hObject    handle to rlb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rlb as text
%        str2double(get(hObject,'String')) returns contents of rlb as a double


% --- Executes during object creation, after setting all properties.
function rlb_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rlb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function rub_Callback(hObject, eventdata, handles)
% hObject    handle to rub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rub as text
%        str2double(get(hObject,'String')) returns contents of rub as a double


% --- Executes during object creation, after setting all properties.
function rub_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function rc_Callback(hObject, eventdata, handles)
% hObject    handle to rc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rc as text
%        str2double(get(hObject,'String')) returns contents of rc as a double


% --- Executes during object creation, after setting all properties.
function rc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function re_Callback(hObject, eventdata, handles)
% hObject    handle to re (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of re as text
%        str2double(get(hObject,'String')) returns contents of re as a double


% --- Executes during object creation, after setting all properties.
function re_CreateFcn(hObject, eventdata, handles)
% hObject    handle to re (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function alb_Callback(hObject, eventdata, handles)
% hObject    handle to alb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of alb as text
%        str2double(get(hObject,'String')) returns contents of alb as a double


% --- Executes during object creation, after setting all properties.
function alb_CreateFcn(hObject, eventdata, handles)
% hObject    handle to alb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function aub_Callback(hObject, eventdata, handles)
% hObject    handle to aub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of aub as text
%        str2double(get(hObject,'String')) returns contents of aub as a double


% --- Executes during object creation, after setting all properties.
function aub_CreateFcn(hObject, eventdata, handles)
% hObject    handle to aub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ac_Callback(hObject, eventdata, handles)
% hObject    handle to ac (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ac as text
%        str2double(get(hObject,'String')) returns contents of ac as a double


% --- Executes during object creation, after setting all properties.
function ac_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ac (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ae_Callback(hObject, eventdata, handles)
% hObject    handle to ae (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ae as text
%        str2double(get(hObject,'String')) returns contents of ae as a double


% --- Executes during object creation, after setting all properties.
function ae_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ae (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tlb_Callback(hObject, eventdata, handles)
% hObject    handle to tlb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tlb as text
%        str2double(get(hObject,'String')) returns contents of tlb as a double


% --- Executes during object creation, after setting all properties.
function tlb_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tlb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tub_Callback(hObject, eventdata, handles)
% hObject    handle to tub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tub as text
%        str2double(get(hObject,'String')) returns contents of tub as a double


% --- Executes during object creation, after setting all properties.
function tub_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tc_Callback(hObject, eventdata, handles)
% hObject    handle to tc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tc as text
%        str2double(get(hObject,'String')) returns contents of tc as a double


% --- Executes during object creation, after setting all properties.
function tc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function te_Callback(hObject, eventdata, handles)
% hObject    handle to te (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of te as text
%        str2double(get(hObject,'String')) returns contents of te as a double


% --- Executes during object creation, after setting all properties.
function te_CreateFcn(hObject, eventdata, handles)
% hObject    handle to te (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ylb_Callback(hObject, eventdata, handles)
% hObject    handle to ylb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ylb as text
%        str2double(get(hObject,'String')) returns contents of ylb as a double


% --- Executes during object creation, after setting all properties.
function ylb_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ylb (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function yub_Callback(hObject, eventdata, handles)
% hObject    handle to yub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of yub as text
%        str2double(get(hObject,'String')) returns contents of yub as a double


% --- Executes during object creation, after setting all properties.
function yub_CreateFcn(hObject, eventdata, handles)
% hObject    handle to yub (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function yc_Callback(hObject, eventdata, handles)
% hObject    handle to yc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of yc as text
%        str2double(get(hObject,'String')) returns contents of yc as a double


% --- Executes during object creation, after setting all properties.
function yc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to yc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ye_Callback(hObject, eventdata, handles)
% hObject    handle to ye (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ye as text
%        str2double(get(hObject,'String')) returns contents of ye as a double


% --- Executes during object creation, after setting all properties.
function ye_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ye (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function lbx_Callback(hObject, eventdata, handles)
% hObject    handle to lbx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lbx as text
%        str2double(get(hObject,'String')) returns contents of lbx as a double


% --- Executes during object creation, after setting all properties.
function lbx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lbx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ubx_Callback(hObject, eventdata, handles)
% hObject    handle to ubx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ubx as text
%        str2double(get(hObject,'String')) returns contents of ubx as a double


% --- Executes during object creation, after setting all properties.
function ubx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ubx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function xc_Callback(hObject, eventdata, handles)
% hObject    handle to xc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xc as text
%        str2double(get(hObject,'String')) returns contents of xc as a double


% --- Executes during object creation, after setting all properties.
function xc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function xe_Callback(hObject, eventdata, handles)
% hObject    handle to xe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xe as text
%        str2double(get(hObject,'String')) returns contents of xe as a double


% --- Executes during object creation, after setting all properties.
function xe_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function target_Callback(hObject, eventdata, handles)
% hObject    handle to target (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of target as text
%        str2double(get(hObject,'String')) returns contents of target as a double


% --- Executes during object creation, after setting all properties.
function target_CreateFcn(hObject, eventdata, handles)
% hObject    handle to target (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function isotope_Callback(hObject, eventdata, handles  )
% hObject    handle to isotope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of isotope as text
%        str2double(get(hObject,'String')) returns contents of isotope as a double


% --- Executes during object creation, after setting all properties.
function isotope_CreateFcn(hObject, eventdata, handles)
% hObject    handle to isotope (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function actime_Callback(hObject, eventdata, handles)
% hObject    handle to actime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of actime as text
%        str2double(get(hObject,'String')) returns contents of actime as a double


% --- Executes during object creation, after setting all properties.
function actime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to actime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tit_Callback(hObject, eventdata, handles)
% hObject    handle to tit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tit as text
%        str2double(get(hObject,'String')) returns contents of tit as a double


% --- Executes during object creation, after setting all properties.
function tit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function date_Callback(hObject, eventdata, handles)
% hObject    handle to date (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of date as text
%        str2double(get(hObject,'String')) returns contents of date as a double


% --- Executes during object creation, after setting all properties.
function date_CreateFcn(hObject, eventdata, handles)
% hObject    handle to date (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function lowcal_Callback(hObject, eventdata, handles)
% hObject    handle to lowcal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lowcal as text
%        str2double(get(hObject,'String')) returns contents of lowcal as a double


% --- Executes during object creation, after setting all properties.
function lowcal_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lowcal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tcx_Callback(hObject, eventdata, handles)
% hObject    handle to tcx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tcx as text
%        str2double(get(hObject,'String')) returns contents of tcx as a double


% --- Executes during object creation, after setting all properties.
function tcx_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tcx (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function tcy_Callback(hObject, eventdata, handles)
% hObject    handle to tcy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of tcy as text
%        str2double(get(hObject,'String')) returns contents of tcy as a double


% --- Executes during object creation, after setting all properties.
function tcy_CreateFcn(hObject, eventdata, handles)
% hObject    handle to tcy (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function filename_Callback(hObject, eventdata, handles)
% hObject    handle to filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of filename as text
%        str2double(get(hObject,'String')) returns contents of filename as a double


% --- Executes during object creation, after setting all properties.

function filename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to filename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function spot_center_guess_x_Callback(hObject, eventdata, handles)
% hObject    handle to spot_center_guess_x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of spot_center_guess_x as text
%        str2double(get(hObject,'String')) returns contents of spot_center_guess_x as a double


% --- Executes during object creation, after setting all properties.
function spot_center_guess_x_CreateFcn(hObject, eventdata, handles)
% hObject    handle to spot_center_guess_x (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function spot_center_guess_y_Callback(hObject, eventdata, handles)
% hObject    handle to spot_center_guess_y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of spot_center_guess_y as text
%        str2double(get(hObject,'String')) returns contents of spot_center_guess_y as a double


% --- Executes during object creation, after setting all properties.
function spot_center_guess_y_CreateFcn(hObject, eventdata, handles)
% hObject    handle to spot_center_guess_y (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function fit_radius_Callback(hObject, eventdata, handles)
% hObject    handle to fit_radius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fit_radius as text
%        str2double(get(hObject,'String')) returns contents of fit_radius as a double


% --- Executes during object creation, after setting all properties.
function fit_radius_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fit_radius (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function list_of_files_text_Callback(hObject, eventdata, handles)
% hObject    handle to list_of_files_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of list_of_files_text as text
%        str2double(get(hObject,'String')) returns contents of list_of_files_text as a double


% --- Executes during object creation, after setting all properties.
function list_of_files_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to list_of_files_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%
function w_c_Callback(hObject, eventdata, handles)
% hObject    handle to w_c (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of w_c as text
%        str2double(get(hObject,'String')) returns contents of w_c as a double


% --- Executes during object creation, after setting all properties.
function w_c_CreateFcn(hObject, eventdata, handles)
% hObject    handle to w_c (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function ion_number_text_Callback(hObject, eventdata, handles)
% hObject    handle to ion_number_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ion_number_text as text
%        str2double(get(hObject,'String')) returns contents of ion_number_text as a double


% --- Executes during object creation, after setting all properties.
function ion_number_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ion_number_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function csr_csv_Callback(hObject, eventdata, handles)
% hObject    handle to csr_csv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of csr_csv as text
%        str2double(get(hObject,'String')) returns contents of csr_csv as a double


% --- Executes during object creation, after setting all properties.
function csr_csv_CreateFcn(hObject, eventdata, handles)
% hObject    handle to csr_csv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%
function radii_list_Callback(hObject, eventdata, handles)
% hObject    handle to radii_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of radii_list as text
%        str2double(get(hObject,'String')) returns contents of radii_list as a double


% --- Executes during object creation, after setting all properties.
function radii_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to radii_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in ind_cyc_freq.
function ind_cyc_freq_Callback(hObject, eventdata, handles)
% hObject    handle to ind_cyc_freq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function ion_rate_Callback(hObject, eventdata, handles)
% hObject    handle to ion_rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ion_rate as text
%        str2double(get(hObject,'String')) returns contents of ion_rate as a double


% --- Executes during object creation, after setting all properties.
function ion_rate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ion_rate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function percentage_Callback(hObject, eventdata, handles)
% hObject    handle to percentage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of percentage as text
%        str2double(get(hObject,'String')) returns contents of percentage as a double


% --- Executes during object creation, after setting all properties.
function percentage_CreateFcn(hObject, eventdata, handles)
% hObject    handle to percentage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function num_spots_Callback(hObject, eventdata, handles)
% hObject    handle to num_spots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of num_spots as text
%        str2double(get(hObject,'String')) returns contents of num_spots as a double


% --- Executes during object creation, after setting all properties.
function num_spots_CreateFcn(hObject, eventdata, handles)
% hObject    handle to num_spots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function n_range_Callback(hObject, eventdata, handles)
% hObject    handle to n_range (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of n_range as text
%        str2double(get(hObject,'String')) returns contents of n_range as a double


% --- Executes during object creation, after setting all properties.
function n_range_CreateFcn(hObject, eventdata, handles)
% hObject    handle to n_range (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in createCSR.
function createCSR_Callback(hObject, eventdata, handles)
% hObject    handle to createCSR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of createCSR


% --- Executes on button press in checkbox_spotID.
function checkbox_spotID_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_spotID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_spotID


% --- Executes on button press in checkbox_finish_analysis.
function checkbox_finish_analysis_Callback(hObject, eventdata, handles)
% hObject    handle to checkbox_finish_analysis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkbox_finish_analysis

function checkbox_sinecurvefitting_Callback(hObject, eventdata, handles)


% --- Executes on button press in angle_correction_impurebeam.
function angle_correction_impurebeam_Callback(hObject, eventdata, handles)
% hObject    handle to angle_correction_impurebeam (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of angle_correction_impurebeam



function spot_angle_Callback(hObject, eventdata, handles)
% hObject    handle to spot_angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of spot_angle as text
%        str2double(get(hObject,'String')) returns contents of spot_angle as a double


% --- Executes during object creation, after setting all properties.
function spot_angle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to spot_angle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in phase_cut_check.
function phase_cut_check_Callback(hObject, eventdata, handles)
% hObject    handle to phase_cut_check (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of phase_cut_check



function phase_cut_Callback(hObject, eventdata, handles)
% hObject    handle to phase_cut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of phase_cut as text
%        str2double(get(hObject,'String')) returns contents of phase_cut as a double


% --- Executes during object creation, after setting all properties.
function phase_cut_CreateFcn(hObject, eventdata, handles)
% hObject    handle to phase_cut (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ppc_Callback(hObject, eventdata, handles)
% hObject    handle to ppc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ppc as text
%        str2double(get(hObject,'String')) returns contents of ppc as a double


% --- Executes during object creation, after setting all properties.
function ppc_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ppc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in ionrate_onoff.
function ionrate_onoff_Callback(hObject, eventdata, handles)
% hObject    handle to ionrate_onoff (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ionrate_onoff



function bandwidth_Callback(hObject, eventdata, handles)
% hObject    handle to bandwidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bandwidth as text
%        str2double(get(hObject,'String')) returns contents of bandwidth as a double


% --- Executes during object creation, after setting all properties.
function bandwidth_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bandwidth (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function wminus_Callback(hObject, eventdata, handles)
% hObject    handle to wminus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of wminus as text
%        str2double(get(hObject,'String')) returns contents of wminus as a double


% --- Executes during object creation, after setting all properties.
function wminus_CreateFcn(hObject, eventdata, handles)
% hObject    handle to wminus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in open_list_of_files_button.
function pushbutton17_Callback(hObject, eventdata, handles)
% hObject    handle to open_list_of_files_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object deletion, before destroying properties.
function text46_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to text46 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object deletion, before destroying properties.
function target_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to target (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object deletion, before destroying properties.
function text32_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to text32 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
