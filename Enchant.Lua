repeat task.wait() until getgenv().Window
local Window = getgenv().Window

local EnchantTab = Window:CreateTab("Enchant", nil)

local function RunEnchant(primary, secondary, item1, item2)
    getgenv().Settings = {
        Enchanting = {
            Enabled = true,
            PRIMARY_ENCHANTS = primary,
            SECONDARY_ENCHANTS = secondary,
            FIRST_SLOT_ITEM_TO_USE = item1,
            SECOND_SLOT_ITEM_TO_USE = item2,
            AUTO_SWITCH_TO_ORBS = true,
            PRIORITIZE_PRIMARY = true
        }
    }

    loadstring(game:HttpGet("https://raw.githubusercontent.com/issascripts/bgsi/refs/heads/main/coolestautoenchantintown.lua"))()
end

-- ======================================
-- AUTO ENCHANT
-- ======================================
EnchantTab:CreateSection("Auto Enchant")

EnchantTab:CreateButton({
    Name = "Secret Hunter + Ultra Roller",
    Callback = function()
        RunEnchant(
            {"Secret Hunter","Ultra Roller"},
            {"Secret Hunter","Ultra Roller"},
            "Shadow Crystal",
            "Shadow Crystal"
        )
    end
})

EnchantTab:CreateButton({
    Name = "Ultra Roller + High Roller",
    Callback = function()
        RunEnchant(
            {"High Roller","Ultra Roller"},
            {"High Roller","Ultra Roller"},
            "Shadow Crystal",
            "Gems"
        )
    end
})

EnchantTab:CreateButton({
    Name = "Shiny Seeker + Ultra Roller",
    Callback = function()
        RunEnchant(
            {"Shiny Seeker","Ultra Roller"},
            {"Shiny Seeker","Ultra Roller"},
            "Shadow Crystal",
            "Shadow Crystal"
        )
    end
})

-- ======================================
-- BUBBLER ENCHANTER
-- ======================================
EnchantTab:CreateSection("Bubbler Enchanter")

EnchantTab:CreateButton({
    Name = "Team Up V + Bubbler V",
    Callback = function()
        RunEnchant(
            {"Team Up V","Bubbler V"},
            {"Team Up V","Bubbler V"},
            "Gems",
            "Gems"
        )
    end
})

EnchantTab:CreateButton({
    Name = "Determination + Bubbler V",
    Callback = function()
        RunEnchant(
            {"Determination","Bubbler V"},
            {"Determination","Bubbler V"},
            "Shadow Crystal",
            "Gems"
        )
    end
})

-- ======================================
-- CURRENCY ENCHANTER
-- ======================================
EnchantTab:CreateSection("Currency Enchanter")

EnchantTab:CreateButton({
    Name = "Team Up V + Looter V",
    Callback = function()
        RunEnchant(
            {"Team Up V","Looter V"},
            {"Team Up V","Looter V"},
            "Gems",
            "Gems"
        )
    end
})

EnchantTab:CreateButton({
    Name = "Determination + Looter V",
    Callback = function()
        RunEnchant(
            {"Determination","Looter V"},
            {"Determination","Looter V"},
            "Shadow Crystal",
            "Gems"
        )
    end
})
