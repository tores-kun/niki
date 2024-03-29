Option Explicit

Dim excelFilePath
excelFilePath = "C:\выдача ников\Niki.xls"

Dim reservedIdsFilePath
reservedIdsFilePath = "C:\выдача ников\reserved_ids.txt"

Dim excelApp, workbook, sheet, xlWhole
Set excelApp = CreateObject("Excel.Application")
excelApp.Visible = False
excelApp.DisplayAlerts = False

' Определение константы xlWhole
xlWhole = 1

If Not IsFileExists(excelFilePath) Then
    WScript.Echo "Файл не найден."
    WScript.Quit
End If

Set workbook = excelApp.Workbooks.Open(excelFilePath)
Set sheet = workbook.ActiveSheet

Dim reservedID
WScript.Echo "Начинаем резервирование..."
reservedID = ReserveID(reservedIdsFilePath)
WScript.Echo "Резервирование завершено."

If Not IsNull(reservedID) Then
    Dim firmName
    firmName = InputBox("Введите УНП фирмы для Ника " & sheet.Cells(reservedID, 1).Value)

    If Len(firmName) > 0 Then
        WScript.Echo "Записываем значение УНП фирмы..."
        sheet.Cells(reservedID, 2).Value = firmName
        workbook.Save
        WScript.Echo "УНП успешно записано для Ника " & sheet.Cells(reservedID, 1).Value & "."
    Else
        ' Освобождаем ID и удаляем запись из файла
        WScript.Echo "Операция отменена. Освобождаем резервирование..."
        ReleaseID reservedIdsFilePath, reservedID
        WScript.Echo "Освобождено."
    End If
Else
    WScript.Echo "Все Ники имеют заполненные значения УНП."
End If

workbook.Close False
excelApp.Quit

Function ReserveID(reservedIdsFilePath)
    Dim fso, file, reservedIDs, reservedID
    Set fso = CreateObject("Scripting.FileSystemObject")
    
    ' Проверяем, существует ли файл с резервированными идентификаторами
    If Not IsFileExists(reservedIdsFilePath) Then
        ' Если файл не существует, создаем его
        Set file = fso.CreateTextFile(reservedIdsFilePath)
    Else
        ' Если файл существует, читаем зарезервированные идентификаторы
        Set file = fso.OpenTextFile(reservedIdsFilePath, 1)
        Do Until file.AtEndOfStream
            reservedID = file.ReadLine
            If Len(reservedID) > 0 Then
                ' Добавляем идентификатор в массив
                If IsArray(reservedIDs) Then
                    ReDim Preserve reservedIDs(UBound(reservedIDs) + 1)
                    reservedIDs(UBound(reservedIDs)) = reservedID
                Else
                    ReDim reservedIDs(0)
                    reservedIDs(0) = reservedID
                End If
                
            End If
        Loop
        file.Close
    End If

    ' Ищем первый свободный идентификатор
    Dim emptyCell
    For Each emptyCell In sheet.Columns(2).Cells
        If IsEmpty(emptyCell.Value) Then
            ' Если найден свободный идентификатор и он соответствует условиям
            If Not IsInArray(CStr(emptyCell.Row), reservedIDs) And IsValidID(sheet.Cells(emptyCell.Row, 1).Text) Then
                ' Резервируем идентификатор
                Set file = fso.OpenTextFile(reservedIdsFilePath, 8, True)
                file.WriteLine CStr(emptyCell.Row)
                file.Close
                ReserveID = emptyCell.Row
                Exit Function
            End If
        End If
    Next

    ' Если не удалось найти свободный идентификатор
    ReserveID = Null
End Function

Function IsValidID(id)
    IsValidID = Len(id) = 4 And IsAlphaNumeric(id)
End Function

Function ReleaseID(reservedIdsFilePath, idToRelease)
    Dim fso, file, reservedIDs
    Dim preservedIDsArray, j, i
    Set fso = CreateObject("Scripting.FileSystemObject")

    ' Читаем зарезервированные идентификаторы
    Set file = fso.OpenTextFile(reservedIdsFilePath, 1)
    reservedIDs = Split(file.ReadAll, vbCrLf)
    file.Close

    ' Освобождаем идентификатор
    ReDim preservedIDsArray(UBound(reservedIDs) - 1)
    For i = LBound(reservedIDs) To UBound(reservedIDs)
        If CStr(reservedIDs(i)) <> CStr(idToRelease) Then
            preservedIDsArray(j) = reservedIDs(i)
            j = j + 1
        End If
    Next
    Set file = fso.CreateTextFile(reservedIdsFilePath)
    For Each reservedID In preservedIDsArray
        If Len(reservedID) > 0 Then
            file.WriteLine CStr(reservedID)
        End If
    Next
    file.Close
End Function

Function IsFileExists(filePath)
    Dim fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    IsFileExists = fso.FileExists(filePath)
End Function

Function IsInArray(value, arr)
    If IsArray(arr) Then
        Dim found, i
        found = False
        For i = LBound(arr) To UBound(arr)
            If CStr(arr(i)) = CStr(value) Then
                found = True
                Exit For
            End If
        Next
        IsInArray = found
    Else
        IsInArray = False
    End If
End Function

Function IsAlphaNumeric(str)
    Dim regEx
    Set regEx = New RegExp
    regEx.IgnoreCase = True
    regEx.Global = True
    regEx.Pattern = "^[a-zA-Z0-9]+$"
    IsAlphaNumeric = regEx.Test(str)
End Function