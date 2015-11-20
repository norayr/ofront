MODULE Miscellaneous; (*JG 29.1.90 / NW 22.22.88 / JT 7.5.90*)

  IMPORT SYSTEM, Files, Viewers, Fonts, Texts, MenuViewers, TextFrames, Oberon, Display, X11;
  
  CONST  TAB =  9X; CR = 0DX; LF = 0AX; BitmapId = 39X;

  TYPE
    FileDesc = RECORD (*image of diskette dir entry*)
      name: ARRAY 22 OF CHAR;
      time, date: INTEGER;
      head: INTEGER;
      size: LONGINT
    END;

    File = POINTER TO FileHandle; (*diskette file*)

    FileHandle = RECORD
      prev, next: File;
      file: FileDesc
    END;
  
  VAR S: Texts.Scanner; T: Texts.Text; W: Texts.Writer;
    dir: File; trailer: FileDesc; i: INTEGER;
  (* cut and paste: *)
    scrap: Texts.Text; B: Texts.Buffer;
    selectionData: POINTER TO ARRAY OF CHAR;
    ownSelection: BOOLEAN;
    myProperty: X11.Atom;

  PROCEDURE CountLines*;
    VAR par: Oberon.ParList;
      R: Texts.Reader;
      S: Texts.Scanner;
      T, source: Texts.Text;
      V: Viewers.Viewer;
      nofLines, totalLines, i: LONGINT;
      X, Y: INTEGER;
      ch: CHAR;
  BEGIN
    Oberon.AllocateSystemViewer(Oberon.Par.frame.X, X, Y);
    T := TextFrames.Text("");
    V := MenuViewers.New(
      TextFrames.NewMenu("Miscellaneous.CountLines", "System.Close System.Copy System.Grow Edit.Search Edit.Store"),
      TextFrames.NewText(T, 0),
      TextFrames.menuH,
      X, Y);
    totalLines := 0;
    par := Oberon.Par;
    Texts.OpenScanner(S, par.text, par.pos); Texts.Scan(S);
    WHILE S.class = Texts.Name DO
      Texts.WriteString(W, S.s);
      Texts.Append(T, W.buf);
      NEW(source); Texts.Open(source, S.s);
      Texts.WriteString(W," counting");
      Texts.Append(T, W.buf);
      Texts.OpenReader(R, source, 0);
      nofLines := 0; i := 0;
      WHILE i < source.len DO
        Texts.Read(R, ch); INC(i);
        IF ch = CR THEN
          LOOP
            Texts.Read(R, ch); INC(i);
            IF ch # CR THEN EXIT END
          END;
          INC(nofLines)
        END
      END;
      Texts.Write(W, " "); Texts.WriteInt(W, nofLines, 1);
      Texts.WriteLn(W);
      Texts.Append(T, W.buf);
      totalLines := totalLines + nofLines;
      Texts.Scan(S)
    END;
    Texts.WriteInt(W, totalLines, 1);
    Texts.WriteLn(W);
    Texts.Append(T, W.buf)
  END CountLines;

  PROCEDURE Cleanup*;
    VAR par: Oberon.ParList;
      R: Texts.Reader;
      S: Texts.Scanner;
      source: Texts.Text;
      g: Files.File;
      Wg: Files.Rider;
      ch: CHAR;
  BEGIN
    par := Oberon.Par;
    Texts.WriteString(W, "Miscellaneous.Cleanup"); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf);
    Texts.OpenScanner(S, par.text, par.pos); Texts.Scan(S);
    WHILE S.class = Texts.Name DO
      Texts.WriteString(W, S.s);
      Texts.Append(Oberon.Log, W.buf);
      NEW(source); Texts.Open(source, S.s);
      Texts.WriteString(W," cleaning up");
      Texts.Append(Oberon.Log, W.buf);
      g := Files.New(S.s); Files.Set(Wg, g, 0);
      Texts.OpenReader(R, source, 0); Texts.Read(R, ch);
      WHILE ch # 0X DO
        IF (ch >= " ") & (ch < 7FX) OR (ch = TAB) OR (ch = CR) THEN
          IF ch = CR THEN Files.Write(Wg, LF) ELSE Files.Write(Wg, ch) END
        END;
        Texts.Read(R, ch)
      END;
      Files.Register(g);
      Texts.WriteLn(W);
      Texts.Append(Oberon.Log, W.buf);
      Texts.Scan(S)
    END
  END Cleanup;

  PROCEDURE ConvertBlanks*;
    VAR par: Oberon.ParList;
      R: Texts.Reader;
      S: Texts.Scanner;
      source: Texts.Text;
      g: Files.File;
      Wg: Files.Rider;
      ch: CHAR;
  BEGIN
    par := Oberon.Par;
    Texts.WriteString(W, "Miscellaneous.ConvertBlanks"); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf);
    Texts.OpenScanner(S, par.text, par.pos); Texts.Scan(S);
    WHILE S.class = Texts.Name DO
      Texts.WriteString(W, S.s);
      Texts.Append(Oberon.Log, W.buf);
      NEW(source); Texts.Open(source, S.s);
      IF source.len # 0 THEN
        Texts.WriteString(W," converting");
        Texts.Append(Oberon.Log, W.buf);
        g := Files.New(S.s);
        Texts.OpenReader(R, source, 0); Files.Set(Wg, g, 0);
        LOOP
          LOOP
            Texts.Read(R, ch);
            IF ch # " " THEN EXIT END;
            Texts.Read(R, ch);
            IF ch # " " THEN Files.Write(Wg, " "); EXIT END;
            Files.Write(Wg, TAB)
          END;
          WHILE (ch # 0X) & (ch # CR) DO
            Files.Write(Wg, ch); Texts.Read(R, ch)
          END;
          IF ch = 0X THEN EXIT END;
          Files.Write(Wg, LF)
        END;
        Files.Register(g)
      ELSE Texts.WriteString(W, " not found")
      END;
      Texts.WriteLn(W);
      Texts.Append(Oberon.Log, W.buf);
      Texts.Scan(S)
    END
  END ConvertBlanks;

  PROCEDURE ConvertTabs*;
    VAR par: Oberon.ParList;
      R: Texts.Reader;
      S: Texts.Scanner;
      source: Texts.Text;
      g: Files.File;
      Wg: Files.Rider;
      ch: CHAR;
  BEGIN
    par := Oberon.Par;
    Texts.WriteString(W, "Miscellaneous.ConvertTabs"); Texts.WriteLn(W);
    Texts.Append(Oberon.Log, W.buf);
    Texts.OpenScanner(S, par.text, par.pos); Texts.Scan(S);
    WHILE S.class = Texts.Name DO
      Texts.WriteString(W, S.s);
      Texts.Append(Oberon.Log, W.buf);
      NEW(source); Texts.Open(source, S.s);
      IF source.len # 0 THEN
        Texts.WriteString(W," reconverting");
        Texts.Append(Oberon.Log, W.buf);
        g := Files.New(S.s);
        Texts.OpenReader(R, source, 0); Files.Set(Wg, g, 0);
        LOOP
          LOOP
            Texts.Read(R, ch);
            IF ch # TAB THEN EXIT END;
            Files.Write(Wg, " "); Files.Write(Wg, " ")
          END;
          WHILE (ch # 0X) & (ch # CR) DO
            Files.Write(Wg, ch); Texts.Read(R, ch)
          END;
          IF ch = 0X THEN EXIT END;
          Files.Write(Wg, LF)
        END;
        Files.Register(g)
      ELSE Texts.WriteString(W, " not found")
      END;
      Texts.WriteLn(W);
      Texts.Append(Oberon.Log, W.buf);
      Texts.Scan(S)
    END
  END ConvertTabs;

  PROCEDURE ClearSelection;
  BEGIN ownSelection := FALSE
  END ClearSelection;

  PROCEDURE CopyOverSelection;
    VAR M: Oberon.CopyOverMsg;
  BEGIN
    IF scrap.len > 0 THEN
      M.text := scrap; M.beg := 0; M.end := scrap.len;
      Oberon.FocusViewer.handle(Oberon.FocusViewer, M)
    END
  END CopyOverSelection;

  PROCEDURE TakeSelection;
  BEGIN
    ownSelection := TRUE;
    X11.SetSelectionOwner(X11.display, X11.XAPRIMARY, X11.primary, X11.lastEventTime);
    IF X11.GetSelectionOwner(X11.display, X11.XAPRIMARY) # X11.primary THEN ClearSelection END
  END TakeSelection;

  PROCEDURE RequestSelection;
  BEGIN
    X11.ConvertSelection(X11.display, X11.XAPRIMARY, X11.XASTRING, myProperty, X11.primary, X11.lastEventTime)
  END RequestSelection;

  PROCEDURE SendSelection(VAR event: X11.SelectionRequestEvent);
    VAR ev: X11.SelectionEvent; R: Texts.Reader; i: INTEGER; ch: CHAR;
  BEGIN
    ev.type := X11.SelectionNotify;
    ev.requestor := event.requestor;
    ev.selection := event.selection;
    ev.target := event.target;
    ev.time := event.time;
    IF (event.selection = X11.XAPRIMARY) & (event.target = X11.XASTRING) THEN
      ev.property := event.property;
      NEW(selectionData, scrap.len + 1);
      Texts.OpenReader(R, scrap, 0); Texts.Read(R, ch); i := 0;
      WHILE ~R.eot DO
        IF ch = CR THEN ch := LF END ;
        selectionData[i] := ch; INC(i);
        Texts.Read(R, ch)
      END ;
      selectionData[i] := 0X;
      X11.ChangeProperty(X11.display, ev.requestor, ev.property, ev.target, 8, X11.PropModeReplace, SYSTEM.ADR(selectionData[0]), i);
    ELSE
      ev.property := X11.None
    END ;
    X11.SendEvent(X11.display, ev.requestor, X11.False, 0, SYSTEM.ADR(ev))
  END SendSelection;

  PROCEDURE ReceiveSelection(VAR event: X11.SelectionEvent);
    VAR type: X11.Atom; format: INTEGER; len, after, prop, adr: LONGINT; ch: CHAR;
  BEGIN
    Texts.Delete(scrap, 0, scrap.len);
    IF (event.selection = X11.XAPRIMARY) & (event.property = myProperty) THEN
      X11.GetWindowProperty(X11.display, event.requestor, event.property, 0, 8192, X11.False, event.target, type, format, len, after, prop);
      adr := prop;
      IF len > 0 THEN
        WHILE len > 0 DO
          SYSTEM.GET(adr, ch); INC(adr); DEC(len);
          IF ch = LF THEN ch := CR END ;
          IF ch # 0X THEN Texts.Write(W, ch) END
        END ;
        Texts.Append(scrap, W.buf);
        X11.Free(prop); X11.DeleteProperty(X11.display, event.requestor, event.property)
      END ;
      CopyOverSelection
    END
  END ReceiveSelection;

  PROCEDURE Cut*;
    VAR t: Texts.Text; beg, end, time: LONGINT;
  BEGIN
    Texts.Delete(scrap, 0, scrap.len); Oberon.GetSelection(t, beg, end, time);
    IF time >= 0 THEN Texts.Save(t, beg, end, B); Texts.Delete(t, beg, end); Texts.Append(scrap, B) END ;
    TakeSelection
  END Cut;

  PROCEDURE Copy*;
    VAR t: Texts.Text; beg, end, time: LONGINT;
  BEGIN
    Texts.Delete(scrap, 0, scrap.len); Oberon.GetSelection(t, beg, end, time);
    IF time >= 0 THEN Texts.Save(t, beg, end, B); Texts.Append(scrap, B) END ;
    TakeSelection
  END Copy;

  PROCEDURE Paste*;
  BEGIN
    IF ownSelection THEN CopyOverSelection ELSE RequestSelection END
  END Paste;

BEGIN
  Texts.OpenWriter(W); NEW(B); Texts.OpenBuf(B);
  NEW(scrap); scrap.notify := TextFrames.NotifyDisplay; Texts.Open(scrap, "");
  X11.SendSelection := SendSelection;
  X11.ReceiveSelection := ReceiveSelection;
  X11.ClearSelection := ClearSelection;
  ClearSelection;
  myProperty := X11.InternAtom(X11.display, SYSTEM.ADR("OberonProperty"), X11.False)
END Miscellaneous.

