# Mac Gitlab Runner

Install script for a standalone gitlab-runner running virtualized MacOS on a MacOS host.

## This is a public repository, DO NOT STORE ANY SENSITIVE INFORMATION HERE!

To install, go to [gitlab.com](https://gitlab.com) and create a runner.

We except you to have an external disk connected to store the tart images.

### Run the following command on your new Mac:
```
/bin/bash -c "$(curl -fsSL https://github.com/magnus-berg/mac-gitlab-runner/install.sh)"
```

### The following will be installed:
- Homebrew
- Gitlab Runner
- Tart
- Gitlab Tart Executor
- iTerm

### The server will have remote-login activated.
Every night at 2 am the server will: 
- Install updates for all brew-packages
- Install system updates
- Pull new tart-images (at the moment ghcr.io/cirruslabs/mac-os-sequoia-xcode:latest)
- Restart