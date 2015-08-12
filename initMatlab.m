if ispc
    mount_point = 'Z:';
    % this is necessary to have access to filename2os_fname.m
    addpath( horzcat( mount_point, '\MATLAB\file_utils') );
end

if isunix
    mount_point = '/mnt/qol_grp_data';
    % this is necessary to have access to filename2os_fname.m
    addpath( horzcat( mount_point, '/MATLAB/file_utils') );
    addpath( horzcat( mount_point, '/MATLAB/linux-matlab-gpib') );
end

%% get access to computer dependent staff
path2add = horzcat( mount_point, '/MATLAB/computer_dependent/', getComputerName());
path2add = filename2os_fname( path2add );
addpath( path2add );


