MODULE Configuration;	(* jt 5.4.95 *)

(* in addition to the standard configuration, this module sets up an intelligent scrolling log viewer
	with a command-level pin point *)

	IMPORT
		Viewers, Oberon, TextFrames, MenuViewers, Display, Texts, FKeys, System, Out, Ofront, Browser, Console (* console temporarily, for debug; -- noch *);

	CONST
		StandardMenu = "System.Close System.Copy System.Grow Edit.Search Edit.Store ";
		LogMenu = "System.Close System.Grow Edit.Locate Edit.Store ";

	VAR
		pinPos: LONGINT;

	PROCEDURE PinLog*;
	BEGIN 
	   Console.String("***DBG*** Configuration.Mod *** PROCEDURE PinLog*;"); Console.Ln;
	   pinPos := Oberon.Log.len;
	   Console.String("***DBG*** Configuration.Mod *** END PinLog;"); Console.Ln;
	END PinLog;

	PROCEDURE HandleLog(F: Display.Frame; VAR M: Display.FrameMsg);
		VAR ch: CHAR; R: Texts.Reader; org: LONGINT;
	BEGIN
	    Console.String("***DBG*** Configuration.Mod *** PROCEDURE HandleLog"); Console.Ln;
		TextFrames.Handle(F, M);
        Console.String("***DBG*** Configuration.Mod *** IF M IS TextFrames.UpdateMsg THEN"); Console.Ln;
		IF M IS TextFrames.UpdateMsg THEN
			WITH M: TextFrames.UpdateMsg DO
				IF (M.text = Oberon.Log) & (M.id = TextFrames.insert) & (M.beg > 0) THEN
				    Console.String("***DBG*** Configuration.Mod *** (M.text = Oberon.Log) & (M.id = TextFrames.insert) & (M.beg > 0)"); Console.Ln;
					Texts.OpenReader(R, Oberon.Log, M.beg-1); Texts.Read(R, ch);
					Console.String("***DBG*** Configuration.Mod ***  IF ch = 0DX THEN"); Console.Ln;
					IF ch = 0DX THEN
						WITH F: TextFrames.Frame DO
						    Console.String("***DBG*** Configuration.Mod *** WITH F: TextFrames.Frame DO"); Console.Ln;
							IF M.beg > TextFrames.Pos(F, F.X + F.W, F.Y) + 1  THEN org := M.beg - 200 ELSE org := F.org END ;
							Console.String("***DBG*** Configuration.Mod *** WHILE (org < pinPos) & (org < M.beg) & (TextFrames.Pos(F, F.X + F.W, F.Y) < M.end-1) DO"); Console.Ln;
							WHILE (org < pinPos) & (org < M.beg) & (TextFrames.Pos(F, F.X + F.W, F.Y) < M.end-1) DO
							    Console.String("***DBG*** Configuration.Mod *** Texts.OpenReader(R, F.text, org); "); Console.Ln;
								Texts.OpenReader(R, F.text, org);
								Console.String("***DBG*** Configuration.Mod *** REPEAT Texts.Read(R, ch) UNTIL R.eot OR (ch = 0DX); "); Console.Ln;
								REPEAT Texts.Read(R, ch) UNTIL R.eot OR (ch = 0DX);
								org := Texts.Pos(R); TextFrames.Show(F, org)
							END
						END
					END
				END
			END
		END;
		Console.String("***DBG*** Configuration.Mod *** END HandleLog;"); Console.Ln
	END HandleLog;

	PROCEDURE Init*;
		VAR logV, toolV: Viewers.Viewer; X, Y: INTEGER; logger: Oberon.Task;
	BEGIN
	   Console.String("***DBG*** Configuration.Mod *** PROCEDURE Init*"); Console.Ln;
		Oberon.OpenDisplay(Display.Width DIV 8 * 5, Display.Width DIV 8 * 3, Display.Height);
		Console.String("***DBG*** Configuration.Mod *** Oberon.FocusViewer := Viewers.This(0, 0);"); Console.Ln;
		Oberon.FocusViewer := Viewers.This(0, 0);
		Console.String("***DBG*** Configuration.Mod *** Oberon.AllocateSystemViewer(0, X, Y);"); Console.Ln;
		Oberon.AllocateSystemViewer(0, X, Y);
		logV := MenuViewers.New(
			TextFrames.NewMenu("System.Log", LogMenu),
			TextFrames.NewText(Oberon.Log, 0),
			TextFrames.menuH,
			X, Y);
		logV.dsc.next.handle := HandleLog;
		Console.String("***DBG*** Configuration.Mod *** Oberon.AllocateSystemViewer(0, X, Y);"); Console.Ln;
		Oberon.AllocateSystemViewer(0, X, Y);
		toolV := MenuViewers.New(
			TextFrames.NewMenu("System.Tool", StandardMenu),
			TextFrames.NewText(TextFrames.Text("System.Tool"), 0),
			TextFrames.menuH,
			X, Y + 50) ;
		NEW(logger); logger.safe := TRUE; logger.time := -1; logger.handle := PinLog;
		Oberon.Install(logger);
		FKeys.Set(12, FKeys.InternationalKey);
		FKeys.Set(10, FKeys.InternationalKey);
		Out.String("Ofront 1.3, Oberon V4"); Out.Ln;
		Oberon.Loop;
		Console.String("***DBG*** Configuration.Mod *** END Init;"); Console.Ln;
	END Init;

BEGIN Init
END Configuration.
