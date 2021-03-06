'-------------------------------------------------------------------------------
'-- VBS script file
'-- Created on 04/18/2018 21:34:08
'-- Author: 
'-- Comment: 
'-------------------------------------------------------------------------------
Option Explicit  'Forces the explicit declaration of all the variables in a script.
'Call fixrtdata(data.Root.ChannelGroups(1))
Sub FixRTData(Group)
  Dim velocityThreshold: velocityThreshold = 20 'km/h
  Dim timeChnName: timeChnName = "Time (GPS)"
  Dim newTimeName: newTimeName = "NewTime"
  Dim timeChn: Set timeChn = Group.Channels(timeChnName)
  Dim velocityChn: Set velocityChn = Group.Channels("Speed2D (km\h)")
  
  'Trim all channels based on vel threshold
  Dim StartIndex: StartIndex = GetCross(velocityChn, velocityThreshold, false)
  If StartIndex > 1 Then Call DataBlDel(Group.Channels, 1, StartIndex)
  Dim EndIndex: EndIndex = GetCross(velocityChn, velocityThreshold, true)
  If velocityChn.Size - EndIndex > 0 Then Call DataBlDel(Group.Channels, EndIndex, velocityChn.Size - EndIndex + 1)
  
  'Gen new time Chn
  Dim i, newchn
  If timeChn.DataType = DataTypeChnString Then
    set newchn = group.Channels.Add("NewTimeDate",DataTypeChnDate)
    For i = 1 to timeChn.Size 
      newChn.Values(i) = timechn.Values(i)
    Next
    call group.Channels.Remove(timeChn.Name)
    Set timeChn = newChn
    timeChn.Name = timeChnName
  End If
  Dim startTime: startTime = GetStartTimeForFile(timeChn)
  Dim stepMs: stepMs = 1 / GetSampleRate(Group) * 1000
  stepMs = round(stepMs,6)
  Call ChnGenTime(Group.Name & "/" & newTimeName,"millisecond",ttr(startTime, "#hh:nn:ss.ffff#"),"",stepMs,"StartStepNo",timeChn.Size)
  Call Group.Channels.Remove(timeChn.Name)
  Group.Channels(newTimeName).Name = timeChnName
  
  
'  Fix TimeFromStart
  Dim fromStart : Set fromStart = group.Channels("TimeFromStart (s)")
  For i = 1 To fromStart.Size
    fromStart.Values(i) = (i - 1) * (stepMs / 1000) 
  Next
  
  'Fix Distance
  Dim distance : Set distance = group.Channels("Distance (m)")
  Dim firstVal: firstVal = distance.Values(1)
  For i = 1 To distance.Size
    distance.Values(i) = distance.Values(i) - firstVal
  Next
  
  Dim valBefore, valAfter
  For i = 1 To distance.Size
    If i = distance.Size Then Exit For
    If distance.Values(i) >= distance.Values(i + 1) Then 
      valBefore = distance.Values(i)
      valAfter = distance.Values(i + 2)
      
      distance.Values(i + 1) = (valBefore + valAfter)/2
      'Msgbox("I fixed a value")
    End If
  Next
  
End Sub

Function GetStartTimeForFile(Chn)
  Dim i, fraction
  Dim timeStep: timeStep = 1 / GetSampleRate(Chn.ChannelGroup)
  Dim firstTime: firstTime = rtt(Chn.Values(1), "hh:nn:ss")
  For i = 1 To Chn.Size
    If firstTime <> rtt(Chn.Values(i), "hh:nn:ss") Then
      fraction = round(1 - timeStep * (i - 1),4)
      fraction = split(fraction, ".")(1)
      GetStartTimeForFile = firstTime & "." & fraction
      Exit Function
    End If
  Next
End Function

Function GetSampleRate(Grp)
  Dim Chn: Set Chn = Grp.Channels("TimeFromStart (s)")
  GetSampleRate = 1 / (Chn.Values(2) - Chn.Values(1))  
End Function


Function GetCross(Chn, Threshold, SearchBack)
  Dim i
  If Not SearchBack Then
    For i = 1 To Chn.Size
      If Chn.Values(i) >= Threshold Then
        GetCross = i
        Exit Function
      End If
    Next 
  Else
    For i = 0 To Chn.Size
      If Chn.Values(Chn.Size - i) >= Threshold Then
        GetCross = Chn.Size - i
        Exit Function
      End If
    Next 
  End If
  
End Function