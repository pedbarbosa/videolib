# Videolib

This tool scans a predetermined folder for TV shows and episodes within, and provides an HTML report with codec details. Optionally it can also create a report for files that aren't coded with 'x265'.

# Setup

```
git clone git@github.com:pedbarbosa/videolib.git
cd videolib
bundle install
cp videolib.yml ~/.videolib.yml
```

Update ~/.videolib.yml as required, and then run:

```
./videolib.rb
```

# Requirements 

### mediainfo

Videolib requires mediainfo 0.7.x to run

#### Mac

Force installation of version 0.7.99 with 'homebrew':

```
brew uninstall media-info
cd "$(brew --repo homebrew/core)"
git checkout 2b537604d07034407a91f83bebbd29fc82f9dd9b
HOMEBREW_NO_AUTO_UPDATE=1 brew install media-info
git checkout master
brew pin media-info
```

#### Linux Arch

```
wget -P /tmp https://archive.archlinux.org/repos/2017/10/01/community/os/x86_64/libmediainfo-0.7.99-1-x86_64.pkg.tar.xz
sudo pacman -R mediainfo
sudo pacman -U /tmp/libmediainfo-0.7.99-1-x86_64.pkg.tar.xz
```

Add 'mediainfo libmediainfo' to 'IgnorePkg' in /etc/pacman.conf