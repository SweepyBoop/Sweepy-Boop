set "workDir=%~dp0"
set "addonDir=D:\World of Warcraft\_retail_\Interface\Addons\SweepyBoop"

rmdir /s /q %addonDir%
mkdir %addonDir%
xcopy "%workDir%" "%addonDir%" /E /I /Y

echo NS.internal = true;>> "%addonDir%\Constants.lua"
