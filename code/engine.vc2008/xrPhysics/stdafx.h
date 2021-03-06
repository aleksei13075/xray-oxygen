
#pragma once

#define	MTL_EXPORT_API
#define ENGINE_API
#define DLL_API		
#define ECORE_API

#include "../xrCore/xrCore.h"
#include "../xrServerEntities/smart_cast.h"
#include "../xrcdb/xrcdb.h"
#include "../xrsound/sound.h"
#include "../xrParticles/stdafx.h"

#include "xrPhysics.h"
#include "../xrCore/xrapi.h"

#include "d3d9types.h"

class CGameMtlLibrary;
IC CGameMtlLibrary &GMLibrary()
{
	VERIFY(PGMLib);
	return *PGMLib;
}