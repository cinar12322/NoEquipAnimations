using BepInEx.Configuration;
using UnityEngine;

namespace NoEquipAnimation
{
    public static class ModConfig
    {
        public static ConfigEntry<bool> DisableWeaponEquipAnimation;
        public static ConfigEntry<bool> DisableArmEquipAnimation;
        public static ConfigEntry<KeyCode> ToggleKey;

        public static void Initialize(ConfigFile config)
        {
            DisableWeaponEquipAnimation = config.Bind(
                "General",
                "DisableWeaponEquipAnimation",
                true,
                "Disable drawing/equip animations for weapons (guns)."
            );

            DisableArmEquipAnimation = config.Bind(
                "General",
                "DisableArmEquipAnimation",
                true,
                "Disable drawing/equip animations for arms/fists."
            );

            ToggleKey = config.Bind(
                "Controls",
                "ToggleKey",
                KeyCode.H,
                "Key to toggle disabling equip animations in-game."
            );

#if PLUGIN_CONFIGURATOR
            InitializePluginConfigurator();
#endif
        }

#if PLUGIN_CONFIGURATOR
        private static void InitializePluginConfigurator()
        {
            try
            {
                var configurator = PluginConfig.API.PluginConfigurator.Create("No Equip Animations", "com.antigravity.noequipanimation");

                // Başlangıç değerlerini BepInEx config'den al
                var weaponToggle = new PluginConfig.API.Fields.BoolField(
                    configurator.rootPanel,
                    "Disable Weapon Animations",
                    "disable_weapon_anims",
                    DisableWeaponEquipAnimation.Value
                );
                weaponToggle.onValueChange += (e) =>
                {
                    DisableWeaponEquipAnimation.Value = e.value;
                };

                var armToggle = new PluginConfig.API.Fields.BoolField(
                    configurator.rootPanel,
                    "Disable Arm/Punch Animations",
                    "disable_arm_anims",
                    DisableArmEquipAnimation.Value
                );
                armToggle.onValueChange += (e) =>
                {
                    DisableArmEquipAnimation.Value = e.value;
                };

                var keyBind = new PluginConfig.API.Fields.KeyCodeField(
                    configurator.rootPanel,
                    "Toggle Mod Key (H = varsayılan)",
                    "toggle_key",
                    ToggleKey.Value
                );
                keyBind.onValueChange += (e) =>
                {
                    ToggleKey.Value = e.value;
                };
            }
            catch (System.Exception ex)
            {
                Debug.LogError($"[NoEquipAnimation] Failed to initialize PluginConfigurator: {ex}");
            }
        }
#endif
    }
}
