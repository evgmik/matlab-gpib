function spectrum_analyzer = E4440a_take_data(varargin)
% This script reads data from E440a spectrum analyzer and saves it to a file
% E4440a_take_data( data_save_flag, data_plot_flag, channels_to_grab_flag, data_save_path, data_file_prefix )
%  channels_to_grab_flag - is boolean array with true/false for the particular channel
%  for example channels_to_grab_flag = [ false true true ] will grab only traces 2 and 3
%
% Eugeniy E. Mikhailov eemikh@wm.edu
% Gleb Romanov   gromanov@hellok.org
% 8/12/2015 linux friendly and use of lab file utils
% 7/27/2015 added a choice to save only specific channels 
% 7/20/2015 added a choice for saving and plotting
% 6/20/2013

%% some sane defaults
nVarargs = length(varargin);
if (nVarargs > 5 )
    error ('wrong number of arguments');
end
if (nVarargs < 5 )
    data_file_prefix = 'S';
else
    data_file_prefix = varargin{5};
end
if (nVarargs < 4 )
    data_path = 'Z:\qol_comp_data\data\'; 
    % do not worry it will convert Z: to proper path in linux
else
    data_path = varargin{4};
end
if (nVarargs < 3 )
    channels_to_grab_flag = [ true, true, true];  % grab all channels
else
    channels_to_grab_flag = varargin{3};
end
if (nVarargs < 2 )
    data_plot_flag = true;  % Default to plot Data 
else
    data_plot_flag = varargin{2};
end
if (nVarargs < 1 )
    data_save_flag = true; % Default to save data
else
    data_save_flag = varargin{1};
end




%% Windows computer parameters
if ispc 
    % Define instrument parameters
    board_index = 0;
    gpib_address = 21;
    bufSize = 100000;

    %% Find and initialize instrument
    obj1 = instrfind('Type', 'gpib', 'BoardIndex', board_index, 'PrimaryAddress', gpib_address, 'Tag', '');
    % alternatively
    % obj1 = instrfind('Type', 'visa-gpib', 'RsrcName', 'GPIB0::21::INSTR', 'Tag', '');

    % Create the GPIB object if it does not exist
    % otherwise use the object that was found.
    if isempty(obj1)
        obj1 = gpib('NI', board_index, gpib_address);
    else
        fclose(obj1);
        obj1 = obj1(1);
    end

    % Adjust the buffers so the traces fit.
    % Do this before fopen(obj1);
    obj1.InputBufferSize  = bufSize;
    obj1.OutputBufferSize = bufSize;

    %% Connect to instrument object, obj1.
    fopen(obj1);
end

%% Unix specific parameters
if isunix 
    obj1=lgpib('Agilent_E4405b')
end

%disp('--------------------')
device_string = query(obj1, '*IDN?');
%disp(horzcat('Connected to ', device_string));

% Communicating with instrument object, obj1.
%
% You can send commands using:
% fprintf(obj1, '_command_');
%
% Or read stuff using:
% _data_ = query(obj1, '_command_');
%disp('Reading traces...');

%% Find number of points
Npoints_string = query(obj1, ':SENSe:SWEep:POINts?');
Npoints = sscanf(Npoints_string, '%f');
%Npoints=4695;

tr1 = NaN(Npoints,1);   % refill traces with NaN 
tr2 = NaN(Npoints,1);
tr3 = NaN(Npoints,1);

%% Read traces
% switch to ASCII trace transfer
fwrite(obj1, ':FORMAT:TRACE:DATA ASCII');

if channels_to_grab_flag(1);      
tr1_string = query(obj1, ':TRACE:DATA? TRACE1;'); % select traces to grab
end 

if channels_to_grab_flag(2);
tr2_string = query(obj1, ':TRACE:DATA? TRACE2;');

end
if channels_to_grab_flag(3); 
tr3_string = query(obj1, ':TRACE:DATA? TRACE3;');
end 

