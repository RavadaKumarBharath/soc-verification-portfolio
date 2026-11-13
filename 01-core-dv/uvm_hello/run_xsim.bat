@echo off
setlocal

if "%~1"=="" (
  echo Usage: run_xsim.bat ^<file.sv ^| list.f^> [top] [testname] [seed]
  exit /b 2
)

rem Set up Vivado tools if this window doesn't have them yet
where xvlog >nul 2>&1
if errorlevel 1 call "C:\Xilinx\2026.1\Vivado\settings64.bat"

set "TOP=%~2"
if "%TOP%"=="" set "TOP=top"
set "TEST=%~3"
set "SEED=%~4"
if "%SEED%"=="" set "SEED=1"

rem A .f argument is treated as a filelist
set SRC="%~f1"
if /I "%~x1"==".f" set SRC=-f "%~f1"

set "PLUS="
if not "%TEST%"=="" set "PLUS=-testplusarg UVM_TESTNAME=%TEST%"

rem One folder per run, next to this script
set "RUN=%~dp0runs\%~n1_s%SEED%"
if exist "%RUN%" rmdir /s /q "%RUN%"
mkdir "%RUN%"
pushd "%RUN%"

echo [1/3] compile   : %~n1
call xvlog -sv -L uvm %SRC% -log compile.log >nul
if errorlevel 1 ( set "STAGE=COMPILE" & goto :fail )

echo [2/3] elaborate : top=%TOP%
call xelab -debug typical -L uvm %TOP% -s snap -log elab.log >nul
if errorlevel 1 ( set "STAGE=ELABORATE" & goto :fail )

echo [3/3] simulate  : seed=%SEED% test=%TEST%
call xsim snap -runall -sv_seed %SEED% %PLUS% -log sim.log >nul
if errorlevel 1 ( set "STAGE=SIMULATE" & goto :fail )

rem Decide PASS/FAIL from the UVM report, not just the exit code
findstr /C:"UVM Report Summary" sim.log >nul
if errorlevel 1 ( set "STAGE=NO_UVM_SUMMARY" & goto :fail )
findstr /R /C:"UVM_ERROR *: *[1-9]" /C:"UVM_FATAL *: *[1-9]" sim.log >nul
if not errorlevel 1 ( set "STAGE=UVM_ERRORS" & goto :fail )

popd
echo PASS  %~n1  seed=%SEED%
echo PASS  %~n1  seed=%SEED% >> "%~dp0runs\summary.log"
exit /b 0

:fail
popd
echo FAIL  %~n1  seed=%SEED%  stage=%STAGE%  (see %RUN%)
echo FAIL  %~n1  seed=%SEED%  stage=%STAGE% >> "%~dp0runs\summary.log"
exit /b 1