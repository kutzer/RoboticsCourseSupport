function [cam,prv] = initCamera
% INITCAMERA initialize a camera object and opens a preview.
%   cam = INITCAMERA initializes a camera object (cam) without opening a 
%   preview. A preview can be initiialized using "preview(cam)".
%
%   [cam,prv] = initCamera initializes a camera object (cam) and preview
%   object (prv).
%   
%   SOFTWARE NOTE: This requires an installed version of the "OS Generic Video 
%         Interface" package
%       >> supportPackageInstaller
%       -> select "Install from Internet"
%       -> select “OS Generic Video Interface”
%       -> login to mathworks using email and password
%       -> Install
%
%   HARDWARE NOTE: The settings used in this function are ta
%   See also imaqreset imaqhwinfo imaqhelp
%
%   M. Kutzer 02Mar2016, USNA

% Updates
%   21Aug2018 - Updated documentation, added see also, and incorporated
%   imaqreset. 

% TODO - remove persistent and replace with device selection
persistent callNum

if isempty(callNum)
    callNum = 1;
end

%% Check for installed adapters
goodAdaptor = false;
info = imaqhwinfo;
for i = 1:numel(info.InstalledAdaptors)
    switch lower(info.InstalledAdaptors{i})
        case 'winvideo'
            goodAdaptor = true;
            break
    end
end

% Prompt user to install the winvideo support package if/when the support
% package is not found. 
if ~goodAdaptor
    error('initCam:BadAdaptor',...
        ['The "winvideo" adaptor is not detected.\n',...
        ' -> Run "supportPackageInstaller"\n',...
        ' -> Select and install "OS Generic Video Interface".\n'])
end

%% Check for available "winvideo" cameras
devices = imaqhwinfo('winvideo');
if isempty(devices.DeviceIDs)
    error('No connected camera found');
end

n = numel(devices.DeviceIDs);
if n > 1
    % Define list of device names for user selection
    for i = 1:n
        camList{i} = devices.DeviceInfo(i).DeviceName;
    end
    % Allow user to select which camera they want to use
    [camIdx,OK] = listdlg('PromptString','Select camera:',...
                      'SelectionMode','single',...
                      'ListString',camList);
    if ~OK
        error('No camera selected.');
    end
else
    camIdx = 1;
end

%% Check for existing devices
vids = imaqfind;
m = size(vids,2);
if m > 0
    for i = 1:m
        switch lower(vids(i).Type)
            case 'videoinput'
                if vids(i).DeviceID == camIdx
                    cam = vids(i);
                    if nargout > 1
                        prv = preview(cam);
                    end
                    return
                end
        end
    end
end

%% Check for available formats
formatIDX = 1; % Use default format if recommended "YUY2_640x480" one is 
               % unavailable
m = numel(devices.DeviceInfo(camIdx).SupportedFormats);
for i = 1:m
    switch devices.DeviceInfo(camIdx).SupportedFormats{i}
        case 'YUY2_640x480'
            formatIDX = i;
            break
    end
end
         
%% Create video input object
cam = videoinput('winvideo',camIdx,...
    devices.DeviceInfo(camIdx).SupportedFormats{formatIDX});

%% Setup camera parameters
set(cam,'ReturnedColorSpace','rgb');
set(cam,'Name',sprintf('camera%d',callNum));
callNum = callNum + 1;

%% Update camera properties
src_obj = getselectedsource(cam); 
set(src_obj, 'ExposureMode', 'manual'); % Manual exposure mode
set(src_obj, 'Exposure', -4);           % Acceptable exposure for 
set(src_obj, 'FrameRate', '15.0000');

%% Start camera and create preview
triggerconfig(cam,'manual'); 
start(cam);

if nargout > 1
    prv = preview(cam);
end