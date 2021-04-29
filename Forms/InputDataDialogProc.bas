#include once "InputDataDialogProc.bi"
#include once "win\commctrl.bi"
#include once "win\ole2.bi"
#include once "win\oleauto.bi"
#include once "crt.bi"
#include once "crt\limits.bi"
#include once "DisplayError.bi"
#include once "Resources.RH"

#ifdef UNICODE
#define _i64tot(value, buffer, radix) _i64tow(value, buffer, radix)
#else
#define _i64tot(value, buffer, radix) _i64toa(value, buffer, radix)
#endif

Const C_COLUMNS As Integer = 5

/'
Sub ProcessErrorDouble( _
		ByVal hwndDlg As HWND, _
		ByVal ControlID As ULONG, _
		ByVal hr As HRESULT _
	)
	
	Dim ResourceId As UINT = Any
	Dim TitleResourceId As UINT = Any
	
	Select Case hr
		Case DISP_E_OVERFLOW
			ResourceId = IDS_OVERFLOWTEXT
			TitleResourceId = IDS_OVERFLOWTITLE
			
		Case DISP_E_TYPEMISMATCH
			ResourceId = IDS_INVALIDCHARTEXT
			TitleResourceId = IDS_INVALIDCHARTITLE
			
		Case E_OUTOFMEMORY
			ResourceId = IDS_OUTOFMEMORYTEXT
			TitleResourceId = IDS_OUTOFMEMORYTITLE
			
		Case E_INVALIDARG
			ResourceId = IDS_COEFFICIENTAZEROTEXT
			TitleResourceId = IDS_COEFFICIENTAZEROTITLE
			
		' Case DISP_E_BADVARTYPE
			'The input parameter is not a valid type of variant
			
		Case Else
			ResourceId = IDS_INVALIDARGTEXT
			TitleResourceId = IDS_INVALIDARGTITLE
			
	End Select
	
	Dim tszTitle(1023) As TCHAR = Any
	Dim ret2 As Long = LoadString( _
		GetModuleHandle(NULL), _
		TitleResourceId, _
		@tszTitle(0), _
		1023 _
	)
	tszTitle(ret2) = 0
	
	Dim tszErrorText(1023) As TCHAR = Any
	Dim ret1 As Long = LoadString( _
		GetModuleHandle(NULL), _
		ResourceId, _
		@tszErrorText(0), _
		1023 _
	)
	tszErrorText(ret1) = 0
	
	If hr = DISP_E_TYPEMISMATCH Then
		Dim tszDecimalSeparator(1023) As TCHAR = Any
		GetLocaleInfo( _
			0, _
			LOCALE_SDECIMAL, _
			@tszDecimalSeparator(0), _
			1023 _
		)
		lstrcat( _
			@tszErrorText(0), _
			@tszDecimalSeparator(0) _
		)
	End If
	
	Dim tInfo As EDITBALLOONTIP = Any
	tInfo.cbStruct = SizeOf(EDITBALLOONTIP)
	tInfo.pszTitle = @tszTitle(0)
	tInfo.pszText = @tszErrorText(0)
	tInfo.ttiIcon = TTI_ERROR
	
	Dim hwndTool As HWND = GetDlgItem(hwndDlg, ControlID)
	
	Edit_ShowBalloonTip(hwndTool, @tInfo)
	
End Sub
'/

Function GetDlgItemDouble( _
		ByVal hwndDlg As HWND, _
		ByVal ControlID As ULONG, _
		ByVal pValue As Double Ptr _
	)As HRESULT
	
	Dim wszValue As WString * 1024 = Any
	GetDlgItemTextW( _
		hwndDlg, _
		ControlID, _
		@wszValue, _
		1023 _
	)
	Dim Value As Double = Any
	Dim hr As HRESULT = VarR8FromStr( _
		@wszValue, _
		0, _
		0, _
		@Value _
	)
	If FAILED(hr) Then
		Return hr
	End If
	
	*pValue = Value
	
	Return S_OK
	
End Function

Function SetDlgItemDouble( _
		ByVal hwndDlg As HWND, _
		ByVal ControlID As ULONG, _
		ByVal Value As Double _
	)As HRESULT
	
	Dim bstrText As BSTR = Any
	
	Dim hr As HRESULT = VarBstrFromR8(Value, 0, 0, @bstrText)
	If FAILED(hr) Then
		Return hr
	End If
	
	SetDlgItemTextW( _
		hwndDlg, _
		ControlID, _
		bstrText _
	)
	
	SysFreeString(bstrText)
	
	Return S_OK
	
End Function

