class X2EventListener_ClassCountsHook extends X2EventListener config(ShowAllClassCounts);

var config bool DisplayClassName;
var config bool DisplayClassIcon;
var config bool UseUltraCompactMode;
var config bool AlwaysShowGTSTrainableClasses;
var config bool ShowAvaliableCounts;
var config bool ShowRookiesFirst;
var config bool ShowHeroUnitLast;

var config int IconSize;
var config int IconOffset;

var config array<name> ScreensToShowClassCount;
var config array<name> PriorityClasses;
var config array<name> IgnoreClasses;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateClassCountsTemplate());

	return Templates;
}

static private function X2EventListenerTemplate CreateClassCountsTemplate()
{
	local CHEventListenerTemplate	Template;
	local name						ScreenClassName;
	local class<UIScreen>			ScreenClass;
	local array<name>				ValidatedScreenClassNames;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'IRI_ClassCountsHook_Listener');

	Template.RegisterInStrategy = true;
	Template.AddCHEvent('UpdateResources', OnUpdateResources, ELD_Immediate);

	foreach default.ScreensToShowClassCount(ScreenClassName)
	{
		ScreenClass = class<UIScreen>(class'XComEngine'.static.GetClassByName(ScreenClassName));
		if (ScreenClass != none)
		{
			ValidatedScreenClassNames.AddItem(ScreenClassName);
		}
	}
	default.ScreensToShowClassCount = ValidatedScreenClassNames;

	return Template;
}

static private function EventListenerReturn OnUpdateResources(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local UIAvengerHUD						HUD;
	local UIScreen							CurrentScreen;
	local UIChooseClass						ChooseSoldierClassScreenCDO;
	local name								ScreenClassName;

	local XComGameState_HeadquartersXCom	XComHQ;
	local XComGameStateHistory				History;
	local XComGameState_Unit				HQUnitState;
	local StateObjectReference				UnitRef;

	local X2SoldierClassTemplateManager		SoldierClassTemplateManager;
	local X2SoldierClassTemplate			SoldierClassTemplate;
	local array<X2SoldierClassTemplate>		GTSSoldierClassTemplates;
	local array<X2SoldierClassTemplate>		SoldierClassTemplates;

	local array<name>						SoldierClassTemplateNames;
	local array<int>						TotalCounts;
	local array<int>						AvailableCounts;
	local string							TextString;
	local string							IconString;
	local int								Index;
	local int								ItemCount;
	local int								i;

	CurrentScreen = `SCREENSTACK.GetCurrentScreen();

	//for screens we want
	foreach default.ScreensToShowClassCount(ScreenClassName)
	{
		if (!CurrentScreen.IsA(ScreenClassName))
			continue;
		
		//check if we can show the class from the GTS
		ChooseSoldierClassScreenCDO = UIChooseClass(class'XComEngine'.static.GetClassDefaultObject(class'XComGame.UIChooseClass'));
		if (ChooseSoldierClassScreenCDO == none)
			return ELR_NoInterrupt;

		GTSSoldierClassTemplates = ChooseSoldierClassScreenCDO.GetClasses();
		foreach default.IgnoreClasses(ScreenClassName)
		{
			for (i = GTSSoldierClassTemplates.Length - 1; i >= 0; i--)
			{
				if (GTSSoldierClassTemplates[i].DataName == ScreenClassName)
				{
					GTSSoldierClassTemplates.Remove(i, 1);
					break;
				}
			}
		}

		SoldierClassTemplateManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();
		SoldierClassTemplates = SoldierClassTemplateManager.GetAllSoldierClassTemplates();
		foreach default.IgnoreClasses(ScreenClassName)
		{
			for (i = SoldierClassTemplates.Length - 1; i >= 0; i--)
			{
				if (SoldierClassTemplates[i].DataName == ScreenClassName)
				{
					SoldierClassTemplates.Remove(i, 1);
					break;
				}
			}
		}
			

		SoldierClassTemplates.Sort(SortClassesByNameAZ);
		if (default.ShowHeroUnitLast) { SoldierClassTemplates.Sort(SortClassesPriority); }
		if (default.ShowRookiesFirst) { SoldierClassTemplates.Sort(SortClassesByRookie); }

		foreach SoldierClassTemplates(SoldierClassTemplate)
		{
			SoldierClassTemplateNames.AddItem(SoldierClassTemplate.DataName);
		}

		// ------------------------------------------------
		
		XComHQ = `XCOMHQ;
		History = `XCOMHISTORY;
		TotalCounts.Length = SoldierClassTemplates.Length;
		AvailableCounts.Length = SoldierClassTemplates.Length;

		foreach XComHQ.Crew(UnitRef)
		{
			HQUnitState = XComGameState_Unit(History.GetGameStateForObjectID(UnitRef.ObjectID));
			if (HQUnitState != none && HQUnitState.IsSoldier())
			{
				Index = SoldierClassTemplateNames.Find(HQUnitState.GetSoldierClassTemplateName());
				if (Index != INDEX_NONE)
				{
					TotalCounts[Index]++;

					if (default.ShowAvaliableCounts && !HQUnitState.CanGoOnMission(false))
						continue;
					
					AvailableCounts[Index]++;
				}
			}
		}

		//get the Resource HUD
		HUD = `HQPRES.m_kAvengerHUD;

		//reset the Resource HUD
		HUD.HideResources();
		HUD.ClearResources();

		HUD.ResourceContainer.MC.SetNum("TEXT_PADDING", 8);

		//add some right side padding
		HUD.AddResource("","");

		//Show counts
		foreach SoldierClassTemplates(SoldierClassTemplate, Index)
		{
			if (TotalCounts[Index] > 0 || default.AlwaysShowGTSTrainableClasses && GTSSoldierClassTemplates.Find(SoldierClassTemplate) != INDEX_NONE)
			{
				TextString = "";
				IconString = "";

				//the MAIN total count and the (avaliable count) or just main
				if (default.ShowAvaliableCounts)
				{
					// [X|A]
					TextString $= class'UIUtilities_Text'.static.GetColoredText("[", eUIState_Faded);
					TextString $= class'UIUtilities_Text'.static.GetColoredText(string(TotalCounts[Index]), eUIState_Normal);
					TextString $= class'UIUtilities_Text'.static.GetColoredText("|", eUIState_Faded);
					TextString $= class'UIUtilities_Text'.static.GetColoredText(string(AvailableCounts[Index]), eUIState_Good);
					TextString $= class'UIUtilities_Text'.static.GetColoredText("]", eUIState_Faded);
				}
				else
				{
					// [X]
					TextString $= class'UIUtilities_Text'.static.GetColoredText("[", eUIState_Faded);
					TextString $= class'UIUtilities_Text'.static.GetColoredText(string(TotalCounts[Index]), eUIState_Normal);
					TextString $= class'UIUtilities_Text'.static.GetColoredText("]", eUIState_Faded);
				}

				//centralise the text under the class name !! NOPE !! -- Doesn't work how you think it would
				//TextString = class'UIUtilities_Text'.static.AlignCenter(TextString);

				// display icon
				if (default.DisplayClassIcon || default.UseUltraCompactMode) 
				{
					IconString = class'UIUtilities_Text'.static.InjectImage(SoldierClassTemplate.IconImage, default.IconSize, default.IconSize, default.IconOffset);
				}

				//decide on top display
				if (default.UseUltraCompactMode)
				{
					HUD.ResourceContainer.MC.SetNum("TEXT_PADDING", 5);
					HUD.AddResource(IconString , TextString);
					ItemCount++;
				}
				else if (default.DisplayClassName && SoldierClassTemplate.DisplayName != "")
				{
					HUD.AddResource(SoldierClassTemplate.DisplayName, IconString $ TextString);
				}
				else
				{
					HUD.AddResource("", IconString $ TextString);
				}
			}
		}

		HUD.ResourceContainer.MC.ProcessCommands();

		// UltraCompact sets the Icon to the top row above, so we shift the row up to fit the numbers under without clipping
		if (default.UseUltraCompactMode)
		{
			for (i = 0 ; i < ItemCount ; i++)
			{
				HUD.ResourceContainer.MC.ChildSetNum("resourceArray.resource[" $ i $"].title", "_y", 100.0);
			}
		}

		//finally show new resource row
		HUD.ShowResources();

		//reset HUD Padding for the next screens use
		HUD.ResourceContainer.MC.SetNum("TEXT_PADDING", 20);

		//we found a screen we wanted, break out and stop looking so we don't repeat
		break;
	}

	return ELR_NoInterrupt;
}

