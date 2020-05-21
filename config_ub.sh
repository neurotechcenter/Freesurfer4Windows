sudo apt-get update
sudo apt-get install wslu
echo "Downloading freesurfer..."
curl.exe -L -o freesurfer.tar.gz https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.1.0/freesurfer-linux-centos8_x86_64-7.1.0.tar.gz
echo "extracting freesurfer into target directory..."
tar xvzf freesurfer.tar.gz -C $1
rm freesurfer.tar.gz
export FREESURFER_HOME=$1/freesurfer 
source $FREESURFER_HOME/SetUpFreeSurfer.sh