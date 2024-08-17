#Requires AutoHotkey v2.0

; Remap Control key to CapsLock
CapsLock::Ctrl

; Toggle CapsLock by pressing both Shift keys simultaneously
Shift::
{
    ; Check if both Shift keys are pressed
    if (GetKeyState("LShift", "P") && GetKeyState("RShift", "P"))
    {
        ; Toggle CapsLock
        SetCapsLockState(!GetKeyState("CapsLock", "T"))
    }
    else
    {
        Send "{Shift Down}"
    }
}
Shift Up::Send "{Shift Up}"

; Remap Alt to Control
Alt::Ctrl

; Remap Windows key to Alt
LWin::Alt
RWin::Alt

; Remap Left Control to Windows key
LCtrl::LWin
