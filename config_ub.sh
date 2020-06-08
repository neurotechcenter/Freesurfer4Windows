
echo "Downloading necessary dependencies..."
sudo apt-get update
sudo apt-get install wslu
echo "Downloading freesurfer..."
curl.exe -L -o freesurfer.tar.gz https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.1.0/freesurfer-linux-centos8_x86_64-7.1.0.tar.gz
echo "extracting freesurfer into target directory..."
tar xvzf freesurfer.tar.gz -C $1
rm freesurfer.tar.gz
export FREESURFER_HOME=$1/freesurfer 
	
export DISPLAY=:0


read -n 1  -p "Do you want to add the Freesurfer Path and DISPLAY setting to profile (y/n) default: y ? " yn
case $yn install
	'y'|'')
		echo 'export FREESURFER_HOME=$1/freesurfer ' >>~/.bash_profile
		echo 'source $FREESURFER_HOME/SetUpFreeSurfer.sh' >>~/.bash_profile
		echo 'export DISPLAY=:0' >>~/.bash_profile
	'n')
	*)
		echo 'Invalid Input'
esac