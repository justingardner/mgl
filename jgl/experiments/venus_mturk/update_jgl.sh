#! /bin/sh

# Updates your app's local copy of jgl library to the latest 
# version from the repository using $JGLPATH
# If your $JGLPATH is not set within your environment, 
# run the script to get instructions

if [ -z "$JGLPATH" ];  then # If JGLPATH is empty string
	echo "JGLPATH is not defined"
	echo "In bash, add \"export JGLPATH='your_jgl_path'\" to your ~/.bashrc"
	echo "In tcsh, add \"set JGLPATH=your_jgl_path\" to your ~/.cshrc.mine"
else 
	# Update jgl library files by copying from $JGLPATH/lib to ./static/lib
	# Need to check if those folders exist
	JGLLIBPATH="$JGLPATH/lib/"
	COPYPATH="./static/lib"  # If your app has a custom directory structure, change this to point to your folder

	# Quit, if ./static/lib does not exist 
	# cause no idea where to copy 
	if [ ! -d $COPYPATH ]; then 
		echo "-------------------------------------------------------------"
		echo "Error: $COPYPATH does not exist"
		echo "Please re-run this script from within your jgl app directory, e.g., cd my-first-app"
		echo "if you have custom directory structure"
		echo "manually copy the following files to your app directory:"
		echo "$JGLLIBPATH/jglLib.js"
		echo "$JGLLIBPATH/jglTask.js"
		echo "$JGLLIBPATH/jglUtils.js"
		echo "-------------------------------------------------------------"
		exit
	fi

	# Check if jgl library path exists and copy files to $COPYPATH
	if [ -d $JGLLIBPATH ]; then 
		# List of jgl library files
		fileNames="jglLib.js jglTask.js jglUtils.js"
		for fileName in $fileNames 
		do
			if [ -f $JGLLIBPATH/$fileName ]; then
				echo "Copying $JGLLIBPATH/$fileName to $COPYPATH"
				cp $JGLLIBPATH/$fileName $COPYPATH
			fi
		done

	else 
		echo "Error: $JGLLIBPATH folder does not exist. Check if JGLPATH is set correctly and re-run"
		exit
	fi
fi

