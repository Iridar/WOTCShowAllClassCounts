//-----------------------------------------------------------
//	Class:	WOTCShowAllClassCounts_MCMScreenListener
//	Author: Iridar
//	
//-----------------------------------------------------------

class WOTCShowAllClassCounts_MCMScreenListener extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	local WOTCShowAllClassCounts_MCMScreen MCMScreen;

	if (ScreenClass==none)
	{
		if (MCM_API(Screen) != none)
			ScreenClass=Screen.Class;
		else return;
	}

	MCMScreen = new class'WOTCShowAllClassCounts_MCMScreen';
	MCMScreen.OnInit(Screen);
}

defaultproperties
{
    ScreenClass = none;
}
