# Kodi IMDB update script

This tools connects to a MySQL / MariaDB database, scans for movies and updates their IMDB ratings. 

## Execute

```
cp imdb_update.yml ~/.imdb_update.yml
```

Update ~/.imdb_update.yml as required, and then run:

```
./imdb_update.rb
```

### Options

The maximum number of movie titles to process can be set by using the 'LIMIT' environment variable. To process only 5 movies you can enter:

```
LIMIT=5 ./imdb_update.rb
```

The starting record to process can be selected by using the 'START' environment variable. You can start from record #10 bu entering:

```
START=10 ./imdb_update.rb
```

Both environment variables can be used at the same time:

```
LIMIT=10 START=20 ./imdb_update.rb
```
