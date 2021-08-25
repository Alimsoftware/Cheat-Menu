#pragma once
#include "pch.h"
class Game
{
public:
	inline static ResourceStore m_MissionData{ "mission", eResourceType::TYPE_TEXT };

#ifdef GTASA
	inline static bool m_bForbiddenArea = true;
	inline static bool m_bSolidWater;
	inline static bool m_bScreenShot;
	inline static uint m_nSolidWaterObj;
	inline static bool m_bKeepStuff;
	inline static ResourceStore m_StatData{ "stat", eResourceType::TYPE_TEXT };
	
	inline static std::vector<std::string> m_DayNames =
	{
		"Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"
	};

	struct m_RandomCheats
	{
		inline static bool m_bEnabled;
		inline static bool m_bProgressBar = true;
		inline static std::string m_EnabledCheats[92][2];
		inline static int m_nInterval = 10;
		inline static CJson m_Json = CJson("cheat name");
		inline static uint m_nTimer;
	};
	struct m_Freecam
	{
		inline static bool m_bEnabled;
		inline static float m_fSpeed = 0.08f;
		inline static float m_fFOV = 60.0f;
		inline static bool m_bInitDone;
		inline static CPed* m_pPed;
		inline static int m_nPed = -1;
		inline static CVector m_fMouse;
		inline static CVector m_fTotalMouse;
		inline static BYTE m_bHudState;
		inline static BYTE m_bRadarState;
	};
	struct m_HardMode
	{
		inline static bool m_bEnabled;
		inline static float m_fBacHealth = 0.0f;
		inline static float m_fBacMaxHealth = 0.0f;
		inline static float m_fBacArmour = 0.0f;
		inline static float m_fBacStamina = 0.0f;
	};
	
#endif
	inline static bool m_bDisableCheats;
	inline static bool m_bDisableReplay;
	inline static bool m_bMissionTimer;
	inline static bool m_bFreezeTime;
	inline static bool m_bSyncTime;
	inline static uint m_nSyncTimer;
	inline static bool m_bMissionLoaderWarningShown;

	Game();
	static void Draw();
	static void RealTimeClock();

#ifdef GTASA
	static void FreeCam();
	static void ClearFreecamStuff();
#endif
};
