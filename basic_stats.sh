#!/bin/bash
CMD=`basename $0`;

# prints the usage message
function usage() {
	echo -e "$CMD is a script to extract some basic info on git authors from
the files contained in the current directory.
If invoked without parameters it will output the overall list of commits count
per author (-o) followed by the list of files in the current directory with 
the commit count for each author.
It can also be used to extract information on specific file extensions.\n
Syntax: $CMD [-h|-o|[-c|-a|-d] <filetype>]
\t-h: prints this help
\t-o: displays just the overall commits count per author
\t-c: displays the files ordered by number of commits
\t-a: displays overall commits, and list of commits by author per each file
\t-d: just extract the authors, to be used in conjunction with tally_authors.rb
\t<filetype>: display authors commit count for specific filetypes
\te.g. $CMD js # examines authorship for *.js files
\n"
}

# returns the list of authors
function extract_authors {
    for filename in $(find . -iname "${PATTERN}"); do
        git log $filename | grep "Author"
    done
}

# uses the log of a specific file to capture the number of commits per person
function count_author_commits_per_file {
    if [[ ! -n $1 ]]; then
        filename=''
    else
        filename=$1;
    fi
    git log --pretty=format:"%an <%ae>" $filename | awk '{
        authorsCount[$NF]++; 
        authors[$NF]=$0; 
    } 
    END { 
        for (i in authorsCount) 
            printf("%d\t%s\n", authorsCount[i], authors[i]); 
    }';
}

function tally_authors {
    if [[ -n $OVERALL_ONLY ]]; then
        echo "Overall";
        count_author_commits_per_file | sort -k1,1nr -k2,2;
        return
    fi
    for filename in $(find . -iname "${PATTERN}" -not -wholename "*.git*" -not -wholename "*.svn*"); do
        authors=`count_author_commits_per_file $filename | sort -k1,1nr -k2,2`;
        if [ "$authors" = "" ]; then
            continue;
        fi
        if [ $filename = '.' ]; then
            echo "Overall"
        else
            echo $filename;
        fi
        echo "$authors";
   done
}

function count_commits_per_file {
    for filename in $(find . -iname "${PATTERN}" -not -wholename "*.git*" -not -wholename "*.svn*"); do
        commits_count=`git rev-list HEAD --count ${filename}`;
        if [ $commits_count -gt 0 ]; then
            echo -e "${commits_count}\t${filename}"; 
        fi
    done
}

function sort_files_by_commits {
    file_commits=`count_commits_per_file | sort -k1,1nr -k2,2`;
    if [[ -n $ALL_STATS ]]; then
        echo "${file_commits}" | while read line; do
            tot_commits=`echo ${line} | awk '{ print $1 }'`;
            filename=`echo "${line}" | awk '{ sub(/.*\t/, ""); print }'`;
            echo ${filename};
            echo "${tot_commits} total commit(s)"
            count_author_commits_per_file $filename | sort -k1,1nr -k2,2;
            echo "";
        done
    else
        echo "$file_commits";
    fi
}

while getopts ":hocad" Option
do
    case $Option in
        h) usage
            exit 0
            ;;
        o) OVERALL_ONLY=true
            ;;
        c) FILE_COMMITS_ONLY=true
            ;;
        a) ALL_STATS=true
            ;;
        d) DEPRECATED=true
            ;;
    esac
done

# Decrements the argument pointer so it points to next argument.
# $1 now references the first non-option item supplied on the command-line
# if one exists.
shift $(($OPTIND - 1))

if [ $# -eq 1 ]; then
    PATTERN="*.$1";
else
    PATTERN='*.*';
fi

if [[ -n $FILE_COMMITS_ONLY ]]; then
    sort_files_by_commits;
elif [[ -n $ALL_STATS ]]; then
    sort_files_by_commits;
elif [[ -n $DEPRECATED ]]; then
    extract_authors;
else
    tally_authors "${PATTERN}";
fi

exit 0
