# Videolib [![Build Status](https://circleci.com/gh/pedbarbosa/videolib.svg?style=shield)](https://travis-ci.org/pedbarbosa/videolib) [![codecov](https://codecov.io/gh/pedbarbosa/videolib/branch/master/graph/badge.svg)](https://codecov.io/gh/pedbarbosa/videolib)

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

Videolib requires mediainfo >= 19.0 to run
