xrandr --newmode $(cvt 1280 720 60 | awk 'NR==2 {$1=""; print $0}')
xrandr --addmode VIRTUAL1 1280x720_60.00
xrandr --output VIRTUAL1 --mode 1280x720_60.00 --right-of eDP1
