Record TFWMInternalModifier
{
    string description;
    boolean have;
    boolean obtainable_now;
    boolean obtainable_theoretically;
    float bonus;
    
    boolean from_familiar_equipment;
};

boolean TFWMInternalModifierEquals(TFWMInternalModifier a, TFWMInternalModifier b)
{
    if (a.description != b.description)
        return false;
    if (a.have != b.have)
        return false;
    if (a.obtainable_now != b.obtainable_now)
        return false;
    if (a.obtainable_theoretically != b.obtainable_theoretically)
        return false;
    if (a.bonus != b.bonus)
        return false;
    if (a.from_familiar_equipment != b.from_familiar_equipment)
        return false;
    return true;
}

TFWMInternalModifier TFWMInternalModifierMake(string description, boolean have, boolean obtainable_now, boolean obtainable_theoretically, float bonus, boolean from_familiar_equipment)
{
    TFWMInternalModifier result;
    result.description = description;
    result.have = have;
    result.obtainable_now = obtainable_now;
    result.obtainable_theoretically = obtainable_theoretically;
    result.bonus = bonus;
    result.from_familiar_equipment = from_familiar_equipment;
    
    return result;
}

TFWMInternalModifier TFWMInternalModifierMake(string description, boolean have, boolean obtainable_now, boolean obtainable_theoretically, float bonus)
{
    return TFWMInternalModifierMake(description, have, obtainable_now, obtainable_theoretically, bonus, false);
}

TFWMInternalModifier TFWMInternalModifierMake()
{
    return TFWMInternalModifierMake("", false, false, false, 0);
}

TFWMInternalModifier TFWMInternalModifierMake(skill s)
{
    effect e = s.to_effect();
    string description = s;
    if (e != $effect[none] && e.have_effect() == 0)
        description += " (cast)";
    
    float weight_modifier = 0.0;
    if (e != $effect[none])
        weight_modifier = e.numeric_modifier("familiar weight");
    else
        weight_modifier = s.numeric_modifier("familiar weight");
    
    return TFWMInternalModifierMake(description, s.have_skill(), s.have_skill(), s.have_skill(), weight_modifier);
}

TFWMInternalModifier TFWMInternalModifierMake(item equippable_item)
{
    if (equippable_item.available_amount() == 0)
        return TFWMInternalModifierMake();
    float weight_modifier = equippable_item.numeric_modifier("familiar weight");
    
    if (equippable_item == $item[crown of thrones])
        weight_modifier = 5.0;
    
    
    string description = equippable_item;
    if (equippable_item.equipped_amount() == 0)
        description += " (equip)";
    
    TFWMInternalModifier result = TFWMInternalModifierMake(description, true, true, true, weight_modifier);
    
    if (equippable_item.to_slot() == $slot[familiar])
        result.from_familiar_equipment = true;
    return result;
}

void listAppend(TFWMInternalModifier [int] list, TFWMInternalModifier entry)
{
	int position = list.count();
	while (list contains position)
		position += 1;
	list[position] = entry;
}


