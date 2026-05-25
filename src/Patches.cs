using HarmonyLib;
using UnityEngine;

namespace NoEquipAnimation
{
    public static class Patches
    {
        // Silahlar için postfix (isArm = false)
        public static void WeaponOnEnablePostfix(MonoBehaviour __instance)
        {
            EnsureFastDraw(__instance.gameObject, false);
        }

        // Kol/yumruk için postfix (isArm = true)
        public static void ArmOnEnablePostfix(MonoBehaviour __instance)
        {
            EnsureFastDraw(__instance.gameObject, true);
        }

        private static void EnsureFastDraw(GameObject go, bool isArm)
        {
            if (go == null) return;

            var fastDraw = go.GetComponent<FastDrawComponent>();
            if (fastDraw == null)
            {
                fastDraw = go.AddComponent<FastDrawComponent>();
                fastDraw.Initialize(isArm);
                Debug.Log($"[NoEquipAnimation] FastDrawComponent eklendi: {go.name} (kol: {isArm})");
            }
        }
    }
}
