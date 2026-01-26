// The Lord of the Rings: The Two Towers Autosplitter
// For Dolphin & Retroarch - requires emu-helper-v3
// Created by NickRPGreen 

state("LiveSplit") {}

startup {
    //Creates a persistent instance of the GameCube class (for Dolphin and Retroarch)
	Assembly.Load(File.ReadAllBytes("Components/emu-help-v3")).CreateInstance("GCN");
    vars.MenuType = vars.Helper.Make<ushort>(0x801C6a8E); // 1=Level Select, 2=Credits, 3=Load Game, 4=Main Menu, 5=Options, 6=Loading/Cutscene/Gameplay, 7=Save Game, 8=Opening Creidts, 9=Score Screen, 10=Upgrades, 11=Artwork
    vars.State = vars.Helper.Make<ushort>(0x801CF6BE); // 0=No Value, 1=Loading/Cutscene, 2=Game, 3=Quit Level 4=??
    vars.EndScene = vars.Helper.Make<ushort>(0x801CF136); // 0=Gameplay, 1=Level End Cutscene
    vars.IsMenu = vars.Helper.Make<ushort>(0x801C6A9A); // 0=Menu, 6=Not Menu
    vars.MenuProgress = vars.Helper.Make<ushort>(0x801C6AB6); // 0=Save Dialog, 1=Level Select, 2=Character Select, 3=Continue, 4=Back
    vars.Level = vars.Helper.Make<ushort>(0x801CF6DA); // See below
    vars.Final = vars.Helper.Make<ushort>(0x801CA95E); // Somewhat erratic, but seems to be consistent for the final cutscene, 528=Aragorn, 20112=Gimli, ??=Legolas
}

update {
    current.MenuType = vars.MenuType.Current;
    current.State = vars.State.Current;
    current.EndScene = vars.EndScene.Current;
    current.IsMenu = vars.IsMenu.Current;
    current.MenuProgress = vars.MenuProgress.Current;
    current.Level = vars.Level.Current;
    current.Final = vars.Final.Current;
}

start {
    // Aragorn starts on skipping opening cutscene
    if (vars.MenuType.Current == 6 && vars.State.Old == 1 && vars.State.Current == 2) return true;
    // Legolas/Gimil starts on selecting character
    else if (vars.MenuType.Current == 1 && vars.MenuProgress.Current == 3 && vars.IsMenu.Old == 0 && vars.IsMenu.Current == 6) return true;
    else return false;
}

split {
    // Split when starting a new level
    if (vars.MenuProgress.Current == 3 && vars.IsMenu.Old == 0 && vars.IsMenu.Current == 6) return true;
    // Split on final cutscene
    else if (vars.Final.Changed && vars.Level.Current == 17952 && (vars.Final.Current == 528 || vars.Final.Current == 20112 || vars.Final.Current == 15376)) return true;
}

reset {
    if (vars.MenuType.Current == 4) return true;
}