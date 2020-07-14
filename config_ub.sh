
echo "Downloading necessary dependencies..."
sudo apt-get update
sudo apt-get install wslu libglu1-mesa libgomp1 tcsh
echo 'Checking for Freesurfer in Directory'
echo $1
if [ -d $1 ] 
then
	read -n 1 -p "Freesurfer directory already exists, do you want to keep it? (y/n) (default: n) " yn
fi
echo ''

if [ "$yn" != 'y' ] 
then
	echo "Downloading freesurfer..."
	curl.exe -L -o freesurfer.tar.gz https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.1.0/freesurfer-linux-centos8_x86_64-7.1.0.tar.gz
	echo "extracting freesurfer into target directory..."
	sudo tar xvzf freesurfer.tar.gz -C $1
	rm freesurfer.tar.gz
fi


export FREESURFER_HOME=$1/freesurfer
	
export DISPLAY=:0


read -n 1  -p "Do you want to add the Freesurfer Path and DISPLAY setting to profile (y/n) default: y ? " yn
echo ''
case $yn in
	'y'|'')
		touch ~/.run_fs
		echo "export FREESURFER_HOME="$1"/freesurfer/" > ~/.run_fs
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