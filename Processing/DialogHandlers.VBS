'-------------------------------------------------------------------------------
'-- VBS script file
'-- Created on 06/23/2018 20:12:53
'-- Author: 
'-- Comment: 
'-------------------------------------------------------------------------------
Option Explicit  'Forces the explicit declaration of all the variables in a script.
Call ScriptInclude(CurrentScriptPath & "DataFinderHelper.VBS", "DataFinderHelper")

Sub HandleSetWorkingDirectory() 
  If PathDlgShow("Select the main working directory for headlight testing", NetworkLoc) = "IDOk" Then
    NetworkLoc = OutPutPath
    Call DataFinderHelper.CreateSearchArea(NetworkLoc)
  End If
End Sub