//Returns TRUE if they currently have, or can easily have, enough to pass.
boolean generateTowerFamiliarWeightMethod(string [int] how, string [int] immediately_obtainable, string [int] missing_potentials, FloatHandle missing_weight)
{
    missing_weight.f = 0.0;
    if (__quest_state["Level 13"].mafia_internal_step > 9) //no need
        return true;
    if (!__misc_state["In run"])
        return true;
    if (__misc_state["familiars temporarily blocked"])
        return true;
    
    
    //Not the best of solutions, but...
    
    TFWMInternalModifier [int] weight_modifiers;
    
    //amphibian sympathy
    weight_modifiers.listAppend(TFWMInternalModifierMake($skill[amphibian sympathy]));
    //leash of linguini
    weight_modifiers.listAppend(TFWMInternalModifierMake($skill[leash of linguini]));
    //empathy of the newt
    weight_modifiers.listAppend(TFWMInternalModifierMake($skill[empathy of the newt]));
    //knob goblin pet-buffing spray
    if ($item[knob goblin pet-buffing spray].available_amount() > 0 || dispensary_available() || $effect[heavy petting].have_effect() > 0)
    {
        weight_modifiers.listAppend(TFWMInternalModifierMake("knob goblin pet-buffing spray", true, true, true, 5.0));
    }
    else if (__misc_state["can equip just about any weapon"])
    {
        weight_modifiers.listAppend(TFWMInternalModifierMake("knob goblin pet-buffing spray (unlock cobb's knob dispensary)", false, false, true, 5.0));
    }
    //hippy concert
    if (get_property("sidequestArenaCompleted") == "hippy" && !get_property_boolean("concertVisited") || $effect[Optimist Primal].have_effect() > 0)
    {
        boolean have_effect = $effect[Optimist Primal].have_effect() > 0;
        weight_modifiers.listAppend(TFWMInternalModifierMake("Optimist Primal (hippy concert)", have_effect, have_effect || !get_property_boolean("concertVisited"), true, 5.0));
    }
    //irradiated pet snacks
    if ($item[irradiated pet snacks].available_amount() > 0 || $effect[healthy green glow].have_effect() > 0)
    {
        boolean have_effect = $effect[healthy green glow].have_effect() > 0;
        weight_modifiers.listAppend(TFWMInternalModifierMake("irradiated pet snacks", have_effect, true, true, 10.0));
    }
    else if (__misc_state["can eat just about anything"] || (__misc_state["can drink just about anything"] && __misc_state["VIP available"]))
    {
        weight_modifiers.listAppend(TFWMInternalModifierMake("irradiated pet snacks (semi-rare, menagerie level 2)", false, false, true, 10.0));
    }
    if (__misc_state["VIP available"] && __misc_state["can drink just about anything"])
    {
        if (get_property_int("_speakeasyDrinksDrunk") <3 && availableDrunkenness() >= 3)
        {
            boolean have_effect = lookupEffect("Hip to the Jive").have_effect() > 0;
            weight_modifiers.listAppend(TFWMInternalModifierMake("Speakeasy hot socks", have_effect, true, true, 10.0));
        }
        
    }
    //billiards
    if (__misc_state["VIP available"] && get_property_int("_poolGames") <3 && $item[Clan pool table].is_unrestricted() || $effect[Billiards Belligerence].have_effect() > 0)
    {
        boolean have_effect = $effect[Billiards Belligerence].have_effect() > 0;
        weight_modifiers.listAppend(TFWMInternalModifierMake("VIP Pool (play aggressively)", have_effect, have_effect || (get_property_int("_poolGames") <3), true, 5.0));
    }
    //tea party
    if (($item[&quot;DRINK ME&quot; potion].available_amount() > 0 || $effect[Down the Rabbit Hole].have_effect() > 0) && (!get_property_boolean("_madTeaParty") || $effect[You Can Really Taste the Dormouse].have_effect() > 0))
    {
        boolean have_effect = $effect[You Can Really Taste the Dormouse].have_effect() > 0;
        weight_modifiers.listAppend(TFWMInternalModifierMake("Mad hatter (reinforced beaded headband)", have_effect, have_effect, true, 5.0));
    }
    //beastly paste
    if ($item[beastly paste].available_amount() > 0 || $effect[Beastly Flavor].have_effect() > 0)
    {
        boolean have_effect = $effect[Beastly Flavor].have_effect() > 0;
        weight_modifiers.listAppend(TFWMInternalModifierMake("beastly paste (4 spleen)", have_effect, true, true, 3.0));
    }
    else if ($familiar[pair of stomping boots].familiar_is_usable())
    {
        weight_modifiers.listAppend(TFWMInternalModifierMake("beastly paste (4 spleen, stomp beasts)", false, false, true, 3.0));
    }
    //resolution
    if ($item[resolution: be kinder].available_amount() > 0 || $effect[Kindly Resolve].have_effect() > 0)
    {
        boolean have_effect = $effect[Kindly Resolve].have_effect() > 0;
        weight_modifiers.listAppend(TFWMInternalModifierMake("resolution: be kinder", have_effect, true, true, 5.0));
    }
    else if ($skill[summon resolutions].have_skill() && __misc_state["bookshelf accessible"])
    {
        weight_modifiers.listAppend(TFWMInternalModifierMake("resolution: be kinder (summon)", false, false, true, 5.0));
    }
    //green candy heart
    if ($item[green candy heart].available_amount() > 0 || $effect[Heart of Green].have_effect() > 0)
    {
        boolean have_effect = $effect[Heart of Green].have_effect() > 0;
        weight_modifiers.listAppend(TFWMInternalModifierMake("green candy heart", have_effect, true, true, 3.0));
    }
    else if ($skill[Summon Candy Hearts].have_skill() && __misc_state["bookshelf accessible"])
    {
        weight_modifiers.listAppend(TFWMInternalModifierMake("green candy heart (summon)", false, false, true, 3.0));
    }
    
    //sugar sheet, sugar shield
    if ($item[astral pet sweater].available_amount() == 0 && ($item[snow suit].available_amount() == 0 || $item[snow suit].numeric_modifier("familiar weight") < 10.0))
    {
        if ($item[sugar shield].available_amount() > 0)
            weight_modifiers.listAppend(TFWMInternalModifierMake($item[sugar shield]));
        else if ($item[sugar sheet].available_amount() > 0)
        {
            weight_modifiers.listAppend(TFWMInternalModifierMake("sugar shield (use sugar sheet)", false, true, true, 10.0, true));
        }
        else if ($skill[Summon Sugar Sheets].have_skill() && __misc_state["bookshelf accessible"])
        {
            //TFWMInternalModifier TFWMInternalModifierMake(string description, boolean have, boolean obtainable_now, boolean obtainable_theoretically, float bonus)
            weight_modifiers.listAppend(TFWMInternalModifierMake("sugar shield (summon sugar sheet)", false, false, true, 10.0, true));
        }
    }
    //ittah bittah hookah
    weight_modifiers.listAppend(TFWMInternalModifierMake($item[ittah bittah hookah]));
    //lead necklace
    weight_modifiers.listAppend(TFWMInternalModifierMake($item[lead necklace]));
    //snow suit - numeric_modifier($item[snow suit], "familiar weight")
    weight_modifiers.listAppend(TFWMInternalModifierMake($item[snow suit]));
    //astral pet sweater
    weight_modifiers.listAppend(TFWMInternalModifierMake($item[astral pet sweater]));
    
    //greaves of the whatever
    weight_modifiers.listAppend(TFWMInternalModifierMake($item[greaves of the murk lord]));
    //furry halo
    weight_modifiers.listAppend(TFWMInternalModifierMake($item[furry halo]));
    //CoT, if they have the right familiars
    if ($familiars[Animated Macaroni Duck, Autonomous Disco Ball, Barrrnacle, Gelatinous Cubeling, Ghost Pickle on a Stick, Misshapen Animal Skeleton, Pair of Ragged Claws, Penguin Goodfella, Spooky Pirate Skeleton].have_familiar_replacement())
    {
        weight_modifiers.listAppend(TFWMInternalModifierMake($item[crown of thrones]));
    }
    
    
    //Find best familiar equipment:
    TFWMInternalModifier best_familiar_equipment;
    foreach key in weight_modifiers
    {
        TFWMInternalModifier modifier = weight_modifiers[key];
        if (modifier.have && modifier.from_familiar_equipment)
        {
            if (modifier.bonus > best_familiar_equipment.bonus)
                best_familiar_equipment = modifier;
        }
    }
    
    float total = 0.0;
    foreach key in weight_modifiers
    {
        TFWMInternalModifier modifier = weight_modifiers[key];
        string description = modifier.description;
        description += " (+" + modifier.bonus.floor() + ")";
        if (modifier.have)
        {
            if (best_familiar_equipment.have && modifier.from_familiar_equipment && !TFWMInternalModifierEquals(best_familiar_equipment, modifier)) //not our chosen familiar equipment
                continue;
            how.listAppend(description);
            total += modifier.bonus;
        }
        else if (modifier.obtainable_now)
        {
            immediately_obtainable.listAppend(description);
        }
        else if (modifier.obtainable_theoretically)
        {
            missing_potentials.listAppend(description);
        }
        
    }
    missing_weight.f = MAX(0, 19 - total);
    
    if (numeric_modifier("familiar weight") >= 19.0)
        return true;
    if (total >= 19.0)
        return true;
    else
        return false;
}

