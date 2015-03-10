# Backto

A simple command line tool for backup files to one location.

## Installation

    $ gem install backto

## Usage

Example of backup Sublime Text 3 config to your Dropbox. You may have some files like below in `~/Dropbox/SublimeText3`

```
├── Installed\ Packages
│   ├── 0_package_control_loader.sublime-package
│   └── Package\ Control.sublime-package
└── Packages
    └── User
        ├── Default\ (OSX).sublime-keymap
        ├── Package\ Control.sublime-settings
        └── Preferences.sublime-settings
```

Just wirte a json config file in `~/Dropbox/sublimetext3.json` like

```json
{
    "form": "./SublimeText3",
    "to": "~/Library/Application Support/Sublime Text 3"
}

```

And then execute

```
$ backto ~/Dropbox/sublimetext3.json
```

