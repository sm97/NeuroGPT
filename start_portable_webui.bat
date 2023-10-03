@echo off
echo Opening NeuroGPT...

set HIDE_OTHER_PROVIDERS=false
set SHOW_ALL_PROVIDERS=false

REM Проверяем наличие папки python
if not exist python (

  echo Python folder not found, downloading...
  
  curl -L -o python.zip https://github.com/Em1tSan/NeuroGPT/releases/download/v1.2.1/python.zip

  echo Unpacking python folder...
  tar -xf python.zip
  del python.zip /q
)

REM Проверяем наличие папки git
if not exist git (

  echo Git folder not found, downloading...
  
  curl -L -o git.zip https://github.com/Em1tSan/NeuroGPT/releases/download/v1.2.1/git.zip

  echo Unpacking git folder...
  tar -xf git.zip
  del git.zip /q
)

set pypath=home = %~dp0python
set venvpath=_ENV=%~dp0venv
if exist venv (powershell -command "$text = (gc venv\pyvenv.cfg) -replace 'home = .*', $env:pypath; $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False);[System.IO.File]::WriteAllLines('venv\pyvenv.cfg', $text, $Utf8NoBomEncoding);$text = (gc venv\scripts\activate.bat) -replace '_ENV=.*', $env:venvpath; $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding($False);[System.IO.File]::WriteAllLines('venv\scripts\activate.bat', $text, $Utf8NoBomEncoding);")

for /d %%i in (tmp\tmp*,tmp\pip*) do rd /s /q "%%i" 2>nul || ("%%i" && exit /b 1) & del /q tmp\tmp* > nul 2>&1 & rd /s /q pip\cache 2>nul

set appdata=tmp
set userprofile=tmp
set temp=tmp
set PATH=git\cmd;python;venv\scripts

echo Checking for updates...
REM Создаем временную копию файла config.json
copy /Y config.json config_temp.json

git init
git remote add origin https://github.com/Em1tSan/NeuroGPT.git
git pull
git checkout portable -f
git branch --set-upstream-to origin/portable

git fetch --all
git reset --hard origin/portable
git pull

REM Восстанавливаем оригинальный файл config.json
copy /Y config_temp.json config.json
del config_temp.json

python -m venv venv
call venv\Scripts\activate.bat
python -c "import json; import collections; config = json.load(open('config.json')); keys = list(config.keys()); keys.insert(2, keys.pop(keys.index('daku_api_key'))); config = collections.OrderedDict([(key, config[key]) for key in keys]); json.dump(config, open('config.json', 'w'), indent=4)"
python -m pip install --upgrade pip
python -m pip install -U setuptools 
python -m pip install whl\quickjs-1.19.2-cp311-cp311-win_amd64.whl
python -m pip install whl\fastwsgi-0.0.9-cp311-cp311-win_amd64.whl
python -m pip install -r requirements.txt
IF NOT EXIST venv\Lib\site-packages\torch (
    echo Torch not found, downloading...
    python -m pip install -r requirements_advanced.txt
)

REM checking for spacy language models and download if not exists
IF NOT EXIST venv\Lib\site-packages\en_core_web_sm (
    echo English language model not found, downloading...
    python -m spacy download en_core_web_sm
)

IF NOT EXIST venv\Lib\site-packages\zh_core_web_sm (
    echo Chinese language model not found, downloading...
    python -m spacy download zh_core_web_sm
)

IF NOT EXIST venv\Lib\site-packages\ru_core_news_sm (
    echo Russian language model not found, downloading...
    python -m spacy download ru_core_news_sm
)

echo Completed.
echo Running NeuroGPT...

REM Determine the language of the operating system
python -c "import locale; print(locale.getdefaultlocale()[0])" > lang.txt
set /p language=<lang.txt

IF "%language%"=="ru_RU" (
  python webui_ru.py
) ELSE (
  python webui_en.py
)

pause

:: Упаковано и собрано telegram каналом Neurogen News: https://t.me/neurogen_news