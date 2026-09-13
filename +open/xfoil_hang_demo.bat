@echo off
REM xfoil_hang_demo.bat - launches xfoil.exe interactively (no stdin
REM redirection) so you can drive it by hand and leave it open on a
REM non-convergent case, for demoing what non-convergence looks like.
REM
REM WHY INTERACTIVE, NOT PIPED: xfoil.m/open.xfoil feed XFoil a whole
REM command script from a FILE via "<" redirection. That's fine as long
REM as the script ends in "quit" -- but if you DON'T send quit (to try
REM to leave XFoil sitting on a failed case), the piped stdin just runs
REM out and this XFoil build crashes immediately:
REM   "Fortran runtime error: End of file"
REM rather than waiting for more input. Confirmed directly while
REM building this. A real keyboard, on the other hand, never sends EOF
REM -- so running interactively (this .bat) and simply not typing "quit"
REM leaves XFoil (and its plot window, if any) genuinely sitting open
REM for as long as you want.
REM
REM See xfoil_hang_demo_commands.txt in this same folder for the exact
REM commands to paste in to reproduce the known-non-convergent case
REM (NACA2412 at AoA=2deg, Re~1.53e6, Mach~0.131 -- confirmed to
REM oscillate rather than converge, independent of iteration count).
REM Stop after typing "alfa 2" and just don't type "quit".

cd /d "%~dp0"
"%~dp0xfoil.exe"
