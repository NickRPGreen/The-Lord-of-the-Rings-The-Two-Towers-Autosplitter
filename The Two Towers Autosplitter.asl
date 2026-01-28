// The Lord of the Rings: The Two Towers Autosplitter
// For Dolphin & Retroarch - requires emu-helper-v3
// Created by NickRPGreen 

state("LiveSplit") {}

startup {
    //Creates a persistent instance of the GameCube class (for Dolphin and Retroarch)
	Assembly.Load(File.ReadAllBytes("Components/emu-help-v3")).CreateInstance("GCN");
    vars.MenuType = vars.Helper.Make<ushort>(0x801C6a8E); // 1=Level Select, 2=Credits, 3=Load Game, 4=Main Menu, 5=Options, 6=Loading/Cutscene/Gameplay, 7=Save Game, 8=Opening Credits, 9=Score Screen, 10=Upgrades, 11=Artwork
    vars.State = vars.Helper.Make<ushort>(0x801CF6BE); // 0=No Value, 1=Loading/Cutscene, 2=Game, 3=Quit Level 4=??
    vars.Ending = vars.Helper.Make<ushort>(0x801CF136); // 0=Gameplay, 1=Level End Cutscene, 5=Dead
    vars.IsMenu = vars.Helper.Make<ushort>(0x801C6A9A); // 0=Menu, 6=Not Menu
    vars.Cutscene = vars.Helper.Make<ushort>(0x804B35A2); // 0=Not Cutscene, 1=Cutscene
    vars.MenuProgress = vars.Helper.Make<ushort>(0x801C6AB6); // 0=Save Dialog, 1=Level Select, 2=Character Select, 3=Continue, 4=Back
    vars.Level = vars.Helper.Make<ushort>(0x801CF6DA); // See below
    vars.LevelMenu = vars.Helper.Make<ushort>(0x801C6AA6); // Level number on level select screen, used to ensure you only split if starting the correct level
    vars.Health = vars.Helper.Make<ushort>(0x8019284E); // Player health, prevent skips when dead
    vars.Character = vars.Helper.Make<ushort>(0x801C6AAE); // Character Select: 0=Aragorn, 1=Legolas, 2=Gimli, 3=Isildur

    vars.subSplit = 0;
    vars.undoSplit = 0;
    vars.currentLevel = 0;
    vars.timerModel = new TimerModel { CurrentState = timer };

    vars.levelNames = new List<string> {"Prologue","Weathertop","Gates of Moria","Balin's Tomb","Amon Hen","Fangorn Forest","Plains of Rohan","Westfold","Gap of Rohan","Deeping Wall","Breached Wall","Hornburg Courtyard"};
    vars.levelNumbers = new List<int> {17792,17808,17824,17840,17856,17872,17888,17896,17904,17920,17936,17952};
    vars.levels = new Dictionary<string, List<string>>(){
        {"Prologue", new List<string> {"Kill them all","Shield Orcs arrive","Volcano erupts","END"}},
        {"Weathertop", new List<string> {"Back foul thing","Help! They're everywhere!","We shall find you","END"}},
        {"Gates of Moria", new List<string> {"This land has changed","Quickly this way","My cousin, Balin","Watcher in the Water","END"}},
        {"Balin's Tomb", new List<string> {"Goblin horde","Cave troll melee","Cave troll ranged","END"}},
        {"Amon Hen", new List<string> {"We must defend him","Find the Halfling!","Fire","Frodo hides","Bridge","Enter Lurtz","Lurtz Fight","END"}},
        {"Fangorn Forest", new List<string> {"Split up","Forest Troll 1","Camp Pit","Forest Troll 2","Forest Troll 3 & 4", "END"}},
        {"Plains of Rohan", new List<string> {"Arrival","Gandalf Blast","Through the fire","Save the couple","END"}},
        {"Westfold", new List<string> {"Strange explosives","Gate","Lake","END"}},
        {"Gap of Rohan", new List<string> {"Wargs","Boss","END"}},
        {"Deeping Wall", new List<string> {"Ladders","Archer Attack","Catapult Attack","END"}},
        {"Breached Wall", new List<string> {"Close the gate","Archers","Troll","Catapult","END"}},
        {"Hornburg Courtyard", new List<string> {"Protect the gate","Help Friend","Uruk-Hai","Trolls Spawn","Trolls Defeated","END"}}
    };
    
    settings.Add("settings",true,"Settings");
    settings.Add("undo",true,"Undo current level splits on death/menu","settings");
    settings.Add("correct",true,"Prevent split if starting the wrong next level","settings");
    settings.Add("falseAragorn",true,"Prevent start if Aragorn is selected","settings");
    settings.Add("falseStart",false,"Allow splitter to start on any new level","settings");
    settings.SetToolTip("falseStart","Leave unchecked to only start on Prologue/Gates of Moria");
    
    settings.Add("splits",true,"Splits");
    settings.SetToolTip("splits","Split upon starting ticked level, or reaching ticked cutscene");
    for(int i = 0; i<vars.levelNames.Count; i++){
        settings.Add(vars.levelNames[i],true,vars.levelNames[i],"splits");
        for(int j = 1; j<vars.levels[vars.levelNames[i]].Count -1; j++) {
            settings.Add(vars.levels[vars.levelNames[i]][j],false,vars.levels[vars.levelNames[i]][j],vars.levelNames[i]);
        }
    }
}

