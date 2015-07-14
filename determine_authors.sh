#!/bin/bash
CMD=`basename $0`;

# prints the usage message
function usage() {
	echo -e "$CMD is a simple script to extract the list of GIT authors from
the files contained in the current directory.
It can be used to extract information only on specific file extensions.\n
Syntax: $CMD [-h|<filetype>]
\t-h: prints usage information
\t<filetype>: display authors for specific filetype
\te.g. determine_authors.sh 'js' # examines authorship for *.js files
\n"
}

function extract_authors {
    for filename in $(find . -iname "*.$1"); do
        git log $filename | grep Author;
    done
}

while getopts ":h" Option
do
    case $Option in
        h ) usage
            exit 0;;
    esac
done

# initialise params
if [ $# -eq 1 ]; then
    EXT=$1;
else
    EXT='*';
fi

extract_authors "${EXT}"

exit 0