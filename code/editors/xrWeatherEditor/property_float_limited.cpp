////////////////////////////////////////////////////////////////////////////
//	Module 		: property_float_limited.cpp
//	Created 	: 07.12.2007
//  Modified 	: 07.12.2007
//	Author		: Dmitriy Iassenev
//	Description : float property implementation class
////////////////////////////////////////////////////////////////////////////

#include "pch.hpp"
#include "property_float_limited.hpp"

property_float_limited::property_float_limited			(
		float_getter_type const &getter,
		float_setter_type const &setter,
		float increment_factor,
		float const %min,
		float const %max
	) :
	inherited				(getter, setter, increment_factor),
	m_min					(min),
	m_max					(max)
{
}

System::Object ^property_float_limited::GetValue		()
{
	float					value = safe_cast<float>(inherited::GetValue());
	if (value < m_min)
		value				= m_min;

	if (value > m_max)
		value				= m_max;

	return					(value);
}

void property_float_limited::SetValue			(System::Object ^object)
{
	float					new_value = safe_cast<float>(object);

	if (new_value < m_min)
		new_value			= m_min;

	if (new_value > m_max)
		new_value			= m_max;

	inherited::SetValue	(new_value);
}	