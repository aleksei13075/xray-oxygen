////////////////////////////////////////////////////////////////////////////
//	Module 		: script_engine_script.cpp
//	Created 	: 25.12.2002
//  Modified 	: 13.05.2004
//	Author		: Dmitriy Iassenev
//	Description : ALife Simulator script engine export
////////////////////////////////////////////////////////////////////////////

#include "stdafx.h"
#include "script_engine.h"
#include "ai_space.h"
#include "script_debugger.h"
#include "../xrScripts/import_ses.hpp"

using namespace luabind;

void ErrorLog(LPCSTR caMessage)
{
	ai().script_engine().error_log("%s",caMessage);
#ifdef PRINT_CALL_STACK
	ai().script_engine().print_stack();
#endif // #ifdef PRINT_CALL_STACK
	
#ifdef USE_DEBUGGER
#	ifndef USE_LUA_STUDIO
		if( ai().script_engine().debugger() ){
			ai().script_engine().debugger()->Write(caMessage);
		}
#	endif // #ifndef USE_LUA_STUDIO
#endif // #ifdef USE_DEBUGGER

#ifdef DEBUG
		bool lua_studio_connected = !!ai().script_engine().debugger();
		if (!lua_studio_connected)
#endif //#ifdef DEBUG
	R_ASSERT2(false, caMessage);
}

void FlushLogs()
{
#ifdef DEBUG
	FlushLog();
	ai().script_engine().flush_log();
#endif // DEBUG
}

void verify_if_thread_is_running()
{
	THROW2	(ai().script_engine().current_thread(),"coroutine.yield() is called outside the LUA thread!");
}

bool is_editor()
{
#ifdef XRGAME_EXPORTS
	return		(false);
#else
	return		(true);
#endif
}

#ifdef XRGAME_EXPORTS
CRenderDevice *get_device()
{
	return		(&Device);
}
#endif

void Lua_DebugBreak()
{
    DebugBreak();
}

void prefetch_module(LPCSTR file_name)
{
	ai().script_engine().process_file(file_name);
}

struct profile_timer_script 
{
	using Clock = std::chrono::high_resolution_clock;
	using Time = Clock::time_point;
	using Duration = Clock::duration;

	Time start_time;
	Duration accumulator;
	u64 count = 0;
	int recurse_mark = 0;

	profile_timer_script() : start_time(), accumulator(), count(0), recurse_mark(0) {}
	
	bool operator< (const profile_timer_script& profile_timer) const 
	{
		return accumulator < profile_timer.accumulator;
	}

	void start()
	{
		if (recurse_mark) 
		{
			++recurse_mark;
			return;
		}

		++recurse_mark;
		++count;
		start_time = Clock::now();
	}

	IC void stop()
	{
		--recurse_mark;
		
		if (recurse_mark)
			return;

		const auto finish = Clock::now();
		if (finish > start_time)
		accumulator += finish - start_time;
	}

	float time() const 
	{
		using namespace std::chrono;
		return float(duration_cast<milliseconds>(accumulator).count()) * 1000000.f;
	}
};

IC	profile_timer_script operator+(const profile_timer_script &portion0, const profile_timer_script &portion1)
{
	profile_timer_script result;
	result.accumulator = portion0.accumulator + portion1.accumulator;
	result.count = portion0.count + portion1.count;
	return (result);
}

#ifdef XRGAME_EXPORTS
ICF	u32	script_time_global	()	{ return Device.dwTimeGlobal; }
ICF	u32	script_time_global_async	()	{ return Device.TimerAsync_MMT(); }
#else
ICF	u32	script_time_global	()	{ return NULL; }
ICF	u32	script_time_global_async	()	{ return NULL; }
#endif+

#ifdef XRGAME_EXPORTS
static bool is_enough_address_space_available_impl()
{
	ENGINE_API bool is_enough_address_space_available();
	return is_enough_address_space_available( );
}
#endif // #ifdef XRGAME_EXPORTS

#pragma optimize("s",on)
void CScriptEngine::script_register(lua_State *L)
{
	module(L)[
		class_<profile_timer_script>("profile_timer")
			.def(constructor<>())
			.def(constructor<profile_timer_script&>())
			.def(const_self + profile_timer_script())
			.def(const_self < profile_timer_script())
			.def(tostring(self))
			.def("start",&profile_timer_script::start)
			.def("stop",&profile_timer_script::stop)
			.def("time",&profile_timer_script::time)
	];

    function    (L, "to_log",                           import_ses::LuaLog);
	function	(L,	"error_log",						ErrorLog);
	function	(L,	"flush",							FlushLogs);
	function	(L,	"prefetch",							prefetch_module);
	function	(L,	"verify_if_thread_is_running",		verify_if_thread_is_running);
	function	(L,	"editor",							is_editor);
	function	(L, "user_name",						import_ses::user_name);
	function	(L, "time_global",						script_time_global);
	function	(L, "time_global_async",				script_time_global_async);
    function    (L, "debuggerTrigger",                  Lua_DebugBreak);
	//function	(L, "LoadModule", load_modules);
#ifdef XRGAME_EXPORTS
	function	(L,	"device",							get_device);
	function	(L,	"is_enough_address_space_available",is_enough_address_space_available_impl);

	//FX: ��������� ����� �������
#pragma todo("FX to FX: update load modules code...")
/*	{
		luabind::functor<LPCSTR> module_init;
		R_ASSERT2(ai().script_engine().functor<LPCSTR>("fray_config.modules_init", module_init), "Can't call lua function!");
		module_init();
	} 
*/
#endif // #ifdef XRGAME_EXPORTS
}
