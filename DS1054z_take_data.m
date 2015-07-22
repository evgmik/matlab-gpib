function [time, channel1, channel2, channel3, channel4] = DS1054z_take_data(scope_visa_name, data_save_flag, data_plot_flag)
%% This script reads data from Rigol DS1054z Digital Oscilloscope via the VISA interface and plots the four channels

savepath =  'Z:\gyro_data\data\';

%% Find and access VISA object.
% scope_visa_name = 'USB0::0x1AB1::0x04CE::DS1ZA170502787::0::INSTR';

% instrfind has different name convention
% instr_name_for_instrfind = strrep( scope_visa_name, '::INSTR', '::0::INSTR');
obj1 = instrfind('Type', 'visa-usb', 'RsrcName', scope_visa_name, 'Tag', '');

% Create the VISA object if it does not exist
% otherwise use the object that was found.
%if isempty(obj1)
    %obj1 = visa('ni', scope_visa_name);
%else
    %fclose(obj1);
    %obj1 = obj1(1);
%end;

%% Configure instrument object, obj1
%set(obj1, 'InputBufferSize', 512000);
%set(obj1, 'OutputBufferSize', 512000);

% Connect to instrument object, obj1.
%fopen(obj1);

obj1=fopen('/dev/usbtmc0');
%% Initial adjustments on scope in preparation for aquizition
%fwrite(obj1,':STOP'); % stop aquiring new data on scope
%fwrite(obj1,':WAVEFORM:POINS:MODE RAW'); % about 8k points expected
%fwrite(obj1,':WAVEFORM:POINS:MODE NOR'); % 600 points expected


%% grab a channel function
function Vchan=grab_channel(chanName)
% Read a waveform from a given channel
    fwrite(obj1, horzcat(':WAVEFORM:SOURCE ', chanName) );
    fwrite(obj1,':WAVEFORM:FORMAT ASCII'); % ascii returns 1200 points
    %fwrite(obj1,':WAVEFORM:FORMAT BYTE');
    %fwrite(obj1, 'WAVeform:STOP 10000');
    fwrite(obj1,':WAVEFORM:MODE NORMAL');
    %fwrite(obj1,':WAVEFORM:MODE MAXIMUM');
    %fwrite(obj1,':WAVEFORM:MODE RAW');
    data1 = query(obj1, ':WAVEFORM:DATA?');
    Vchan = sscanf(data1(12:end), '%f,');
end

%% grab channels
channel1 = grab_channel('CHANNEL1');
channel2 = grab_channel('CHANNEL2');
channel3 = grab_channel('CHANNEL3');
channel4 = grab_channel('CHANNEL4');

Npnts=length(channel1);

%% grab and prepare timing information
timescale_str = query(obj1, ':TIMEBASE:MAIN:SCALE?');
timescale = sscanf( timescale_str, '%f');

timeoffset_str = query(obj1, ':TIMEBASE:MAIN:OFFSET?');
timeoffset = sscanf( timeoffset_str, '%f');

time = linspace( -Npnts/2 , Npnts/2, Npnts) * timescale*12/Npnts;
time = time + timeoffset;
time = time';

%% which scope was used
deviceid = query(obj1, '*IDN?');

%% clean up of scope state
%fwrite(obj1,':RUN'); % switch scope into aquiring mode
%fwrite(obj1,':KEY:FORCE'); % return control to user

%% Disconnect from instrument object, obj1.
fclose(obj1);


%% Save data to a file
if (data_save_flag) 

% first we need iteration number
run_number = get_runnum( savepath );

% generate data file name
data_file_base = horzcat( ...
    savepath ...
    , 'S' ...
    , datestr(date,'yyyymmdd') ...
    , '_', num2str(run_number,'%05.f') ...
    );
save_to_file = horzcat( data_file_base, '.dat' );

% report to user the filename
disp(' ');
disp(horzcat('Saving data to ',save_to_file));

%% open data file
save_to_file_handle = fopen(save_to_file,'wt');

%% finally save data
% header first
comment_symbol='%';
str=horzcat(comment_symbol,' ', datestr(clock));
fprintf(save_to_file_handle,'%s', str);
fprintf(save_to_file_handle,'\n');
str=horzcat(comment_symbol,' ','Device:', '   ', deviceid);
fprintf(save_to_file_handle,'%s', str);
fprintf(save_to_file_handle,'\n');

% here comes the data
data = [time, channel1, channel2, channel3, channel4];
[nrows, ncols] = size(data);
fmtstr='%e';
for i=1:(ncols-1)
    fmtstr=horzcat(fmtstr, '\t%e');
end
fmtstr=horzcat(fmtstr, '\n');
fprintf(save_to_file_handle, fmtstr,data'); % do not forget to transpone columniwise data !!!

% Close the file
fclose(save_to_file_handle);

end % end of data save if

%% Plot the scope data
if (data_plot_flag)
plot(time,channel1,'DisplayName','channel1','Color','black');
hold all;
plot(time,channel2,'DisplayName','channel2','Color','Cyan');
plot(time,channel3,'DisplayName','channel3','Color','Magenta');
plot(time,channel4,'DisplayName','channel4','Color','Blue');
grid on
hold off;
xlabel('Time (s)');
ylabel('Voltage (V)');
legend('show');
end % end of data plot if

if (data_save_flag && data_plot_flag)
fig_fname = horzcat( data_file_base, '.png' );
print( '-opengl','-r300', '-dpng', fig_fname);
fig_fname = horzcat( data_file_base, '.eps' );
print( '-painters','-r600','-depsc2', fig_fname);
end


disp('Done');


end
