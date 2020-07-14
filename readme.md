# Freesurfer4Windows

The idea of Freesurfer4Windows is an install script that will allow you to run [Freesurfer](https://surfer.nmr.mgh.harvard.edu/) on Windows using [WSL](https://docs.microsoft.com/en-us/windows/wsl/about).
The automated script will perform multiple operations.
- Enabling the WSL Subsystem on Windows 10
- Download and Install of a Ubuntu Distribution
- Download and Configuration Freesurfer to run on Windows
- Installing and enabling [XLaunch](https://sourceforge.net/projects/vcxsrv/) to enable Freeview


# Installation

Before Installation you will have to allow execution of powershell scripts:
- Open Powershell as administrator
  - Type  Powershell into the Windows 10 Searchbar
  - Rightclick Windows Powershell and Run as Administrator
  
- Run `Set-ExecutionPolicy unrestricted` and accept the change in execution policy (y)

You are now able to run the Freesurfer4Windows Installation script. Run runme.bat and follow the instructions.

After installation has finished, you will need to obtain a [Freesurfer license](https://surfer.nmr.mgh.harvard.edu/fswiki/License). 

# Running Freeview

In order to run Freeview WSL needs a way to run graphical applications. For this purpose XLaunch is installed as part of Freesurfer4Windows. XLaunch has to run in the background if you want to use a graphical application. Start XLauch without a client and **disable native opengl**.

If you did not let Freesurfer4Windows add the freesurfer path to the profile you will need to manually run `export DISPLAY=:0` before you can run graphical applications. 




