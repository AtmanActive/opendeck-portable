#Requires AutoHotkey v2.0

#SingleInstance Force

#NoTrayIcon

; opendeck-portable
; version 1.0.5
; by AtmanActive 2024, 2025, 2026
; https://github.com/AtmanActive/opendeck-portable

A_FileEncoding := "UTF-8-RAW"

A_AllowMainWindow := 0

; https://www.autohotkey.com/docs/v2/

; GET APP'S RUNTIME PATH
my_exe_path := A_ScriptDir

my_portable_data_path := my_exe_path
my_portable_exe_path  := my_exe_path
my_portable_exe_wdir  := my_exe_path
my_portable_ini_path  := my_exe_path

if ( A_IsCompiled )
{
	my_portable_data_path := my_exe_path "\Data"
	my_portable_exe_path  := my_exe_path "\App\opendeck.exe"
	my_portable_exe_wdir  := my_exe_path "\App"
	my_portable_ini_path  := my_exe_path "\opendeck-portable.ini"
}
else
{
	my_portable_data_path := SubStr( my_exe_path, 1, InStr( my_exe_path, "\", , -1 ) - 1 ) "\Data"
	my_portable_exe_path  := SubStr( my_exe_path, 1, InStr( my_exe_path, "\", , -1 ) - 1 ) "\App\opendeck.exe"
	my_portable_exe_wdir  := SubStr( my_exe_path, 1, InStr( my_exe_path, "\", , -1 ) - 1 ) "\App"
	my_portable_ini_path  := SubStr( my_exe_path, 1, InStr( my_exe_path, "\", , -1 ) - 1 ) "\opendeck-portable.ini"
}

win_user_appdata_roaming_path := A_AppData "\opendeck"
win_user_appdata_roaming_double := ConvertToDoubleBackslash( win_user_appdata_roaming_path )
win_user_appdata_roam_placeholder := "<win_user_appdata_roam_placeholder>"

LocalAppData := EnvGet( "LocalAppData" )
win_user_appdata_local_path := LocalAppData "\opendeck"



ini_do_use_stealth  := IniRead( my_portable_ini_path, "Settings", "Stealth", 0 )
ini_do_use_pathwrap := IniRead( my_portable_ini_path, "Settings", "Pathwrap", 1 )


; GLOBAL STATE FLAGS
; tracks whether OpenDeck has been launched by us (used by the OnExit handler to know if post-flight sync is needed)
g_opendeck_was_launched := 0
; tracks whether post-flight sync has already been performed (used to prevent double-execution)
g_postflight_sync_done := 0


; FileAppend "`n", "**", "`n"
; FileAppend my_portable_data_path "`n", "**", "`n"
; FileAppend win_user_appdata_roaming_path "`n", "**", "`n"
; FileAppend win_user_appdata_roaming_double "`n", "**", "`n"




SyncFolders( sourceDir, targetDir, pre_or_post_flight, overwrite := true )
{

	; if the source directory doesn't exist, there is nothing to sync
	; this happens on a fresh install where neither portable Data nor AppData folders exist yet
	if ( ! DirExist( sourceDir ) )
	{
		return
	}

	; Ensure paths end with backslash
	;sourceDir := RTrim( sourceDir, "\" ) "\"
	;targetDir := RTrim( targetDir, "\" ) "\"
	loop_source_dir := RTrim( sourceDir, "\" ) "\"
	
	;FileAppend sourceDir "`n", "**", "`n"
	;FileAppend targetDir "`n", "**", "`n"
	
	; Create target directory if it doesn't exist
  if ( ! DirExist( targetDir ) )
	{
		DirCreate( targetDir ) ; This function will also create all parent directories given in DirName if they do not already exist.
	}
  
	; Sync files
  Loop Files, loop_source_dir "*.*", "FR"  ; FR = Files and Recursive
  {
		
		this_loop_entry := A_LoopFileFullPath
		
		; Remove sourceDir from the start of the path to get the relative path in target directory
		this_loop_item := SubStr( this_loop_entry, ( StrLen( loop_source_dir ) ) )
		
		this_loop_dir := SubStr( this_loop_item, 1, InStr( this_loop_item, "\", , -1 ) )
		
		this_loop_target_dir := targetDir this_loop_dir
		this_loop_target_file := targetDir this_loop_item
		
		; FileAppend "`n", "**", "`n"
		; FileAppend this_loop_entry "`n", "**", "`n"
		; FileAppend this_loop_item "`n", "**", "`n"
		; FileAppend this_loop_dir "`n", "**", "`n"
		; FileAppend this_loop_target_dir "`n", "**", "`n"
    ; FileAppend this_loop_target_file "`n", "**", "`n"
		
		; Create directory if needed
		if ( ! DirExist( this_loop_target_dir ) )
		{
			DirCreate( this_loop_target_dir ) ; This function will also create all parent directories given in DirName if they do not already exist.
		}
		
		if ( ! FileExist( this_loop_target_file ) )
		{
			; File doesn't exist in target, copy it
			do_process_file( this_loop_entry, this_loop_target_file, pre_or_post_flight, this_loop_item )
		} 
		else 
		{
			; Compare timestamps
			src_file_time := FileGetTime( this_loop_entry )
			dst_file_time := FileGetTime( this_loop_target_file )
			
			; WE CAN NOT USE FILESIZE COMPARISON DUE TO PATH REWRITING WHICH WILL ALWAYS MAKE THE FILES DIFFER IN SIZE
			;src_file_size := FileGetSize( this_loop_entry )
			;dst_file_size := FileGetSize( this_loop_target_file )
			
			if ( src_file_time != dst_file_time ) 
			{
				if ( overwrite )
				{
					do_process_file( this_loop_entry, this_loop_target_file, pre_or_post_flight, this_loop_item )
				}
			}
		}
		
		;Break
		;Continue
		
  } ; END Loop Files
	 
} ; END SyncFolders()






do_process_file( src_file_path, dst_file_path, pre_or_post_flight, src_file_name )
{
	
	try  ; Attempts to execute code.
	{
		src_file_time := FileGetTime( src_file_path )
	}
	catch as e  ; Handles the first error thrown by the block above.
	{
		MsgBox "An error was thrown while trying FileGetTime on " src_file_path "`n`nSpecifically: " e.Message
	}
	
	split_filename_array := StrSplit( src_file_name, "." )
	
	src_file_extension := split_filename_array[ split_filename_array.Length ]
	
	; FileAppend "`n", "**", "`n"
	; FileAppend "src_file_path: " src_file_path "`n", "**", "`n"
	; FileAppend "src_file_extension: " src_file_extension "`n", "**", "`n"
	
	
	if ( pre_or_post_flight = 0 )
	{
		
		; TESTING CASE - NO FILE MANGLING
		
		do_copy_file( src_file_path, dst_file_path )
		
	}
	else if ( pre_or_post_flight = 1 )
  {
		
    ; PRE-FLIGHT: REPLACE PATH PLACEHOLDERS WITH FULL DESTINATION PATH
		
		if ( ( src_file_extension = "json" ) )
		{
      do_portable_unwrap_a_file( src_file_path, dst_file_path )
    }
		else
		{
			do_copy_file( src_file_path, dst_file_path )
		}
		
  }
	else if ( pre_or_post_flight = 2 )
	{
		
		; POST-FLIGHT: REPLACE FULL PATHS WITH PLACEHOLDERS
		
		if ( ( src_file_extension = "json" ) )
		{
			do_portable_wrap_a_file( src_file_path, dst_file_path )
		}
		else
		{
			do_copy_file( src_file_path, dst_file_path )
		}
		
	}
	
} ; END do_process_file( src_file_path, dst_file_path, pre_or_post_flight, src_file_name )





do_copy_file( src_file_path, dst_file_path )
{
	
	src_file_time := FileGetTime( src_file_path )
	FileCopy src_file_path, dst_file_path, 1
	FileSetTime src_file_time, dst_file_path  ; Preserve timestamp
	
} ; END do_copy_file( src_file_path, dst_file_path )




do_portable_wrap_a_file( src_file_path, dst_file_path )
{
	
	; FileAppend "`n", "**", "`n"
	; FileAppend "do_portable_wrap_a_file()" "`n", "**", "`n"
	; FileAppend src_file_path "`n", "**", "`n"
	; FileAppend dst_file_path "`n", "**", "`n"
		
	src_file_time := FileGetTime( src_file_path )
	
	src_file_contents := FileRead( src_file_path )
	
	src_file_replaced := StrReplace( src_file_contents, win_user_appdata_roaming_double, win_user_appdata_roam_placeholder )
	
	if ( FileExist( dst_file_path ) )
	{
		FileDelete dst_file_path
	}
	FileAppend src_file_replaced, dst_file_path
	FileSetTime src_file_time, dst_file_path  ; Preserve timestamp
	
	src_file_contents := "" ; Free the memory.
	src_file_replaced := "" ; Free the memory.
	
} ; END do_portable_wrap_a_file( src_file_path, dst_file_path )






do_portable_unwrap_a_file( src_file_path, dst_file_path )
{
	
	; FileAppend "`n", "**", "`n"
	; FileAppend "do_portable_unwrap_a_file()" "`n", "**", "`n"
	; FileAppend src_file_path "`n", "**", "`n"
	; FileAppend dst_file_path "`n", "**", "`n"
	
	src_file_time := FileGetTime( src_file_path )
	
	src_file_contents := FileRead( src_file_path )
	
	src_file_replaced := StrReplace( src_file_contents, win_user_appdata_roam_placeholder, win_user_appdata_roaming_double )
	
	if ( FileExist( dst_file_path ) )
	{
		FileDelete dst_file_path
	}
	FileAppend src_file_replaced, dst_file_path
	FileSetTime src_file_time, dst_file_path  ; Preserve timestamp
	
	src_file_contents := "" ; Free the memory.
	src_file_replaced := "" ; Free the memory.
	
} ; END do_portable_unwrap_a_file( src_file_path, dst_file_path )









do_change_registry_to_prevent_autolaunch()
{
	
	reg_key := "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
	reg_val := "OpenDeck"
	
	TestRegValue := RegRead( reg_key, reg_val, 0 )
	
	if ( TestRegValue != 0 )
  {
		RegDelete reg_key, reg_val
	}
	
} ; END do_change_registry_to_prevent_autolaunch()









do_change_settings_to_prevent_autolaunch( src_file_path )
{

	; if the settings file doesn't exist yet, there is nothing to change
	; this happens on a fresh install where OpenDeck has never been run before
	if ( ! FileExist( src_file_path ) )
	{
		return
	}

	src_file_time := FileGetTime( src_file_path )
	
	src_file_contents := FileRead( src_file_path )
	
	src_file_replaced := StrReplace( src_file_contents, '"autolaunch": true', '"autolaunch": false' )
	
	if ( src_file_contents != src_file_replaced )
	{
		FileDelete src_file_path
		FileAppend src_file_replaced, src_file_path
		FileSetTime src_file_time, src_file_path  ; Preserve timestamp
	}
	
	src_file_contents := "" ; Free the memory.
	src_file_replaced := "" ; Free the memory.
	
} ; END do_change_settings_to_prevent_autolaunch( src_file_path )





; Function to convert path with single backslashes to double backslashes
ConvertToDoubleBackslash( path )
{
	return StrReplace( path, "\", "\\" )
}




do_postflight_sync()
{

	; GUARD: prevent double-execution of the post-flight sync
	; this can happen if the normal flow completes the sync AND THEN the script exits, triggering OnExit again
	if ( g_postflight_sync_done )
	{
		return
	}
	g_postflight_sync_done := 1


	; if opendeck.exe is still running (e.g. during Windows shutdown), we need to terminate it first
	; otherwise we can't reliably sync files that OpenDeck may still be writing to
	PID_running := ProcessExist( "opendeck.exe" )
	if ( PID_running > 0 )
	{
		ProcessClose( PID_running )
		; give opendeck.exe a moment to fully terminate before we start syncing
		ProcessWaitClose( "opendeck.exe", 5 )
	}


	do_use_pathwrap := 2
	if ( ! ini_do_use_pathwrap )
	{
		do_use_pathwrap := 0
	}

	do_change_settings_to_prevent_autolaunch( win_user_appdata_roaming_path "\settings.json" )

	; sync files from windows appdata well known paths to our portable data store
	SyncFolders( win_user_appdata_roaming_path, my_portable_data_path "\Roaming", do_use_pathwrap, 1 ) ; we'll wrap unless ini setting tells us not to (for OpenDeck v2.4.0+)
	SyncFolders( win_user_appdata_local_path,   my_portable_data_path "\Local",   0, 1 )

	; we have to delete OpenDeck's autolaunch registry entry since we want it to be run by opendeck-portable exclusively
	do_change_registry_to_prevent_autolaunch()


	; stealth mode anyone?
	if ( ini_do_use_stealth )
	{
		; leave no trace on the host
		DirDelete win_user_appdata_roaming_path, true
		DirDelete win_user_appdata_local_path,   true
	}

} ; END do_postflight_sync()



handle_script_exit( ExitReason, ExitCode )
{

	; only run the post-flight sync if OpenDeck was actually launched by us
	; if the script exits before launching (e.g. due to pre-launch checks), we must not sync
	if ( ! g_opendeck_was_launched )
	{
		return 0 ; allow exit, do nothing
	}

	; run the post-flight sync
	; the double-execution guard inside do_postflight_sync() ensures this is safe to call
	; even if the sync already ran in the normal flow
	do_postflight_sync()

	return 0 ; allow exit to proceed

} ; END handle_script_exit( ExitReason, ExitCode )




PID := ProcessExist( "opendeck.exe" )

If ( PID > 0 )
{
	MsgBox( "OpenDeck is already running. Please close it and try again." )
  Exit 1
}



if ( ! FileExist( my_portable_exe_path ) )
{
	MsgBox( "opendeck.exe not found at the specified path: `n`n" my_portable_exe_path "`n`nPlease copy opendeck.exe and it's sibling folders to that path to enable it to work in portable mode." )
  Exit 1
}





; REGISTER EXIT HANDLER
; this ensures post-flight sync runs even if the script is terminated by Windows shutdown/logoff
; without this, RunWait would never return during shutdown and the user's changes would be lost
OnExit( handle_script_exit )



; RUN

; we have to delete OpenDeck's autolaunch registry entry since we want it to be run by opendeck-portable exclusively
do_change_registry_to_prevent_autolaunch()
do_change_settings_to_prevent_autolaunch( my_portable_data_path "\Roaming\settings.json" )

; sync files (if any) from our portable data store to windows appdata well known paths
SyncFolders( my_portable_data_path "\Roaming", win_user_appdata_roaming_path, 1, 1 ) ; we'll always try to unwrap just in case there is any string <win_user_appdata_roam_placeholder> left in our conf files (could be old version or something) - no harm for future versions
SyncFolders( my_portable_data_path "\Local",   win_user_appdata_local_path,   0, 1 )



; mark that OpenDeck has been launched (this tells the OnExit handler that post-flight sync is needed)
g_opendeck_was_launched := 1

; LAUNCH OpenDeck
ExitCode := RunWait( my_portable_exe_path " --hide", my_portable_exe_wdir )


; NORMAL EXIT PATH: OpenDeck was closed by the user
; the post-flight sync function handles everything including the double-execution guard
do_postflight_sync()
