function spectrum_analyzer = E4440a_take_data(data_save_flag, data_plot_flag)
% This script reads data from E440a spectrum analyzer and saves it to a file
%
% Eugeniy E. Mikhailov eemikh@wm.edu
% Gleb Romanov   gromanov@hellok.org
% 6/20/2013
% 7/20/2015 added a choice for saving and plotting

%% some sane defaults

switch (nargin)
    case 0
        data_plot_flag = true;
        data_save_flag = true;
    case 1
        data_plot_flag = true;
    case 2
        % we are good, nothing to do
    otherwise
        warning('Mora arguments than needed are provided');
        data_plot_flag = true;
        data_save_flag = true;
end

%% Define instrument parameters
board_index = 0;
gpib_address = 21;
bufSize = 100000;

%% Data file parameters
data_prefix = 'S';
data_path = 'Z:\qol_comp_data\data\';
run_number_file = 'Z:\qol_comp_data\data\autofile\runnum.dat';

%% Find and initialize instrument
%obj1 = instrfind('Type', 'gpib', 'BoardIndex', board_index, 'PrimaryAddress', gpib_address, 'Tag', '');

% Create the GPIB object if it does not exist
% otherwise use the object that was found.
%if isempty(obj1)
    %obj1 = gpib('NI', board_index, gpib_address);
%else
    %fclose(obj1);
    %obj1 = obj1(1);
%end


% Adjust the buffers so the traces fit.
% Do this before fopen(obj1);
%obj1.InputBufferSize  = bufSize;
%obj1.OutputBufferSize = bufSize;

obj1=lgpib('Agilent_E4405b')
%% Connect to instrument object, obj1.
%fopen(obj1);
disp('--------------------')
device_string = query(obj1, '*IDN?');
disp(horzcat('Connected to ', device_string));

% Communicating with instrument object, obj1.
%
% You can send commands using:
% fprintf(obj1, '_command_');
%
% Or read stuff using:
% _data_ = query(obj1, '_command_');
disp('Reading traces...');
%% Read traces
% switch to ASCII trace transfer
write(obj1, ':FORMAT:TRACE:DATA ASCII');
tr1_string = query(obj1, ':TRACE:DATA? TRACE1;');
tr2_string = query(obj1, ':TRACE:DATA? TRACE2;');
tr3_string = query(obj1, ':TRACE:DATA? TRACE3;');

disp('Reading Spectrum Analyzer parameters...');
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
%fclose(obj1);
disp('Spectrum Analyzer data communincation is done');

%% Convert the traces from strings into vectors
tr1 = sscanf(tr1_string, '%f,');
tr2 = sscanf(tr2_string, '%f,');
tr3 = sscanf(tr3_string, '%f,');

% Transpose the vectors
tr1 = tr1';
tr2 = tr2';
tr3 = tr3';

% Create the frequency vector
freq_start = sscanf(freq_start_string, '%f');
freq_stop = sscanf(freq_stop_string, '%f');
Npoints = length(tr1);
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
    save_to_file = qol_get_next_data_file( data_prefix, data_path, run_number_file );
    %
    % Write the data to a file
    disp(' ');
    disp(horzcat('Saving data to ',save_to_file));
    save_to_file_handle = fopen(save_to_file,'wt');
    fprintf(save_to_file_handle,'%s',horzcat('# ', datestr(clock)));
    fprintf(save_to_file_handle,'\n');
    fprintf(save_to_file_handle,'%s',horzcat('# Device:', '   ', device_string));
    fprintf(save_to_file_handle,'%s',horzcat('# Frequency center, Hz', '   ', freq_center_string));
    fprintf(save_to_file_handle,'%s',horzcat('# Frequency span, Hz', '   ', freq_span_string));
    fprintf(save_to_file_handle,'%s',horzcat('# Frequency start, Hz', '   ', freq_start_string));
    fprintf(save_to_file_handle,'%s',horzcat('# Frequency stop, Hz', '   ', freq_stop_string));
    fprintf(save_to_file_handle,'%s',horzcat('# Amplitude units      ', amplitude_units_string));
    fprintf(save_to_file_handle,'%s',horzcat('# Attenuation      ', attenuation_string));
    fprintf(save_to_file_handle,'%s',horzcat('# Reference level     ', ref_level_string));
    fprintf(save_to_file_handle,'%s',horzcat('# Log scale    ', log_scale_string));
    fprintf(save_to_file_handle,'%s',horzcat('# Resolution bandwidth, Hz', '   ', rbw_string));
    fprintf(save_to_file_handle,'%s',horzcat('# Video bandwidth, Hz', '   ', vbw_string));
    fprintf(save_to_file_handle,'%s',horzcat('# Sweep time, seconds', '   ', sweep_time_string));
    
    % saving traces data
    data = [freq; tr1; tr2; tr3];
    fprintf(save_to_file_handle,'%f\t%f\t%f\t%f\n',data);
    % Close the file
    fclose(save_to_file_handle);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if (data_plot_flag)
    %% Plot raw traces
    %
    % Open a window
    figure111 = figure(111);
    %close(figure111);
    %figure1 = figure(111);
    %
    % Create axes
    axes1 = axes('Parent',figure111,'YGrid','on','XGrid','on','FontSize',14);
    box(axes1,'on');
    hold(axes1,'all');
    %ylim([-2,12])
    %ylim([-85,-70])
    %
    % Create plot
    plot(freq/1e6,tr1,'Color',[1 0 0],'Parent',axes1,'DisplayName','Trace 1')
    plot(freq/1e6,tr2,'Color',[0 0 0],'Parent',axes1,'DisplayName','Trace 2')
    plot(freq/1e6,tr3,'Color',[0 0 1],'Parent',axes1,'DisplayName','Trace 3')
    %
    % Create xlabel
    xlabel('Detection frequency, MHz','FontSize',14);
    %
    % Create ylabel
    ylabel('Noise power, dBm','FontSize',14);
    %
    % Show legend
    legend('show');
    grid on;
    
    
    %% Plot processed traces
    
    % Open a window
    figure222 = figure(222);
    close(figure222);
    figure222 = figure(222);
    %
    % Create axes
    axes2 = axes('Parent',figure222,'YGrid','on','XGrid','on','FontSize',14);
    box(axes2,'on');
    hold(axes2,'all');
    %ylim([-2,12])
    %ylim([-85,-70])
    %
    % Create plot
    plot(freq/1e6,tr1-tr1,'Color',[0 0 0],'Parent',axes2,'DisplayName','Zero')
    plot(freq/1e6,tr2-tr1,'Color',[1 0 0],'Parent',axes2,'DisplayName','Tr2 - Tr1')
    plot(freq/1e6,tr3-tr1,'Color',[0 0 1],'Parent',axes2,'DisplayName','Tr3 - Tr1')
    %
    % Create xlabel
    xlabel('Detection frequency, MHz','FontSize',14);
    %
    % Create ylabel
    ylabel('Noise power, dB','FontSize',14);
    %
    % Show legend
    legend('show');
end

%drawnow;



%% Finish up and cleanup
% Close all opened files
fclose('all');

% Bring focus back to the command window
%commandwindow;
