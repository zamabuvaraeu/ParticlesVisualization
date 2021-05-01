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
Const PARTICLES_BUFFER_CAPACITY As Integer = 100

Type ParticlesBuffer
	Dim Capacity As Integer
	Dim Length As Integer
	Dim Particles As Particle Ptr
End Type

Type DirectXWindowData
	Dim MemoryDC As HDC
	Dim MemoryBM As HBITMAP
	Dim GreenPen As HPEN
	Dim BlueBrush As HBRUSH
	Dim OldMemoryBM As HGDIOBJ
	Dim OldPen As HGDIOBJ
	Dim OldBrush As HGDIOBJ
	Dim Buffer As ParticlesBuffer
End Type

Sub DirectXWindowRender( _
		ByVal hWin As HWND, _
		ByVal Parameter As DirectXWindowData Ptr _
	)
	
	' Прямоугольник обновления
	Dim UpdateRectangle As RECT = Any
	' SetRect( _
		' @UpdateRectangle, _
		' ShapeRectangle.left - MOVE_DX - 1, _
		' ShapeRectangle.top - MOVE_DY - 1, _
		' ShapeRectangle.right + MOVE_DX + 1, _
		' ShapeRectangle.bottom + MOVE_DY + 1 _
	' )
	GetClientRect(hWin, @UpdateRectangle)
	
	' Стираем старое изображение
	FillRect(Parameter->MemoryDC, @UpdateRectangle, Cast(HBRUSH, GetStockObject(BLACK_BRUSH)))
	
	' Рисуем
	For i As Integer = 0 To Parameter->Buffer.Length - 1
		Ellipse( _
			Parameter->MemoryDC, _
			Parameter->Buffer.Particles[i].X, _
			Parameter->Buffer.Particles[i].Y, _
			Parameter->Buffer.Particles[i].R, _
			Parameter->Buffer.Particles[i].R _
		)
	Next
	
	' Выводим в окно
	InvalidateRect(hWin, @UpdateRectangle, FALSE)
	
End Sub

Function DirectXWindowWndProc(ByVal hWin As HWND, ByVal wMsg As UINT, ByVal wParam As WPARAM, ByVal lParam As LPARAM) As LRESULT
	
	Select Case wMsg
		
		Case WM_CREATE
			Dim Parameter As DirectXWindowData Ptr = Allocate(SizeOf(DirectXWindowData))
			If Parameter = NULL Then
				PostQuitMessage(1)
			End If
			
			Parameter->Buffer.Capacity = PARTICLES_BUFFER_CAPACITY
			Parameter->Buffer.Length = 0
			Parameter->Buffer.Particles = Allocate(Parameter->Buffer.Capacity * SizeOf(Particle))
			If Parameter->Buffer.Particles = NULL Then
				PostQuitMessage(1)
			End If
			
			SetWindowLongPtr(hWin, GWLP_USERDATA, Cast(LONG_PTR, Parameter))
			
			Dim hDC As HDC = GetDC(hWin)
			Parameter->MemoryDC = CreateCompatibleDC(hDC)
			
			Dim ClientRect As RECT = Any
			GetClientRect(hWin, @ClientRect)
			Parameter->MemoryBM = CreateCompatibleBitmap(hDC, ClientRect.right, ClientRect.bottom)
			ReleaseDC(hWin, hDC)
			
			Parameter->GreenPen = CreatePen(PS_SOLID, 3, rgbGreen)
			Parameter->BlueBrush = CreateSolidBrush(rgbBlue)
			
			Parameter->OldMemoryBM = SelectObject(Parameter->MemoryDC, Parameter->MemoryBM)
			Parameter->OldPen = SelectObject(Parameter->MemoryDC, Parameter->GreenPen)
			Parameter->OldBrush = SelectObject(Parameter->MemoryDC, Parameter->BlueBrush)
			
			' Визуализация
			' DirectXWindowRender(hWin)
			
		Case WM_PAINT
			Dim Parameter As DirectXWindowData Ptr = Cast(DirectXWindowData Ptr, GetWindowLongPtr(hWin, GWLP_USERDATA))
			Dim ps As PAINTSTRUCT = Any
			Dim hDC As HDC = BeginPaint(hWin, @ps)
			BitBlt( _
				hDC, _
				ps.rcPaint.left, ps.rcPaint.top, ps.rcPaint.right, ps.rcPaint.bottom, _
				Parameter->MemoryDC, _
				ps.rcPaint.left, ps.rcPaint.top, _
				SRCCOPY _
			)
			EndPaint(hWin, @ps)
			
		Case DRXWINDOW_ADD
			Dim Parameter As DirectXWindowData Ptr = Cast(DirectXWindowData Ptr, GetWindowLongPtr(hWin, GWLP_USERDATA))
			Dim nCount As Long = Cast(Long, wParam)
			
			Dim cbFreeSpace As Integer = Parameter->Buffer.Capacity - Parameter->Buffer.Length
			
			If cbFreeSpace < CInt(nCount) Then
				Dim NewCapacity As Integer = Parameter->Buffer.Capacity + CInt(nCount) + PARTICLES_BUFFER_CAPACITY
				
				Dim NewParticles As Particle Ptr = Allocate(NewCapacity * SizeOf(Particle))
				If NewParticles = NULL Then
					Return 0
				End If
				
				Parameter->Buffer.Capacity = NewCapacity
				
				CopyMemory(NewParticles, Parameter->Buffer.Particles, Parameter->Buffer.Length * SizeOf(Particle))
				
				Deallocate(Parameter->Buffer.Particles)
				
				Parameter->Buffer.Particles = NewParticles
			End If
			
			Dim pParticle As Particle Ptr = CPtr(Particle Ptr, lParam)
			CopyMemory(@Parameter->Buffer.Particles[Parameter->Buffer.Length], pParticle, CInt(nCount) * SizeOf(Particle))
			
			Dim NewLength As Integer = Parameter->Buffer.Length + CInt(nCount)
			Parameter->Buffer.Length = NewLength
			
			DirectXWindowRender(hWin, Parameter)
			
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
			Deallocate(Parameter->Buffer.Particles)
			Deallocate(Parameter)
			PostQuitMessage(0)
			
		Case Else
			Return DefWindowProc(hWin, wMsg, wParam, lParam)
			
	End Select
	
	Return 0
	
End Function
