% This script reads data from HP8596E spectrum analyzer and saves it to a file
%
% Mi Zhang (Revised from the code of Gleb Romanov   gromanov@hellok.org)
% 9/25/2013

clear;



% Define stuff
board_index = 0;
gpib_address = 18;
data_prefix = 'S';
data_path = 'Z:\Mi Squeezing\buffered cell\data\';
run_number_file = 'Z:\Mi Squeezing\85Rb\autofile\runnum.dat';

% Find a GPIB object.
obj1 = instrfind('Type', 'gpib', 'BoardIndex', board_index, 'PrimaryAddress', gpib_address, 'Tag', '');

% Create the GPIB object if it does not exist
% otherwise use the object that was found.
if isempty(obj1)
    %obj1 = gpib('NI', board_index, gpib_address);
    obj1 = lgpib('HP8596E');
else
    fclose(obj1);
    obj1 = obj1(1);
end

% Adjust the buffers so the traces fit.
% Do this before fopen(obj1);
%obj1.InputBufferSize  = 10240;
%obj1.OutputBufferSize = 10240;

% Connect to instrument object, obj1.
%fopen(obj1);
disp('--------------------')
disp(horzcat('Connected to ',query(obj1, 'ID?')));

% Communicating with instrument object, obj1.
%
% You can send commands using:
% fprintf(obj1, '_command_');
%
% Or read stuff using:
% _data_ = query(obj1, '_command_');
disp('Reading data...');

% We want our data in dB
write(obj1, 'O3');

% Read all 3 traces
trA_string = query(obj1, 'TRA?');
trB_string = query(obj1, 'TRB?');
trC_string = query(obj1, 'TRC?');

% Read various stuff
device_string = query(obj1, 'ID?');
freq_start_string = query(obj1, 'FA?');
freq_stop_string = query(obj1, 'FB?');
freq_center_string = query(obj1, 'CF?');
freq_span_string = query(obj1, 'SP?');
amplitude_units_string = query(obj1, 'AUNITS?');
attenuation_string = query(obj1, 'AT?');
ref_level_string = query(obj1, 'RL?');
log_scale_string = query(obj1, 'LG?');
rbw_string = query(obj1, 'RB?');
vbw_string = query(obj1, 'VB?');
sweep_time_string = query(obj1, 'ST?');

% Disconnect from instrument object, obj1.
clear(obj1);
disp('Done');

% Convert the traces from strings into vectors
trA = sscanf(trA_string,'%f,');
trB = sscanf(trB_string,'%f,');
trC = sscanf(trC_string,'%f,');

% Transpose the vectors
trA = trA';
trB = trB';
trC = trC';

% Create the frequency trace
freq_start = sscanf(freq_start_string, '%f');
freq_stop = sscanf(freq_stop_string, '%f');
span = freq_stop - freq_start;
freq = 0:length(trA)-1;
freq = freq/max(freq);
freq = freq_start + freq * span;


% Plot stuff
%
% Open a window

figure1 = figure(1);
close(figure1);
figure1 = figure(1);
%
% Create axes
axes1 = axes('Parent',figure1,'YGrid','on','XGrid','on','FontSize',14);
box(axes1,'on');
hold(axes1,'all');
%ylim([-2,12])
%ylim([-85,-70])
%
% Create plot
plot(freq/1e3,trA,'Color',[1 0 0],'Parent',axes1,'DisplayName','Trace A')
plot(freq/1e3,trB,'Color',[0 0 0],'Parent',axes1,'DisplayName','Trace B')
plot(freq/1e3,trC,'Color',[0 1 0],'Parent',axes1,'DisplayName','Trace C')
%
% Create xlabel
xlabel('Detection frequency, kHz','FontSize',14);
%
% Create ylabel
ylabel('Noise power, dB','FontSize',14);
%
% Show legend
legend('show');


% Plot with shot noise subtracted
%
% Open a window
figure2 = figure(2);
close(figure2);
figure2 = figure(2);
%
% Create axes
axes2 = axes('Parent',figure2,'YGrid','on','XGrid','on','FontSize',14);
box(axes2,'on');
hold(axes2,'all');
%ylim([-2,12])
%ylim([-85,-70])
%
% Create plot
plot(freq/1e6,trA-trA,'Color',[1 0 0],'Parent',axes2,'DisplayName','Zero')
plot(freq/1e6,trB-trA,'Color',[0 0 0],'Parent',axes2,'DisplayName','B - A')
plot(freq/1e6,trC-trA,'Color',[0 1 0],'Parent',axes2,'DisplayName','C - A')
%
% Create xlabel
xlabel('Detection frequency, MHz','FontSize',14);
%
% Create ylabel
ylabel('Noise power, dB','FontSize',14);
%
% Show legend
legend('show');
%
drawnow;



% Open the file containing the run number and read it

run_number_file_handle = fopen(run_number_file,'r');
run_number = fscanf(run_number_file_handle,'%d');
fclose(run_number_file_handle);
% Increment it and write back
run_number = run_number + 1;
if run_number > 999
    run_number = 0;
end;
run_number_file_handle = fopen(run_number_file,'w');
fprintf(run_number_file_handle, '%.3d', run_number);
fclose(run_number_file_handle);




% Get full path of the file to save

save_to_file = horzcat(data_path,'S',num2str(run_number),'D',datestr(date,'yyyymmdd'),'.dat');

% Write the data to a file
disp(' ');
disp(horzcat('Saving data to ',save_to_file));
save_to_file_handle = fopen(save_to_file,'wt');
fprintf(save_to_file_handle,'%s','# 14  (header lines)');
fprintf(save_to_file_handle,'\n');
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
%
% An example of how you shouldn't write data:
%
% for i = 1:length(freq)
%    fprintf(save_to_file_handle,'%s',sprintf('%f',freq(i)));
%    fprintf(save_to_file_handle,'\t');
%    fprintf(save_to_file_handle,'%s',sprintf('%f',trA(i)));
%    fprintf(save_to_file_handle,'\t');
%    fprintf(save_to_file_handle,'%s',sprintf('%f',trB(i)));
%    fprintf(save_to_file_handle,'\n');
% end;
%
% This is much faster:
data = [freq; trA; trB; trC;];
fprintf(save_to_file_handle,'%f\t%f\t%f\t%f\r\n',data);
% Close the file
fclose(save_to_file_handle);
disp('Done');

% Close all opened files
fclose('all');

% Bring focus back to the command window
commandwindow;
