#!/bin/sh
TMP="tmp";
LOGSTASH=${TMP}/logstash;
DBDIR="logstash.docset/Contents/Resources";
DB="docSet.dsidx";
DOCUMENTDIR="${DBDIR}/Documents";
VERSION="1.2.2";
BASE=$(pwd);
mkdir ${TMP};
git clone "git@github.com:logstash/logstash.git" ${TMP}/logstash;
cd ${LOGSTASH};
git checkout "v${VERSION}";
bundle install;
make docs;
cd ${BASE};

HEADER="<html>\n<head>\n<link rel='stylesheet' href='http://logstash.net/style.css'>\n</head>\n<body>\n<div class='container' style='width:100%;padding:1em;'>\n<div id='content_right'>\n<div class='content_wrapper'>\n";
FOOTER="<div class='clear'>\n</div>\n</div>\n</div>\n</body>";
INSERTSQL="INSERT OR IGNORE INTO searchIndex(name, type, path) VALUES";

rm -fv "${DBDIR}/${DB}";
echo "CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);" | sqlite3 ${DBDIR}/${DB}; 
echo "CREATE UNIQUE INDEX anchor ON searchIndex (name, type, path);" | sqlite3 ${DBDIR}/${DB};
rm -rvf "${DOCUMENTDIR}/"
mkdir -v "${DOCUMENTDIR}"
cp -vr ${LOGSTASH}/build/docs/codecs ${DOCUMENTDIR};
cp -vr ${LOGSTASH}/build/docs/inputs ${DOCUMENTDIR};
cp -vr ${LOGSTASH}/build/docs/filters ${DOCUMENTDIR};
cp -vr ${LOGSTASH}/build/docs/outputs ${DOCUMENTDIR};
find ${DOCUMENTDIR} -name \*.erb -exec rm -f {} \;
find ${DOCUMENTDIR} -name \*-re -exec rm -f {} \;
for module in codecs inputs filters outputs; do
	for i in $(ls ${DOCUMENTDIR}/${module}/*.html); do
		echo "Adding header and footer to: ${i}"
		gsed -i "1,4d" "${i}"
		gsed -i "1 s|^|${HEADER}|" "${i}";
		gsed -i "$ s:$:${FOOTER}:" "${i}";
		RELPATH=$(echo ${i} | sed "s:${DOCUMENTDIR}/::g");
		NAME=$(echo ${RELPATH} | sed "s:${module}/::g" | sed 's/.html//g');
		echo "${INSERTSQL} (\"${module}/${NAME}\", \"Module\", \"${RELPATH}\");" | sqlite3 ${DBDIR}/${DB};

		# Find directives in side each file and add them to the index
		grep '<a name="' "${i}" | \
			gsed -r "s:^.*\"(\w+)\".$:${INSERTSQL} (\"${module}/${NAME}/\1\", \"Directive\", \"${RELPATH}#\1\");:g" | \
			sqlite3 ${DBDIR}/${DB};

	done
done

tar --exclude='.DS_Store' -cvzf releases/logstash-${VERSION}.tgz logstash.docset
rm -rf "${DOCUMENTDIR}/"
rm -rf ${TMP};
