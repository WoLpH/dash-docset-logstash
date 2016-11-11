#!/bin/sh -e
LOGSTASH=logstash
DBDIR="logstash.docset/Contents/Resources"
DB="docSet.dsidx"
DOCUMENTDIR="${DBDIR}/Documents"
BASE=$(pwd)

if [ -d $LOGSTASH ]; then
    cd $LOGSTASH
    git pull
    git clean -df
    cd $BASE
else
    git clone "git@github.com:elastic/logstash.net.git" $LOGSTASH
fi

HEADER="
<html>\n
    <head>\n
        <link rel='stylesheet' href='http://logstash.net/style.css'>
    </head>\n
    <body>\n
        <div class='container' style='width:100%;padding:1em;'>\n
            <div id='content_right'>\n
                <div class='content_wrapper'>\n"

FOOTER="
                <div class='clear'>\n
                </div>\n
            </div>\n
        </div>\n
    </body>\n
</html>"

INSERTSQL="INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES"
HEADER=$(echo "$HEADER" | tr '\n' ' ')
FOOTER=$(echo "$FOOTER" | tr '\n' ' ')

generate(){
    VERSION=$1
    echo "Generating docs for Logstash $VERSION"

    rm -fv "${DBDIR}/${DB}"
    echo "
    CREATE TABLE searchIndex(
        id INTEGER PRIMARY KEY,
        name TEXT,
        type TEXT,
        path TEXT
    );
    CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);
    " | sqlite3 ${DBDIR}/${DB}

    rm -rf "${DOCUMENTDIR}/"
    mkdir -v "${DOCUMENTDIR}"
    cp -r ${LOGSTASH}/docs/$VERSION/codecs ${DOCUMENTDIR}
    cp -r ${LOGSTASH}/docs/$VERSION/inputs ${DOCUMENTDIR}
    cp -r ${LOGSTASH}/docs/$VERSION/filters ${DOCUMENTDIR}
    cp -r ${LOGSTASH}/docs/$VERSION/outputs ${DOCUMENTDIR}

    for module in codecs inputs filters outputs; do
	    for i in $(ls ${DOCUMENTDIR}/${module}/*.html); do
	        echo "Adding header and footer to: ${i}"
	  	    gsed -i "1,4d" "${i}"
	  	    gsed -i "1 s|^|${HEADER}|" "${i}"
	  	    gsed -i "$ s:$:${FOOTER}:" "${i}"
	  	    RELPATH=$(echo ${i} | sed "s:${DOCUMENTDIR}/::g")
	  	    NAME=$(echo ${RELPATH} | sed "s:${module}/::g" | sed 's/.html//g')
	  	    echo "${INSERTSQL} (\"${module}/${NAME}\", \"Module\", \"${RELPATH}\");" | sqlite3 ${DBDIR}/${DB}

	  	    # Find directives in side each file and add them to the index
	  	    grep '<a name="' "${i}" | \
	  		    gsed -r "s:^.*\"(\w+)\".$:${INSERTSQL} (\"${module}/${NAME}/\1\", \"Directive\", \"${RELPATH}#\1\");:g" | \
	  		    sqlite3 ${DBDIR}/${DB}

	    done
    done

    RELEASE_FILE="releases/logstash-${VERSION}.tgz"
    echo "Generating release: $RELEASE_FILE"
    tar --exclude='.DS_Store' -czf ${RELEASE_FILE} logstash.docset
    rm -rf "${DOCUMENTDIR}/"
}

# Always generate latest version
VERSION=$(ls $LOGSTASH/docs | sort -n | tail -n 1)
generate $VERSION
rm logstash.xml

# Generate all missing versions
for VERSION in $(ls $LOGSTASH/docs | sort -n); do
    # Skip old versions which have a different log format
    [ -d "$LOGSTASH/docs/$VERSION/codecs" ] || continue

    echo "
    <entry>
        <version>$VERSION</version>
	    <url>https://github.com/WoLpH/dash-docset-logstash/raw/master/releases/logstash-${VERSION}.tgz</url>
    </entry>" >> logstash.xml

    [ ! -f "releases/logstash-${VERSION}.tgz" ] && generate $VERSION
done

# Unpack the latest version to keep an unpacked version in the repo for ease of use
tar xzf "releases/logstash-${VERSION}.tgz"
