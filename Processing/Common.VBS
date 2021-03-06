Function GoesBetween(rightEdge, leftEdge, chnX, chnY)
  Dim midpoint, info
  Set midpoint = New Point
  midpoint.X = (rightEdge.X + leftEdge.X) /2
  midpoint.Y = (rightEdge.Y + leftEdge.Y) /2

  CrossIndex = PNo(chnX, midpoint.X)
  XPosAtCross = CHD(CrossIndex, chnX)
  YPosAtCross = CHD(CrossIndex, chnY)
  If Abs(XPosAtCross - midpoint.X) < 0.5 Then
    If Abs(YPosAtCross - midpoint.Y) < 1 Then
      GoesBetween = CrossIndex
      Exit Function
    End If
  End If
  GoesBetween = -1
End Function

Function GetCurvesDriven(posX, posY)  
  Dim curve, curveData, startL, startR, endL, endR, info, cross, curves
  Set curveData = New TrackInfo
  Set curves = CreateObject("Scripting.Dictionary")
  For Each curve In curveData.TrackChannels
    Set startL = curveData.GetPoint(curve, true, true)
    Set startR = curveData.GetPoint(curve, true, false)
    Set endL = curveData.GetPoint(curve, false, true)
    Set endR = curveData.GetPoint(curve, false, false)

    If GoesBetween(startL, startR, posX, posY) <> -1 Then
      cross = GoesBetween(endL, endR, posX, posY)
      If cross <> -1 Then
        Set info = (New CurveInfo)(curve, cross)
        Call curves.Add(curve, info)
      End If
    End If
  Next
  Set GetCurvesDriven = curves
End Function

Function DetermineWhichLuxFile(Results, TargetTime)
  Dim result, f, dataF, chn, currentMax, max, minimumTime, minIndex, maxName, derivative, timeChn, grp
  currentMax = -1
  For Each result In Results
    f = result.Properties("Folder").Value

    Set dataF = DataFileLoadSel(f & "\" & result.Name, "TDMS", "[1]/[1, " & result.ChannelGroups(1).Channels.Count & "]] " , "Register")
    
    ' Get the lux channel
    Set chn = dataF.Item(1)
    ' Get the current group
    Set grp = chn.ChannelGroup
    ' Get the time channel
    Set timeChn = dataF.Item(2)    
    ' Shorten channels around target time
    Dim shortChn: Set shortChn = ShortenChannelsAtTarget(timeChn, chn, TargetTime, true)
    
    ' Take the derivative
    Set derivative = ChnDifferentiate(shortChn.TimeChn, shortChn.AmplitudeChn,"/DifferentiatedX","/DifferentiatedY")
    ' Get Minimum time
    minIndex = GetChannelMinIndex(derivative.Item(2))
    minimumTime = Chv(minIndex, derivative.Item(1).Name)

    ' If two data files cross near the target time take the one with the highest lux output
    If abs(datediff("s", minimumTime,TargetTime)) < 2 Then
      max = GetChannelMax(shortChn.AmplitudeChn)
      If max > currentMax Then 
        currentMax = max
        maxName = result.Name
      End If
    End If

    Call grp.Channels.Remove(shortChn.TimeChn.Name)    
    Call grp.Channels.Remove(shortChn.AmplitudeChn.Name)    
    Call grp.Channels.Remove(derivative.Item(1).Name)
    Call grp.Channels.Remove(derivative.Item(2).Name)
  Next
  DetermineWhichLuxFile = maxName
End Function

Function ShortenChannelsAtTarget(timeChn, ampChn, targetTime, replaceSourceChannels)
  Dim startTime: startTime = DateAdd("s", -1, targetTime)
  Dim endTime: endTime = DateAdd("s", 1, targetTime)
  Dim timeName: timeName = timeChn.Name
  Dim ampName: ampName = ampChn.Name
  Dim grp: Set grp = timeChn.ChannelGroup
  
  Call ChnTimeAreaCopy(timeChn, ampChn, "targettime", "targetlight", startTime, endTime)
  Dim returnValue: Set returnValue = (New ShortenedChannels)(grp.Channels("targettime"),grp.Channels("targetlight"))
  If replaceSourceChannels = True Then
    Call grp.Channels.Remove(timeChn.Name)
    Call grp.Channels.Remove(ampChn.Name)
    returnValue.TimeChn.Name = timeName
    returnValue.AmplitudeChn.Name = ampName
  End If
  Set ShortenChannelsAtTarget = returnValue