%disp('Reading Spectrum Analyzer parameters...');
%% Read various spectrum analyzer parameters
freq_start_string = query(obj1, ':SENSE:FREQUENCY:START?');
freq_stop_string = query(obj1, ':SENSE:FREQUENCY:STOP?');
freq_center_string = query(obj1, ':SENSE:FREQUENCY:CENTER?');
freq_span_string = query(obj1, ':SENSE:FREQUENCY:SPAN?');
amplitude_units_string = query(obj1, ':UNIT:POWER?');
attenuation_string = query(obj1, ':SENSE:POWER:RF:ATTenuation?');
ref_level_string = query(obj1, ':DISPLAY:WINDOW:TRACE:Y:SCALE:RLEVEL?');

log_scale_string = query(obj1, ':DISPlAY:WINDOW:TRACE:Y:SCALE:PDIVISION?');

rbw_string = query(obj1, 'SENSE:BANDWIDTH:RESOLUTION?');
vbw_string = query(obj1, 'SENSE:BANDWIDTH:VIDEO?');
sweep_time_string = query(obj1, ':SENSE:SWEEP:TIME?');

%% Disconnect from instrument object, obj1.
if ispc
    % windows needs to close the file
    fclose(obj1);
end

%disp('Spectrum Analyzer data communincation is done');

%% Convert the grabbed traces from strings into vectors 
if channels_to_grab_flag(1);
tr1 = sscanf(tr1_string, '%f,');
end

if channels_to_grab_flag(2);
tr2 = sscanf(tr2_string, '%f,');
end 

if channels_to_grab_flag(3);
tr3 = sscanf(tr3_string, '%f,');
end 

% Transpose the vectors
tr1 = tr1';
tr2 = tr2';
tr3 = tr3';

% Create the frequency vector
freq_start = sscanf(freq_start_string, '%f');
freq_stop = sscanf(freq_stop_string, '%f');
freq = linspace(freq_start,freq_stop, Npoints);



% Create spectrum analyzer structure
spectrum_analyzer.traces=[tr1',tr2', tr3'];
spectrum_analyzer.freq=freq';
spectrum_analyzer.RBW=sscanf(rbw_string, '%f');
spectrum_analyzer.VBW=sscanf(vbw_string, '%f');
spectrum_analyzer.sweep_time=sscanf(sweep_time_string, '%f');

%% Save data to a file
if (data_save_flag)
    % Get full path of the file to save
    save_to_file = qol_get_next_data_file( data_file_prefix, data_path );

    % Write the data to a file
    %disp(' ');
    disp(horzcat('Saving data to ',save_to_file));
    header = { ...
        horzcat(datestr(clock)) ...
        , horzcat('Device:', '   ', device_string) ...
        , horzcat('Frequency center, Hz', '   ', freq_center_string) ...
        , horzcat('Frequency span, Hz', '   ', freq_span_string) ...
        , horzcat('Frequency start, Hz', '   ', freq_start_string) ...
        , horzcat('Frequency stop, Hz', '   ', freq_stop_string) ...
        , horzcat('Amplitude units      ', amplitude_units_string) ...
        , horzcat('Attenuation      ', attenuation_string) ...
        , horzcat('Reference level     ', ref_level_string) ...
        , horzcat('Log scale    ', log_scale_string) ...
        , horzcat('Resolution bandwidth, Hz', '   ', rbw_string) ...
        , horzcat('Video bandwidth, Hz', '   ', vbw_string) ...
        , horzcat('Sweep time, seconds', '   ', sweep_time_string) ...
        , horzcat('Columns are : freq tr1 tr2 tr3') ...
    };
    
    % preparing data in column wise fashion
    data = [freq; tr1; tr2; tr3];
    data = data'; % now data is column wise
    save_table_with_header(save_to_file, data, header, '%');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if (data_plot_flag)
    %% Plot raw traces
    %
    % Open a window
    figure111 = figure(111);
    % Create plot
    plot(freq/1e6, tr1, 'Color', [1 0 0], 'DisplayName', 'Trace 1'); hold on
    plot(freq/1e6, tr2, 'Color', [0 0 0], 'DisplayName', 'Trace 2');
    plot(freq/1e6, tr3, 'Color', [0 0 1], 'DisplayName', 'Trace 3'); hold off
    
    xlabel('Detection frequency, MHz','FontSize',14);
    ylabel('Noise power, dBm','FontSize',14);

    % Show legend
    legend('show');
    grid on;
end

%drawnow;

%% Finish up and cleanup
% Close all opened files
fclose('all');

% Bring focus back to the command window
%commandwindow;
