@echo off
setlocal EnableDelayedExpansion
echo ***************************************************************************
echo               btulz.code.bat
echo                     by niuren.zhu
echo                           2019.02.27
echo  说明：
echo     1. 遍历工作目录，获取模型目录，并应用代码模板。
echo     2. 参数1，工作目录。
echo     3. 参数2，输出目录。
echo     4. 参数3，模板目录。
echo     5. 参数4，工具目录。
echo ****************************************************************************
REM 设置参数变量
REM 启动目录
set STARTUP_FOLDER=%~dp0
REM 传入的工作目录
set WORK_FOLDER=%~1
REM 传入的输出目录
set OUTPUT_FOLDER=%~2
REM 传入的模板目录
set TEMPLATE_FOLDER=%~3
REM 传入的工具目录
set TOOLS_FOLDER=%~4
REM 判断是否传目录，没有则是启动目录
if "%WORK_FOLDER%"=="" set WORK_FOLDER=%STARTUP_FOLDER%
if "%OUTPUT_FOLDER%"=="" set OUTPUT_FOLDER=%STARTUP_FOLDER%
if "%TEMPLATE_FOLDER%"=="" set TEMPLATE_FOLDER=%STARTUP_FOLDER%templates
if "%TOOLS_FOLDER%"=="" set TOOLS_FOLDER=%STARTUP_FOLDER%ibas_tools
REM 若目录最后字符不是“\”则补齐
if "%WORK_FOLDER:~-1%" neq "\" set WORK_FOLDER=%WORK_FOLDER%\
if "%OUTPUT_FOLDER:~-1%" neq "\" set OUTPUT_FOLDER=%OUTPUT_FOLDER%\
if "%TEMPLATE_FOLDER:~-1%" neq "\" set TEMPLATE_FOLDER=%TEMPLATE_FOLDER%\
if "%TOOLS_FOLDER:~-1%" neq "\" set TOOLS_FOLDER=%TOOLS_FOLDER%\

echo --启动目录：%STARTUP_FOLDER%
echo --工作目录：%WORK_FOLDER%
echo --输出目录：%OUTPUT_FOLDER%
echo --模板目录：%TEMPLATE_FOLDER%
echo --工具目录：%TOOLS_FOLDER%
REM 检查工具目录
set BTULZ_CORE="%TOOLS_FOLDER%btulz.transforms.core-0.1.1.jar"
set TEMP_FILE="%STARTUP_FOLDER%~btulz.transforms-latest.tar"
set BTULZ_URL=http://maven.colorcoding.org/repository/maven-releases/org/colorcoding/tools/btulz.transforms/latest/btulz.transforms-latest.tar
if not exist %BTULZ_CORE% (
REM 尝试下载工具包
  curl -V >nul || goto :START_URL
  7z >nul || goto :START_URL
  echo --正在初始工具
  curl -fSL -o %TEMP_FILE% %BTULZ_URL%
  if exist %TEMP_FILE% (
    7z x %TEMP_FILE% -r -y -o%TOOLS_FOLDER%
    del /q /s %TEMP_FILE% >nul
    goto :START
  )
:START_URL
  if %ERRORLEVEL% neq 0 start %BTULZ_URL%
  echo --文件下载完成后，请解压到%TOOLS_FOLDER%目录
  goto :EOF
)

:START
REM 检查工作清单
if exist "%STARTUP_FOLDER%~working_tasks.txt" (
  set /p INPUT=--已经存在工作清单，是否清除？（y/n）:
  if "!INPUT!" neq "n" del /f /q "%STARTUP_FOLDER%~working_tasks.txt"
)
cd "%WORK_FOLDER%"
if not exist "%STARTUP_FOLDER%~working_tasks.txt" (
  echo --正在构建工作清单
  type nul>"%STARTUP_FOLDER%~working_tasks.txt"
  for /f %%l in ('dir /a:d /b /s datastructures') do (
    set FOLDER=%%l
    echo !FOLDER!|FINDSTR /c:ibas- /c:btulz /c:target >nul
    if !ERRORLEVEL! neq 0 (
      echo !FOLDER! >>"%STARTUP_FOLDER%~working_tasks.txt"
    )
  )
)

REM 执行工作清单
set TEMP_FOLDER=%OUTPUT_FOLDER%\~temp\
for /f %%l in (%STARTUP_FOLDER%~working_tasks.txt) do (
  set FOLDER=%%l
  echo --执行：!FOLDER!
  java -jar %BTULZ_CORE% code -TemplateFolder=%TEMPLATE_FOLDER% -OutputFolder=%TEMP_FOLDER% -Domains=!FOLDER!
)
REM 提取文件
if exist "%TEMP_FOLDER%" (
  for /f %%l in ('dir /a-d /b /s %TEMP_FOLDER%') do (
    copy /y %%l %OUTPUT_FOLDER% >nul
  )
  rd /q /s %TEMP_FOLDER% >nul
)
cd "%STARTUP_FOLDER%"
echo --完成