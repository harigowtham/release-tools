#!/bin/sh
# Steps to run this
# login to bugzilla from cmd.
       # for this we use the bugzilla package which is installed. use command "bugzilla login"
       # And enter the user name (example@email.com)and password.
# Run as the command as per the example ./close-bugs.sh 5.12 https://lists.gluster.org/pipermail/gluster-users/2020-March/037797.html

declare BUGS VERSION ANNOUNCEURL

if [ "x$DRY_RUN" != "x" ]; then
  DR="echo"
fi

check_for_command()
{
  env bugzilla --version >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "`bugzilla` command is missing"
    echo "Install `python-bugzilla` before running this script again"
    exit 1
  fi
}

close_bugs()
{
	COMMENT="This bug is getting closed because a release has been made available that should address the reported issue. In case the problem is still not fixed with glusterfs-${VERSION}, please open a new bug report.

glusterfs-${VERSION} has been announced on the Gluster mailinglists [1], packages for several distributions should become available in the near future. Keep an eye on the Gluster Users mailinglist [2] and the update infrastructure for your distribution.

[1] ${ANNOUNCEURL}
[2] https://www.gluster.org/pipermail/gluster-users/"

	xargs -n 8 ${DR} bugzilla modify \
		--fixed_in=glusterfs-${VERSION} \
		--status=CLOSED \
		--close=CURRENTRELEASE \
		--comment="${COMMENT}" ${@}
}

get_bugs()
{
        echo "getting the release note for ${VERSION} to parse bugs"
        wget https://raw.githubusercontent.com/gluster/glusterdocs/master/docs/release-notes/${VERSION}.md &> /dev/null
        if [[ "$?" != 0 ]]; then
                echo "Error getting the file from github."
                echo "Make sure the release notes are merged in https://github.com/gluster/glusterdocs"
                exit 1
        else
                echo "Downloaded the file successfully"
        fi
        echo "parsing release note ${VERSION}.md"
        sed -n '/#[0-9]/p' ${VERSION}.md | sed 's/].*//' | tr -d '[]'| sed 's/ //' | sed 's/-#//' > /tmp/bugs
        #removing the downloaded file
        rm ${VERSION}.md
}

#remove this function
query_bugs()
{
        echo "arg:${@}"
        bugzilla query -b ${@}
}

check_for_command

if [ $# -ne 2 ]; then
  echo "Usage: $0 <version-string-for-current-release> <url-to-mailing-list-announcement>"
  exit 1
fi

# the version that was just released.
# example: 5.12
VERSION=$1
#the piper mail announcement mail about the release
#example: https://lists.gluster.org/pipermail/gluster-users/2020-March/037797.html
ANNOUNCEURL=$2

get_bugs
while IFS= read -r line
do
  close_bugs "$line"
done < /tmp/bugs
rm /tmp/bugs
echo "Done"
