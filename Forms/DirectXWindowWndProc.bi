#ifndef DIRECTXWINDOWWNDPROC_BI
#define DIRECTXWINDOWWNDPROC_BI

#include once "windows.bi"

#define DRXWINDOW_ADD WM_USER
#define DRXWINDOW_CLEAR WM_USER + 1

Const USERCLASS_DIRECTXWINDOW = __TEXT("DirectXWindow")

Type Particle
	X As Integer
	Y As Integer
	Z As Integer
	R As Integer
End Type

Declare Function DirectXWindowWndProc( _
	ByVal hWnd As HWND, _
	ByVal wMsg As UINT, _
	ByVal wParam As WPARAM, _
	ByVal lParam As LPARAM _
) As LRESULT

#endif