update {
    // Undo splits if restarting level after death, or restarting a level
    if (vars.Ending.Current == 0 && vars.Ending.Old == 5 || vars.State.Changed && vars.State.Current == 3 && settings["undo"]) {
        for(int i = 0; i<vars.undoSplit; i++) vars.timerModel.UndoSplit(); 
    }

    if (vars.MenuType.Current == 1) {
        vars.subSplit = 0;
        vars.undoSplit = 0;
    }
}

start {
    // Aragorn starts on skipping opening Prologue cutscene
    if (vars.MenuType.Current == 6 && vars.State.Old == 1 && vars.State.Current == 2 && vars.Level.Current == 17792) {
        vars.currentLevel = 0;
        return true;
    }
    // Legolas/Gimil/Isildur starts on selecting character for Gates of Moria only
    else if (vars.MenuType.Current == 1 && vars.MenuProgress.Current == 3 && vars.IsMenu.Old == 0 && vars.IsMenu.Current == 6) {
        if((settings["falseAragorn"] && vars.Character.Current == 0) || (!settings["falseStart"] && vars.LevelMenu.Current != 2)){
            return false;
        }
        else{
            vars.currentLevel = 2;
            return true;
        }
    }
}

onStart {
    vars.subSplit = 0;
    vars.undoSplit = 0;
}

split {
    // Aragorn split from Prologue to Weathertop
    if (vars.MenuType.Old == 9 && vars.MenuType.Current == 6 && vars.Level.Current == 17792) {
        vars.currentLevel = 1;
        vars.subSplit = 0;
        vars.undoSplit = 0;
        print("Prologue Skip");
        return true;
    }
    
    // Split when starting a new level
    else if (vars.MenuProgress.Current == 3 && vars.IsMenu.Old == 0 && vars.IsMenu.Current == 6) {
        if(vars.LevelMenu.Current != vars.currentLevel + 1 && settings["correct"]){
            return false;
        }
        else {
            vars.currentLevel = vars.LevelMenu.Current;
            print("New Level Skip");
            return true;
        }
    }

    // Subsplits
    else if (vars.Cutscene.Old == 0 && vars.Cutscene.Current == 1 && vars.Health.Current != 0) {
        vars.subSplit++;
        var check = vars.levels[vars.levelNames[vars.levelNumbers.IndexOf(vars.Level.Current)]][vars.subSplit-1];
        if(vars.subSplit == 1) return false;
        else if (settings[check] && check != "END"){
            vars.undoSplit++;
            print("Subsplit Skip: " + check);
            return true;
        }
    }
}

reset {
    if (vars.MenuType.Current == 4 || vars.MenuType.Current == 8) return true;
}

shutdown {
    vars.Helper.Dispose();
}

