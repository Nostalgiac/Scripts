$currentLocation = Split-Path -Parent $MyInvocation.MyCommand.Path;
DISM.exe /Online /Add-Package /PackagePath:$currentLocation/microsoft-windows-netfx3-ondemand-package.cab
