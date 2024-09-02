set workDir=%~dp0
set publishDir=%workDir%SweepyBoop

del %workDir%SweepyBoop.zip

XCOPY %workDir%*.lua %publishDir%\
XCOPY %workDir%*.toc %publishDir%\
XCOPY %workDir%*.xml %publishDir%\

XCOPY %workDir%ClassIcons %publishDir%\ClassIcons\ /s /y

XCOPY %workDir%Libs %publishDir%\Libs\ /s /y

XCOPY %workDir%CooldownTracking %publishDir%\CooldownTracking\ /s /y

findstr /v /i /L /c:"Internal" %publishDir%\SweepyBoop.toc > %publishDir%\SweepyBoop.toc.new

move %publishDir%\SweepyBoop.toc.new %publishDir%\SweepyBoop.toc
