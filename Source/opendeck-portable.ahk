#Requires AutoHotkey v2.0

#SingleInstance Force

#NoTrayIcon

; opendeck-portable
; version 1.0.0
; by AtmanActive 2024
; https://github.com/AtmanActive/opendeck-portable

A_FileEncoding := "UTF-8-RAW"

A_AllowMainWindow := 0

; https://www.autohotkey.com/docs/v2/

; GET APP'S RUNTIME PATH
my_exe_path := A_ScriptDir

my_portable_data_path := my_exe_path
my_portable_exe_path  := my_exe_path
my_portable_exe_wdir  := my_exe_path

if ( A_IsCompiled )
{
	my_portable_data_path := my_exe_path "\Data"
	my_portable_exe_path  := my_exe_path "\App\opendeck.exe"
	my_portable_exe_wdir  := my_exe_path "\App"
}
else
{
	my_portable_data_path := SubStr( my_exe_path, 1, InStr( my_exe_path, "\", , -1 ) - 1 ) "\Data"
	my_portable_exe_path  := SubStr( my_exe_path, 1, InStr( my_exe_path, "\", , -1 ) - 1 ) "\App\opendeck.exe"
	my_portable_exe_wdir  := SubStr( my_exe_path, 1, InStr( my_exe_path, "\", , -1 ) - 1 ) "\App"
}

win_user_appdata_roaming_path := A_AppData "\opendeck"
win_user_appdata_roaming_double := ConvertToDoubleBackslash( win_user_appdata_roaming_path )
win_user_appdata_roam_placeholder := "<win_user_appdata_roam_placeholder>"


; FileAppend "`n", "**", "`n"
; FileAppend my_portable_data_path "`n", "**", "`n"
; FileAppend win_user_appdata_roaming_path "`n", "**", "`n"
; FileAppend win_user_appdata_roaming_double "`n", "**", "`n"




SyncFolders( sourceDir, targetDir, pre_or_post_flight, overwrite := true ) 
{
	
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
	
	src_file_time := FileGetTime( src_file_path )
	
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







; Function to convert path with single backslashes to double backslashes
ConvertToDoubleBackslash( path ) 
{
	return StrReplace( path, "\", "\\" )
}




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



SyncFolders( my_portable_data_path, win_user_appdata_roaming_path, 1, 1 )

ExitCode := RunWait( my_portable_exe_path " --hide", my_portable_exe_wdir )

SyncFolders( win_user_appdata_roaming_path, my_portable_data_path, 2, 1 )
