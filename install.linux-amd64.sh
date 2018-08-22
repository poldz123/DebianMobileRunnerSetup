#!/bin/bash
set -e

before_install()
{
  echo -e "\n\nExecuting Before Install...\n\n"

  echo "Checking the machine..."
  [[ $(uname -m) != "x86_64" ]] && { echo -e "ERROR: Machine does not support 64-bit instructions, exiting...\n" ; exit 1 ; } 
  echo "Checking the inputs..."
  [[ -z "$ANDROID_PLATFORM_VERSIONS" ]] && { echo -e "ERROR: Android platform versions was not set, exiting...\n" ; exit 1 ; }
  [[ -z "$ANDROID_BUILD_TOOLS" ]] && { echo -e "ERROR: Android build tools was not set, exiting..\n" ; exit 1 ; }
  [[ -z "$GITLAB_INSTANCE_URL" ]] && { echo -e "ERROR: Gitlab instance URL was not set, exiting..\n" ; exit 1 ; }
  [[ -z "$GITLAB_CI_TOKEN" ]] && { echo -e "ERROR: Gitlab-CI token was not set, exiting..\n" ; exit 1 ; }
  [[ -z "$GITLAB_CI_DESCRIPTION" ]] && { echo -e "ERROR: Gitlab-CI description not set, exiting..\n" ; exit 1 ; }
  [[ -z "$GITLAB_CI_TAGS" ]] && { echo -e "ERROR: Gitlab-CI tags was not set, exiting..\n" ; exit 1 ; }

  echo "Validating the input version numbers..."
  platform_version_regex="^[0-9]+$"
  for platform_version in ${ANDROID_PLATFORM_VERSIONS//,/ } ; do
    if ! [[ $platform_version =~ $platform_version_regex ]] ; then
      echo "ERROR: $platform_version is not a valid platform version, exitting..."; exit 1
    fi
  done
  build_tools_version_regex="^[0-9]+[.][0-9]+[.][0-9]+?$"
  for build_tools_version in ${ANDROID_BUILD_TOOLS//,/ } ; do
    if ! [[ $build_tools_version =~ $build_tools_version_regex ]] ; then
      echo "ERROR: $build_tools_version is not a valid build tool version, exitting..."; exit 1
    fi
  done
}

after_install()
{
  echo "Executing After Install..."
}

install_java()
{ 
  echo -e "\n\nInstalling Java...\n\n"
  
  JAVA_JDK_VERSION="jdk-8u181-linux-x64.tar.gz" 
  if ! [ -x "$(command -v javac)" ] ||
     ! [ -x "$(command -v java)" ] ||
       [ $(java -version 2>&1 | grep -i version | sed 's/.*version ".*\.\(.*\)\..*"/\1/; 1q') -lt 8 ] ||
       [ $(javac -version 2>&1 | grep -i javac | sed 's/.*javac .*\.\(.*\)\..*/\1/; 1q') -lt 8 ]; then
    echo "Java JDK 8 is not installed, installing..."
    wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u181-b13/96a7b8442fe848ef90c96a2fad6ed6d1/$JAVA_JDK_VERSION"
    rm -rf /opt/jdk
    mkdir /opt/jdk
    tar -zxf $JAVA_JDK_VERSION -C /opt/jdk
    update-alternatives --install /usr/bin/java java /opt/jdk/jdk1.8.0_181/bin/java 100
    update-alternatives --install /usr/bin/javac javac /opt/jdk/jdk1.8.0_181/bin/javac 100    
    rm $JAVA_JDK_VERSION
  else
    echo "Java JDK 8 has already been installed, skipping..."
  fi
}
 
install_android_sdk()
{
  echo -e "\n\nInstalling Android SDK...\n\n"
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
    rm -rf ANDROID_HOME
    curl -L $ANDROID_SDK_URL -o $ANDROID_SDK_FILE
    mkdir -p $ANDROID_HOME
    pushd $ANDROID_HOME
    unzip -x $ANDROID_SDK_FILE
    popd
    rm $ANDROID_SDK_FILE
  else
    echo "Android SDK has already been installed"
  fi

  # Create a shell script that would export all of the path and home directory
  # of the android sdk to the profile which is sharable to all of the users.
  EXPORT_SDK_HOME="export ANDROID_HOME=$ANDROID_HOME"
  EXPORT_SDK_PATH="export PATH=$ANDROID_SDK_DIRECTORY_TOOLS:$ANDROID_SDK_DIRECTORY_TOOLS_BINARY:$ANDROID_SDK_DIRECTORY_PLATFORM_TOOLS:\$PATH"
  echo -e "$EXPORT_SDK_HOME\n$EXPORT_SDK_PATH" > "$ANDROID_SDK_PROFILE_SH_FILE"
  # Set the sdk tools to be executable by all of the user in the system.
  chmod +x -R $ANDROID_SDK_DIRECTORY_TOOLS
  chmod +x -R $ANDROID_SDK_DIRECTORY_TOOLS_BINARY
  # Set the path and home within sudo
  eval "$EXPORT_SDK_HOME"
  eval "$EXPORT_SDK_PATH"
  echo "Setting the PATH and HOME environment variables within the user profile... Done"
}

install_android_sdk_manager_packages()
{
  echo -e "\n\nInstalling Android SDK Manager Packages...\n\n"
  yes | sdkmanager --licenses
  sdkmanager --update
  sdkmanager --verbose \
	     "platform-tools" \
	     "tools" \
	     $(printf "platforms;android-%s " ${ANDROID_PLATFORM_VERSIONS//,/ }) \
             $(printf "build-tools;%s " ${ANDROID_BUILD_TOOLS//,/ })
  sdkmanager --verbose --update
  chmod +x -R $ANDROID_SDK_DIRECTORY_PLATFORM_TOOLS
}

install_gitlab_runner()
{
  echo -e "\n\nInstalling Gitlab Runner...\n\n"

  wget -O /usr/local/bin/gitlab-runner https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64
  chmod +x /usr/local/bin/gitlab-runner
  curl -sSL https://get.docker.com/ | sh
  useradd --comment 'GitLab Runner' --create-home gitlab-runner --shell /bin/bash
  gitlab-runner install --user=gitlab-runner --working-directory=/home/gitlab-runner
  gitlab-runner start 

  # Unregister all of the runners before registering a new one
  if which gitlab-runner > /dev/null; then
    gitlab-runner verify --delete
    gitlab-runner unregister --all-runners
  fi
  # Register the runner within gitlab using non-interactive
  gitlab-runner register \
    --url "$GITLAB_INSTANCE_URL" \
    --registration-token "$GITLAB_CI_TOKEN" \
    --name "$GITLAB_CI_DESCRIPTION" \
    --tag-list "$GITLAB_CI_TAGS" \
    --executor shell \
    --limit 1 \
    --locked="false" \
    --non-interactive

  # Re-install the runner to properly set which user the runner service is going to be executed.
  gitlab-runner uninstall &> /dev/null || true
  gitlab-runner install \
    --user="gitlab-runner" \
    --working-directory="/home/gitlab-runner"
  # Make sure to start the gitlab runner after it was installed. After installation
  # the runner service is stopped by default that would cause the runner within gilab to show
  # that is has not yet recieved connection with the runner yet.
  gitlab-runner start
}

main ()
{
  before_install
  install_java
  install_android_sdk
  install_android_sdk_manager_packages
  install_gitlab_runner
}

echo -e "\nPlease enter the android platform versions (comma separated) (e.g 21,22,24)"
read ANDROID_PLATFORM_VERSIONS
echo "Please enter the android build tools versions (comma separated) (e.g. 23.0.1,24.0.1)"
read ANDROID_BUILD_TOOLS
echo "Please enter the gitlab-ci coordinator URL (e.g. https://gitlab.com )"
read GITLAB_INSTANCE_URL
echo "Please enter the gitlab-ci token for this runner"
read GITLAB_CI_TOKEN
echo "Please enter the gitlab-ci description for this runner"
read GITLAB_CI_DESCRIPTION
echo "Please enter the gitlab-ci tags for this runner (comma separated)"
read GITLAB_CI_TAGS
main
