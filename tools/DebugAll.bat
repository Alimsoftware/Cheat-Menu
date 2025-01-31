@echo off
echo --------------------------------------------------
echo Building DebugAll
echo --------------------------------------------------
echo[
call "tools\Setup.bat"
MsBuild CheatMenu.sln /property:Configuration=Debug
del %SA_DIR%"\CheatMenuSA.asi" /Q
del %SA_DIR%"\CheatMenuSA.pdb" /Q
del %VC_DIR%"\CheatMenuVC.asi" /Q
del %VC_DIR%"\CheatMenuVC.pdb" /Q
del %III_DIR%"\CheatMenuIII.asi" /Q
del %III_DIR%"\CheatMenuIII.pdb" /Q
%systemroot%\System32\xcopy /s "bin\CheatMenuSA.asi" %SA_DIR% /K /D /H /Y 
%systemroot%\System32\xcopy /s "bin\CheatMenuVC.asi" %VC_DIR% /K /D /H /Y 
%systemroot%\System32\xcopy /s "bin\CheatMenuIII.asi" %III_DIR% /K /D /H /Y 
%systemroot%\System32\xcopy /s "bin\CheatMenuSA.pdb" %SA_DIR% /K /D /H /Y 
%systemroot%\System32\xcopy /s "bin\CheatMenuVC.pdb" %VC_DIR% /K /D /H /Y 
%systemroot%\System32\xcopy /s "bin\CheatMenuIII.pdb" %III_DIR% /K /D /H /Y 