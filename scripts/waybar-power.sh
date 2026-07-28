#!/bin/bash

device=$(upower -e | grep -m1 'battery\|line_power')
info=$(upower -i "$device" 2>/dev/null)

state=$(echo "$info" | awk '/state:/{print $2}')
percent=$(echo "$info" | awk '/percentage:/{print $2}')

if [[ "$state" == "charging" ]]; then
    echo "󰂄 $percent"
elif [[ "$state" == "fully-charged" ]]; then
    echo "󰁹 $percent"
elif [[ -n "$percent" ]]; then
    echo "󰁺 $percent"
else
    echo "󰚥 AC"
fi