Function InputDataDialogProc( _
		ByVal hwndDlg As HWND, _
		ByVal uMsg As UINT, _
		ByVal wParam As WPARAM, _
		ByVal lParam As LPARAM _
	)As INT_PTR
	
	Select Case uMsg
		
		Case WM_INITDIALOG
			Dim hInst As HINSTANCE = GetModuleHandle(NULL)
			Dim hIcon As HICON = LoadIcon(hInst, CPtr(LPCTSTR, IDI_MAIN))
			SendMessage(hwndDlg, WM_SETICON, ICON_BIG, Cast(LPARAM, hIcon))
			
			SendMessage(GetDlgItem(hwndDlg, IDC_UPD_COORDINATES_X), UDM_SETRANGE32, INT_MIN, Cast(LPARAM, INT_MAX))
			SendMessage(GetDlgItem(hwndDlg, IDC_UPD_COORDINATES_X), UDM_SETPOS32, 0, Cast(LPARAM, 0))
			
			SendMessage(GetDlgItem(hwndDlg, IDC_UPD_COORDINATES_Y), UDM_SETRANGE32, INT_MIN, Cast(LPARAM, INT_MAX))
			SendMessage(GetDlgItem(hwndDlg, IDC_UPD_COORDINATES_Y), UDM_SETPOS32, 0, Cast(LPARAM, 0))
			
			SendMessage(GetDlgItem(hwndDlg, IDC_UPD_COORDINATES_Z), UDM_SETRANGE32, INT_MIN, Cast(LPARAM, INT_MAX))
			SendMessage(GetDlgItem(hwndDlg, IDC_UPD_COORDINATES_Z), UDM_SETPOS32, 0, Cast(LPARAM, 0))
			
			SendMessage(GetDlgItem(hwndDlg, IDC_UPD_PARAMETER_R), UDM_SETRANGE32, INT_MIN, Cast(LPARAM, INT_MAX))
			SendMessage(GetDlgItem(hwndDlg, IDC_UPD_PARAMETER_R), UDM_SETPOS32, 0, Cast(LPARAM, 1))
			
			Dim hListInterest As HWND = GetDlgItem(hwndDlg, IDC_LVW_COORDINATES)
			ListView_SetExtendedListViewStyle(hListInterest, LVS_EX_FULLROWSELECT Or LVS_EX_GRIDLINES)
			
			Scope
				Dim szText(265) As TCHAR = Any
				
				Dim Column As LVCOLUMN = Any
				With Column
					.mask = LVCF_FMT Or LVCF_WIDTH Or LVCF_TEXT Or LVCF_SUBITEM
					.fmt = LVCFMT_RIGHT
					.cx = 50
					.pszText = @szText(0)
					' .cchTextMax = 0
					' iSubItem as long
					' iImage as long
					' iOrder as long
				End With
				
				LoadString(hInst, IDS_NUMBER, @szText(0), 264)
				Column.iSubItem = 0
				ListView_InsertColumn(hListInterest, 0, @Column)
				
				Column.cx = 100
				For i As Integer = 1 To C_COLUMNS - 1
					LoadString(hInst, IDS_COORDINATES_X + i - 1, @szText(0), 264)
					Column.iSubItem = i
					ListView_InsertColumn(hListInterest, i, @Column)
				Next
			End Scope
			
			' SetDlgItemDouble(hwndDlg, IDC_EDT_ROOTX1, 2.0)
			' SetDlgItemDouble(hwndDlg, IDC_EDT_ROOTX2, -0.25)
			
		Case WM_COMMAND
			
			Select Case HIWORD(wParam)
				
				Case 0
					
					Select Case LOWORD(wParam)
						
						Case IDM_FILE_EXIT
							EndDialog(hwndDlg, 0)
							
						Case IDC_BTN_ADD
							Dim buf(1023) As TCHAR = Any
							_i64tot(1, @buf(0), 10)
							
							Dim Item As LVITEM = Any
							With Item
								.mask = LVIF_TEXT ' Or LVIF_STATE Or LVIF_IMAGE
								.iItem  = 0
								.iSubItem = 0
								' .state = 0
								' .stateMask = 0
								.pszText = @buf(0)
								' .cchTextMax = 0
								' .iImage = i
								' lParam as LPARAM
								' iIndent as long
								' iGroupId as long
								' cColumns as UINT
								' puColumns as PUINT
							End With
							
							Dim hListInterest As HWND = GetDlgItem(hwndDlg, IDC_LVW_COORDINATES)
							ListView_InsertItem(hListInterest, @Item)
							
							GetDlgItemText(hwndDlg, IDC_EDT_COORDINATES_X, @buf(0), 1023)
							Item.iSubItem = 1
							Item.pszText = @buf(0)
							ListView_SetItem(hListInterest, @Item)
							
							GetDlgItemText(hwndDlg, IDC_EDT_COORDINATES_Y, @buf(0), 1023)
							Item.iSubItem = 2
							Item.pszText = @buf(0)
							ListView_SetItem(hListInterest, @Item)
							
							GetDlgItemText(hwndDlg, IDC_EDT_COORDINATES_Z, @buf(0), 1023)
							Item.iSubItem = 3
							Item.pszText = @buf(0)
							ListView_SetItem(hListInterest, @Item)
							
							GetDlgItemText(hwndDlg, IDC_EDT_PARAMETER_R, @buf(0), 1023)
							Item.iSubItem = 4
							Item.pszText = @buf(0)
							ListView_SetItem(hListInterest, @Item)
							
					End Select
					
				' Case 1
					' Акселератор
					
				' Case Else
					' Элемент управления
					
			End Select
			
		Case WM_CLOSE
			EndDialog(hwndDlg, 0)
			
		Case Else
			Return False
			
	End Select
	
	Return True
	
End Function
