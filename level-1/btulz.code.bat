@echo off
setlocal EnableDelayedExpansion
echo ***************************************************************************
echo               btulz.code.bat
echo                     by niuren.zhu
echo                           2019.02.27
echo  ˵����
echo     1. ��������Ŀ¼����ȡģ��Ŀ¼����Ӧ�ô���ģ�塣
echo     2. ����1������Ŀ¼��
echo     3. ����2�����Ŀ¼��
echo     4. ����3��ģ��Ŀ¼��
echo     5. ����4������Ŀ¼��
echo ****************************************************************************
REM ���ò�������
REM ����Ŀ¼
set STARTUP_FOLDER=%~dp0
REM ����Ĺ���Ŀ¼
set WORK_FOLDER=%~1
REM ��������Ŀ¼
set OUTPUT_FOLDER=%~2
REM �����ģ��Ŀ¼
set TEMPLATE_FOLDER=%~3
REM ����Ĺ���Ŀ¼
set TOOLS_FOLDER=%~4
REM �ж��Ƿ�Ŀ¼��û����������Ŀ¼
if "%WORK_FOLDER%"=="" set WORK_FOLDER=%STARTUP_FOLDER%
if "%OUTPUT_FOLDER%"=="" set OUTPUT_FOLDER=%STARTUP_FOLDER%
if "%TEMPLATE_FOLDER%"=="" set TEMPLATE_FOLDER=%STARTUP_FOLDER%templates
if "%TOOLS_FOLDER%"=="" set TOOLS_FOLDER=%STARTUP_FOLDER%ibas_tools
REM ��Ŀ¼����ַ����ǡ�\������
if "%WORK_FOLDER:~-1%" neq "\" set WORK_FOLDER=%WORK_FOLDER%\
if "%OUTPUT_FOLDER:~-1%" neq "\" set OUTPUT_FOLDER=%OUTPUT_FOLDER%\
if "%TEMPLATE_FOLDER:~-1%" neq "\" set TEMPLATE_FOLDER=%TEMPLATE_FOLDER%\
if "%TOOLS_FOLDER:~-1%" neq "\" set TOOLS_FOLDER=%TOOLS_FOLDER%\

echo --����Ŀ¼��%STARTUP_FOLDER%
echo --����Ŀ¼��%WORK_FOLDER%
echo --���Ŀ¼��%OUTPUT_FOLDER%
echo --ģ��Ŀ¼��%TEMPLATE_FOLDER%
echo --����Ŀ¼��%TOOLS_FOLDER%
REM ��鹤��Ŀ¼
set BTULZ_CORE="%TOOLS_FOLDER%btulz.transforms.core-0.1.1.jar"
set TEMP_FILE="%STARTUP_FOLDER%~btulz.transforms-latest.tar"
set BTULZ_URL=http://maven.colorcoding.org/repository/maven-releases/org/colorcoding/tools/btulz.transforms/latest/btulz.transforms-latest.tar
if not exist %BTULZ_CORE% (
REM �������ع��߰�
  curl -V >nul || goto :START_URL
  7z >nul || goto :START_URL
  echo --���ڳ�ʼ����
  curl -fSL -o %TEMP_FILE% %BTULZ_URL%
  if exist %TEMP_FILE% (
    7z x %TEMP_FILE% -r -y -o%TOOLS_FOLDER%
    del /q /s %TEMP_FILE% >nul
    goto :START
  )
:START_URL
  if %ERRORLEVEL% neq 0 start %BTULZ_URL%
  echo --�ļ�������ɺ����ѹ��%TOOLS_FOLDER%Ŀ¼
  goto :EOF
)

:START
REM ��鹤���嵥
if exist "%STARTUP_FOLDER%~working_tasks.txt" (
  set /p INPUT=--�Ѿ����ڹ����嵥���Ƿ��������y/n��:
  if "!INPUT!" neq "n" del /f /q "%STARTUP_FOLDER%~working_tasks.txt"
)
cd "%WORK_FOLDER%"
if not exist "%STARTUP_FOLDER%~working_tasks.txt" (
  echo --���ڹ��������嵥
  type nul>"%STARTUP_FOLDER%~working_tasks.txt"
  for /f %%l in ('dir /a:d /b /s datastructures') do (
    set FOLDER=%%l
    echo !FOLDER!|FINDSTR /c:ibas- /c:btulz /c:target >nul
    if !ERRORLEVEL! neq 0 (
      echo !FOLDER! >>"%STARTUP_FOLDER%~working_tasks.txt"
    )
  )
)

REM ִ�й����嵥
set TEMP_FOLDER=%OUTPUT_FOLDER%\~temp\
for /f %%l in (%STARTUP_FOLDER%~working_tasks.txt) do (
  set FOLDER=%%l
  echo --ִ�У�!FOLDER!
  java -jar %BTULZ_CORE% code -TemplateFolder=%TEMPLATE_FOLDER% -OutputFolder=%TEMP_FOLDER% -Domains=!FOLDER!
)
REM ��ȡ�ļ�
if exist "%TEMP_FOLDER%" (
  for /f %%l in ('dir /a-d /b /s %TEMP_FOLDER%') do (
    copy /y %%l %OUTPUT_FOLDER% >nul
  )
  rd /q /s %TEMP_FOLDER% >nul
)
cd "%STARTUP_FOLDER%"
echo --���