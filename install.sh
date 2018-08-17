#!/bin/bash

before_install()
{
  echo "Executing Before Install..."
  # Installing the pyton command to add repository in debian
  apt-get install -y software-properties-common
  apt-get install dirmngr
}

after_install()
{
  echo "Executing After Install..."
}

set_up_environment_variables()
{
  echo "Setting up the Environment Variables"
}

install_java()
{
  echo "Installing Java..."
  # Adds the java repository, repo, keys and update the apt. This also append the repo urls to
  # the sources file and making sure that we do not append same deb and deb source
  # all over again when running the installation.
  DEB="deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main"
  DEB_SOURCE="deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main"
  apt-key adv --recv-key --keyserver keyserver.ubuntu.com EEA14886
  grep -q -F "$DEB" /etc/apt/sources.list || echo "$DEB" >> /etc/apt/sources.list
  grep -q -F "$DEB_SOURCE" /etc/apt/sources.list || echo "$DEB_SOURCE" >> /etc/apt/sources.list
  apt-get update
  # Install the java8 installer and make sure that we respond to the prompt
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
  apt-get -y install oracle-java8-installer
}

install_android_sdk()
{
  echo "Installing Android SDK..."
  # Install the android sdk tools manually through the zip file, this is to be
  # able to do fastbooting to the android cli and prevent unnecessary tools that
  # would bloat the memory with junk tools. Only install what we needed.
  ANDROID_HOME="/usr/lib/android-sdk"
  ANDROID_SDK_VERSION=4333796
  ANDROID_SDK_FILE_NAME="sdk-tools-linux-$ANDROID_SDK_VERSION.zip"
  ANDROID_SDK_FILE="$HOME/$ANDROID_SDK_FILE_NAME"
  ANDROID_SDK_URL="https://dl.google.com/android/repository/$ANDROID_SDK_FILE_NAME"
  ANDROID_SDK_DIRECTORY_TOOLS="$ANDROID_HOME/tools"
  ANDROID_SDK_DIRECTORY_TOOLS_BINARY="$ANDROID_SDK_DIRECTORY_TOOLS/bin"
  ANDROID_SDK_DIRECTORY_PLATFORM_TOOLS="$ANDROID_HOME/platform-tools"
  ANDROID_SDK_PROFILE_SH_FILE="/etc/profile.d/android_sdk.sh"
  # Check that the android sdk tools are installed to prevent redownloading of sdk
  # every single time we run this script.
  if [ ! -d "$ANDROID_SDK_DIRECTORY_TOOLS" ] || 
     [ ! -d "$ANDROID_SDK_DIRECTORY_TOOLS_BINARY" ] || 
     [ ! -d "$ANDROID_SDK_DIRECTORY_PLATFORM_TOOLS" ]; then
    curl -L $ANDROID_SDK_URL -o $ANDROID_SDK_FILE
    mkdir -p $ANDROID_HOME
    pushd $ANDROID_HOME
    unzip -x $ANDROID_SDK_FILE
    popd
    rm $ANDROID_SDK_FILE
  fi
  # Create a shell script that would export all of the path and home directory
  # of the android sdk to the profile which is sharable to all of the users.
  EXPORT_SDK_HOME="export ANDROID_HOME=$ANDROID_HOME"
  EXPORT_SDK_PATH="export PATH=$ANDROID_SDK_DIRECTORY_TOOLS:$ANDROID_SDK_DIRECTORY_TOOLS_BINARY:$ANDROID_SDK_DIRECTORY_PLATFORM_TOOLS:\$PATH"
  echo -e "$EXPORT_SDK_HOME\n$EXPORT_SDK_PATH" > "$ANDROID_SDK_PROFILE_SH_FILE"
  # Set the sdk tools to be executable by all of the user in the system.
  chmod +x -R $ANDROID_SDK_DIRECTORY_TOOLS
  chmod +x -R $ANDROID_SDK_DIRECTORY_TOOLS_BINARY
  chmod +x -R $ANDROID_SDK_DIRECTORY_PLATFORM_TOOLS
}

install_android_sdk_manager_packages()
{
  echo "Installing Android SDK Manager Packages..."
  yes | sdkmanager --licenses
  sdkmanager --verbose \
	     "platform-tools" \
	     "tools" \
	     "platforms;android-"{21,27} \
             "build-tools;"{27.0.3}
  sdkmanager --verbose --update
}

registerRunner()
{
  echo "Registering Gitlab Runner..."
}

unregisterRunner()
{
  echo "Unregistering Gitlab Runner..."
}

main ()
{
  before_install
  install_java
#  install_android_sdk
#  install_android_sdk_manager_packages
}

main