boolean needMoreFamiliarWeightForTower()
{
    string [int] how;
    string [int] immediately_obtainable;
    string [int] missing_potentials;
    FloatHandle missing_weight;
    return !generateTowerFamiliarWeightMethod(how, immediately_obtainable, missing_potentials, missing_weight);
}


            
string generatePotatoSuggestion()
{
    if (familiar_is_usable($familiar[fancypants scarecrow]) && $item[swashbuckling pants].available_amount() > 0)
        return "Run swashbuckling pants on scarecrow. (2x potato)";
    else if (familiar_is_usable($familiar[fancypants scarecrow]) && $item[spangly mariachi pants].available_amount() > 0)
        return "Run spangly mariachi pants on scarecrow. (2x potato)";
    else if (familiar_is_usable($familiar[mad hatrack]) && $item[spangly sombrero].available_amount() > 0)
        return "Run spangly sombrero on mad hatrack. (2x potato)";
    else
        return "Run a potato familiar if you can.";
}


void QLevel13Init()
{
	//questL13Final
    
	QuestState state;
	QuestStateParseMafiaQuestProperty(state, "questL13Final");
    if (my_path_id() == PATH_BUGBEAR_INVASION)
        QuestStateParseMafiaQuestPropertyValue(state, "finished"); //never will start
	state.quest_name = "Naughty Sorceress Quest";
	state.image_name = "naughty sorceress lair";
	state.council_quest = true;
	//alternate idea: gate, mirror, stone mariachis, courtyard, tower... hmm, no
	
	state.state_boolean["past gates"] = (state.mafia_internal_step > 1);
	state.state_boolean["past keys"] = (state.mafia_internal_step > 3);
	state.state_boolean["past hedge maze"] = (state.mafia_internal_step > 4);
	state.state_boolean["past tower"] = (state.mafia_internal_step > 10); //5
	state.state_boolean["shadow will need to be defeated"] = !(state.mafia_internal_step < 9);
    //FIXME what paths don't fight the shadow?
    
	state.state_boolean["king waiting to be freed"] = (state.mafia_internal_step == 17);
    
    
	state.state_boolean["have relevant guitar"] = $items[acoustic guitarrr,heavy metal thunderrr guitarrr,stone banjo,Disco Banjo,Shagadelic Disco Banjo,Seeger's Unstoppable Banjo,Massive sitar,4-dimensional guitar,plastic guitar,half-sized guitar,out-of-tune biwa,Zim Merman's guitar,dueling banjo].available_amount() > 0;
    
	state.state_boolean["have relevant accordion"] = $items[stolen accordion,calavera concertina,Rock and Roll Legend,Squeezebox of the Ages,The Trickster's Trikitixa,toy accordion].available_amount() > 0;
	state.state_boolean["have relevant drum"] = $items[tambourine, big bass drum, black kettle drum, bone rattle, hippy bongo, jungle drum].available_amount() > 0;
    
    if (state.state_boolean["past keys"])
    {
        state.state_boolean["have relevant guitar"] = true;
        
        state.state_boolean["have relevant accordion"] = true;
        state.state_boolean["have relevant drum"] = true;
    }
	state.state_boolean["digital key used"] = state.state_boolean["past keys"]; //FIXME be finer-grained?
    
    boolean other_quests_completed = true;
    for i from 2 to 12
    {
        if (!__quest_state["Level " + i].finished)
            other_quests_completed = false;
    }
    if (other_quests_completed && my_level() >= 13)
        state.startable = true;
    
	
	__quest_state["Level 13"] = state;
	__quest_state["Lair"] = state;
}


void QLevel13GenerateTasks(ChecklistEntry [int] task_entries, ChecklistEntry [int] optional_task_entries, ChecklistEntry [int] future_task_entries)
{
	if (!__quest_state["Level 13"].in_progress)
		return;
	QuestState base_quest_state = __quest_state["Level 13"];
	ChecklistSubentry subentry;
	subentry.header = base_quest_state.quest_name;
    string url = "lair.php";
	
	string image_name = base_quest_state.image_name;
    
	boolean should_output_main_entry = true;
	if (base_quest_state.mafia_internal_step == 1)
	{
		//at three gates
		subentry.entries.listAppend("At three gates.");
        if (__misc_state["can use clovers"] && (availableDrunkenness() >= 3 || inebriety_limit() == 0))
        {
            //FIXME be better
            if ($items[large box,blessed large box].available_amount() == 0 && $items[bubbly potion,cloudy potion,dark potion,effervescent potion,fizzy potion,milky potion,murky potion,smoky potion,swirly potion].items_missing().count() > 0)
            {
                if (in_hardcore())
                    subentry.entries.listAppend("For potions, acquire a large box (fax, dungeons of doom) and meatpaste with a clover.");
                else
                    subentry.entries.listAppend("For potions, pull a large box and meatpaste with a clover.");
            }
        }
        else
            subentry.entries.listAppend("For potions, visit the dungeons of doom.");
        url = "lair1.php";
	}
	else if (base_quest_state.mafia_internal_step == 2)
	{
		//past three gates, at mirror
		subentry.entries.listAppend("At mirror.");
        url = "lair1.php";
	}
	else if (base_quest_state.mafia_internal_step == 3)
	{
		//past mirror, at six keys
		subentry.entries.listAppend("Six keys.");
        url = "lair2.php";
	}
	else if (base_quest_state.mafia_internal_step == 4)
	{
        url = "lair3.php";
		//at hedge maze
		subentry.modifiers.listAppend("+67% item");
		subentry.entries.listAppend("Hedge maze. Find puzzles.");
		if (item_drop_modifier() < 66.666666667)
			subentry.entries.listAppend("Need more +item.");
        if ($item[hedge maze key].available_amount() == 0)
			subentry.entries.listAppend("Find the key.");
        else
			subentry.entries.listAppend("Find the way out.");
            
            
        monster pickpocket_monster = $monster[Topiary Golem];
        if (__misc_state["can pickpocket"] && pickpocket_monster != $monster[none])
        {
            int total_initiative_needed = pickpocket_monster.base_initiative;
            int initiative_needed = total_initiative_needed - initiative_modifier();
            if (initiative_needed > 0)
                subentry.entries.listAppend("Need " + initiative_needed + "% more initiative to pickpocket every turn.");
        }
		
	}
	else if (base_quest_state.mafia_internal_step > 4 && base_quest_state.mafia_internal_step < 11)
	{
        //step4 through step9 - 5 - 10
		//at tower, time to kill monsters!
        
        
        int level = -1;
        
        if (base_quest_state.mafia_internal_step == 5)
            level = 1;
        else if (base_quest_state.mafia_internal_step == 6)
            level = 2;
        else if (base_quest_state.mafia_internal_step == 7)
            level = 3;
        else if (base_quest_state.mafia_internal_step == 8)
            level = 4;
        else if (base_quest_state.mafia_internal_step == 9)
            level = 5;
        else if (base_quest_state.mafia_internal_step == 10)
            level = 6;
        
        boolean output_tower_killing_ideas = false;
        item monster_item = __misc_state_string["Tower monster item " + level].to_item();
        
        subentry.entries.listAppend("Tower monster on floor " + level + ".");
        if (monster_item != $item[none])
        {
            if (monster_item.available_amount() > 0)
                subentry.entries.listAppend("Use " + HTMLGenerateSpanOfClass(monster_item, "r_bold") + ".");
            else
            {
                subentry.entries.listAppend(HTMLGenerateSpanFont("Need " + HTMLGenerateSpanOfClass(monster_item, "r_bold") + ".", "red", ""));
                output_tower_killing_ideas = true;
            }
        }
        else
        {
            subentry.entries.listAppend(HTMLGenerateSpanFont("Need unknown item.", "red", ""));
            output_tower_killing_ideas = true;
        }
        
        if (output_tower_killing_ideas)
        {
            string [int] tower_killing_ideas;
            
            if (my_path_id() == PATH_HEAVY_RAINS && $skill[thunder bird].have_skill() && my_thunder() >= 5 && $skill[curse of weaksauce].have_skill())
            {
                string [int] line;
                if ($skill[itchy curse finger].have_skill())
                {
                    line.listAppend("cast curse of weaksauce");
                    line.listAppend("cast a stun");
                }
                else
                {
                    line.listAppend("cast a stun");
                    line.listAppend("cast curse of weaksauce");
                }
                line.listAppend("cast thunder bird/stun/staggers repeatedly under defense is below zero");
                line.listAppend("attack");
                tower_killing_ideas.listAppend(line.listJoinComponents(", ", "then").capitalizeFirstLetter());
            }
            else if ($skill[curse of weaksauce].have_skill() && $item[crayon shavings].available_amount() >= 2) //currently disabled because while it'll work in theory, I haven't tested it
            {
                string [int] line;
                if ($skill[itchy curse finger].have_skill())
                {
                    line.listAppend("cast curse of weaksauce");
                    line.listAppend("cast a stun");
                }
                else
                {
                    line.listAppend("cast a stun");
                    line.listAppend("cast curse of weaksauce");
                }
                line.listAppend("throw two crayon shavings");
                line.listAppend("stagger/stun until defense is below zero");
                
                line.listAppend("attack");
                tower_killing_ideas.listAppend(line.listJoinComponents(", ", "then").capitalizeFirstLetter());
            }
            
            //Familiar sources:
            if (!__misc_state["familiars temporarily blocked"])
            {
                string potato_suggestion = generatePotatoSuggestion();
                tower_killing_ideas.listAppend(potato_suggestion);
                
                
                //Bjorn:
                if ($familiar[mariachi chihuahua].have_familiar())
                {
                    if ($item[buddy bjorn].available_amount() > 0)
                    {
                        if (my_bjorned_familiar() != $familiar[mariachi chihuahua])
                            tower_killing_ideas.listAppend("Put your mariachi chihuahua in your buddy bjorn. (50% stagger)");
                    }
                    else if ($item[crown of thrones].available_amount() > 0)
                    {
                        if (my_enthroned_familiar() != $familiar[mariachi chihuahua])
                            tower_killing_ideas.listAppend("Put your mariachi chihuahua in your crown of thrones. (50% stagger)");
                    }
                }
            }
            
            if ($item[attorney's badge].available_amount() > 0 && $item[attorney's badge].equipped_amount() == 0)
                tower_killing_ideas.listAppend("Could equip attorney's badge for more blocking.");
            if ($item[navel ring of navel gazing].available_amount() > 0 && $item[navel ring of navel gazing].equipped_amount() == 0)
                tower_killing_ideas.listAppend("Could equip navel ring of navel gazing for more blocking.");
                
                
            
            string [int] stun_sources;
            string [int] stagger_sources;
            
            
            //Stun/stagger sources:
            //(this is not a comprehensive list)
            //√shadow noodles, √thunderstrike, √soul bubble
            //√potato, √bjorned chihuahua, √attorney's badge, √navel ring
            
            //√ply reality, √entangling noodles as not-pastamancer, √pantsgiving 2x, √deft hands, DNA...?, √3x disco dances...
            //√airblaster gun
            //√club foot IF seal clubber
            //√Break It On Down
            //√gob of wet hair, √gyroscope, √macrame net, √ornate picture frame, √palm-frond net(?), √Rain-Doh indigo cup, √superamplified boom box, √Throw Shield (OPS), √tongue depressor
            
            //√gas balloon, √brick of sand(?), √chloroform rag, naughty paper shuriken, √sausage bomb, √floorboard cruft
            //√dumb mud will insta if available
            //√finger cuffs (support acquiring)
            //√Rain-Doh blue balls
            //√CSA obedience grenade, √The Lost Comb
            //Accordion Bash if AT wearing an accordion FIXME do that
            //Shell Up(?)
            //sooooooul finger? does it work? 40 saucery...
            
            if ($item[Game Grid ticket].item_amount() > 0 && $item[Game Grid ticket].is_unrestricted())
                tower_killing_ideas.listAppend("Could acquire " + $item[Game Grid ticket].item_amount() + " finger cuffs. (stun)");
            if ($skill[shadow noodles].have_skill())
                stun_sources.listAppend("shadow noodles");
            if ($skill[thunderstrike].have_skill())
                stun_sources.listAppend("thunderstrike");
            if ($skill[soul saucery].have_skill() && my_class() == $class[sauceror])
                stun_sources.listAppend("soul bubble");
                
            foreach it in $items[gas balloon,brick of sand,chloroform rag,sausage bomb,floorboard cruft,finger cuffs,CSA obedience grenade,The Lost Comb]
            {
                if (it.item_amount() == 0 || !it.is_unrestricted())
                    continue;
                stun_sources.listAppend(it.pluralizeWordy());
            }
            if ($item[naughty paper shuriken].available_amount() > 0)
                stun_sources.listAppend("naughty paper shuriken");
            if ($item[Rain-Doh blue balls].available_amount() > 0)
                stun_sources.listAppend("Rain-Doh blue balls");
            
            if ($item[thor's pliers].equipped_amount() > 0)
                stagger_sources.listAppend("ply reality");
            if (my_class() != $class[pastamancer] && $skill[entangling noodles].have_skill())
                stagger_sources.listAppend("entangling noodles");
            if ($item[pantsgiving].equipped_amount() > 0)
            {
                stagger_sources.listAppend("pocket crumbs");
                stagger_sources.listAppend("air dirty laundry");
            }
            if (my_class() == $class[disco bandit] && $skill[deft hands].have_skill())
                stagger_sources.listAppend("first combat item thrown");
            if (my_class() == $class[disco bandit] && $skill[Disco State of Mind].have_skill() && $skill[Flashy Dancer].have_skill())
            {
                if ($skill[disco dance of doom].have_skill())
                    stagger_sources.listAppend("disco dance");
                if ($skill[Disco Dance II: Electric Boogaloo].have_skill())
                    stagger_sources.listAppend("disco dance II");
                if ($skill[Disco Dance 3: Back in the Habit].have_skill())
                    stagger_sources.listAppend("disco dance 3");
            }
            if ($item[airblaster gun].equipped_amount() > 0)
                stagger_sources.listAppend("air blast");
            //FIXME not implemented because need to test for a club, plus it takes up fury
            //if (my_class() == $class[seal clubber] && $skill[club foot].have_skill())
                //stagger_sources.listAppend("");
            if ($skill[Break It On Down].have_skill())
                stagger_sources.listAppend("break it on down");
            
            foreach it in $items[gob of wet hair,gyroscope,macrame net,ornate picture frame,palm-frond net,superamplified boom box]
            {
                if (it.item_amount() == 0 || !it.is_unrestricted())
                    continue;
                stagger_sources.listAppend(it.pluralizeWordy());
            }
            if ($item[operation patriot shield].equipped_amount() > 0)
                stagger_sources.listAppend("throw shield");
            if ($item[Rain-Doh indigo cup].available_amount() > 0)
                stagger_sources.listAppend("Rain-Doh indigo cup");
            if ($item[tongue depressor].available_amount() > 0)
                stagger_sources.listAppend("tongue depressor");
                
            if (stun_sources.count() > 0)
                tower_killing_ideas.listAppend("Stuns: " + stun_sources.listJoinComponents(", ", "and"));
            if (stagger_sources.count() > 0)
                tower_killing_ideas.listAppend("Stagger sources: " + stagger_sources.listJoinComponents(", ", "and"));
            
            
            
            
            if ($item[small golem].available_amount() > 0)
            {
                if ($skill[Ambidextrous Funkslinging].have_skill() && $item[slime stack].available_amount() > 0)
                    tower_killing_ideas.listAppend("Small golem available. Funksling early in combat with a slime stack for 3k damage/round.");
                else
                    tower_killing_ideas.listAppend("Small golem available. Use early in combat for 3k damage/round.");
            }
            if ($item[slime stack].available_amount() > 0)
                tower_killing_ideas.listAppend($item[slime stack].pluralize() + " available. (15% damage)");
                
            if ($skill[frigidalmatian].have_skill() && my_maxmp() >= 300 && $effect[Frigidalmatian].have_effect() == 0)
                tower_killing_ideas.listAppend("Possibly cast Frigidalmatian.");
                
            if (monster_level_adjustment() > 0)
                tower_killing_ideas.listAppend(HTMLGenerateSpanFont("Try to reduce your ML", "red", "") + ", as it reduces damage done to them.");
                
            if ((my_path_id() == PATH_HEAVY_RAINS || $item[water wings for babies].available_amount() >= 3) && $item[water wings for babies].equipped_amount() <3)
                tower_killing_ideas.listAppend("Equip three water wings for babies to reduce ML. (increased damage)");
            
            if (tower_killing_ideas.count() > 0)
                subentry.entries.listAppend("Or towerkill (very difficult):" + HTMLGenerateIndentedText(tower_killing_ideas.listJoinComponents("<hr>")));
            else
                subentry.entries.listAppend("Or towerkill.");
                
            if ($item[dumb mud].available_amount() > 0)
                subentry.entries.listAppend("Or just use dumb mud, which will insta-kill a tower monster.");
        }
            
        if (level <= 3)
            url = "lair4.php";
        else
            url = "lair5.php";
	}
	else if (base_quest_state.mafia_internal_step == 11 || base_quest_state.mafia_internal_step == 12)
	{
        url = "lair6.php";
		//past tower, at some sort of door code
		subentry.entries.listAppend("Puzzles.");
		subentry.entries.listAppend("Have mafia do it: Quests" + __html_right_arrow_character + "Tower (to shadow)");
	}
	else if (base_quest_state.mafia_internal_step == 13)
	{
        url = "lair6.php";
		//at top of tower (fight shadow??)
		//8 -> fight shadow
        int total_initiative_needed = $monster[Your Shadow].monster_initiative();
		subentry.modifiers.listAppend("+HP");
		subentry.modifiers.listAppend("+" + total_initiative_needed + "% init");
		subentry.entries.listAppend("Fight your shadow.");
        foreach it in $items[attorney's badge, navel ring of navel gazing]
        {
            if (it.available_amount() > 0 && it.equipped_amount() == 0)
                subentry.entries.listAppend("Possibly equip your " + it + ". (blocks shadow)");
        }
        
        string [int] healing_items_available;
        foreach it in $items[filthy poultice,gauze garter,red pixel potion,Dreadsylvanian seed pod,soggy used band-aid,Mer-kin healscroll,scented massage oil,extra-strength red potion,red potion]
        {
            if (it.available_amount() == 0)
                continue;
            if (it.available_amount() == 1)
                healing_items_available.listAppend(it.to_string());
            else
                healing_items_available.listAppend(it.pluralize());
        }
        if (healing_items_available.count() > 0)
            subentry.entries.listAppend("Healing items available: " + healing_items_available.listJoinComponents(", ", "and") + ".");
        else
            subentry.entries.listAppend("May want to go find some healing items.");
            
            
        int initiative_needed = total_initiative_needed - initiative_modifier();
        if (initiative_needed > 0 && !$skill[Ambidextrous Funkslinging].have_skill())
            subentry.entries.listAppend("Need " + initiative_needed + "% more initiative.");
	}
	else if (base_quest_state.mafia_internal_step == 14 || base_quest_state.mafia_internal_step == 15)
	{
        url = "lair6.php";
		//counter familiars
        
        if (!__misc_state["familiars temporarily blocked"])
        {
            subentry.modifiers.listAppend("+familiar weight");
            subentry.entries.listAppend("Counter familiars. Need 20-pound familiars.");
            subentry.entries.listAppend("Have mafia do it: Quests" + __html_right_arrow_character + "Tower (complete)");
            familiar [int] missing_familiars;
            foreach f in $familiars[Mosquito,Angry Goat,Barrrnacle,Sabre-Toothed Lime,Levitating Potato]
            {
                if (f.have_familiar_replacement())
                    continue;
                missing_familiars.listAppend(f);
            }
            if (missing_familiars.count() > 0)
            {
                string [item] where_to_find_hatchlings;
                where_to_find_hatchlings[$item[mosquito larva]] = "Spooky forest."; //should have it
                where_to_find_hatchlings[$item[goat]] = "Combine goat cheese (goatlet, dairy goat, 40% drop) with anti-cheese from the atomic testing house in the desert beach.";
                where_to_find_hatchlings[$item[barrrnacle]] = "Find from a crusty pirate in the f'c'le. (15% drop)";
                where_to_find_hatchlings[$item[sabre-toothed lime cub]] = "Combine saber teeth (goatlet, sabre-toothed goat, 5% drop, or stone age hippy camp, 20% drop) with a lime. (Menagerie level 1, fruit golem, 15% drop)";
                where_to_find_hatchlings[$item[potato sprout]] = "Complete the daily dungeon, visit vending machine.";
                if (in_bad_moon())
                    where_to_find_hatchlings[$item[potato sprout]] += " Alternatively, adventure in the haunted conservatory.";
                    
                string [int] missing_description;
                foreach key in missing_familiars
                {
                    familiar f = missing_familiars[key];
                    
                    string line;
                    if (missing_description.count() > 0)
                        line += "<hr>";
                    line += f.hatchling.capitalizeFirstLetter();
                    if (f.hatchling.available_amount() > 0)
                    {
                        line += "|*Use your " + f.hatchling + ".";
                    }
                    else
                    {
                        line += "|*" + where_to_find_hatchlings[f.hatchling];
                    }
                    missing_description.listAppend(line);
                }
                subentry.entries.listAppend("Missing familiars: " + HTMLGenerateIndentedText(missing_description));
            }
            
            FloatHandle missing_weight;
            string [int] familiar_weight_how;
            string [int] familiar_weight_immediately_obtainable;
            string [int] familiar_weight_missing_potentials;
            boolean have_familiar_weight_for_tower = generateTowerFamiliarWeightMethod(familiar_weight_how, familiar_weight_immediately_obtainable, familiar_weight_missing_potentials,missing_weight);
            if (!have_familiar_weight_for_tower)
            {
                string [int] description;
                description.listAppend("Need +" + missing_weight.f.floor() + " familiar weight.");
                if (familiar_weight_how.count() > 0)
                    description.listAppend("Have " + familiar_weight_how.listJoinComponents(", ", "and") + ".");
                if (familiar_weight_immediately_obtainable.count() > 0)
                    description.listAppend("Could use " + familiar_weight_immediately_obtainable.listJoinComponents(", ", "and") + ".");
                if (familiar_weight_missing_potentials.count() > 0 && missing_weight.f > 0.0)
                    description.listAppend("Could acquire " + familiar_weight_missing_potentials.listJoinComponents(", ", "or") + ".");
                
                subentry.entries.listAppend(description.listJoinComponents("|*"));
            }
        }
        else
            subentry.entries.listAppend("Counter familiars.");
	}
	else if (base_quest_state.mafia_internal_step == 16)
	{
        url = "lair6.php";
		//At NS. Good luck, we're all counting on you.
        if (my_path_id() != PATH_HEAVY_RAINS)
        {
            subentry.modifiers.listAppend("+moxie equipment");
            subentry.modifiers.listAppend("no buffs");
        }
		subentry.entries.listAppend("She awaits.");
        if (!__misc_state["familiars temporarily blocked"] && my_path_id() != PATH_HEAVY_RAINS)
        {
            string potato_suggestion = generatePotatoSuggestion();
            
            subentry.entries.listAppend(potato_suggestion);
        }
        
        if (my_path_id() == PATH_HEAVY_RAINS)
        {
            subentry.modifiers.listAppend("many buffs");
            if ($familiar[warbear drone].have_familiar())
                subentry.entries.listAppend("Run a warbear drone if you can.");
                
            subentry.entries.listAppend("Try to run as many buffs as you can. (one removed per round, have " + my_effects().count() + ")");
            subentry.entries.listAppend("Try to have as many damage sources as possible. (40? damage cap per source)");
            subentry.entries.listAppend("Only your weapon, offhand, and familiar equipment(?) are relevant this fight.");
            if ($item[crayon shavings].available_amount() > 0)
                subentry.entries.listAppend("Try repeatedly using crayon shavings?");
            if ($skill[frigidalmatian].have_skill() && my_maxmp() >= 300 && $effect[Frigidalmatian].have_effect() == 0)
                subentry.entries.listAppend("Try casting Frigidalmatian.");
        }
        
		image_name = "naughty sorceress";
	}
	else if (base_quest_state.mafia_internal_step == 17)
	{
        url = "lair6.php";
		//King is waiting in his prism.
        
        boolean trophies_are_possible = false;
        
        //ehh, disable displaying this, mostly because it's in the way
        //if (in_hardcore())
            //trophies_are_possible = true; //Gourdcore, Golden Meat Stack
        
        if (trophies_are_possible)
            task_entries.listAppend(ChecklistEntryMake("__item puzzling trophy", "trophy.php", ChecklistSubentryMake("Check for trophies", "10k meat, trophy requirements", "Certain trophies are missable after freeing the king")));
		should_output_main_entry = false;
        
        
        if (my_path_id() == PATH_AVATAR_OF_SNEAKY_PETE)
        {
            if (availableDrunkenness() > 0)
            {
                task_entries.listAppend(ChecklistEntryMake("__item gibson", "inventory.php?which=1", ChecklistSubentryMake("Drink " + availableDrunkenness() + " drunkenness", "", "Freeing the king reduces your liver capacity.")));
            }
        }
        
        if (my_path_id() == PATH_HEAVY_RAINS)
        {
            if ($skill[rain dance].have_skill() && my_rain() >= 10)
            {
                int times = floor(my_rain().to_float() / 10.0);
                task_entries.listAppend(ChecklistEntryMake("__effect Rain Dancin'", "skills.php", ChecklistSubentryMake("Cast Rain Dance " + pluralizeWordy(times, "time", "times"), "", "+20% item buff for aftercore.")));
            }
        }
		
	}
	if (should_output_main_entry)
		task_entries.listAppend(ChecklistEntryMake(image_name, url, subentry));
}