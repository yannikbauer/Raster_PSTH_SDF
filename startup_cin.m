% THIS IS THE DEFAULT STARTUP SCRIPT TO RUN DATAJOINT USING THE BINARIES
% AND SCHEMAS FROM THE LAB SHARE ON HUXLEY


% Reset persistent objects to enforce reconnect
clear functions;

% Set directories that are needed by the database scripts.
global DJ_DIRS

% Base dirs
DJ_DIRS.lab = fullfile(filesep, 'Volumes', 'busse_lab');
DJ_DIRS.data = fullfile(filesep,'Volumes', 'busse_data');

% Sub dirs
DJ_DIRS.binaries = fullfile(DJ_DIRS.lab, 'binaries');
DJ_DIRS.code = fullfile(filesep, 'Volumes', 'code');

% Special dirs
DJ_DIRS.logs = fullfile(DJ_DIRS.data, 'blab', 'logs');
DJ_DIRS.blackrockSettings = fullfile(DJ_DIRS.data, 'blab', 'blackrockSettings');
DJ_DIRS.ephys = fullfile(DJ_DIRS.data, 'blab', 'ephys');
DJ_DIRS.iTracking = fullfile(DJ_DIRS.data, 'blab', 'iTracking');
DJ_DIRS.iPosition = fullfile(DJ_DIRS.data, 'blab', 'iPosition');

% Prefix and sufixes
DJ_DIRS.suffix.unsorted_folder = '-all';

% Check if lab share is mounted
if(~exist(DJ_DIRS.lab, 'file'))
    fprintf(2, 'You need to mount the lab share and rerun the startup script before you will be able to access the database.\n');
    return;
end

% Check if data share is mounted
if(~exist(DJ_DIRS.data, 'file'))
    fprintf(2, 'Data could not be found, import/populate might not be possible.\n');
end

% Include into search path directories that come with DataJoint
addpath(fullfile(DJ_DIRS.binaries, 'DataJoint', 'matlab'))
% Include our version of mym (version that comes with datajoint does not compile well)
addpath(fullfile(DJ_DIRS.binaries, 'DataJoint', 'mym'))

% Include our own stuff
addpath(fullfile(DJ_DIRS.code, 'm', 'DataJoint'))
addpath(genpath(fullfile(DJ_DIRS.code, 'm', 'DataJoint', 'utils')))

% Include blackrock functions for import
addpath(fullfile(DJ_DIRS.code, 'm', 'blackrock'))
% Include expo functions for import
addpath(genpath(fullfile(DJ_DIRS.binaries, 'Expo', 'ExpoXMLToMatlab')))
% Include clabx functions (needed for most computed tables)
addpath(fullfile(DJ_DIRS.code, 'm', 'clabx'));
% Include treadmill ball movement import functions
addpath(fullfile(DJ_DIRS.code, 'm', 'BallMovement'))

% Initialize mym
mymSetup()

% Modify the System Path
myPath = getenv('PATH');
myPath = [myPath ':/opt/local/bin:/opt/local/sbin:/usr/local/bin'];
setenv('PATH', myPath);
%!echo $PATH

% Set datajoint passwort
setenv('DJ_HOST', 'huxley.cin.medizin.uni-tuebingen.de:53306')
setenv('DJ_USER', 'write') % Read for read only, write to insert data and execute to administer
setenv('DJ_PASS', 'route1')
setenv('DJ_INIT', 'SET SESSION sql_mode="TRADITIONAL"')