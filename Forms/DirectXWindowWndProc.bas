#include once "DirectXWindowWndProc.bi"
#include once "win\windowsx.bi"
#include once "DisplayError.bi"
#include once "Resources.RH"

Const rgbRed As COLORREF = &h000000FF
Const rgbGreen As COLORREF = &h0000FF00
Const rgbBlue As COLORREF = &h00FF0000
Const rgbBlack As COLORREF = &h00000000
Const rgbWhite As COLORREF = &h00FFFFFF
Const MOVE_DX = 10
Const MOVE_DY = 10

Type DirectXWindowData
	Dim MemoryDC As HDC
	Dim MemoryBM As HBITMAP
	Dim OldMemoryBM As HGDIOBJ
	Dim GreenPen As HPEN
	Dim BlueBrush As HBRUSH
	Dim OldPen As HGDIOBJ
	Dim OldBrush As HGDIOBJ
	' Dim ShapeRectangle As RECT
End Type

Sub DirectXWindowRender(ByVal hWin As HWND)
	' Прямоугольник обновления
	' Dim UpdateRectangle As RECT = Any
	' SetRect( _
		' @UpdateRectangle, _
		' ShapeRectangle.left - MOVE_DX - 1, _
		' ShapeRectangle.top - MOVE_DY - 1, _
		' ShapeRectangle.right + MOVE_DX + 1, _
		' ShapeRectangle.bottom + MOVE_DY + 1 _
	' )
	' Стираем старое изображение
	' FillRect(MemoryDC, @UpdateRectangle, Cast(HBRUSH, GetStockObject(BLACK_BRUSH)))
	' Рисуем
	' Ellipse(MemoryDC, ShapeRectangle.left, ShapeRectangle.top, ShapeRectangle.right, ShapeRectangle.bottom)
	' Выводим в окно
	' InvalidateRect(hWin, @UpdateRectangle, FALSE)
End Sub

Function DirectXWindowWndProc(ByVal hWin As HWND, ByVal wMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM) As LRESULT
	
	Select Case wMsg
		
		Case WM_CREATE
			Dim Parameter As DirectXWindowData Ptr = Allocate(SizeOf(DirectXWindowData))
			If Parameter = NULL Then
				PostQuitMessage(1)
			End If
			
			SetWindowLongPtr(hWin, GWLP_USERDATA, Cast(LONG_PTR, Parameter))
			
			Dim ClientRect As RECT = Any
			GetClientRect(hWin, @ClientRect)
			
			Dim hDC As HDC = GetDC(hWin)
			Parameter->MemoryDC = CreateCompatibleDC(hDC)
			Parameter->MemoryBM = CreateCompatibleBitmap(hDC, ClientRect.right, ClientRect.bottom)
			ReleaseDC(hWin, hDC)
			
			Parameter->GreenPen = CreatePen(PS_SOLID, 3, rgbGreen)
			Parameter->BlueBrush = CreateSolidBrush(rgbBlue)
			
			Parameter->OldMemoryBM = SelectObject(Parameter->MemoryDC, Parameter->MemoryBM)
			Parameter->OldPen = SelectObject(Parameter->MemoryDC, Parameter->GreenPen)
			Parameter->OldBrush = SelectObject(Parameter->MemoryDC, Parameter->BlueBrush)
			
			' Визуализация
			DirectXWindowRender(hWin)
			
		Case WM_PAINT
			Dim Parameter As DirectXWindowData Ptr = Cast(DirectXWindowData Ptr, GetWindowLongPtr(hWin, GWLP_USERDATA))
			Dim ps As PAINTSTRUCT = Any
			Dim hDC As HDC = BeginPaint(hWin, @ps)
			BitBlt(hDC, ps.rcPaint.left, ps.rcPaint.top, ps.rcPaint.right, ps.rcPaint.bottom, _
				Parameter->MemoryDC, ps.rcPaint.left, ps.rcPaint.top, _
				SRCCOPY _
			)
			EndPaint(hWin, @ps)
			
		Case DRXWINDOW_ADD
			' Dim pParticle As Particle Ptr = CPtr(Particle Ptr, lParam)
			
		Case DRXWINDOW_CLEAR
			
		Case WM_DESTROY
			Dim Parameter As DirectXWindowData Ptr = Cast(DirectXWindowData Ptr, GetWindowLongPtr(hWin, GWLP_USERDATA))
			SelectObject(Parameter->MemoryDC, Parameter->OldMemoryBM)
			SelectObject(Parameter->MemoryDC, Parameter->OldBrush)
			SelectObject(Parameter->MemoryDC, Parameter->OldPen)
			DeleteObject(Parameter->BlueBrush)
			DeleteObject(Parameter->GreenPen)
			DeleteObject(Parameter->MemoryBM)
			DeleteDC(Parameter->MemoryDC)
			Deallocate(Parameter)
			PostQuitMessage(0)
			
		Case Else
			Return DefWindowProc(hWin, wMsg, wParam, lParam)
			
	End Select
	
	Return 0
	
End Function
