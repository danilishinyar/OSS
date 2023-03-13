#!/bin/bash

err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S')]: $*" >&2
}

PS3='> '
options=(
         "Table of file systems" 
         "Mount fs"
         "Unmount fs"
         "Change params of fs"
         "Show params of fs"
         "Info ext* fs"
         "Quit"
       )


makelist() {
  local -n options1=$1
  options1+=(
            "Help"
            "Exit"
            ) 
  while true
  do
  select opt in "${options1[@]}"; do
    case $opt in
      Help)
        echo $2
        break
        ;;
      Exit)
        return 0
        ;;
      *)
        if [ -z $opt ]; then
          err "Enter number from the list"
          break
        else
          return $REPLY
        fi
        ;;
      esac
    done
  done
  }



output() {
  if [ $1 -ne 0 ]; then
    err $3
    return
  else
    echo $2
  fi
}


table_fs() {
  df -x proc -x sys -x tmpfs -x devtmpfs -H --output=target,source,fstype,size
}


mount_fs() {
  read -p "Path to file/device: " filepath

  #Check if filepath is valid

  if [ ! -f $filepath ] && [ ! -b $filepath ]; then
    err "Doesn't exist"
    return
  fi

  read -p "Path to mount point: " mountpath

  #Check if mount path is valid

  if [ ! -e $mountpath ]; then
    mkdir $mountpath
    if [ $? -ne 0 ]; then
      err "Can't create dir"
      return
    fi 
  fi

  if [ -d $mountpath ]; then
    if [ ! -z "$(ls -A $mountpath)" ]; then
      err "Dir not empty"
      return
    fi
  else
    err "Not a directory"
  fi

  #Mount fs (link with device if it is file)

  if [ -f $filepath ]; then
    device=$(losetup --find --show $filepath)
    mkfs -t ext4 $device
    mount $device $mountpath
  else
    mount $filepath $mountpath
  fi
  output $? "Successfully mounted" "Error occured"
  mount | grep $mountpath
  return
}


umount_fs(){
  read -p "Enter file system path (skip to choose):" fspath

  if [ -z $fspath ]; then
    IFS=$'\n' read -r -d '' -a arr < <(df -x proc -x sys -x devtmpfs -x tmpfs --output=target | tail -n+2 && printf '\0')
    makelist arr "Enter number of dir you want to unmount"
    num=$?
    [ $num == 0 ] && return
    fspath=${arr[num-1]}
  fi

  if [ ! -z $fspath ]; then
    umount $fspath
  fi
  output $? "Successfully unmounted" "Error occured"
}


show_fs(){
  read -p "Enter file system path (skip to choose):" fspath

  if [ -z $fspath ]; then
    IFS=$'\n' read -r -d '' -a arr < <(df -x proc -x sys -x devtmpfs -x tmpfs --output=target | tail -n+2 && printf '\0')
    makelist arr "Enter number of dir you want to show params"
    num=$?
    [ $num == 0 ] && return
    fspath=${arr[num-1]}
  fi

  if [ ! -z $fspath ]; then
    mount | grep $fspath -m 1
  fi
}



info_ext(){
  echo "Current ext* file systems:"

}


if [ "$1" = "-h" ]; then
  echo "Script that allows to manage file systems."
  exit
fi
while true
do
select opt in "${options[@]}"
do
  case $opt in
    "Table of file systems")
      table_fs
      break
      ;;
    "Mount fs")
      mount_fs
      break
      ;;
    "Unmount fs")
      umount_fs
      break
      ;;
    "Change params of fs")
      echo "4"
      ;;
    "Show params of fs")
      show_fs
      break
      ;;
    "Info ext* fs")
      echo "6"
      ;;
    "Quit")
      exit
      ;;
    *) err "Invalid option $REPLY"
  esac
done
done





