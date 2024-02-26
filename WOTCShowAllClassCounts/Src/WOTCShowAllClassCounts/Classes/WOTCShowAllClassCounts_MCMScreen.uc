class WOTCShowAllClassCounts_MCMScreen extends Object config(WOTCShowAllClassCounts);

var config int VERSION_CFG;

var localized string ModName;
var localized string PageTitle;
var localized string GroupHeader;
var localized string GroupHeader2;
var localized string LabelEnd;
var localized string LabelEndTooltip;

`include(WOTCShowAllClassCounts\Src\ModConfigMenuAPI\MCM_API_Includes.uci)

`MCM_API_AutoCheckBoxVars(DisplayClassName);
`MCM_API_AutoCheckBoxVars(DisplayClassIcon);
`MCM_API_AutoCheckBoxVars(UseUltraCompactMode);
`MCM_API_AutoCheckBoxVars(AlwaysShowGTSTrainableClasses);
`MCM_API_AutoCheckBoxVars(ShowAvaliableCounts);
`MCM_API_AutoCheckBoxVars(ShowRookiesFirst);
`MCM_API_AutoCheckBoxVars(ShowHeroUnitLast);

`include(WOTCShowAllClassCounts\Src\ModConfigMenuAPI\MCM_API_CfgHelpers.uci)

`MCM_API_AutoCheckBoxFns(DisplayClassName, 1);
`MCM_API_AutoCheckBoxFns(DisplayClassIcon, 1);
`MCM_API_AutoCheckBoxFns(UseUltraCompactMode, 1);
`MCM_API_AutoCheckBoxFns(AlwaysShowGTSTrainableClasses, 1);
`MCM_API_AutoCheckBoxFns(ShowAvaliableCounts, 1);
`MCM_API_AutoCheckBoxFns(ShowRookiesFirst, 1);
`MCM_API_AutoCheckBoxFns(ShowHeroUnitLast, 1);

event OnInit(UIScreen Screen)
{
	`MCM_API_Register(Screen, ClientModCallback);
}

simulated function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
	local MCM_API_SettingsPage Page;
	local MCM_API_SettingsGroup Group;

	LoadSavedSettings();
	Page = ConfigAPI.NewSettingsPage(ModName);
	Page.SetPageTitle(PageTitle);
	Page.SetSaveHandler(SaveButtonClicked);
	Page.EnableResetButton(ResetButtonClicked);

	Group = Page.AddGroup('Group', GroupHeader);

	`MCM_API_AutoAddCheckBox(Group, DisplayClassName);
	`MCM_API_AutoAddCheckBox(Group, DisplayClassIcon);
	`MCM_API_AutoAddCheckBox(Group, UseUltraCompactMode, UseUltraCompactMode_ChangeHandler);
	`MCM_API_AutoAddCheckBox(Group, AlwaysShowGTSTrainableClasses);
	`MCM_API_AutoAddCheckBox(Group, ShowAvaliableCounts);

	Group.GetSettingByName('DisplayClassName').SetEditable(!UseUltraCompactMode); 
	Group.GetSettingByName('DisplayClassIcon').SetEditable(!UseUltraCompactMode); 

	Group = Page.AddGroup('Group2', GroupHeader2);
	`MCM_API_AutoAddCheckBox(Group, ShowRookiesFirst);
	`MCM_API_AutoAddCheckBox(Group, ShowHeroUnitLast);

	//Group.AddLabel('Label_End', LabelEnd, LabelEndTooltip);

	Page.ShowSettings();
}

private function UseUltraCompactMode_ChangeHandler(MCM_API_Setting _Setting, bool _SettingValue)
{
	UseUltraCompactMode = _SettingValue;
	if (UseUltraCompactMode)
	{
		DisplayClassName = false;
		DisplayClassIcon = true;
	}
	else
	{
		DisplayClassName = `GETMCMVAR(DisplayClassName);
		DisplayClassIcon = `GETMCMVAR(DisplayClassIcon);
	}

	_Setting.GetParentGroup().GetSettingByName('DisplayClassName').SetEditable(!UseUltraCompactMode);
	_Setting.GetParentGroup().GetSettingByName('DisplayClassIcon').SetEditable(!UseUltraCompactMode);
}

simulated function LoadSavedSettings()
{
	DisplayClassName = `GETMCMVAR(DisplayClassName);
	DisplayClassIcon = `GETMCMVAR(DisplayClassIcon);
	UseUltraCompactMode = `GETMCMVAR(UseUltraCompactMode);
	AlwaysShowGTSTrainableClasses = `GETMCMVAR(AlwaysShowGTSTrainableClasses);
	ShowAvaliableCounts = `GETMCMVAR(ShowAvaliableCounts);
	ShowRookiesFirst = `GETMCMVAR(ShowRookiesFirst);
	ShowHeroUnitLast = `GETMCMVAR(ShowHeroUnitLast);
}

simulated function ResetButtonClicked(MCM_API_SettingsPage Page)
{
	`MCM_API_AutoReset(DisplayClassName);
	`MCM_API_AutoReset(DisplayClassIcon);
	`MCM_API_AutoReset(UseUltraCompactMode);
	`MCM_API_AutoReset(AlwaysShowGTSTrainableClasses);
	`MCM_API_AutoReset(ShowAvaliableCounts);
	`MCM_API_AutoReset(ShowRookiesFirst);
	`MCM_API_AutoReset(ShowHeroUnitLast);
}


simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
	VERSION_CFG = `MCM_CH_GetCompositeVersion();
	SaveConfig();
}


