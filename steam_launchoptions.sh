#!/bin/env bash

#    Common launch options for all Steam client Windows/Linux games on Linux
#    Copyright (C) 2018  Pekka Helenius
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

###########################################################

# Default target platform
# Valid platforms are: Windows, Linux

DEFAULT_PLATFORM="Windows"
SECOND_PLATFORM="Linux"

LAUNCH_OPTIONS_WINDOWS="WINEPATH=/usr/bin/ %command%"
LAUNCH_OPTIONS_LINUX="%command%"

###########################################################

# Default Steam client main folder path

STEAMPATH="$HOME/.local/share/Steam"

###########################################################

# http://wiki.bash-hackers.org/snipplets/print_horizontal_line#a_line_across_the_entire_width_of_the_terminal
function INFO_SEP() { printf '%*s\n' "${COLUMNS:-$(tput cols)}" '' | tr ' ' - ; }

###########################################################

if [[ ! -d ${STEAMPATH} ]]; then
  INFO_SEP
  echo -e "\n\e[1mError: Steam client folder not found for user $USER\e[0m\n\nAborting.\n"
  exit 1
fi

if [[ $(ps -o pid --no-headers -C steamwebhelper | wc -l) -ne 0 ]]; then
  INFO_SEP
  echo -e "\n\e[1mError: Steam client is running\e[0m\n\nYou must close your Steam client in order to run this script. Otherwise, launch options would not be accepted by the client.\n\nAborting.\n"
  exit 1
fi

###########################################################

INFO_SEP

echo -e "\n\e[1mSteam Platform Target\e[0m\nPlease determine your target platform for Steam games launch option changes.\n\nValid options are\n\n1) ${DEFAULT_PLATFORM}\n2) ${SECOND_PLATFORM}\n"

read -r -p "" -i "1" -e PLATFORM

if [[ $(printf '%s' ${PLATFORM} | sed '/^\s*$/d') == "" ]]; then
  echo -e "Warning: Platform not determined. Using default platform (${DEFAULT_PLATFORM}).\n"
  PLATFORM=${DEFAULT_PLATFORM}
elif [[ ! $(printf '%s' ${PLATFORM} | sed '/^\s*$/d') =~ ^[1-2]$ ]]; then
  echo -e "Not a valid value. Valid values are 1 and 2. Using default platform (${DEFAULT_PLATFORM}).\n"
  PLATFORM=${DEFAULT_PLATFORM}
fi

if [[ $PLATFORM -eq 1 ]]; then
  PLATFORM=${DEFAULT_PLATFORM}
elif [[ $PLATFORM -eq 2 ]]; then
  PLATFORM=${SECOND_PLATFORM}
fi

if [[ $PLATFORM != "Windows" ]] && [[ $PLATFORM != "Linux" ]]; then
  echo -e "Invalid platform '${PLATFORM}'. Aborting\n"
  exit 1
fi

###########################################################

# Default platform specific launch options

if [[ $PLATFORM == "Windows" ]]; then
  DEFAULT_LAUNCH_OPTIONS=${LAUNCH_OPTIONS_WINDOWS}
elif [[ $PLATFORM == "Linux" ]]; then
  DEFAULT_LAUNCH_OPTIONS=${LAUNCH_OPTIONS_LINUX}
fi

###########################################################

echo -e "\nTarget platform: \e[1m${PLATFORM}\e[0m\n"

echo -e "\e[1mCommon launch options for all Steam client ${PLATFORM} games on Linux\e[0m\n"

INFO_SEP

echo -e "\e[1mWARNING:\e[0m This script overrides any launch options used for Steam client ${PLATFORM} games on Linux.\n\nDefault launch override options are as follows:\n\n\e[1m${DEFAULT_LAUNCH_OPTIONS}\e[0m\n\n\
If you want to use these options, press Enter. Otherwise, supply your own launch override \
string now.\n\e[1mNOTE:\e[0m Be aware that any previous overrides for ${PLATFORM} Steam games will be overwritten.\n"

read -r -p "" -i "${DEFAULT_LAUNCH_OPTIONS}" -e LAUNCH_OPTIONS_RAW

###########################################################

if [[ $(printf '%s' ${LAUNCH_OPTIONS_RAW} | sed '/^\s*$/d') == "" ]]; then
  echo -e "Launch options are empty. Any previous launch options will be cleared.\n"
else
  echo -e "\nLaunch options are:\n\e[1m${LAUNCH_OPTIONS_RAW}\e[0m\n"
fi

