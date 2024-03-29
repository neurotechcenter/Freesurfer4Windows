
echo "Downloading necessary dependencies..."
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install wslu libglu1-mesa libgomp1 tcsh dos2unix curl wget unzip libxt-dev libxext-dev libncurses5
echo 'Checking for Freesurfer in Directory'
echo $1
if [ "$(ls -A $1)" ]
then
	read -n 1 -p "Freesurfer directory is not empty, do you want to download Freesurfer? (y/n) (default: n) " yn
	if [ "$yn" != 'y' ] 
	then
		yn='n'
	fi
	
else
	read -n 1 -p "Freesurfer directory is empty, do you want to download Freesurfer? (y/n) (default: y) " yn
fi
echo ''

if [ "$yn" != 'n' ] 
then
	echo "Downloading freesurfer 7.2.0..."
	sudo wget -O freesurfer.tar.gz https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.2.0/freesurfer-linux-ubuntu18_amd64-7.2.0.tar.gz
	echo "extracting freesurfer into target directory..."
	sudo tar xzf freesurfer.tar.gz -C $1
	rm freesurfer.tar.gz
fi


export FREESURFER_HOME=$1/freesurfer
	
export DISPLAY=:0


read -n 1  -p "Do you want to add the Freesurfer Path and DISPLAY setting to profile (y/n) default: y ? " yn
echo ''
case $yn in
	'y'|'')
		touch ~/.run_fs
		echo "export FREESURFER_HOME="$1"/freesurfer" > ~/.run_fs
		echo 'source $FREESURFER_HOME/SetUpFreeSurfer.sh' >> ~/.run_fs
		echo 'export DISPLAY=:0' >> ~/.run_fs
		chmod +x ~/.run_fs
		touch ~/.bash_profile
		if ! grep -q '. ~/.run_fs' ~/.bash_profile
		then
			echo '. ~/.run_fs' >> ~/.bash_profile
		fi
		;; 
	'n')
		echo './bash_profile will not be changed'
		;;
	*)
		echo 'Invalid Input'
		;;
esac

read -n 1  -p "Do you want to download the MATLAB R2014b Runtime (required for hippocampal/thalamic segmentation) (y/n) default: y ? " yn
echo ''
case $yn in
	'y'|'')
		echo 'installing MATLAB R2014b Runtime...'
		echo "export FREESURFER_HOME="$1"/freesurfer"
		$FREESURFER_HOME/bin/fs_install_mcr R2014b
		echo 'MATLAB Runtime installation completed. Please wait for next step...'
		;; 
	'n')
		echo './MATLAB R2014b Runtime was not installed.'
		;;
	*)
		echo 'Invalid Input'
		;;
esac
