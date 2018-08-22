# GitlabMobileRunnerSetup

This setup script is used to automatically install java, android sdk, tools and registering the machine as a [gitlab-runner](https://docs.gitlab.com/runner/).

The main purpose of this script is to use the computer as a runner within gitlab to run tests for android locally. Running the script
will ask you information about what version of the build-tools and platform-tools you want to install and the gitlab-runner specifics
which you can find [here](https://docs.gitlab.com/runner/register/).

Now you don't want to worry about setting up environment variables since the script will set that up for you and also 
all of the informations are ask and validated before the actual installation.

## Specification

Currently right now it only support [Debian-based distributions](https://en.wikipedia.org/wiki/Category:Debian-based_distributions) since the script is mainly using the `apt` package management.

## Running

To run the script you need to have root access and execute this command.
```bash
sudo bash -c "$(curl -L https://raw.githubusercontent.com/poldz123/GitlabMobileRunnerSetup/master/install.deb.sh)"
```

### Running with input file

Running the script above will constantly ask you for information input. Now it may take a while setting them up specially
if the script failed and you need to all over input them again.

This is where the input file is used. It skips all of those inputs and auto fill them and it is passed to the script.
You can get the [input file](https://github.com/poldz123/GitlabMobileRunnerSetup/blob/master/mobile-runner-input) and fill that up with your inputs.

```
Remember that only the information should exist within the input file and all
of the comments should be removed.
```

To run the script with input file you need to have root access and execute this command.
```bash
sudo bash -c "$(curl -L https://raw.githubusercontent.com/poldz123/GitlabMobileRunnerSetup/master/install.deb.sh)" < NAME_OF_THE_INPUT_FILE
```

Right as the end of the command above there is this `< NAME_OF_THE_INPUT_FILE` that is the filled input file that is passed to the script.