read -r -p "Confirm [Y/n] " -i "y" -e confirm
if [[ ! $(echo ${confirm} | sed '/^\s*$/d') =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e "Aborting\n"
  exit 0
fi
unset confirm
echo ""

###########################################################

# Commonly used Internal Field Separator for loops in this script

IFS=$'\n'

###########################################################

# Determine platform-specific games and their AppIDs

i=0
for game in $(find ${STEAMPATH}/steamapps/common/ -mindepth 1 -maxdepth 1 -type d -printf '%f\n'); do
  gamedir="${STEAMPATH}/steamapps/common/${game}"

  if [[ ${PLATFORM} == "Windows" ]]; then
    bincmd=$(find "${gamedir}" -type f | sed -E '/.*\/.*\.exe$/!d')
  elif [[ ${PLATFORM} == "Linux" ]]; then
    bincmd=$(find "${gamedir}" -type f | sed -E '/.*\/.*\.[A-Za-z0-9]+$/d')
  fi

  for bin in ${bincmd}; do
    if [[ $(file -bn ${bin}) == *${PLATFORM}* ]]; then
      valid_games[$i]="${game}"
      let i++
      break
    fi
  done
done

if [[ -z ${valid_games[*]} ]]; then
  echo -e "No ${PLATFORM} games found\n"
  exit 0
fi

# Sort game list
valid_games=($(sort <<< "${valid_games[*]}"))

i=0
workdir=${PWD}
cd ${STEAMPATH}/steamapps/
for game_idfile in ${valid_games[@]}; do
  games_appids[$i]=$(grep -l -d skip "${game_idfile}" * | grep -oE "[0-9]*")
  let i++
done
cd ${workdir}

echo -e "Found local ${PLATFORM} games:\n\n$(i=0; for k in ${valid_games[*]}; do echo -e "$(( ${i} + 1))) ${k} (AppID: ${games_appids[$i]})"; let i++; done)\n\n"

###########################################################

echo -e "Select the game(s) you want to update [Default: all]\n"

read -r -p "" -i "all" -e SELECTED_GAMES

if [[ $(printf '%s' ${SELECTED_GAMES} | sed 's/[ \t]*$//') == "all" ]]; then

  k=0
  for h in ${valid_games[@]}; do 
    SELECTED_GAMES_NAMES[$k]=${h}
    SELECTED_GAMES_APPIDS[$k]=${games_appids[$k]}
    let k++
  done

else

  p=0
  unset IFS
  for game_selection in ${SELECTED_GAMES}; do
    if [[ ${game_selection} =~ ^[0-9]+$ ]]; then
      single_game=${games_appids[$(( ${game_selection} - 1 ))]}
      if [[ -z ${single_game} ]]; then
        echo -e "\e[1mWarning:\e[0m Game option ${game_selection} not in valid range\n"
      else
        gamelist[$p]="${single_game}"
        let p++
      fi
    else
      echo -e "\e[1mWarning:\e[0m Unrecognized game option ${game_selection}\n"
    fi
  done
  IFS=$'\n'

  # Sort game list, remove duplicates
  gamelist=($(sort -u <<< "${gamelist[*]}"))

fi

if [[ -v gamelist ]]; then
  x=0
  for s in ${gamelist[*]}; do
    y=0
    for j in ${games_appids[*]}; do
      if [[ "${s}" == "${j}" ]]; then
        gamelist_names[$x]="${valid_games[$y]} (AppID: ${s})"
        gamelist_appids[$x]="${s}"
        let x++
      fi
      let y++
    done
  done

  # Sort game list
  SELECTED_GAMES_APPIDS=($(sort <<< "${gamelist_appids[*]}"))
  SELECTED_GAMES_NAMES=($(sort <<< "${gamelist_names[*]}"))

  echo -e "\nSelected games:\n$(for g in ${gamelist_names[*]}; do echo -e "- ${g}"; done)\n"

fi

###########################################################

# Find file localconfig.vdf
LOCALCONF=$(find ${STEAMPATH}/userdata/*/config -type f -name "localconfig.vdf")

###########################################################

read -r -p "Apply changes to the selected games [Y/n] " confirm
if [[ ! $(echo ${confirm} | sed '/^\s*$/d') =~ ^([yY][eE][sS]|[yY])$ ]]; then
  echo -e "Aborting\n"
  exit 0
fi

echo ""

###########################################################

d=0
for game_id in ${SELECTED_GAMES_APPIDS[@]}; do

  echo -e "Applying launch options for ${SELECTED_GAMES_NAMES[$d]}"

  # We seek these patterns in the ${LOCALCONF} file
  pattern1="\"${game_id}\""
  pattern2="\}$"
  inclpattern="LastPlayed"

  # These are raw line numbers which partially match our patterns
  # We sort these in reverse order, so that the last found lines are listed first
  # The first listed group of lines is the one we are interested in
  lines_rawnumbers=$(sed -n "/${pattern1}/,/${pattern2}/=;/${pattern2}/{x;/${inclpattern}/=;s/.*//;x}" ${LOCALCONF} | sort -r)

  # Pretty much same than above, but get only valid part from the ${LOCALCONF} file
  # This match applies only, if all the following is valid:
  # - starting pattern is ${pattern1}
  # - ending pattern is ${pattern2}
  # - there exists a third pattern ${inclpattern} between starting and ending patterns
  #
  lines_raw=$(sed -n "/${pattern1}/,/${pattern2}/{H};/${pattern2}/{x;/${inclpattern}/p;s/.*//;x}" ${LOCALCONF})

  # If we can't determine a valid line range as specified in ${lines_raw}, shift the loop
  # and continue to the next game
  if [[ -z ${lines_raw} ]]; then
    echo -e "Warning: Could not find valid entries for ${SELECTED_GAMES_NAMES[$d]}\n"
    error=
    shift
  fi

  # Just put lines_rawnumbers into a valid array 'linenumbers', nothing else
  i=0
  for line_rawnumber in ${lines_rawnumbers[*]}; do
    linenumbers[$i]=${line_rawnumber}
    let i++
  done

  # We don't need this variable anymore
  unset lines_rawnumbers

  # Determine/Calculate valid line number range for lines presented in ${lines_raw}
  # We are interested only in the last uniform line range found in 'linenumbers' array
  #
  # We iterate through this uniform line range, starting from the largest number, which is
  # the first index value in 'linenumbers' array
  # We compare currently iterated line number to the next one in 'linenumbers' array
  #
  # The currently iterated line number is substracted by 1 and compared to
  # the next 'linenumbers' array index value. If they match, we continue iteration.
  # Once the first non-matching value pair is found, we determine the first line
  # number, presented by variable 'first_rawline', adn break the loop
  line_count=0
  for line in ${linenumbers[@]}; do
    if [[ $(( ${line} - 1 )) -ne ${linenumbers[$(( ${line_count} + 1 ))]} ]]; then
      first_rawline=${linenumbers[${line_count}]}
      break
    fi
    let line_count++
  done

  # We reversed the line numbers in 'linenumbers' array so the last line is actually the first value in this array
  last_rawline=${linenumbers[0]}

  # These are actual game specific option lines between brackets
  # Numbers in these calculations have been determined by investigating
  # the structure of ${LOCALCONF} file
  first_optionline=$(( ${first_rawline} + 2 ))
  last_optionline=$(( ${last_rawline} - 1 ))

  # Determine how many prefix tabulators are needed for the "LaunchOptions" field in ${LOCALCONF} file
  prefixtab_count=$(sed -n "${last_optionline}p" ${LOCALCONF} | cat -T -- | grep -o "^[\^I]*" | awk -F ^ '{print NF-1}')

  # Print counted number of tabulator prefix characters for LaunchOptions field
  prefixtabs=$(printf "\t%.0s" $(seq 1 $prefixtab_count))

  # Final format of LaunchOptions field to be inserted into the ${LOCALCONF} file
  LAUNCH_OPTIONS=$(printf '%s\"%s\"\t\t\"%s\"' ${prefixtabs} "LaunchOptions" ${LAUNCH_OPTIONS_RAW})

  # Iterate through all game-specific lines
  for dataline in $(seq ${first_optionline} ${last_optionline}); do

    # If the current line has string "LaunchOptions", replace that line with the new one
    # Break the loop after that, we don't need to iterate through other lines
    if [[ $(sed -n "${dataline}p" ${LOCALCONF} | grep "\"LaunchOptions\"" | wc -l) -eq 1 ]]; then
      OPTIONS=${LAUNCH_OPTIONS} LINE=${dataline} \
      perl -npi -e 's/.*\n/$ENV{OPTIONS}\n/g if $.==$ENV{LINE}' ${LOCALCONF}
      break
    fi

    # If the current line is the last option line for the game and "LaunchOptions" field has not been encountered yet, append our "LaunchOptions" field as the last field for this game
    # Break the loop after that
    if [[ ${dataline} -eq ${last_optionline} ]]; then
      prevline_contents=$(sed -n "${dataline}p" ${LOCALCONF})

      OPTIONS=${LAUNCH_OPTIONS} LINE=${dataline} PREVCONTENTS=${prevline_contents} \
      perl -npi -e 's/.*\n/$ENV{PREVCONTENTS}\n$ENV{OPTIONS}\n/g if $.==$ENV{LINE}' ${LOCALCONF}
      break

    fi

  done

  let d++
done

if [[ -v error ]]; then
  echo -e "\nSomething went wrong. Check messages above.\n"
  exit 1
else
  echo -e "\nDone. You can start your Steam client.\n"
  exit 0
fi
