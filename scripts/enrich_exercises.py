#!/usr/bin/env python3
"""
Enriches exercises_def.json with aliases and descriptions.
Only adds data to exercises that are missing it — safe to re-run.
"""

import json, os

JSON_PATH = os.path.join(os.path.dirname(__file__), "../Exercis/Resources/exercises_def.json")

ENRICHMENT = {
    # ── BICEPS ───────────────────────────────────────────────────────────────
    "wger_biceps_curls_with_barbell": {
        "aliases": ["Barbell Curl", "BB Curl", "Standing Barbell Curl"],
        "description": "Stand holding a barbell with an underhand grip, arms fully extended. Curl the bar toward your shoulders by flexing the elbows, keeping your upper arms stationary. Lower under control back to the start."
    },
    "wger_biceps_curls_with_szbar": {
        "aliases": ["EZ Bar Curl", "EZ-Bar Bicep Curl", "Curl Bar Curl"],
        "description": "Hold an EZ-bar at the angled grip positions with an underhand grip. Curl the bar toward your chin while keeping your elbows fixed at your sides. Return slowly to the starting position."
    },
    "wger_biceps_curls_with_dumbbell": {
        "aliases": ["Dumbbell Curl", "DB Curl", "Alternating Dumbbell Curl"],
        "description": "Stand or sit holding a dumbbell in each hand with arms fully extended. Curl one or both dumbbells upward by flexing the elbow, rotating the wrist to a supinated position at the top. Lower with control."
    },
    "wger_hammercurls": {
        "aliases": ["Hammer Curl", "Neutral Grip Curl", "DB Hammer Curl"],
        "description": "Hold dumbbells at your sides with a neutral grip, thumbs pointing forward. Curl the dumbbells upward without rotating your wrists, keeping the neutral grip throughout. Lower under control."
    },
    "wger_hammercurls_on_cable": {
        "aliases": ["Cable Hammer Curl", "Rope Hammer Curl"],
        "description": "Attach a rope to a low pulley cable. Stand facing the machine and curl the rope upward with a neutral grip, keeping elbows at your sides. Squeeze at the top and lower with control."
    },
    "wger_dumbbells_on_scott_machine": {
        "aliases": ["Dumbbell Preacher Curl", "Scott Curl Dumbbell"],
        "description": "Sit at a preacher bench and rest the back of your upper arm on the pad. Curl the dumbbell upward until fully flexed, then lower slowly back to full extension."
    },
    "wger_preacher_curls": {
        "aliases": ["Preacher Curl", "Scott Curl", "EZ Bar Preacher Curl"],
        "description": "Rest the back of your upper arms on a preacher bench pad while gripping a barbell or EZ-bar. Curl the weight upward to full flexion, then lower slowly to full extension without letting the arms go slack."
    },
    "wger_singlearm_preacher_curl": {
        "aliases": ["One-Arm Preacher Curl", "Single Arm Scott Curl"],
        "description": "Rest the back of one upper arm on the preacher pad and hold a dumbbell. Curl the weight up to full flexion and lower slowly, working each arm independently."
    },
    "wger_dumbbell_concentration_curl": {
        "aliases": ["Concentration Curl", "Seated Concentration Curl"],
        "description": "Sit on a bench with your legs apart, bracing your elbow against the inside of your thigh. Curl the dumbbell up toward your shoulder, then lower under control."
    },
    "wger_biceps_curl_with_cable": {
        "aliases": ["Cable Curl", "Cable Bicep Curl", "Low Cable Curl"],
        "description": "Stand at a low pulley cable with an underhand grip on the bar. Curl the handle toward your shoulders while keeping your elbows stationary. Lower under control."
    },
    "wger_overhand_cable_curl": {
        "aliases": ["Reverse Cable Curl", "Pronated Cable Curl"],
        "description": "Attach a straight bar to a low pulley and grip it with an overhand grip. Curl the bar upward while keeping your elbows at your sides, working the brachialis and brachioradialis."
    },
    "wger_reverse_bar_curl": {
        "aliases": ["Reverse Curl", "Overhand Barbell Curl", "Pronated Curl"],
        "description": "Hold a barbell with an overhand grip and arms fully extended. Curl the bar upward while keeping the overhand grip, engaging the brachialis and forearm extensors. Lower under control."
    },
    "wger_z_curls": {
        "aliases": ["Zottman Curl", "Z-Curl"],
        "description": "Start with a supinated grip and curl dumbbells to the top position. At the top, rotate your wrists to a pronated grip and lower the weight slowly. This targets both the biceps on the way up and the brachioradialis on the way down."
    },

    # ── TRICEPS ───────────────────────────────────────────────────────────────
    "wger_dips": {
        "aliases": ["Parallel Bar Dips", "Chest Dips", "Tricep Dips"],
        "description": "Support yourself on parallel bars with arms straight. Lower your body by bending your elbows until your upper arms are parallel to the floor, then push back up to the start. Lean forward to emphasize the chest, stay upright for triceps focus."
    },
    "wger_dips_between_two_benches": {
        "aliases": ["Bench Dip", "Tricep Bench Dip"],
        "description": "Place your hands on one bench and your heels on another, with your body suspended between them. Bend your elbows to lower your hips toward the floor, then push back up. Keep your back close to the front bench."
    },
    "wger_french_press_skullcrusher_szbar": {
        "aliases": ["Skull Crusher EZ Bar", "Lying Triceps Extension", "French Press EZ Bar", "Skullcrusher"],
        "description": "Lie on a bench holding an EZ-bar with an overhand grip above your forehead. Bend at the elbows to lower the bar toward your forehead, then extend back to the start keeping your upper arms vertical."
    },
    "wger_french_press_skullcrusher_dumbbells": {
        "aliases": ["Dumbbell Skull Crusher", "Lying Dumbbell Tricep Extension"],
        "description": "Lie on a bench holding dumbbells with arms extended above you. Bend at the elbows to lower the dumbbells toward your temples, then extend back up. Keep your upper arms perpendicular to the floor throughout."
    },
    "wger_triceps_dips": {
        "aliases": ["Tricep Dip", "Bodyweight Dip"],
        "description": "Support yourself on parallel bars and lower your body by bending at the elbows while keeping your torso upright. Push back to the start by extending your arms. Keeping the body vertical places maximal stress on the triceps."
    },
    "wger_tricep_dumbbell_kickback": {
        "aliases": ["Tricep Kickback", "Dumbbell Kickback"],
        "description": "Hinge forward with a flat back and upper arm parallel to the floor. Extend your forearm backward until your arm is fully straight, squeezing the triceps at the top. Return slowly to the bent position."
    },
    "wger_triceps_extensions_on_cable": {
        "aliases": ["Cable Tricep Pushdown", "Rope Pushdown", "Cable Rope Pushdown"],
        "description": "Attach a rope to a high pulley. Stand facing the machine and push the rope downward by extending your elbows, flaring the rope ends outward at the bottom. Control the return to the start position."
    },
    "wger_triceps_extensions_on_cable_with_bar": {
        "aliases": ["Cable Bar Pushdown", "Straight Bar Pushdown", "Tricep Bar Pushdown"],
        "description": "Attach a straight or V-bar to a high pulley and grip it with an overhand grip. Push the bar straight down by extending the elbows, keeping upper arms fixed at your sides. Return under control."
    },
    "wger_tricep_push_down_freewieghts": {
        "aliases": ["Overhead Tricep Extension", "Tricep Pushdown Dumbbell"],
        "description": "Hold a dumbbell or weight overhead with both hands. Lower the weight behind your head by bending the elbows, then press back up to full extension."
    },
    "wger_triceps_machine": {
        "aliases": ["Machine Tricep Extension", "Tricep Press Machine"],
        "description": "Sit at a triceps machine and grip the handles with elbows bent. Push the handles downward by fully extending your elbows, then return under control."
    },
    "wger_seated_triceps_press": {
        "aliases": ["Overhead Tricep Press", "Seated Overhead Extension", "Dumbbell Overhead Tricep Extension"],
        "description": "Sit on a bench holding a dumbbell or barbell overhead with arms fully extended. Lower the weight behind your head by bending the elbows, then press back up. Keep your elbows close to your head throughout."
    },
    "wger_barbell_triceps_extension": {
        "aliases": ["Barbell Overhead Tricep Extension", "Standing Tricep Extension"],
        "description": "Hold a barbell overhead with a narrow grip and arms extended. Lower the bar behind your head by bending the elbows, then press back up to full extension. Keep upper arms vertical and close to your head."
    },
    "wger_dumbbell_triceps_extension": {
        "aliases": ["Dumbbell Tricep Extension", "Single Dumbbell Overhead Extension"],
        "description": "Hold a dumbbell overhead with both hands gripping one end. Lower the dumbbell behind your head by bending the elbows, then press back up keeping your upper arms vertical."
    },
    "wger_triceps_bench_press_one_barbell": {
        "aliases": ["Close Grip Bench Tricep Press"],
        "description": "Lie on a bench holding a barbell with a narrow grip directly above your chest. Lower the bar to your chest by bending the elbows close to your sides, then press back up focusing on tricep engagement."
    },

    # ── CHEST ─────────────────────────────────────────────────────────────────
    "wger_bench_press": {
        "aliases": ["Flat Bench Press", "Barbell Bench Press", "BB Bench Press"],
        "description": "Lie on a flat bench with feet flat on the floor and grip the barbell slightly wider than shoulder-width. Lower the bar to your mid-chest with control, then press it back up to full arm extension."
    },
    "wger_bench_press_narrow_grip": {
        "aliases": ["Close Grip Bench Press", "Narrow Grip Bench"],
        "description": "Lie on a flat bench and grip the bar with hands about shoulder-width apart or narrower. Lower the bar to your lower chest while keeping elbows closer to your sides, then press back up. Primarily targets the triceps with secondary chest involvement."
    },
    "wger_closegrip_bench_press": {
        "aliases": ["Close Grip Bench", "Narrow Bench Press"],
        "description": "Lie on a flat bench with hands placed close together on the bar. Lower the bar to your lower chest with elbows tucked in, then press back up driving through the triceps."
    },
    "wger_benchpress_dumbbells": {
        "aliases": ["Dumbbell Bench Press", "DB Bench Press", "Flat DB Press"],
        "description": "Lie on a flat bench holding a dumbbell in each hand at chest level. Press both dumbbells upward until your arms are fully extended, then lower them back to chest level with control."
    },
    "wger_incline_bench_press": {
        "aliases": ["Incline Barbell Press", "Incline BB Press"],
        "description": "Lie on an incline bench set to 30–45 degrees and grip the barbell slightly wider than shoulder-width. Lower the bar to your upper chest, then press back up to full extension. Emphasizes the upper chest."
    },
    "wger_incline_dumbbell_press": {
        "aliases": ["Neutral-Grip Incline Dumbbell Bench Press", "Incline Dumbbell Bench Press", "Incline DB Press"],
        "description": "Lie on an incline bench holding dumbbells at chest height with palms facing forward or toward each other. Press the dumbbells upward and slightly inward until fully extended, then lower back to the start."
    },
    "wger_decline_bench_press_barbell": {
        "aliases": ["Decline Bench Press", "Decline Barbell Press"],
        "description": "Lie on a decline bench with feet secured and grip the barbell wider than shoulder-width. Lower the bar to your lower chest, then press back up to full extension. Targets the lower pectoral fibers."
    },
    "wger_decline_bench_press_dumbbell": {
        "aliases": ["Decline Dumbbell Press", "Decline DB Press"],
        "description": "Lie on a decline bench holding dumbbells at your lower chest. Press the dumbbells upward until arms are extended, then lower with control. Emphasizes the lower chest."
    },
    "wger_fly_with_dumbbells": {
        "aliases": ["Dumbbell Fly", "Chest Fly", "Flat Dumbbell Fly"],
        "description": "Lie on a flat bench with dumbbells held above your chest, elbows slightly bent. Lower the dumbbells in a wide arc until you feel a stretch in your chest, then bring them back together above you."
    },
    "wger_fly_with_dumbbells_decline_bench": {
        "aliases": ["Decline Dumbbell Fly", "Decline Chest Fly"],
        "description": "Lie on a decline bench holding dumbbells above your lower chest. Lower the dumbbells in a wide arc until you feel a stretch, then bring them back up in the same arc. Targets the lower chest."
    },
    "wger_incline_dumbbell_flye": {
        "aliases": ["Incline Dumbbell Fly", "Incline Chest Fly"],
        "description": "Lie on an incline bench holding dumbbells above your upper chest. Lower the dumbbells outward in a wide arc until you feel a deep stretch, then squeeze them back together above you."
    },
    "wger_fly_with_cable": {
        "aliases": ["Cable Fly", "Cable Chest Fly", "Cable Crossover"],
        "description": "Stand between two cable stations with handles set at chest height. Pull both handles together in front of your chest in a wide arc, squeezing at the center. Control the return to the stretched position."
    },
    "wger_cable_crossover": {
        "aliases": ["Cable Crossover Fly", "High Cable Fly", "High to Low Cable Fly"],
        "description": "Set cables above shoulder height and stand in the center. Pull the handles together and downward in an arc, crossing them slightly at the bottom. Return to the start position under control."
    },
    "wger_leverage_machine_chest_press": {
        "aliases": ["Chest Press Machine", "Machine Press", "Hammer Strength Chest Press"],
        "description": "Sit at a chest press machine with back flat against the pad and handles at chest level. Press the handles forward until arms are extended, then return under control."
    },
    "wger_push_ups": {
        "aliases": ["Pushup", "Push-Up", "Standard Push-Up"],
        "description": "Start in a high plank position with hands slightly wider than shoulders. Lower your chest to the floor by bending your elbows, keeping your body in a straight line. Push back up to the start."
    },
    "wger_incline_pushups": {
        "aliases": ["Incline Push-Up", "Elevated Push-Up"],
        "description": "Place your hands on an elevated surface like a bench, with body in a straight line. Lower your chest toward the surface by bending the elbows, then push back up. Easier than standard push-ups, emphasizes lower chest."
    },
    "wger_decline_pushups": {
        "aliases": ["Decline Push-Up", "Feet Elevated Push-Up"],
        "description": "Place your feet on an elevated surface and hands on the floor in push-up position. Lower your chest toward the floor, then push back up. The elevation shifts emphasis to the upper chest."
    },
    "wger_pike_push_ups": {
        "aliases": ["Pike Push-Up", "Downward Dog Push-Up"],
        "description": "Start in a downward dog position with hips raised high. Bend your elbows to lower the top of your head toward the floor between your hands, then push back up. Primarily targets the shoulders."
    },
    "wger_side_to_side_push_ups": {
        "aliases": ["Side to Side Push-Up", "Archer Push-Up"],
        "description": "Start in a wide push-up position. Lower yourself toward one hand while straightening the opposite arm, then push back up and repeat to the other side."
    },
    "wger_pause_bench": {
        "aliases": ["Pause Bench Press", "Paused Bench Press"],
        "description": "Perform a standard bench press but pause for 1–2 seconds with the bar touching your chest before pressing. This eliminates the stretch-shortening reflex and increases chest and tricep recruitment."
    },
    "wger_perfect_push_up": {
        "aliases": ["Rotating Push-Up", "Perfect Pushup"],
        "description": "Perform a push-up using rotating handles that allow your wrists to rotate naturally. At the bottom of the rep, rotate the handles outward to externally rotate the shoulders, engaging more chest fibers."
    },
    "wger_crossbench_dumbbell_pullovers": {
        "aliases": ["Dumbbell Pullover", "Cross-Bench Pullover"],
        "description": "Lie across a bench with only your shoulders supported, hips lowered toward the floor, holding a dumbbell above your chest. Lower the dumbbell in an arc behind your head until you feel a stretch in your chest and lats, then pull it back."
    },

    # ── BACK ──────────────────────────────────────────────────────────────────
    "wger_pullups": {
        "aliases": ["Pull-Up", "Overhand Pull-Up", "Wide Grip Pull-Up"],
        "description": "Hang from a bar with an overhand grip wider than shoulder-width. Pull your body upward until your chin clears the bar, leading with your elbows. Lower under control back to a dead hang."
    },
    "wger_chin_ups": {
        "aliases": ["Chin-Up", "Underhand Pull-Up", "Supinated Pull-Up"],
        "description": "Hang from a bar with a shoulder-width underhand grip. Pull your body upward until your chin clears the bar, squeezing the biceps and lats at the top. Lower with control."
    },
    "wger_chinups": {
        "aliases": ["Chin-Up", "Underhand Pull-Up"],
        "description": "Hang from a bar with an underhand grip at shoulder width. Pull yourself up until your chin is above the bar, then lower under control. The underhand grip places greater demand on the biceps compared to pull-ups."
    },
    "wger_pull_ups_on_machine": {
        "aliases": ["Assisted Pull-Up", "Machine Pull-Up", "Assisted Chin-Up"],
        "description": "Use an assisted pull-up machine with a counterweight to reduce the load. Grip the handles and pull your body upward until your chin clears the bar, then lower with control."
    },
    "wger_widegrip_pulldown": {
        "aliases": ["Wide Grip Lat Pulldown", "Neutral-Grip Lat Pulldown", "Lat Pulldown", "Wide Grip Pulldown"],
        "description": "Sit at a lat pulldown station and grip the bar wider than shoulder-width. Pull the bar down toward your upper chest by driving your elbows down and back. Return the bar to the top under control."
    },
    "wger_lat_pull_down_straight_back": {
        "aliases": ["Lat Pulldown Straight Back", "Upright Lat Pulldown"],
        "description": "Sit upright at a lat pulldown station and pull the bar to your upper chest while keeping your torso vertical. Drive your elbows straight down without leaning back. Return under control."
    },
    "wger_lat_pull_down_leaning_back": {
        "aliases": ["Lat Pulldown Leaning Back", "Behind Neck Pulldown"],
        "description": "Sit at a lat pulldown and lean back slightly to 70–80 degrees. Pull the bar down toward your upper chest, leading with your elbows. The slight lean increases the range of motion through the lats."
    },
    "wger_closegrip_lat_pull_down": {
        "aliases": ["Close Grip Pulldown", "V-Bar Pulldown", "Neutral Grip Lat Pulldown"],
        "description": "Attach a V-bar or close-grip handle to a lat pulldown machine. Pull the handle to your upper chest while keeping your torso upright, squeezing your shoulder blades together at the bottom."
    },
    "wger_underhand_lat_pull_down": {
        "aliases": ["Reverse Grip Pulldown", "Supinated Lat Pulldown", "Underhand Pulldown"],
        "description": "Grip the lat pulldown bar with a shoulder-width underhand grip. Pull the bar to your upper chest, driving your elbows down. The supinated grip increases bicep involvement."
    },
    "wger_bent_over_rowing": {
        "aliases": ["Bent Over Row", "Barbell Row", "BB Row", "Overhand Row"],
        "description": "Hinge at the hips with a flat back until your torso is roughly parallel to the floor, holding a barbell with an overhand grip. Row the bar toward your lower ribcage by driving your elbows back. Lower under control."
    },
    "wger_bent_over_rowing_reverse": {
        "aliases": ["Reverse Grip Bent Over Row", "Underhand Barbell Row", "Supinated Row"],
        "description": "Hinge forward with a flat back and grip the barbell with an underhand grip. Pull the bar toward your lower abdomen, driving your elbows back. The underhand grip increases bicep involvement and shifts the row angle."
    },
    "wger_bentover_dumbbell_rows": {
        "aliases": ["Dumbbell Row", "DB Bent Over Row", "Two-Arm Dumbbell Row"],
        "description": "Hinge at the hips holding dumbbells, with your back flat and parallel to the floor. Row both dumbbells toward your hips by driving your elbows back, then lower with control."
    },
    "wger_rowing_seated": {
        "aliases": ["Seated Cable Row", "Cable Row", "Low Row"],
        "description": "Sit at a cable row station with feet on the platform and a slight bend in the knees. Pull the handle toward your lower ribcage, driving your elbows back and squeezing your shoulder blades. Return under control."
    },
    "wger_rowing_lying_on_bench": {
        "aliases": ["Chest Supported Row", "Prone Row", "Bench Row"],
        "description": "Lie face-down on an incline bench and let the dumbbells hang at arm's length. Row both dumbbells toward your hips by driving your elbows back, fully retracting your shoulder blades."
    },
    "wger_rowing_tbar": {
        "aliases": ["T-Bar Row", "Landmine Row"],
        "description": "Straddle a T-bar machine or landmine bar and grip the handle with both hands. Hinge at the hips and pull the bar toward your chest, squeezing the shoulder blades together. Lower under control."
    },
    "wger_longpulley_low_row": {
        "aliases": ["Long Pulley Row", "Cable Seated Row"],
        "description": "Sit at a long cable pulley station with your legs slightly bent. Pull the handle toward your abdomen by driving your elbows back, squeezing the shoulder blades. Extend your arms fully on the return."
    },
    "wger_longpulley_narrow": {
        "aliases": ["Narrow Grip Cable Row", "Close Grip Seated Row"],
        "description": "Sit at a cable pulley using a close-grip attachment. Row the handle toward your lower ribcage by retracting your shoulder blades and driving your elbows back. Return to full extension."
    },
    "wger_low_row_machine": {
        "aliases": ["Seated Row Machine", "Horizontal Row Machine"],
        "description": "Sit at a row machine with your chest against the pad. Pull the handles toward your body by retracting your shoulder blades and driving your elbows back. Return under control."
    },
    "wger_leverage_machine_iso_row": {
        "aliases": ["Hammer Strength Row", "Iso Row", "Machine ISO Row"],
        "description": "Sit at an iso-lateral row machine and pull each handle independently toward your torso. Drive your elbow back and fully retract the shoulder blade, then return under control."
    },
    "wger_pendelay_rows": {
        "aliases": ["Pendlay Row", "Strict Barbell Row", "Dead Stop Row"],
        "description": "Set a barbell on the floor or just above it. With a flat back parallel to the floor, explosively row the bar to your lower chest, letting it return to a dead stop on the floor between each rep."
    },
    "wger_incline_dumbbell_row": {
        "aliases": ["Incline DB Row", "Prone Incline Row"],
        "description": "Lie face-down on an incline bench at 45 degrees, holding dumbbells. Row both dumbbells toward your hips by driving your elbows upward and back, squeezing your shoulder blades at the top."
    },
    "wger_shotgun_row": {
        "aliases": ["Single Arm Cable Row", "One Arm Row"],
        "description": "Stand beside a cable stack and grip a single handle. Row the handle toward your hip by driving your elbow back while rotating your torso slightly. Return to the start with control."
    },
    "wger_deadhang": {
        "aliases": ["Dead Hang", "Passive Hang"],
        "description": "Hang from a pull-up bar with a shoulder-width grip and arms fully extended. Relax your shoulders to allow full decompression of the spine. Hold for time to build grip strength and shoulder mobility."
    },
    "wger_hyperextensions": {
        "aliases": ["Back Extension", "Hyperextension", "Lower Back Extension"],
        "description": "Position yourself face-down on a hyperextension bench with your hips at the top pad. Lower your torso toward the floor, then raise back up until your body forms a straight line. Avoid hyperextending beyond neutral."
    },
    "wger_good_mornings": {
        "aliases": ["Good Morning", "Barbell Good Morning"],
        "description": "Stand with a barbell across your upper back and feet shoulder-width apart. Hinge at the hips with a slight knee bend until your torso is nearly parallel to the floor, then drive back up through your hips."
    },
    "wger_superman": {
        "aliases": ["Superman Hold", "Back Extension Bodyweight"],
        "description": "Lie face-down on the floor with arms extended overhead. Simultaneously lift your arms, chest, and legs off the floor by contracting your lower back and glutes. Hold briefly and lower."
    },
    "wger_straight_arm_pull_down_bar_attachment": {
        "aliases": ["Straight Arm Pulldown", "Cable Pullover"],
        "description": "Stand facing a high cable pulley and grip a straight bar with arms extended. Without bending your elbows, pull the bar down in an arc toward your thighs, engaging the lats. Return under control."
    },
    "wger_straightarm_pull_down_bar_attachment": {
        "aliases": ["Straight Arm Pulldown", "Cable Pullover"],
        "description": "Stand facing a high cable pulley and grip a straight bar with arms extended. Without bending your elbows, pull the bar down in an arc toward your thighs, engaging the lats. Return under control."
    },
    "wger_straightarm_pull_down_rope_attachment": {
        "aliases": ["Rope Straight Arm Pulldown", "Rope Cable Pullover"],
        "description": "Attach a rope to a high pulley. Grip the rope with arms extended and pull downward in an arc toward your thighs without bending your elbows. Feel the lats stretch at the top and squeeze at the bottom."
    },

    # ── SHOULDERS ─────────────────────────────────────────────────────────────
    "wger_military_press": {
        "aliases": ["Overhead Press", "Standing Press", "OHP", "Barbell OHP"],
        "description": "Stand holding a barbell at collarbone height with a slightly wider than shoulder-width grip. Press the bar overhead to full arm extension, moving your head slightly back as the bar passes. Lower under control."
    },
    "wger_military_press_256": {
        "aliases": ["Seated Overhead Press", "Seated Military Press", "Seated OHP"],
        "description": "Sit on a bench with back support and hold a barbell at shoulder level. Press the bar overhead to full extension, then lower back to shoulder height. The seated position removes leg drive for stricter shoulder isolation."
    },
    "wger_shoulder_press_barbell": {
        "aliases": ["Barbell Shoulder Press", "Barbell Overhead Press"],
        "description": "Hold a barbell at shoulder height with elbows forward and slightly below the bar. Press overhead to full extension, then lower back to the start. Can be performed seated or standing."
    },
    "wger_shoulder_press_dumbbells": {
        "aliases": ["Dumbbell Shoulder Press", "DB Overhead Press", "DB OHP"],
        "description": "Sit or stand holding dumbbells at shoulder height with palms facing forward. Press both dumbbells overhead until arms are fully extended, then lower back to shoulder height."
    },
    "wger_shoulder_press_on_machine": {
        "aliases": ["Machine Shoulder Press", "Machine OHP"],
        "description": "Sit at a shoulder press machine and grip the handles at shoulder height. Press the handles upward to full arm extension, then return under control."
    },
    "wger_shoulder_press_on_multi_press": {
        "aliases": ["Smith Machine Shoulder Press", "Multi-Press OHP"],
        "description": "Sit under a Smith machine bar set at shoulder height. Unrack and press the bar overhead along its fixed track, then lower back to shoulder height."
    },
    "wger_arnold_shoulder_press": {
        "aliases": ["Arnold Press", "Arnold Dumbbell Press", "Rotating Shoulder Press"],
        "description": "Start with dumbbells at chin height, palms facing you. As you press upward, rotate your palms outward so they face forward at the top. Reverse the rotation on the way down."
    },
    "wger_diagonal_shoulder_press": {
        "aliases": ["Diagonal Press", "Landmine Press"],
        "description": "Hold a weight at shoulder height and press it upward and diagonally outward at an angle, rather than straight overhead. This variation reduces shoulder impingement risk."
    },
    "wger_lateral_raises": {
        "aliases": ["Lateral Raise", "Side Raise", "Dumbbell Lateral Raise"],
        "description": "Stand holding dumbbells at your sides with a slight bend in the elbows. Raise both dumbbells out to the sides until your arms are parallel to the floor, then lower with control."
    },
    "wger_side_raise": {
        "aliases": ["Side Lateral Raise", "DB Side Raise"],
        "description": "Stand or sit holding dumbbells at your sides. Lift both dumbbells laterally until they reach shoulder height, keeping a slight bend in the elbows. Lower slowly."
    },
    "wger_lateral_raises_on_cable_one_armed": {
        "aliases": ["Cable Lateral Raise", "One-Arm Cable Lateral Raise"],
        "description": "Stand beside a low cable pulley and grip the handle with the far hand across your body. Raise your arm out to the side until parallel to the floor, then lower with control."
    },
    "wger_lateraltofront_raises": {
        "aliases": ["Lateral to Front Raise", "Combo Raise"],
        "description": "Hold dumbbells and raise them out to the side, then transition the movement into a front raise at the top. Lower forward and return to the sides."
    },
    "wger_front_raises": {
        "aliases": ["Front Raise", "Dumbbell Front Raise", "Barbell Front Raise"],
        "description": "Hold dumbbells or a barbell in front of your thighs. Raise the weight straight forward to shoulder height with arms slightly bent, then lower under control."
    },
    "wger_rear_delt_raises": {
        "aliases": ["Rear Delt Fly", "Bent Over Rear Delt Raise", "Reverse Fly"],
        "description": "Hinge forward at the hips with a flat back, holding dumbbells hanging below you. Raise both dumbbells out to the sides in a reverse fly motion until your arms are parallel to the floor. Squeeze the rear delts at the top."
    },
    "wger_upright_row_szbar": {
        "aliases": ["EZ Bar Upright Row", "Upright Row EZ Bar"],
        "description": "Hold an EZ-bar in front of your thighs with an overhand grip. Pull the bar straight up toward your chin by raising your elbows above your hands, then lower under control."
    },
    "wger_upright_row_w_dumbbells": {
        "aliases": ["Dumbbell Upright Row", "DB Upright Row"],
        "description": "Hold dumbbells in front of your thighs. Pull them upward close to your body, leading with your elbows until they reach chin height, then lower with control."
    },
    "wger_upright_row_on_multi_press": {
        "aliases": ["Smith Machine Upright Row", "Machine Upright Row"],
        "description": "Set a Smith machine bar at thigh height and grip it with a shoulder-width overhand grip. Pull the bar straight up toward your chin by leading with your elbows, then lower."
    },
    "wger_bent_high_pulls": {
        "aliases": ["Bent Over High Pull", "Barbell High Pull"],
        "description": "Hold a barbell and hinge slightly forward. Explosively pull the bar upward in a high row motion, leading with your elbows above shoulder height. This is a power movement that targets the rear delts and traps."
    },
    "wger_shrugs_barbells": {
        "aliases": ["Barbell Shrug", "Trap Shrug"],
        "description": "Stand holding a barbell in front of your thighs. Elevate your shoulders straight upward as high as possible, squeezing your traps at the top. Lower under control without rolling the shoulders."
    },
    "wger_shrugs_dumbbells": {
        "aliases": ["Dumbbell Shrug", "DB Shrug"],
        "description": "Stand holding dumbbells at your sides. Shrug both shoulders straight upward toward your ears, squeezing the traps at the top. Lower slowly and repeat."
    },
    "wger_cable_external_rotation": {
        "aliases": ["External Rotation Cable", "Shoulder External Rotation"],
        "description": "Stand beside a cable at elbow height with your elbow bent at 90 degrees close to your side. Rotate your forearm outward away from your body, then return under control. Targets the rotator cuff."
    },

    # ── LEGS ──────────────────────────────────────────────────────────────────
    "wger_squats": {
        "aliases": ["Barbell Back Squat", "Back Squat", "Barbell Squat", "BB Squat"],
        "description": "Stand with a barbell across your upper traps, feet shoulder-width apart. Descend by breaking at the hips and knees simultaneously until your thighs are parallel or below, then drive back up through your heels."
    },
    "wger_front_squats": {
        "aliases": ["Front Squat", "Barbell Front Squat"],
        "description": "Hold a barbell in a front rack position across your shoulders. Squat down with an upright torso until your thighs are parallel to the floor, then drive back up. Requires significant ankle and thoracic mobility."
    },
    "wger_overhead_squat": {
        "aliases": ["Overhead Squat", "OHS"],
        "description": "Hold a barbell or PVC pipe overhead with a wide snatch grip and arms locked out. Squat to full depth while keeping the bar over your mid-foot, then stand back up. Tests mobility throughout the entire kinetic chain."
    },
    "wger_super_squat": {
        "aliases": ["20-Rep Squat", "Breathing Squat"],
        "description": "Perform a high-rep barbell squat set, typically 20 reps, taking several deep breaths between each rep. The extended set builds significant leg mass and cardiovascular conditioning."
    },
    "wger_body_squats": {
        "aliases": ["Bodyweight Squat", "Air Squat", "Squat"],
        "description": "Stand with feet shoulder-width apart and arms extended forward for balance. Sit back and down until your thighs are parallel to the floor, then drive back up through your heels."
    },
    "wger_braced_squat": {
        "aliases": ["Goblet Squat Hold", "Braced Squat"],
        "description": "Hold a weight at your chest and squat to full depth, holding the bottom position. Use your elbows to push your knees outward to improve squat depth and hip mobility."
    },
    "wger_pistol_squat": {
        "aliases": ["Single Leg Squat", "Pistol", "One-Leg Squat"],
        "description": "Stand on one leg with the other leg extended forward. Lower yourself to full depth on the standing leg while keeping the extended leg off the floor, then drive back up."
    },
    "wger_dumbbell_goblet_squat": {
        "aliases": ["Goblet Squat", "KB Goblet Squat"],
        "description": "Hold a dumbbell or kettlebell vertically at your chest. Squat down until your elbows touch the inside of your knees, then drive back up. Excellent for teaching squat mechanics."
    },
    "wger_squat_jumps": {
        "aliases": ["Jump Squat", "Squat Jump", "Explosive Squat"],
        "description": "Perform a bodyweight squat and at the top of the movement, explode upward into a jump. Land softly, absorbing the impact by bending the knees, and immediately descend into the next rep."
    },
    "wger_bulgarian_split_squat": {
        "aliases": ["Bulgarian Split Squat", "Rear Foot Elevated Split Squat", "RFESS"],
        "description": "Place your rear foot on an elevated surface and step forward into a lunge position. Lower your rear knee toward the floor by bending your front knee, then drive back up through the front heel."
    },
    "wger_dumbbell_split_squat": {
        "aliases": ["Split Squat", "Dumbbell Lunge", "Static Lunge"],
        "description": "Hold dumbbells at your sides and take a staggered stance. Lower your rear knee toward the floor, keeping your front shin vertical, then push back up. Both feet remain stationary throughout."
    },
    "wger_romanian_deadlift": {
        "aliases": ["RDL", "Romanian Deadlift", "Stiff-Leg Deadlift Barbell"],
        "description": "Hold a barbell at hip height with a shoulder-width overhand grip. Hinge at the hips with a slight knee bend, lowering the bar along your legs until you feel a strong hamstring stretch, then drive your hips forward to return."
    },
    "wger_stifflegged_deadlifts": {
        "aliases": ["Stiff Leg Deadlift", "SLDL", "Straight Leg Deadlift"],
        "description": "Hold a barbell and hinge at the hips with legs nearly straight. Lower the bar toward the floor while maintaining a flat back, feeling a stretch in the hamstrings, then return to standing by extending the hips."
    },
    "wger_deadlifts": {
        "aliases": ["Deadlift", "Conventional Deadlift", "Barbell Deadlift"],
        "description": "Stand with a barbell over your mid-foot, hip-width stance. Hinge down to grip the bar and set your back flat. Drive through your legs and extend your hips to lift the bar to lockout, then lower with control."
    },
    "wger_rack_deadlift": {
        "aliases": ["Rack Pull", "Partial Deadlift", "Block Pull"],
        "description": "Set a barbell on rack pins at knee height or above. Grip and deadlift the bar from this elevated position to lockout, then lower back to the pins. Allows heavier loading of the upper pull and lockout."
    },
    "wger_deficit_deadlift": {
        "aliases": ["Deficit Deadlift", "Elevated Deadlift"],
        "description": "Stand on a small platform or plate to increase the range of motion of a conventional deadlift. Pull the bar from below your standard starting position, building strength off the floor."
    },
    "wger_speed_deadlift": {
        "aliases": ["Dynamic Effort Deadlift", "Speed Pull"],
        "description": "Perform deadlifts at 50–70% of your max weight, focusing on moving the bar as explosively as possible off the floor. Used to build rate of force development and improve bar speed."
    },
    "wger_leg_press_on_hackenschmidt_machine": {
        "aliases": ["Leg Press", "45 Degree Leg Press", "Machine Leg Press"],
        "description": "Sit in a leg press machine with feet hip-width on the platform. Lower the weight toward your chest by bending your knees to 90 degrees, then press back up to full extension without locking the knees."
    },
    "wger_leg_presses_narrow": {
        "aliases": ["Narrow Stance Leg Press", "Feet Together Leg Press"],
        "description": "Sit in a leg press with feet placed close together in the center of the platform. Press the weight upward, emphasizing the outer quad with the narrower stance."
    },
    "wger_leg_presses_wide": {
        "aliases": ["Wide Stance Leg Press", "Sumo Leg Press"],
        "description": "Sit in a leg press with feet placed wide on the outer edges of the platform. Lower and press the weight, placing greater emphasis on the inner thigh and glutes."
    },
    "wger_calf_press_using_leg_press_machine": {
        "aliases": ["Seated Calf Press", "Leg Press Calf Raise"],
        "description": "Sit in a leg press machine and place only the balls of your feet on the lower edge of the platform. Press upward by plantarflexing the ankle, squeezing the calves at the top. Lower the heels for a full stretch."
    },
    "wger_leg_extension": {
        "aliases": ["Quad Extension", "Knee Extension", "Machine Leg Extension"],
        "description": "Sit in a leg extension machine with the pad resting on your lower shins. Extend both legs until straight, contracting the quadriceps at the top. Lower under control."
    },
    "wger_leg_curls_laying": {
        "aliases": ["Lying Leg Curl", "Prone Leg Curl", "Hamstring Curl"],
        "description": "Lie face-down on a leg curl machine with the pad behind your ankles. Curl your heels toward your glutes by flexing the hamstrings, then lower under control."
    },
    "wger_leg_curls_sitting": {
        "aliases": ["Seated Leg Curl", "Seated Hamstring Curl"],
        "description": "Sit at a leg curl machine with the pad resting on top of your lower legs. Flex your knees by pulling your heels downward, contracting the hamstrings. Return under control."
    },
    "wger_leg_curls_standing": {
        "aliases": ["Standing Leg Curl", "One-Leg Curl"],
        "description": "Stand at a standing leg curl machine and place the pad behind one ankle. Curl your heel toward your glute by flexing the hamstring, then lower with control. Work each leg independently."
    },
    "wger_dumbbell_lunges_standing": {
        "aliases": ["Standing Lunge", "Stationary Lunge", "Dumbbell Stationary Lunge"],
        "description": "Hold dumbbells at your sides and take a large step forward. Lower your rear knee toward the floor, keeping your front knee over your ankle, then push back to the starting position."
    },
    "wger_dumbbell_lunges_walking": {
        "aliases": ["Walking Lunge", "Dumbbell Walking Lunge"],
        "description": "Hold dumbbells at your sides. Step forward into a lunge and lower your rear knee close to the floor, then bring your rear foot forward to step into the next lunge. Continue alternating legs as you travel forward."
    },
    "wger_bodyweight_lunges": {
        "aliases": ["Bodyweight Lunge", "Lunge", "Forward Lunge"],
        "description": "Stand upright and step one foot forward into a lunge position. Lower your rear knee toward the floor, then push through your front heel to return to standing. Alternate legs."
    },
    "wger_standing_calf_raises": {
        "aliases": ["Calf Raise", "Standing Calf Raise", "Gastrocnemius Raise"],
        "description": "Stand on the edge of a step or calf raise machine with heels hanging off. Rise onto your toes as high as possible, hold briefly, then lower your heels below the platform for a full stretch."
    },
    "wger_sitting_calf_raises": {
        "aliases": ["Seated Calf Raise", "Soleus Raise"],
        "description": "Sit on a seated calf raise machine with the pad on your thighs. Push up onto your toes by plantarflexing the ankle, pause at the top, then lower heels for a full stretch. Emphasizes the soleus over the gastrocnemius."
    },
    "wger_calf_raises_on_hackenschmitt_machine": {
        "aliases": ["Hack Machine Calf Raise", "Machine Standing Calf Raise"],
        "description": "Stand on a Hackenschmidt or hack squat machine with heels off the edge of the platform. Rise onto your toes, squeezing the calves at the top, then lower for a full stretch."
    },
    "wger_lifefitness_calf_extension_machine": {
        "aliases": ["Machine Calf Extension", "Calf Extension Machine"],
        "description": "Sit at a calf extension machine with feet on the footplate. Push through the balls of your feet to extend the ankles fully, then lower under control for a complete calf stretch."
    },
    "wger_weighted_stepups": {
        "aliases": ["Step-Up", "Dumbbell Step-Up", "Weighted Step-Up"],
        "description": "Hold dumbbells and place one foot on a bench or box. Drive through the elevated foot to step up, bringing the other foot to the platform. Step back down and repeat, alternating legs."
    },
    "wger_weighted_step": {
        "aliases": ["Loaded Step", "Weighted Stair Step"],
        "description": "Hold a weight and step up onto a box or platform one foot at a time. Control the descent and repeat. Focus on the working leg doing the driving rather than pushing off the trailing foot."
    },
    "wger_depth_jumps": {
        "aliases": ["Depth Jump", "Drop Jump", "Box Drop Jump"],
        "description": "Step off a box and immediately upon landing, jump upward as explosively as possible. The goal is to minimize ground contact time. Develops reactive strength and power."
    },
    "wger_duck_walks": {
        "aliases": ["Duck Walk", "Squat Walk"],
        "description": "Lower into a deep squat position and walk forward while staying low, keeping your torso upright. Develops hip mobility, quad strength, and stability in the deep squat position."
    },

    # ── CORE ──────────────────────────────────────────────────────────────────
    "wger_plank": {
        "aliases": ["Plank Hold", "Prone Plank", "Forearm Plank"],
        "description": "Rest on your forearms and toes with your body forming a straight line from head to heels. Brace your core and glutes to prevent your hips from sagging or rising. Hold for time."
    },
    "wger_side_plank": {
        "aliases": ["Side Plank Hold", "Lateral Plank"],
        "description": "Lie on your side and prop yourself up on one forearm and the side of your foot. Lift your hips so your body forms a straight line, and hold. Works the lateral core and obliques."
    },
    "wger_crunches": {
        "aliases": ["Crunch", "Ab Crunch", "Abdominal Crunch"],
        "description": "Lie on your back with knees bent and hands behind your head. Curl your shoulder blades off the floor by contracting your abs, without pulling on your neck. Lower under control."
    },
    "wger_crunches_on_machine": {
        "aliases": ["Machine Crunch", "Ab Machine"],
        "description": "Sit at an ab crunch machine and grip the handles. Flex forward at the waist by contracting the abs, bringing your elbows toward your knees. Return under control."
    },
    "wger_crunches_with_cable": {
        "aliases": ["Cable Crunch", "Kneeling Cable Crunch"],
        "description": "Kneel facing away from a high pulley and hold the rope behind your head. Flex your torso downward by crunching your abs, bringing your elbows toward your knees. Return to upright."
    },
    "wger_situps": {
        "aliases": ["Sit-Up", "Full Sit-Up"],
        "description": "Lie on your back with knees bent and feet anchored. Raise your entire torso up toward your knees by contracting your core, then lower under control back to the floor."
    },
    "wger_negative_crunches": {
        "aliases": ["Reverse Crunch", "Hip Raise"],
        "description": "Lie on your back and bring your knees to your chest. Curl your hips off the floor by contracting your lower abs, then lower with control. Focuses on the lower portion of the rectus abdominis."
    },
    "wger_decline_press_situp": {
        "aliases": ["Decline Sit-Up", "Decline Crunch"],
        "description": "Lie on a decline bench with feet secured and hands behind your head. Sit fully upright, then lower back to the bench under control. The decline increases range of motion compared to flat sit-ups."
    },
    "wger_sprinter_situps": {
        "aliases": ["Sprinter Crunch", "Bicycle Crunch"],
        "description": "Lie on your back and alternately crunch up while bringing one knee toward your chest and the opposite elbow toward it. Rotate to each side in a controlled cycling motion."
    },
    "wger_hanging_leg_raises": {
        "aliases": ["Hanging Leg Raise", "Hanging Knee Raise", "HLR"],
        "description": "Hang from a pull-up bar with arms extended. Raise your legs until they are parallel to the floor or higher, keeping them straight or with knees bent. Lower under control without swinging."
    },
    "wger_leg_raises_lying": {
        "aliases": ["Lying Leg Raise", "Floor Leg Raise"],
        "description": "Lie flat on your back with legs extended. Keeping legs straight or slightly bent, raise them to 90 degrees, then lower slowly without letting your heels touch the floor."
    },
    "wger_leg_raises_standing": {
        "aliases": ["Standing Leg Raise", "Captain's Chair", "Knee Raise"],
        "description": "Hang from a captain's chair or support yourself with armrests. Raise your knees toward your chest or extend your legs to horizontal, contracting the abs. Lower under control."
    },
    "wger_hip_raise_lying": {
        "aliases": ["Hip Raise", "Bridge", "Glute Bridge"],
        "description": "Lie on your back with knees bent and feet flat on the floor. Drive your hips upward by contracting your glutes until your body forms a straight line from shoulders to knees. Lower under control."
    },
    "wger_hollow_hold": {
        "aliases": ["Hollow Body Hold", "Hollow Position"],
        "description": "Lie on your back and simultaneously raise your legs and shoulder blades off the floor, pressing your lower back into the ground. Hold a compressed position with arms extended overhead or at your sides."
    },
    "wger_flutter_kicks": {
        "aliases": ["Flutter Kick", "Scissor Kick"],
        "description": "Lie on your back with hands under your lower back for support. Raise both legs slightly off the floor and alternate kicking them up and down in a small, controlled flutter motion."
    },
    "wger_isometric_wipers": {
        "aliases": ["Windshield Wipers Isometric", "Isometric Leg Hold"],
        "description": "Hang from a bar and raise your legs to horizontal. Hold the position isometrically while maintaining tension throughout your core and hip flexors."
    },
    "wger_side_crunch": {
        "aliases": ["Oblique Crunch", "Side Crunch"],
        "description": "Lie on your back with knees rolled to one side. Crunch your upper body upward and slightly toward your raised knees, contracting the obliques. Lower and repeat on both sides."
    },
    "wger_trunk_rotation_with_cable": {
        "aliases": ["Cable Wood Chop", "Cable Rotation", "Pallof Press"],
        "description": "Stand sideways to a cable machine and grip the handle with both hands. Rotate your torso away from the machine in a controlled arc, then return under control. Targets the obliques."
    },
    "wger_cable_woodchoppers": {
        "aliases": ["Cable Woodchop", "Wood Chop", "High to Low Cable Chop"],
        "description": "Set a cable at shoulder height and grip with both hands. Pull the cable diagonally across your body from high to low or low to high, rotating through your core. Targets the obliques and transverse abdominis."
    },
    "wger_upper_external_oblique": {
        "aliases": ["Oblique Twist", "Russian Twist"],
        "description": "Sit on the floor with knees bent, lean back slightly, and rotate your torso from side to side. For added difficulty, hold a weight and touch it to the floor on each side."
    },
    "wger_side_dumbbell_trunk_flexion": {
        "aliases": ["Dumbbell Side Bend", "Lateral Trunk Flexion"],
        "description": "Stand holding a dumbbell in one hand with arm at your side. Bend laterally toward the dumbbell side, then contract your opposite oblique to return upright. Keep your hips stationary."
    },
    "wger_dumbbell_side_bends": {
        "aliases": ["Side Bend", "Oblique Side Bend"],
        "description": "Stand holding dumbbells at your sides. Bend your torso sideways toward one dumbbell, then use your obliques to pull back to upright. Work both sides evenly."
    },
    "wger_barbell_ab_rollout": {
        "aliases": ["Ab Wheel Rollout", "Barbell Rollout", "Rollout"],
        "description": "Kneel holding a barbell loaded with round plates. Roll the bar forward, extending your body toward the floor while keeping your core braced, then pull back to the starting position."
    },

    # ── POWER / OLYMPIC ───────────────────────────────────────────────────────
    "wger_power_clean": {
        "aliases": ["Power Clean", "Clean"],
        "description": "Start with a barbell over mid-foot. Explosively pull the bar upward by extending your hips and knees, then drop under the bar and catch it in a front rack position. Stand to complete the rep."
    },
    "wger_snatch": {
        "aliases": ["Barbell Snatch", "Olympic Snatch"],
        "description": "Pull a barbell from the floor to overhead in one explosive movement, catching it with arms locked out and landing in a squat or power position. A highly technical Olympic lift requiring significant mobility and coordination."
    },
    "wger_push_press": {
        "aliases": ["Push Press", "Dumbbell Push Press"],
        "description": "Hold a barbell at shoulder height and dip slightly at the knees. Explosively extend your legs to drive the bar overhead, then lock it out at the top. The leg drive allows heavier loads than a strict press."
    },
    "wger_high_pull": {
        "aliases": ["Barbell High Pull", "Snatch High Pull"],
        "description": "Grip a barbell at hip height and pull it explosively upward toward your chin while rising onto your toes, leading with your elbows. Used to develop the pulling power for Olympic lifts."
    },
    "wger_kettlebell_swings": {
        "aliases": ["KB Swing", "Russian Swing", "American Swing"],
        "description": "Stand with feet hip-width and a kettlebell between your feet. Hinge at the hips and swing the kettlebell back between your legs, then explosively drive your hips forward to swing it up to chest height."
    },
    "wger_2_handed_kettlebell_swing": {
        "aliases": ["Two-Hand KB Swing", "Double Kettlebell Swing"],
        "description": "Stand with feet hip-width and grip a kettlebell with both hands. Hinge and swing the bell between your legs, then drive your hips forward to swing it to shoulder height. Use hip power rather than arm strength."
    },
    "wger_turkish_getup": {
        "aliases": ["TGU", "Turkish Get-Up"],
        "description": "Lie on your back holding a kettlebell or dumbbell overhead in one hand. Follow a specific sequence of movements to stand up while keeping the weight overhead, then reverse the sequence back to the ground."
    },

    # ── FUNCTIONAL / CONDITIONING ─────────────────────────────────────────────
    "wger_burpees": {
        "aliases": ["Burpee", "Squat Thrust"],
        "description": "From standing, squat down and place your hands on the floor. Jump your feet back into a push-up position, perform a push-up, jump your feet forward, then explosively jump upward with arms overhead."
    },
    "wger_bear_walk": {
        "aliases": ["Bear Crawl", "Bear Walk"],
        "description": "Start on all fours with knees hovering just off the floor. Move forward by advancing opposite hand and foot simultaneously while keeping your back flat. Builds coordination and full-body strength."
    },
    "wger_car_push": {
        "aliases": ["Sled Push", "Car Push", "Loaded Push"],
        "description": "Push a heavy vehicle or sled from behind by driving through your legs and maintaining a rigid torso. An intense lower-body and conditioning exercise."
    },
    "wger_farmers_walks": {
        "aliases": ["Farmer's Walk", "Farmer's Carry", "Heavy Carry"],
        "description": "Hold heavy dumbbells or kettlebells at your sides and walk a set distance. Keep your shoulders back, core braced, and maintain an upright posture throughout. Builds grip, core, and whole-body stability."
    },
    "wger_yolk_walks": {
        "aliases": ["Yoke Walk", "Yoke Carry"],
        "description": "Place a heavy yoke across your upper back and walk a set distance. The unstable load challenges your core and balance far more than a standard barbell squat."
    },
    "wger_high_knee_jumps": {
        "aliases": ["High Knee Run", "Running in Place"],
        "description": "Run in place, driving your knees as high as possible with each step. Maintain an upright torso and pump your arms. Used for cardiovascular conditioning and hip flexor development."
    },
    "wger_full_sit_outs": {
        "aliases": ["Sit Out", "Sprawl"],
        "description": "Starting in a push-up position, rotate your body by sweeping one leg under and through while extending the opposite arm, finishing with your back to the ground. Rotate back and repeat to the other side."
    },

    # ── GRIP / MISC ───────────────────────────────────────────────────────────
    "wger_hand_grip": {
        "aliases": ["Grip Squeeze", "Hand Gripper"],
        "description": "Hold a hand gripper or grip trainer and squeeze it fully closed, then release under control. Repeated reps build grip strength and forearm endurance."
    },
    "wger_axe_hold": {
        "aliases": ["Axe Hold", "Plate Hold"],
        "description": "Hold a weight plate by the top rim at arm's length, like holding an axe. The offset center of mass challenges grip and forearm strength isometrically."
    },
    "wger_hercules_pillars": {
        "aliases": ["Hercules Hold", "Static Hold"],
        "description": "Grip two loading pin handles attached to weights and hold them as long as possible. Tests grip strength and mental toughness."
    },

    # ── GYMNASTICS / CALISTHENICS ─────────────────────────────────────────────
    "wger_pullups": {
        "aliases": ["Pull-Up", "Overhand Pull-Up", "Wide Grip Pull-Up"],
        "description": "Hang from a bar with an overhand grip wider than shoulder-width. Pull your body upward until your chin clears the bar, leading with your elbows. Lower under control back to a dead hang."
    },
    "wger_ring_dips": {
        "aliases": ["Ring Dip", "Gymnastic Ring Dip"],
        "description": "Support yourself on gymnastics rings with arms straight. Lower your body by bending at the elbows while stabilizing the rings, then press back up. The rings make this significantly harder than bar dips."
    },
    "wger_l_hold": {
        "aliases": ["L-Sit", "L Hold"],
        "description": "Support your body on parallel bars or the floor with arms straight and legs extended horizontally to form an L shape. Hold the position by engaging your core and hip flexors."
    },
    "wger_wall_handstand": {
        "aliases": ["Handstand Hold", "Wall Handstand"],
        "description": "Kick up into a handstand against a wall. Hold the inverted position with arms straight, body tight, and toes pointing up. Develops shoulder strength and body awareness."
    },
    "wger_bodyups": {
        "aliases": ["Body Up", "Planche Lean"],
        "description": "Start in a push-up position and push your body backward over your hands by extending your arms, then pull forward again. Develops the pushing muscles of the shoulder girdle."
    },
    "wger_wall_pushup": {
        "aliases": ["Wall Push-Up", "Standing Push-Up"],
        "description": "Stand facing a wall and place your hands on it at shoulder height. Bend your elbows to bring your chest toward the wall, then push back to the start. A regression of the standard push-up."
    },
    "wger_mgm_machine": {
        "aliases": ["Multi-Gym Machine", "Cable Machine"],
        "description": "Perform an exercise on a multi-gym cable machine. The specific movement depends on attachment and cable position selected."
    },

    # ── BUTTERFLY / PECK DECK ─────────────────────────────────────────────────
    "wger_butterfly": {
        "aliases": ["Pec Deck", "Chest Fly Machine", "Pec Fly Machine"],
        "description": "Sit at a pec deck machine with forearms on the pads or handles at chest height. Bring your arms together in front of you by squeezing your chest, then return under control."
    },
    "wger_butterfly_narrow_grip": {
        "aliases": ["Narrow Grip Pec Deck", "Close Grip Chest Fly Machine"],
        "description": "Sit at a pec deck machine with a narrower grip setting. Squeeze your forearms or handles together in front of your chest, emphasizing the inner chest."
    },
    "wger_butterfly_reverse": {
        "aliases": ["Reverse Pec Deck", "Rear Delt Machine Fly", "Reverse Fly Machine"],
        "description": "Sit facing the pad of a pec deck machine and grip the handles from the front. Open your arms outward in a reverse fly motion, squeezing the rear delts and rhomboids."
    },

    # ── ROWING MACHINE ────────────────────────────────────────────────────────
    "wger_bent_high_pulls": {
        "aliases": ["Bent Over High Pull"],
        "description": "Hinge forward and explosively pull a barbell or cable upward toward chin level, leading with the elbows above the hands. Combines a row with an upright pull."
    },

    # ── MISC ──────────────────────────────────────────────────────────────────
    "wger_push_ups": {
        "aliases": ["Pushup", "Push-Up", "Standard Push-Up"],
        "description": "Start in a high plank with hands slightly wider than shoulders. Lower your chest toward the floor by bending your elbows, then push back to the start keeping your body rigid."
    },
    "wger_hip_raise_lying": {
        "aliases": ["Glute Bridge", "Hip Bridge", "Hip Raise"],
        "description": "Lie on your back with knees bent and feet flat on the floor. Drive your hips upward by squeezing your glutes until your body forms a straight line, then lower with control."
    },
    "wger_incline_plank_with_alternate_floor_touch": {
        "aliases": ["Incline Plank Tap", "Incline Plank Reach"],
        "description": "Start in an incline plank with hands on a bench. Alternately reach one hand forward to touch the floor, maintaining plank alignment throughout and minimizing hip rotation."
    },
    "wger_cable_woodchoppers": {
        "aliases": ["Wood Chop", "Cable Wood Chop", "Diagonal Chop"],
        "description": "Set a cable at high or low position. Grip with both hands and pull diagonally across your body while rotating through your core. Works the obliques and transverse abdominis."
    },
    "wger_push_press": {
        "aliases": ["Push Press", "Leg Drive Press"],
        "description": "Hold a barbell at shoulder height, dip slightly at the knees, then explosively drive your legs to propel the bar overhead. Lock out the arms at the top. The leg drive allows heavier pressing loads."
    },
}

# ── Load + patch ──────────────────────────────────────────────────────────────

with open(JSON_PATH) as f:
    data = json.load(f)

patched = 0
for exercise in data:
    eid = exercise.get("id")
    if eid not in ENRICHMENT:
        continue
    info = ENRICHMENT[eid]
    changed = False
    if not exercise.get("aliases") and info.get("aliases"):
        exercise["aliases"] = info["aliases"]
        changed = True
    if not exercise.get("description") and info.get("description"):
        exercise["description"] = info["description"]
        changed = True
    if changed:
        patched += 1

with open(JSON_PATH, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

# ── Report ────────────────────────────────────────────────────────────────────
included = [e for e in data if e.get("status") == "include"]
with_aliases = [e for e in included if e.get("aliases")]
with_desc    = [e for e in included if e.get("description")]
missing_both = [e for e in included if not e.get("aliases") and not e.get("description")]

print(f"Patched: {patched} exercises")
print(f"Total included: {len(included)}")
print(f"With aliases: {len(with_aliases)}")
print(f"With description: {len(with_desc)}")
print(f"\nMissing both ({len(missing_both)}):")
for e in missing_both:
    print(f"  {e['id']} | {e['name']}")