/////////////////////////////////////////////////////////////////////////////////////////////
//	SORT OPTIONS
/////////////////////////////////////////////////////////////////////////////////////////////

// Sorts by alphabetical A-Z
static private function int SortClassesByNameAZ(X2SoldierClassTemplate ClassA, X2SoldierClassTemplate ClassB)
{	
	if (ClassA.DisplayName > ClassB.DisplayName)
	{
		return 1;
	}
	else if (ClassA.DisplayName < ClassB.DisplayName)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

// Sorts HeroClasses
static private function int SortClassesPriority(X2SoldierClassTemplate ClassA, X2SoldierClassTemplate ClassB)
{	
	local int ClassAPriority, ClassBPriority;

	//check default hero array
	if (class'X2SoldierClass_DefaultChampionClasses'.default.ChampionClasses.find(ClassA.DataName) != INDEX_NONE) { ClassAPriority = 2;	}
	if (class'X2SoldierClass_DefaultChampionClasses'.default.ChampionClasses.find(ClassB.DataName) != INDEX_NONE) { ClassBPriority = 2;	}

	//check mods priority lists
	if (default.PriorityClasses.find(ClassA.DataName) != INDEX_NONE) { ClassAPriority = 1;	}
	if (default.PriorityClasses.find(ClassB.DataName) != INDEX_NONE) { ClassBPriority = 1;	}

	if (ClassAPriority > ClassBPriority)
	{
		return 1;
	}
	else if (ClassAPriority < ClassBPriority)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}

// Sorts Rookie Class
static private function int SortClassesByRookie(X2SoldierClassTemplate ClassA, X2SoldierClassTemplate ClassB)
{	
	local int ClassAPriority, ClassBPriority;

	//check mods priority lists
	if (ClassA.DataName == 'Rookie' ) { ClassAPriority = 1;	}
	if (ClassB.DataName == 'Rookie' ) { ClassBPriority = 1;	}

	if (ClassAPriority > ClassBPriority)
	{
		return -1;
	}
	else if (ClassAPriority < ClassBPriority)
	{
		return 1;
	}
	else
	{
		return 0;
	}
}
