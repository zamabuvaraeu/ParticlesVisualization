#ifndef DIRECTXWINDOWWNDPROC_BI
#define DIRECTXWINDOWWNDPROC_BI

#include once "windows.bi"

' wParam - Count
' lParam - Particle pointer
#define DRXWINDOW_ADD WM_USER

' wParam - Not Used
' lParam - Not Used
#define DRXWINDOW_CLEAR WM_USER + 1

Const USERCLASS_DIRECTXWINDOW = __TEXT("DirectXWindow")

Type Particle
	X As Integer
	Y As Integer
	Z As Integer
	R As Integer
End Type

Declare Function RegisterDirecXWindowClass( _
)As Integer

#endif
