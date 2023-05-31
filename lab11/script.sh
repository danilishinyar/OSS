#!/bin/bash


err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S')]: $*" >&2
}


check() {
	if [ $1 -ne 0 ]; then
		err ${@:3}
		exit
	else
		if [ "$2" != "" ]; then
			echo $2
		fi
	fi
}


display() {
    if [ $(wc -l <<< "$1") -lt 30 ]; then
        echo "$1"
    else
        less <<< "$1"
    fi
}


listselect() {
	local -n list=$1
	list+=("Info" "Quit")
	select opt in "${list[@]}"; do
	case $opt in
		Quit) return 0;;
		Info) echo "$2";;
		*)
			if [[ -z $opt ]]; then
				echo "Error: enter number from the list" >&2
			else
				return $REPLY
			fi
			;;
	esac
	done
}


index() {
	local -n list=$1
	for i in "${!list[@]}"; do
		if [[ "${list[$i]}" = "$2" ]]; then
			return "$((i+1))"
		fi
	done
	return 0
}


partselect() {
	read -p "$2" name
	index $1 "$name"
	res=$?
	if [ $res == 0 ]; then
		local -n list=$1
		readarray -t filtered < <(printf -- '%s\n' "${list[@]}" | grep "$name")
		listselect filtered "$3"
		res=$?
		if [ $res == 0 ]; then
			return 0
		else
			index $1 "${filtered[res - 1]}"
			return $?
		fi
	else
		return $res
	fi
}


if [ "$EUID" -ne 0 ]; then
	exit
fi

if [ "$1" = "--help" ]; then
	echo 'This script allows to manage audit events'
	exit
fi


PS3=$'\n> '
options=(
	"Find audit event"
	"Audit report"
	"Audit settings"
	"Info"
	"Quit"
)


select opt in "${options[@]}"
do
	case $opt in
	"Find audit event")
		read -p "Event type (empty = ALL): " etype
		if [ "$eventtype" == "" ]; then
			etype=ALL
		fi
		read -p "Userid (can be empty): " userid
		read -p "Enter search string: " searchstring
		if [ "$search" == "" ]; then
			search="="
		fi
		if [ "$userid" == "" ]; then
			ausearch -m $etype | grep $search -B 2
		else
			ausearch -m "$etype" -ui "$userid" | grep "$search" -B 2
		fi
		;;

	"Audit report")
		report=""
		echo "Choose option: "
		select opt in "Report about login" "Report about failures" "Info" "Quit"; do
		case $opt in
            "Report about login")
				report="-au"
                break
                ;;
            "Report about failures")
				report="--failed --user"
                break
                ;;
            "Info")
                echo "Choose report wisely"
                ;;
            "Quit")
                break
                ;;
	        *) echo "Wa-wa $REPLY";;
		esac
		done
		[ "$report" == "" ] && continue
		period=""
		echo "Choose time period: "
		select opt in "1 day" "week" "month" "year" "Info" "Quit"; do
		case $opt in
            "1 day")
				period="today"
                break
                ;;
            "week")
				period="this-week"
                break
                ;;
            "month")
				period="this-month"
                break
                ;;
            "year")
				period="this-year"
                break
                ;;
            "Info")
                echo "Choose time period"
                ;;
            "Quit")
                break
                ;;
	        *) echo "Wa-wa $REPLY";;
		esac
		done
		[ "$period" == "" ] && continue

		aureport $report -ts "$period" > report
		check $? "Report is saved in file named report" "Error while saving"
        ;;

	"Audit settings")
		select opt in "Add catalog or file to watchlist" "Delete from watch list" "Report" "Info" "Quit"; do
		case $opt in
            "Add catalog or file to watchlist")
				read -e -p "Enter path: " path
				if [ "$path" == "" ]; then
					err "Can't be empty"
					continue
				fi
				if [ -d "$path" ]; then
					auditctl -a exit,always -F "dir=$path" -F perm=warx
				elif [ -f "$path" ]; then
					auditctl -w "$path" -p warx
				else
					err "Doesn't exist"
					continue
				fi
                ;;
            "Delete from watchlist")
				rules=$(auditctl -l)
				if [[ "$rules" == "No rules"* ]]; then
					echo "No rules"
					continue
				fi
				readarray -t paths < <(auditctl -l | cut -d " " -f2)
				listselect paths "Choose rule: "
				res=$?
				[ $res == 0 ] && continue
				rule="${paths[res - 1]}"
				auditctl -W $rule
                ;;
            "Report")
				rules=$(auditctl -l)
				if [[ "$rules" == "No rules"* ]]; then
					echo "No rules"
					continue
				fi
				readarray -t paths < <(cut -d " " -f2 <<< "$rules")
				listselect paths "Choose path"
				res=$?
				[ $res == 0 ] && continue
				path=${paths[res - 1]}
				res=$(aureport --file | grep $path)
				[ "$res" == "" ] && res="No events"
				echo "${res}"
                ;;
            "Info")
                echo "Enter option you want"
                ;;
            "Quit")
                break
                ;;
	        *) echo "Wa-wa $REPLY";;
		esac
		done
        ;;
	"Info")
		echo "Enter option you want"
		;;
	"Quit")
		break
		;;
	*) echo "Incorrect input";;
	esac
done
