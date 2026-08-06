#Requires AutoHotkey v2.0.12+

^+x:: {
    dts := FormatTime(, 'yyyy-MM-dd')
    SendText('#anchor(' dts ' | ... )')
}