End Function

Class ShortenedChannels
  Dim TimeChn, AmplitudeChn
  Public  Default Function Init(timeChn, amplitudeChn)
    Set Me.TimeChn = timeChn
    Set Me.AmplitudeChn = amplitudeChn
    Set Init = Me
  End Function 
End Class

Function GetChannelMinIndex(channel)
  Dim p, i, index
  p = 0
  For i = 1 to channel.Size
    If channel.Values(i) < p Then 
      p = channel.Values(i) 
      index = i
    End If
  Next
  GetChannelMinIndex = index
End Function


Function GetChannelMax(channel)
  Dim p, i
  p = 0
  For i = 1 to channel.Size
    If channel.Values(i) > p Then p = channel.Values(i) 
  Next
  GetChannelMax = p
End Function

Function GetCurvePrefix(testCurve)
  Select Case TestCurve
  Case "Straight"
    GetCurvePrefix = "STRT"
    Exit Function
  Case Else
    GetCurvePrefix = TestCurve
    Exit Function
  End Select
End Function

Function GetTrackPoint(curve, isStart, isLeft)
  Dim track: Set track = New TrackInfo
  Set GetTrackPoint= track.GetPoint(curve, isStart, isLeft)
  Set track = Nothing
End Function

Class CurveInfo
  Dim CurveID, StartPoint
  Public  Default Function Init(curveID, startPoint)
    Me.CurveID = curveID
    Me.StartPoint = startPoint
    Set Init = Me
  End Function 
End Class

Class Point
  Dim X, Y
  Public  Default Function Init(x, y)
    Me.X = x
    Me.Y = y
    Set Init = Me
  End Function 
End Class 

Class TrackInfo
  Dim TrackChannels
  Private TrackGroup, LeftString, RightString, StartString, EndString
  Dim Points
  
  Private Sub Class_Initialize()
    TrackChannels = Array("150L", "250L", "150R", "250R", "Straight")
    TrackGroup = "track"
    LeftString = "LE"
    RightString = "RE"
    StartString = "ST"
    EndString = "ED"
    Set Points = CreateObject("Scripting.Dictionary")
    Call Fill
  End Sub
  
  Private Sub Fill
    Dim chnName, chn1, chn2, chn3, chn4, st, ed, grp
    Set grp = Data.Root.ChannelGroups(TrackGroup)
    For Each chnName In TrackChannels
      Set chn1 = grp.Channels(chnName & "_LEdge_x")
      Set chn2 = grp.Channels(chnName & "_LEdge_y")
      Set chn3 = grp.Channels(chnName & "_REdge_x")
      Set chn4 = grp.Channels(chnName & "_REdge_y")
      Set st = (New Point)(chn1.Values(1), chn2.Values(1))
      Set ed = (New Point)(chn1.Values(chn1.Size), chn2.Values(chn2.Size))
      Call Points.Add(chnName & LeftString & StartString, st)
      Call Points.Add(chnName & LeftString & EndString, ed)
      Set st = Nothing
      Set ed = Nothing
      Set st = (New Point)(chn3.Values(1), chn4.Values(1))
      Set ed = (New Point)(chn3.Values(chn3.Size), chn4.Values(chn4.Size))
      Call Points.Add(chnName & RightString & StartString, st)
      Call Points.Add(chnName & RightString & EndString, ed)
      Set st = Nothing
      Set ed = Nothing
    Next
  End Sub
  
  Function GetPoint(curve, isStart, isLeft)
    Dim item, s1, s2
    If isLeft = True Then
      s1 = LeftString
    Else
      s1 = RightString
    End If
    
    If isStart = True Then
      s2 = StartString
    Else
      s2 = EndString
    End If
    
    If Points.Exists(curve & s1 & s2) Then
      Set GetPoint = Points.Item(curve & s1 & s2)
      Exit Function
    End If
    Set GetPoint = Nothing
  End Function
End Class