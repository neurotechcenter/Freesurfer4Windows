# Freesurfer4Windows

The idea of Freesurfer4Windows is an install script that will allow you to run [Freesurfer](https://surfer.nmr.mgh.harvard.edu/) on Windows using [WSL](https://docs.microsoft.com/en-us/windows/wsl/about).
The automated script will perform multiple operations.
- Enabling the WSL Subsystem on Windows 10
- Download and Install of Ubuntu
- Download and Configuration of Freesurfer to run on Windows
- Installing and enabling [XLaunch](https://sourceforge.net/projects/vcxsrv/) to enable Freeview


# Installation

To run the Freesurfer4Windows Installation script simply start the runme.bat and follow the instructions.

After the installation has finished, you will need to obtain a [Freesurfer license](https://surfer.nmr.mgh.harvard.edu/fswiki/License). 

# Running Freeview

To run Freeview, WSL needs a way to run graphical applications. For this purpose, XLaunch installs as part of Freesurfer4Windows. XLaunch has to run in the background if you want to use Freeview. Start XLauch without a client and **disable native opengl**.

If you did not let Freesurfer4Windows add the freesurfer path to the profile, you must run `export DISPLAY=:0` before you can run a graphical application. 
