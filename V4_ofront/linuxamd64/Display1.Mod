MODULE Display1;  (* RC 11.12.92*)

  IMPORT Display, X11, Console, Unix, Kernel, S := SYSTEM, ulmTypes;

  CONST
    white = 0; grey1 = 1; grey2 = 2; grey3 = 3; grey4 = 4; black = 5;
    texture0 = 6; texture1 = 7; texture2 = 8; texture3 = 9;

  VAR
    GcC: X11.GC;
    Window: X11.Window;
    lastcolC, lastmodeC, lastx, lasty, lastw, lasth: INTEGER;
    width0: BOOLEAN;
    scrPat: ARRAY 10 OF LONGINT;

  PROCEDURE GetPatternSize*(pat: X11.Pattern; VAR w, h: INTEGER);
  (* Returns the pattern size. *)
    VAR p: X11.PatternPtr;
  BEGIN p := S.VAL(X11.PatternPtr, pat); w := p.w; h := p.h
  END GetPatternSize;

  PROCEDURE ThisPattern*(n: INTEGER): X11.Pattern;
  (* Returns the n-th predefined pattern (corresponding to the printer patterns). If the pattern is not available,
    0 is returned. n must be >= 0. Currently 10 patterns are predefined (0 .. 9). *)
  BEGIN
    IF n >= LEN(scrPat) THEN RETURN 0
    ELSE RETURN scrPat[n]
    END
  END ThisPattern;

  PROCEDURE Secondary(F: Display.Frame; col, mode: INTEGER): BOOLEAN;
    VAR cliprect: X11.Rectangle;
	tmpint: LONGINT;
  BEGIN
    IF X11.lclen > 0 THEN X11.FlushLCache END ;
    Kernel.Lock();
    IF (F.X # lastx) OR (F.Y # lasty) OR (F.W # lastw) OR (F.H # lasth) THEN
      lastx := F.X; lasty := F.Y; lastw := F.W; lasth := F.H;
      (*cliprect.x := lastx;*)
	  ulmTypes.ToInt16(lastx, cliprect.x);
	  (*cliprect.y := X11.Height-lasty-lasth; *)
	  ulmTypes.ToInt16(X11.Height-lasty-lasth, cliprect.y);
	  (*cliprect.w := lastw;*)
	  ulmTypes.ToInt16(lastw, cliprect.w);
	  (*cliprect.h := lasth;*)
	  ulmTypes.ToInt16(lasth, cliprect.h);
      IF lasty >= 0 THEN 
	     Window := X11.primary 
	  ELSE Window := X11.secondary; 
	  (*INC(cliprect.y, X11.UBottom) *)
	  ulmTypes.Int16ToInt64(cliprect.y, tmpint);
	  INC(tmpint,  LONG(X11.UBottom));
	  ulmTypes.ToInt16(tmpint, cliprect.y);
	  END ;
      IF (S.VAL(INTEGER, cliprect.x) <= 0) & (S.VAL(INTEGER, cliprect.y) <= 0) & (S.VAL(INTEGER, cliprect.w) >= X11.Width) & (S.VAL(INTEGER, cliprect.h) >= X11.Height) THEN (* no clipping *)
        X11.SetClipMask(X11.display, GcC, X11.None)
      ELSE
        X11.SetClipRectangles(X11.display, GcC, 0, 0, S.ADR(cliprect), 1, X11.YXBanded)
      END
    END ;
    IF mode = X11.paint THEN mode := X11.replace END ;
    IF mode # lastmodeC THEN X11.SetFunction(X11.display, GcC, X11.function[mode]); lastmodeC := mode END ;
    IF col # lastcolC THEN X11.SetForeground(X11.display, GcC, X11.pixelValues[col]); lastcolC := col END ;
    Kernel.Unlock();
    RETURN Window = X11.secondary
  END Secondary;

  PROCEDURE Line*(F: Display.Frame; col, X0, Y0, X1, Y1, mode: INTEGER);
  (* Draws a line from (X0, Y0) to (X1, Y1) inclusive, clipped against F.  For all line points (x, y) the following holds
    always: (min(X0, X1) <= x) & (x <= max(X0, X1) & (min(Y0, Y0) <= y) & (y <= max(Y0, Y1). *)
  BEGIN
    IF Secondary(F, col, mode) THEN DEC(Y0, X11.UBottom); DEC(Y1, X11.UBottom) END ;
    Kernel.Lock();
    IF ~width0 THEN width0 := TRUE; X11.SetLineAttributes(X11.display, GcC, 0, X11.LineSolid, X11.CapButt, X11.JoinMiter) END ;
    X11.DrawLine(X11.display, Window, GcC, X0, X11.Height-Y0-1, X1, X11.Height-Y1-1);
    Kernel.Unlock()
  END Line;

  PROCEDURE Circle*(F: Display.Frame; col, X, Y, R, mode: INTEGER);
  (* Draws a circle with center (X, Y) and radius R, clipped against F. For all circle points (x, y)  the following holds always:
    (X-R <= x) & (x < X+R) & (Y-R <= y) & (y < Y+R). *)
  BEGIN
    IF R > 0 THEN (* else problem in X *)
      IF Secondary(F, col, mode) THEN DEC(Y, X11.UBottom) END ;
      Kernel.Lock();
      IF width0 THEN width0 := FALSE; X11.SetLineAttributes(X11.display, GcC, 1, X11.LineSolid, X11.CapButt, X11.JoinMiter) END ;
      X11.DrawArc(X11.display, Window, GcC, X-R, X11.Height-Y-R, 2*R-1, 2*R-1, 0, 360*64);
      Kernel.Unlock()
    END
  END Circle;

  PROCEDURE Ellipse*(F: Display.Frame; col, X, Y, A, B, mode: INTEGER);
  (* Draws an ellipse with center (X, Y) and radii A and B, clipped against F. For all ellipse points (x, y)  the following holds
    always: (X-A <= x) & (x < X+A) & (Y-B <= y) & (y < Y+B). When A = B the resulting ellipse has the same shape
    as the corresponding circle with R = A. *)
  BEGIN
    IF (A > 0) & (B > 0) THEN (* else problem in X *)
      IF Secondary(F, col, mode) THEN DEC(Y, X11.UBottom) END ;
      Kernel.Lock();
      IF width0 THEN width0 := FALSE; X11.SetLineAttributes(X11.display, GcC, 1, X11.LineSolid, X11.CapButt, X11.JoinMiter) END ;
      X11.DrawArc(X11.display, Window, GcC, X-A, X11.Height-Y-B, 2*A-1, 2*B-1, 0, 360*64);
      Kernel.Unlock()
    END
  END Ellipse;

  PROCEDURE CreateGC;
  BEGIN
    Kernel.Lock();
    GcC := X11.CreateGC(X11.display, X11.primary, 0, 0);
    IF GcC = 0 THEN Console.String("Cannot create X graphic context"); Console.Ln; Unix.Exit(1) END ;
    X11.SetPlaneMask(X11.display, GcC, X11.planesMask);
    X11.SetGraphicsExposures(X11.display, GcC, X11.True);
    X11.SetBackground(X11.display, GcC, X11.background);
    X11.SetLineAttributes(X11.display, GcC, 0, X11.LineSolid, X11.CapButt, X11.JoinMiter);
    X11.SetArcMode(X11.display, GcC, X11.ArcPieSlice);
    lastcolC := -1; lastmodeC := -1; width0 := TRUE;
    lastx := -1; lasty := -1; lastw := -1; lasth := -1;
    Window := X11.secondary;
    Kernel.Unlock()
  END CreateGC;

  PROCEDURE Init;
    VAR image: ARRAY 17 OF SET;

    PROCEDURE Repl(step: INTEGER);
      VAR i: INTEGER;
    BEGIN i := step;
      WHILE i < 16 DO image[i+1] := image[i-step+1]; INC(i) END
    END Repl;

  BEGIN
  
    (*-- initialize screen patterns ---*)
    image[1] := {};
    Repl(1);
    scrPat[white] := Display.NewPattern(image, 16, 16);
    
    image[4] := {0, 8};
    image[3] := {};
    image[2] := {4, 12};
    image[1] := {};
    Repl(4);
    scrPat[grey1] := Display.NewPattern(image, 16, 16);
    
    image[2] := {0, 4, 8, 12};
    image[1] := {2, 6, 10, 14};
    Repl(2);
    scrPat[grey2] :=  Display.NewPattern(image, 16, 16);
    
    image[1] := {0, 2, 4, 6, 8, 10, 12, 14};
    image[0] := {1, 3, 5, 7, 9, 11, 13, 15};
    Repl(2);
    scrPat[grey3] :=  Display.NewPattern(image, 16, 16);
  
    image[2] := {1..3, 5..7, 9..11, 13..15};
    image[1] := {0, 1, 3..5, 7..9, 11..13, 15};
    Repl(2);
    scrPat[grey4] :=  Display.NewPattern(image, 16, 16);
    
    image[1] := {0..15};
    Repl(1);
    scrPat[black] := Display.NewPattern(image, 16, 16);
    
    image[4] :={3, 7, 11, 15};
    image[3] :={2, 6, 10, 14};
    image[2] :={1, 5, 9, 13};
    image[1] :={0, 4, 8, 12};
    Repl(4);
    scrPat[texture0] := Display.NewPattern(image, 16, 16);
    
    image[4] :={0, 4, 8, 12};
    image[3] :={1, 5, 9, 13};
    image[2] :={2, 6, 10, 14};
    image[1] :={3, 7, 11, 15};
    Repl(4);
    scrPat[texture1] := Display.NewPattern(image, 16, 16);
    
    image[1] := {2, 6, 10, 14};
    Repl(1);
    scrPat[texture2] := Display.NewPattern(image, 16, 16);
    
    image[4] := {};
    image[3] := {};
    image[2] := {};
    image[1] := {0..15};
    Repl(4);
    scrPat[texture3] := Display.NewPattern(image, 16, 16);

  END Init;
  

BEGIN
  CreateGC;
  Init
END Display1.
