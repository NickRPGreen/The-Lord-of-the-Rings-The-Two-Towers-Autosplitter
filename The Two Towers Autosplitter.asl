// The Lord of the Rings: The Two Towers Autosplitter
// For Dolphin & Retroarch - requires emu-helper-v3
// Created by NickRPGreen 

state("LiveSplit") {}

startup {
    vars.T = new ExpandoObject();           // Container for variables not desired in the ASL VAR Viewer
    var T = vars.T;                         // Quick-access to container

    //Creates a persistent instance of the GameCube class (for Dolphin and Retroarch)
	Assembly.Load(File.ReadAllBytes("Components/emu-help-v3")).CreateInstance("GCN");
    T.MenuType = vars.Helper.Make<ushort>(0x801C6a8E); // See T.menus
    T.State = vars.Helper.Make<ushort>(0x801CF6BE); // 0=No Value, 1=Loading/Cutscene, 2=Game, 3=Quit Level 4=??
    T.Ending = vars.Helper.Make<ushort>(0x801CF136); // 0=Gameplay, 1=Level End Cutscene, 5=Dead
    T.IsMenu = vars.Helper.Make<ushort>(0x801C6A9A); // 0=Menu, 6=Not Menu
    T.Cutscene = vars.Helper.Make<ushort>(0x804B35A2); // 0=Not Cutscene, 1=Cutscene
    T.MenuProgress = vars.Helper.Make<ushort>(0x801C6AB6); // See T.levelSelect
    T.Level = vars.Helper.Make<ushort>(0x801CF6DA); // See below
    T.LevelMenu = vars.Helper.Make<ushort>(0x801C6AA6); // Level number on level select screen, used to ensure you only split if starting the correct level
    T.Health = vars.Helper.Make<ushort>(0x8019284E); // Player health, prevent skips when dead
    T.Armor = vars.Helper.Make<ushort>(0x80192A06); // Player armor, separate from health
    T.Character = vars.Helper.Make<ushort>(0x801C6AAE); // Character Select Screen: 0=Aragorn, 1=Legolas, 2=Gimli, 3=Isildur

    T.subSplit = 0;
    T.undoSplit = 0;
    T.currentLevel = 0;
    T.start = false;
    T.timerModel = new TimerModel { CurrentState = timer };

    // Menus
    T.menus = new Dictionary<int, string>(){
        {0, "Unknown"},
        {1, "Level Select"},
        {2, "Credits"},
        {3, "Load Game"},
        {4, "Main Menu"},
        {5, "Options"},
        {6, "Gameplay"},
        {7, "Save Game"},
        {8, "Opening Credits"},
        {9, "Score Screen"},
        {10, "Upgrades"},
        {11, "Artwork"}
    };

    T.levelSelect = new Dictionary<int, string>(){
        {0, "Save Dialog"},
        {1, "Level Select"},
        {2, "Character Select"},
        {3, "Continue"},
        {4, "Back"}
    };

    T.characters = new Dictionary<int, string>(){
        {0, "Aragorn"},
        {1, "Legolas"},
        {2, "Gimli"},
        {3, "Isildur"}
    };

    T.levelNames = new List<string> {"Prologue","Weathertop","Gates of Moria","Balin's Tomb","Amon Hen","Fangorn Forest","Plains of Rohan","Westfold","Gap of Rohan","Deeping Wall","Breached Wall","Hornburg Courtyard"};
    T.levelNumbers = new List<int> {17792,17808,17824,17840,17856,17872,17888,17896,17904,17920,17936,17952};
    T.levels = new Dictionary<string, List<string>>(){
        {"Prologue", new List<string> {"Kill them all","Shield Orcs arrive","Volcano erupts","END"}},
        {"Weathertop", new List<string> {"Back foul thing","Help! They're everywhere!","We shall find you","END"}},
        {"Gates of Moria", new List<string> {"This land has changed","Quickly this way","My cousin, Balin","Watcher in the Water","END"}},
        {"Balin's Tomb", new List<string> {"Goblin horde","Cave troll melee","Cave troll ranged","END"}},
        {"Amon Hen", new List<string> {"We must defend him","Find the Halfling!","Fire","Frodo hides","Bridge","Frodo Escapes","Enter Lurtz","Lurtz Fight","END"}},
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
    settings.SetToolTip("splits","Split upon starting ticked level, or reaching ticked cutscene. Final split when defeating trolls always splits whether ticked or not.");
    for(int i = 0; i<T.levelNames.Count; i++){
        settings.Add(T.levelNames[i],true,T.levelNames[i],"splits");
        for(int j = 1; j<T.levels[T.levelNames[i]].Count -1; j++) {
            settings.Add(T.levels[T.levelNames[i]][j],false,T.levels[T.levelNames[i]][j],T.levelNames[i]);
        }
    }
    settings.SetToolTip("Trolls Defeated","This split will always trigger whether ticked or not");
}

update {
    var T = vars.T;
    
    // Viewable Current States
    // Menus
    current.Menu = T.menus[T.MenuType.Current];
    current.MenuProgress = T.levelSelect[T.MenuProgress.Current];

    // Level
    if(T.start == false) {
        current.Level = "Prologue";
        T.start = true;
    }
    if(T.Level.Changed && T.Level.Current != 0) current.Level = T.levelNames[T.levelNumbers.IndexOf(T.Level.Current)];

    if(T.subSplit == 0) current.Section = T.levels[current.Level][0];
    else current.Section = T.levels[current.Level][T.subSplit-1];
    
    if(T.Cutscene.Current == 0) current.InCutscene = "False";
    else current.InCutscene = "True";

    // Player
    if(T.Level.Current == 17792) current.Character = "Isildur";
    else if(T.Level.Current == 17808) current.Character = "Aragorn";
    else current.Character = T.characters[T.Character.Current];

    if(T.Armor.Current > 0) current.Health = T.Health.Current + " HP + " + T.Armor.Current + " AR";
    else current.Health = T.Health.Current + " HP";
    
    // Undo splits if restarting level after death, or restarting a level
    if (T.Ending.Current == 0 && T.Ending.Old == 5 || T.State.Changed && T.State.Current == 3 && settings["undo"]) {
        // Undo one less split if dying on Fangorn Forest, as there is a checkpoint at the first subsplit
        if(T.Level.Current == 17872 && T.subSplit > 1){
            for(int i = 0; i<T.undoSplit-1; i++) T.timerModel.UndoSplit();
            T.subSplit = 2;
            T.undoSplit = 0;
        }
        // Undo behaviour for every other level
        else {
            for(int i = 0; i<T.undoSplit; i++) T.timerModel.UndoSplit();
            T.subSplit = 1;
            T.undoSplit = 0;
        }
    }

    if (T.MenuType.Current == 1) {
        T.subSplit = 0;
        T.undoSplit = 0;
    }
}

start {
    var T = vars.T;
    // Aragorn starts on skipping opening Prologue cutscene
    if (T.MenuType.Current == 6 && T.State.Old == 1 && T.State.Current == 2 && T.Level.Current == 17792) {
        T.currentLevel = 0;
        return true;
    }
    // Legolas/Gimil/Isildur starts on selecting character for Gates of Moria only
    else if (T.MenuType.Current == 1 && T.MenuProgress.Current == 3 && T.IsMenu.Old == 0 && T.IsMenu.Current == 6) {
        if((settings["falseAragorn"] && T.Character.Current == 0) || (!settings["falseStart"] && T.LevelMenu.Current != 2)){
            return false;
        }
        else{
            T.currentLevel = 2;
            return true;
        }
    }
}

onStart {
    var T = vars.T;
    T.subSplit = 0;
    T.undoSplit = 0;
}

split {
    var T = vars.T;
    // Aragorn split from Prologue to Weathertop
    if ((T.MenuType.Old == 9 || T.MenuType.Old == 7) && T.MenuType.Current == 6 && T.Level.Current == 17792) {
        T.currentLevel = 1;
        T.subSplit = 0;
        T.undoSplit = 0;

        print("Prologue Skip");
        return true;
    }
    
    // Split when starting a new level
    else if (T.MenuProgress.Current == 3 && T.IsMenu.Old == 0 && T.IsMenu.Current == 6) {
        if(T.LevelMenu.Current != T.currentLevel + 1 && settings["correct"]){
            return false;
        }
        else {
            T.currentLevel = T.LevelMenu.Current;
            print("New Level Skip");
            return true;
        }
    }

    // Subsplits
    else if (T.Cutscene.Old == 0 && T.Cutscene.Current == 1 && T.Health.Current != 0) {
        T.subSplit++;
        var check = T.levels[current.Level][T.subSplit-1];
        if(T.subSplit == 1) return false;
        else if ((settings[check] && check != "END") || check == "Trolls Defeated"){
            T.undoSplit++;
            print("Subsplit Skip: " + check);
            return true;
        }
    }
}

reset {
    var T = vars.T;
    if (T.MenuType.Current == 4 || T.MenuType.Current == 8) return true;
}

shutdown {
    vars.Helper.Dispose();
}
