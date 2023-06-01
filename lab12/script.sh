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
		Выход) return 0;;
		Справка) echo "$2";;
		*)
			if [[ -z $opt ]]; then
				echo "Error enter number from the list" >&2
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
	echo 'This script allows you to manahe SElinux settings.'
	exit
fi

PS3=$'\n> '
options=(
	"Manage ports"
	"Manage files"
    "Manage switchers"
	"Info"
	"Quit"
)

select opt in "${options[@]}"
do
	case $opt in
	"Manage ports")
		readarray -t services < <(semanage port -l -n | cut -d' ' -f1)
		partselect services "Enter service name: " "Enter service number"
		res=$?
		[ $res == 0 ] && continue
		service=${services[res - 1]}
		select opt in "Add new port" "Delete port" "Modify port" "Info" "Quit"; do
		case $opt in
            "Add new port")
				read -p "Enter port number: " port
				semanage port -a -t "$service" -p tcp "$port"
                check $? "Suckass" "Error"
                ;;
            "Delete port")
				readarray -t ports < <(semanage port -l | grep -E "^$service\s" | awk '{$1=$2=""; print $0}' | sed 's/,/\n/g' | sed 's/\s//g')
				listselect ports "Enter port number"
				res=$?
				if [ $res -ne 0 ]; then
					port=${ports[res - 1]}
					semanage port -d -t "$service" -p tcp "$port"
                	check $? "Deleted" "Error"
				fi
                ;;
            "Modify port")
				readarray -t ports < <(semanage port -l | grep -E "^$service\s" | awk '{$1=$2=""; print $0}' | sed 's/,/\n/g' | sed 's/\s//g')
				listselect ports "Enter port number"
				res=$?
				if [ $res -ne 0 ]; then
					port=${ports[res - 1]}
					read -p "Enter new number: " port2
					semanage port -d -t "$service" -p tcp "$port"
                	check $? "Deleted" "Error"
					semanage port -a -t "$service" -p tcp "$port2"
					check $? "Port added" "Error"
				fi
                ;;
            "Info")
                echo "Enter what do you want to do with port $service"
                ;;
            "Quit")
                break
                ;;
	        *) echo "Incorrect input $REPLY";;
		esac
		done
		;;

	"Manage files")
        select opt in "Catalog redevelopment" "Start full fs redevelopment with reboot" "Change file/catalog type" "Info" "Quit"; do
		case $opt in
            "Catalog redevelopment")
				read -e -p "Catalog name: " path
				restorecon -Rvv "$path"
                check $? "OK" "Error"
                ;;
            "Start full fs redevelopent with reboot")
                touch /.autorelabel
                check $? "OK" "Error"
                ;;
            "Change file/catalog type")
				read -e -p "Enter path: " path
				path=$(realpath "$path")
				read -p "Enter new type: " newtype
				semanage fcontext -a -t "$newtype" "$path(/.*)?"
                check $? "" "Error"
				restorecon -Rv "$path"
                check $? "OK" "Error"
                ;;
            "Info")
                echo "Choose operation"
                ;;
            "Quit")
                break
                ;;
	        *) echo "Wa-wa $REPLY";;
		esac
		done
        ;;

	"Manage switchers")
		select opt in "Display list of switcher with description and state" "Change switcher" "Info" "Quit"; do
		case $opt in
            "Display list of switchers with description and state")
                getsebool -a
                ;;
            "Change switcher")
				readarray -t booleans < <(getsebool -a | cut -d' ' -f1)
				partselect booleans "Enter name of the switcher: " "Enter number of the switcher:"
				res=$?
				if [ $res -ne 0 ]; then
					boolean=${booleans[res - 1]}
					state=$(getsebool "$boolean" | awk -F '--> ' '{print $2}')
					echo "Current state: $state"
					read -p "Switch (y/n)? " answer
					case ${answer:0:1} in
						y|Y )
							state=$(echo "$state" | sed -e 's/off/o_n/' -e 's/on/o_ff/' -e 's/_//')
							setsebool -P "$boolean" "$state"
               		 		check $? "Successful: $boolean := $state" ":---------("
						;;
					esac
				fi
                ;;
            "Info")
                echo "Choose switchers setting"
                ;;
            "Quit")
                break
                ;;
	        *) echo "Wa-wa $REPLY";;
		esac
		done
		;;
	"Info")
		echo "Enter command"
		;;
	"Quit")
		break
		;;
	*) echo "Incorrect input $REPLY";;
	esac
done
