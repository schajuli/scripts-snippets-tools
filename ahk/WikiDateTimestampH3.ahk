#Requires AutoHotkey v2.0.12+

^+y:: {
    dts := FormatTime(, 'yyyy-MM-dd')
    SendText('### ' dts)
}
