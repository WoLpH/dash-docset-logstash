# logstash docset for dash

This is a simple [logstash](http://logstash.net) docset for [dash](http://kapeli.com/dash).

## Usage

Enter the following feed address:

[`dash-feed://https%3A%2F%2Fraw.github.com%2FWoLpH%2Fdash-docset-logstash%2Fmaster%2Flogstash.xml`](dash-feed://https%3A%2F%2Fraw.github.com%2FWoLpH%2Fdash-docset-logstash%2Fmaster%2Flogstash.xml)

Or the https version of the link:

https://raw.githubusercontent.com/WoLpH/dash-docset-logstash/master/logstash.xml

## Generating

To generate the docs yourself you have a few prerequisites:

 1. `gnu-sed` (With homebrew you can install this using `brew install gnu-sed`)
 2. `git`
 3. `sqlite3`

After that simply run the `generate.sh` command and you're done:

    ./generate.sh

## License

See [LICENSE](LICENSE).

