set workDir=%~dp0
set publishDir=%workDir%SweepyBoop

del %workDir%SweepyBoop.zip

XCOPY %workDir%*.lua %publishDir%\
XCOPY %workDir%*.toc %publishDir%\
XCOPY %workDir%*.xml %publishDir%\

XCOPY %workDir%ClassIcons %publishDir%\ClassIcons\ /s /y

XCOPY %workDir%Libs %publishDir%\Libs\ /s /y

XCOPY %workDir%ArenaFrames %publishDir%\ArenaFrames\ /s /y
XCOPY %workDir%Misc %publishDir%\Misc\ /s /y
XCOPY %workDir%Nameplates %publishDir%\Nameplates\ /s /y
XCOPY %workDir%RaidFrames %publishDir%\RaidFrames\ /s /y

findstr /v /i /L /c:"Internal" %publishDir%\SweepyBoop.toc > %publishDir%\SweepyBoop.toc.new

move %publishDir%\SweepyBoop.toc.new %publishDir%\SweepyBoop.toc
