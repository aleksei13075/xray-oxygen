////////////////////////////////////////////////////////////////////////////
//	Module 		: script_ini_file.h
//	Created 	: 21.05.2004
//  Modified 	: 21.05.2004
//	Author		: Dmitriy Iassenev
//	Description : Script ini file class
////////////////////////////////////////////////////////////////////////////

#pragma once

#include "../xrScripts/export/script_token_list.h"
#include "../xrScripts/export/script_export_space.h"

class CScriptIniFile : public CInifile 
{
protected:
	using inherited =  CInifile;

public:
						CScriptIniFile		(IReader *F, const char* path=0);
						CScriptIniFile		(const char* szFileName, BOOL ReadOnly=TRUE, BOOL bLoadAtStart=TRUE, BOOL SaveAtEnd=TRUE);
	virtual 			~CScriptIniFile		();
			bool		line_exist			(const char* S, const char* L);
			bool		section_exist		(const char* S);
			int			r_clsid				(const char* S, const char* L);
			bool		r_bool				(const char* S, const char* L);
			int			r_token				(const char* S, const char* L, const CScriptTokenList &token_list);
			const char*	r_string_wb			(const char* S, const char* L);
			const char*	update				(const char* file_name);
			u32			line_count			(const char* S);
			const char*	r_string			(const char* S, const char* L);
			u32			r_u32				(const char* S, const char* L);
			int			r_s32				(const char* S, const char* L);
			float		r_float				(const char* S, const char* L);
			Fvector		r_fvector3			(const char* S, const char* L);
			DECLARE_SCRIPT_REGISTER_FUNCTION
};
add_to_type_list(CScriptIniFile)
#undef script_type_list
#define script_type_list save_type_list(CScriptIniFile)

#include "script_ini_file_inline.h"