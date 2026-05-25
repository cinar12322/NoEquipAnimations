using BepInEx;
using HarmonyLib;
using UnityEngine;

namespace NoEquipAnimation
{
    [BepInPlugin("com.antigravity.noequipanimation", "No Equip Animations", "1.0.0")]
    public class Plugin : BaseUnityPlugin
    {
        private Harmony harmony;

        private void Awake()
        {
            Logger.LogInfo("Initializing ULTRAKILL No Equip Animations mod...");

            // Initialize Configuration
            ModConfig.Initialize(Config);

            // Harmony'yi başlat ama patch'leri tek tek güvenli şekilde uygula
            harmony = new Harmony("com.antigravity.noequipanimation");
            ApplyPatchesSafely();

            Logger.LogInfo("ULTRAKILL No Equip Animations mod initialized!");
        }

        private void ApplyPatchesSafely()
        {
            // Her silah tipi için güvenli patch — bulunamazsa uyarı ver, crash etme
            TryPatch(typeof(Revolver), "OnEnable", nameof(Patches.WeaponOnEnablePostfix), false);
            TryPatch(typeof(Shotgun), "OnEnable", nameof(Patches.WeaponOnEnablePostfix), false);
            TryPatch(typeof(Nailgun), "OnEnable", nameof(Patches.WeaponOnEnablePostfix), false);
            TryPatch(typeof(Railcannon), "OnEnable", nameof(Patches.WeaponOnEnablePostfix), false);
            TryPatch(typeof(RocketLauncher), "OnEnable", nameof(Patches.WeaponOnEnablePostfix), false);
            TryPatch(typeof(Punch), "OnEnable", nameof(Patches.ArmOnEnablePostfix), true);
        }

        private void TryPatch(System.Type targetType, string methodName, string postfixName, bool isArm)
        {
            try
            {
                var original = AccessTools.Method(targetType, methodName);
                if (original == null)
                {
                    Logger.LogWarning($"[NoEquipAnimation] {targetType.Name}.{methodName} bulunamadı, atlanıyor.");
                    return;
                }

                var postfix = isArm
                    ? new HarmonyMethod(typeof(Patches), nameof(Patches.ArmOnEnablePostfix))
                    : new HarmonyMethod(typeof(Patches), nameof(Patches.WeaponOnEnablePostfix));

                harmony.Patch(original, postfix: postfix);
                Logger.LogInfo($"[NoEquipAnimation] {targetType.Name}.{methodName} patch edildi.");
            }
            catch (System.Exception ex)
            {
                Logger.LogWarning($"[NoEquipAnimation] {targetType.Name}.{methodName} patch başarısız: {ex.Message}");
            }
        }

        private void Update()
        {
            if (Input.GetKeyDown(ModConfig.ToggleKey.Value))
            {
                bool nextValue = !ModConfig.DisableWeaponEquipAnimation.Value;
                ModConfig.DisableWeaponEquipAnimation.Value = nextValue;
                ModConfig.DisableArmEquipAnimation.Value = nextValue;
                Config.Save();

                // nextValue=true → animasyon KAPALI (kırmızı), false → animasyon AÇIK (yeşil)
                string status = nextValue ? "<color=red>KAPALI</color>" : "<color=lime>AÇIK</color>";
                Logger.LogInfo($"Equip animasyonları: {(nextValue ? "Kapalı" : "Açık")}");

                try
                {
                    if (MonoSingleton<HudMessageReceiver>.Instance != null)
                        MonoSingleton<HudMessageReceiver>.Instance.SendHudMessage($"Equip Animasyonu: {status}", "", "", 0, false);
                }
                catch { }
            }
        }

        private void OnDestroy()
        {
            harmony?.UnpatchSelf();
        }
    }
}
