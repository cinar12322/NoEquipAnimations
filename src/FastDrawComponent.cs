using UnityEngine;

namespace NoEquipAnimation
{
    public class FastDrawComponent : MonoBehaviour
    {
        private Animator animator;
        private float originalSpeed = 1f;
        private int framesToFast = 0;
        private bool isArm = false;

        public void Initialize(bool isArmComponent)
        {
            isArm = isArmComponent;
        }

        void Awake()
        {
            animator = GetComponentInChildren<Animator>();
        }

        void OnEnable()
        {
            if (animator == null)
            {
                animator = GetComponentInChildren<Animator>();
            }

            if (animator != null)
            {
                originalSpeed = animator.speed;
                
                // Determine whether we should speed up based on config
                bool shouldDisable = isArm ? ModConfig.DisableArmEquipAnimation.Value : ModConfig.DisableWeaponEquipAnimation.Value;

                if (shouldDisable)
                {
                    animator.speed = 1000f;
                    framesToFast = 2; // Speed up for 2 frames to let the animation tick instantly and transition
                }
            }
        }

        void Update()
        {
            if (animator != null && framesToFast > 0)
            {
                framesToFast--;
                if (framesToFast == 0)
                {
                    animator.speed = originalSpeed;
                }
            }
        }
    }
}
