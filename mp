#!/bin/bash
# - rmr = remove range (e.g. 1 5 = remove tracks 1-5)
get_pos(){
  mpc | sed -n 's/^.\+#\([[:digit:]]\+\)\/.\+/\1/g; 2p'
}
get_length(){
  mpc | sed -n 's/^.\+#[[:digit:]]\+\/\([[:digit:]]\+\).\+/\1/g; 2p'
}
list_with_arrow(){
  mpc playlist | nl | sed "$(get_pos)s/^./>/g"
}
max(){
  if [ $1 -gt $2 ]; then echo $1; else echo $2; fi
}
min(){
  if [ $1 -lt $2 ]; then echo $1; else echo $2; fi
}
safe_from(){
  echo $(max 1 $1)
}
safe_to(){
  echo $(min $(get_length) $1)
}

# for some reason '?' and '-?' don't work in fish
if [[ -z $1 || $1 == "help" || $1 == "h" || $1 == "-h" ]]; then
  echo -e "mpc wrapper for ranged playlist commands"
  echo -e "usage:\tmp [COMMAND] [ARGS]\n"
  echo -e "commands:"
  echo -e "ls\t\tscroll playlist with position numbers"
  echo -e "near\t\tshow condensed playlist with position numbers"
  echo -e "mv X Y Z\tmove playlist range X - Y to Z"
  echo -e "rm X Y\tdelete playlist range X - Y"
# playlist with position numbers and j/k scroll
elif [ $1 == "ls" ]; then
  list_with_arrow | less
elif [ $1 == "near" ]; then
  p=$(get_pos)
  l=$(($(tput lines) / 2 - 1))
  echo $l
  list_with_arrow | sed -En "$(safe_from $(($p-$l))),$(safe_to $(($p+$l)))p"
# position
elif [ $1 == "pos" ]; then
  track=$(get_pos)
  length=$(get_length)
  if [[ -z $track || -z $length ]]; then
    echo "mpc is stopped or empty"
  else
    echo "track $track/$length"
  fi
# move range
elif [ $1 == "mv" ]; then
  # can these be made portable (single brace)?
  length=$(get_length)
  if [[ -z $2 || -z $3 || -z $4 ]]; then
    echo "usage: mp mv [SOURCE-RANGE-START] [SOURCE-RANGE-END] [DESTINATION]"
  elif [[ $2 -lt 1 || $3 -gt $length || $4 -lt 1 || $4 -gt $length ]]; then
    echo "invalid source range or destination position"
  elif [[ $2 -gt $3 ]]; then
    echo "[SOURCE-RANGE-START] can't exceed [SOURCE-RANGE-END]"
  elif [[ $4 -gt $2 && $4 -lt $3 ]]; then
    echo "[DESTINATION] can't be between [SOURCE-RANGE-START] and [SOURCE-RANGE-END]"
  else
    range=$(bash -c "echo {$2..$3}")
    if [[ $4 -lt $2 ]]; then
      offset=$(($4-$2))
      for from in $range; do
        mpc mv $from $(($from+$offset))
      done
    elif [[ $4 -gt $3 ]]; then
      for n in $range; do
        mpc mv $2 $4
      done
    else
      echo "nothing to move!"
    fi
  fi
elif [ $1 == "rm" ]; then
  # can these be made portable (single brace)?
  length=$(get_length)
  if [[ -z $2 || -z $3 ]]; then
    echo "usage: mp rm [DEL-RANGE-START] [DEL-RANGE-END]"
  elif [[ $2 -lt 1 || $3 -gt $length ]]; then
    echo "invalid deletion range"
  elif [[ $2 -gt $3 ]]; then
    echo "[SOURCE-RANGE-START] can't exceed [SOURCE-RANGE-END]"
  else
    range=$(bash -c "echo {$2..$3}")
    for n in $range; do
      mpc del $2
    done
  fi
else
  echo "unknown command '$1'"
fi
