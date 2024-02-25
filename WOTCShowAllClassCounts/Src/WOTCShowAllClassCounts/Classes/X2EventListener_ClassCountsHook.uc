class X2EventListener_ClassCountsHook extends X2EventListener config(Game);

var config bool DisplayClassName;
var config bool DisplayClassIcon;
var config bool	AlwaysShowGTSTrainableClasses;

var config(ShowAllClassCounts) array<name> ScreensToShowClassCount;
var config(ShowAllClassCounts) array<name> IgnoreClasses;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateClassCountsTemplate());

	return Templates;
}

static private function X2EventListenerTemplate CreateClassCountsTemplate()
{
	local CHEventListenerTemplate Template;
	local name ScreenClassName;
	local class<UIScreen> ScreenClass;
	local array<name> ValidatedScreenClassNames;

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
	local XComGameState_HeadquartersXCom	XComHQ;
	local XComGameStateHistory				History;
	local UIAvengerHUD						HUD;
	local UIScreen							CurrentScreen;
	local XComGameState_Unit				HQUnitState;
	local string							TextString;
	local array<int>						TotalCounts;
	local array<int>						AvailableCounts;
	local X2SoldierClassTemplate			SoldierClassTemplate;
	local StateObjectReference				UnitRef;
	local int								Index;
	local UIChooseClass						ChooseSoldierClassScreenCDO;
	local X2SoldierClassTemplateManager		SoldierClassTemplateManager;
	local array<X2SoldierClassTemplate>		GTSSoldierClassTemplates;
	local array<X2SoldierClassTemplate>		SoldierClassTemplates;
	local array<name>						SoldierClassTemplateNames;
	local name								ScreenClassName;
	local int i;

	CurrentScreen = `SCREENSTACK.GetCurrentScreen();
	//`LOG("CurrentScreen:" @ CurrentScreen.Class.Name,, 'IRITEST');

	foreach default.ScreensToShowClassCount(ScreenClassName)
	{
		if (!CurrentScreen.IsA(ScreenClassName))
			continue;
		
		ChooseSoldierClassScreenCDO = UIChooseClass(class'XComEngine'.static.GetClassDefaultObject(class'XComGame.UIChooseClass'));
		if (ChooseSoldierClassScreenCDO == none)
			return ELR_NoInterrupt;

		GTSSoldierClassTemplates = ChooseSoldierClassScreenCDO.GetClasses();

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

		SoldierClassTemplates.Sort(class'UIChooseClass'.static.SortClassesByName);

		foreach SoldierClassTemplates(SoldierClassTemplate)
		{
			SoldierClassTemplateNames.AddItem(SoldierClassTemplate.DataName);
		}
		
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
					if (HQUnitState.CanGoOnMission(false))
					{
						AvailableCounts[Index]++;
					}
				}
			}
		}

		HUD = `HQPRES.m_kAvengerHUD;
		foreach SoldierClassTemplates(SoldierClassTemplate, Index)
		{
			if (TotalCounts[Index] > 0 || default.AlwaysShowGTSTrainableClasses && GTSSoldierClassTemplates.Find(SoldierClassTemplate) != INDEX_NONE)
			{
				TextString = "";

				if (default.DisplayClassIcon) 
				{
					TextString = class'UIUtilities_Text'.static.InjectImage(SoldierClassTemplate.IconImage, 30, 30, -15);
				}

				TextString @= class'UIUtilities_Text'.static.GetColoredText(string(TotalCounts[Index]), eUIState_Normal);

				TextString @= class'UIUtilities_Text'.static.GetColoredText("(" $ AvailableCounts[Index] $ ")", eUIState_Good);

				if (default.DisplayClassName && SoldierClassTemplate.DisplayName != "")
				{
					HUD.AddResource(SoldierClassTemplate.DisplayName, TextString);
				}
				else
				{	
					HUD.AddResource("", TextString);
				}
			}
		}
		HUD.ShowResources();

		break;
	}
	
	return ELR_NoInterrupt;
}