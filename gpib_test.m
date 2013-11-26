%% Open scope
%
% get a handle to the oscilloscope from /etc/gpib.conf
%
hscope = gpib_function('ibfind','LECROY_WR');
%% Write a message
%
% Send the *IDN? message to the scope
%
[status,write_count] = gpib_function('ibwrt',hscope,'*IDN?');
fprintf('status = 0x%04X\nwrite_count = %d bytes\n',status,write_count);
%% Read the reply
%
% Show the identifier returned by the LeCroy
%
[reply,status,read_count] = gpib_function('ibrdl',hscope,4096);
fprintf('reply = %s\nstatus = 0x%04X\nread_count = %d bytes\n',strtrim(reply),status,read_count);