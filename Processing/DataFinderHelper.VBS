'-------------------------------------------------------------------------------
'-- VBS script file
'-- Created on 06/23/2018 20:28:00
'-- Author: 
'-- Comment: 
'-------------------------------------------------------------------------------
Option Explicit  'Forces the explicit declaration of all the variables in a script.

Sub DeleteSearchArea
  Dim dataFinder : Set dataFinder = Navigator.ConnectDataFinder("My DataFinder")
  Dim searchAreas : Set searchAreas = dataFinder.GetSettings.SearchAreas
  If searchAreas.Exists("HeadlightTestSearch") Then
    Call dataFinder.GetSettings.SearchAreas.Remove("HeadlightTestSearch")
    'Pause(10) 'It can take some time to remove a search area. This might need to be adjusted if not long enough.
     call msgboxdisp("Removing the existing search area can take some time.","MB_NOBUTTON",,,,TRUE)
    pause(10)
    call msgboxcancel()
  End If 
End Sub

Sub CreateSearchArea(SearchPath)
  Dim dataFinder : Set dataFinder = Navigator.ConnectDataFinder("My DataFinder")
  Dim searchAreas : Set searchAreas = dataFinder.GetSettings.SearchAreas
  Dim searchArea
  If Not searchAreas.ExistsByPath(SearchPath) Then
    Call DeleteSearchArea
    On Error Resume Next
    Set searchArea = dataFinder.GetSettings.SearchAreas.Add("HeadlightTestSearch", SearchPath)
    If Err.number <> 0 Then
      msgbox("Unable to add the new search area please try again.")
      On Error Goto 0
      Call Err.Clear
      Exit Sub
    End If
    Dim fso : Set fso = CreateObject("Scripting.FileSystemObject")
    If fso.FolderExists(SearchPath & "Archived") Then
      Call searchArea.ExcludeFolders.Add(SearchPath & "Archived")
    End If 
    Call dataFinder.Indexer.UpdateSearchArea(searchArea.LocalPath)
  End If  
End Sub
