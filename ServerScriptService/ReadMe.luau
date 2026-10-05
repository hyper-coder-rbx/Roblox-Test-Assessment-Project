
--Read Me file

--[[

Author: Dilpreet Singh
Date: 05-10-2026

----------------------------------------------------------------------------------------------
 ^^^^^^^^^^^^^&&&&&&& Usage Pattern updates for this project &&&&&&&^^^^^^^^^^^^^^^^^^^^^^:-
----------------------------------------------------------------------------------------------

Your overall approach:
    - Used new Server Authority model, instead of classic network ownership.
    - Now it is exploit safe as Roblox defines. Prevents: Fly hacks, speed hacks, position hacks, etc.
    - Used new IAS (Input Action System), instead of classic UIS / CAS.
    - Inputs are directly listen on server. No client side dependency (workable for this scope)
    - Used Knit Framework as the codebase architecture.
    - Used tools: Roblox Studio, a bit AI, only. 
    - Whole code is sole written by me (Dilpreet Singh).
    
○ What you completed
    - Multiplayer Arena: PvP only, highest xp earned player wins.
    - Loot System: Total 4 collectibles: DashZeroCooldown, SpeedBoost, Landmine, Collectible.
    - Ability System: Dash uses cooldown (configurable in ReplicatedStorage.Shared.Constants)
    - Basic UI: Basic implementation of MatchUI, ControlsUI & MatchResultUI.
    
○ What you did not complete
    Everything listed in the assessment is completed with the options available.
    
○ What you would improve if you had more time
    - Fix any of remaining corner cases / bugs.
    - Add more VFX, SFX, UI animations.
    - Design lobby & arena more better (upto a mark as being developer)
    - More UI, Fun elements, new abilities, collectables, etc.
    
○ Any setup or run instructions, if needed
    - Nothing special, only max players limited to 15 for now.
    - Key elements to consider: 
        - One match at a time (only enrolled players goes to arena map).
        - Configurations are placed inside ServerStorage.Configs
        - You can change the configurations as you want.
        
    - Run the game, play it, enjoy.


If you have any question regarding the code, architecture, etc.
Please feel free to contact.

Thanks & Regards

~ Built with code, shipped with care ~

]]


return "Dev's Read Me"
