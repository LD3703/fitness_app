// Překlady vestavěného obsahu (cviky, návody, rutiny, programy) do jazyků,
// které nejsou přímo v databázi. Angličtina a čeština jsou v seed_data.dart,
// seed_instructions.dart a plan_templates.dart.

/// Texty jednoho jazyka; klíčem je slug (u plánů anglický název).
typedef SeedTranslation = ({
  Map<String, String> exerciseNames,
  Map<String, String> exerciseInstructions,
  Map<String, String> routineNames,
  Map<String, String> programNames,
  Map<String, String> programDescriptions,
  Map<String, String> planNames,
});

const seedTranslations = <String, SeedTranslation>{
  'de': (
    exerciseNames: {
      'bench_press': 'Bankdrücken',
      'incline_dumbbell_press': 'Schrägbankdrücken mit Kurzhanteln',
      'cable_fly': 'Cable Flys',
      'push_up': 'Liegestütz',
      'deadlift': 'Kreuzheben',
      'barbell_row': 'Langhantelrudern',
      'lat_pulldown': 'Latzug',
      'pull_up': 'Klimmzug',
      'overhead_press': 'Schulterdrücken (Overhead Press)',
      'lateral_raise': 'Seitheben',
      'pike_push_up': 'Pike-Liegestütz',
      'dumbbell_curl': 'Kurzhantel-Curls',
      'triceps_pushdown': 'Trizepsdrücken am Kabel',
      'dips': 'Dips',
      'back_squat': 'Kniebeuge',
      'leg_press': 'Beinpresse',
      'romanian_deadlift': 'Rumänisches Kreuzheben',
      'bodyweight_squat': 'Kniebeuge ohne Gewicht',
      'lunge': 'Ausfallschritt',
      'hip_thrust': 'Hip Thrust',
      'glute_bridge': 'Glute Bridge',
      'plank': 'Unterarmstütz (Plank)',
      'crunch': 'Crunch',
      'mountain_climber': 'Mountain Climber',
      'jumping_jack': 'Hampelmann',
      'dumbbell_bench_press': 'Kurzhantel-Bankdrücken',
      'incline_bench_press': 'Schrägbankdrücken',
      'chest_press_machine': 'Brustpresse',
      'pec_deck': 'Butterfly',
      'seated_cable_row': 'Rudern am Kabelzug (sitzend)',
      'one_arm_dumbbell_row': 'Einarmiges Kurzhantelrudern',
      'chin_up': 'Klimmzug im Untergriff',
      'dumbbell_shoulder_press': 'Kurzhantel-Schulterdrücken',
      'rear_delt_fly': 'Reverse Flys',
      'face_pull': 'Face Pulls',
      'barbell_curl': 'Langhantel-Curls',
      'hammer_curl': 'Hammer Curls',
      'cable_curl': 'Bizeps-Curls am Kabel',
      'skull_crusher': 'French Press (Skull Crusher)',
      'overhead_triceps_extension': 'Trizepsdrücken über Kopf',
      'close_grip_bench_press': 'Enges Bankdrücken',
      'front_squat': 'Frontkniebeuge',
      'goblet_squat': 'Goblet Squat',
      'bulgarian_split_squat': 'Bulgarian Split Squat',
      'leg_extension': 'Beinstrecker',
      'leg_curl': 'Beinbeuger',
      'calf_raise': 'Wadenheben',
      'hanging_leg_raise': 'Beinheben im Hang',
      'cable_crunch': 'Kabel-Crunch',
      'dead_bug': 'Dead Bug',
      'side_plank': 'Seitstütz',
      'burpee': 'Burpee',
      'kettlebell_swing': 'Kettlebell Swing',
      'weighted_pull_up': 'Klimmzug mit Zusatzgewicht',
      'weighted_dips': 'Dips mit Zusatzgewicht',
      'barbell_shrug': 'Langhantel-Shrugs',
      'dumbbell_shrug': 'Kurzhantel-Shrugs',
      'wrist_curl': 'Handgelenk-Curls',
      'reverse_curl': 'Reverse Curls',
      'dead_hang': 'Hängen an der Stange',
      'back_extension': 'Rückenstrecken (Hyperextensions)',
      'good_morning': 'Good Mornings',
      'superman': 'Superman',
      'decline_bench_press': 'Negativ-Bankdrücken',
      'smith_bench_press': 'Bankdrücken an der Multipresse',
      'dumbbell_fly': 'Kurzhantel-Flys',
      'incline_dumbbell_fly': 'Schrägbank-Flys mit Kurzhanteln',
      'low_to_high_cable_fly': 'Cable Flys von unten nach oben',
      'incline_chest_press_machine': 'Schrägbank-Brustpresse',
      'chest_dips': 'Dips für die Brust',
      'incline_push_up': 'Erhöhte Liegestütze',
      'decline_push_up': 'Liegestütze mit erhöhten Füßen',
      'dumbbell_floor_press': 'Floor Press mit Kurzhanteln',
      't_bar_row': 'T-Bar-Rudern',
      'pendlay_row': 'Pendlay-Rudern',
      'machine_row': 'Rudern an der Maschine',
      'chest_supported_row': 'Kurzhantelrudern auf der Schrägbank',
      'close_grip_lat_pulldown': 'Latzug mit engem Griff',
      'straight_arm_pulldown': 'Überzüge am Kabel mit gestreckten Armen',
      'band_assisted_pull_up': 'Klimmzüge mit Band',
      'inverted_row': 'Umgekehrtes Rudern',
      'neutral_grip_pull_up': 'Klimmzüge im Neutralgriff',
      'rack_pull': 'Rack Pulls',
      'trap_bar_deadlift': 'Kreuzheben mit Trap Bar',
      'single_arm_cable_row': 'Einarmiges Kabelrudern',
      'dumbbell_pullover': 'Kurzhantel-Pullover',
      'renegade_row': 'Renegade Rows',
      'arnold_press': 'Arnold Press',
      'shoulder_press_machine': 'Schulterpresse an der Maschine',
      'push_press': 'Push Press',
      'cable_lateral_raise': 'Seitheben am Kabel',
      'machine_lateral_raise': 'Seitheben an der Maschine',
      'front_raise': 'Frontheben mit Kurzhanteln',
      'upright_row': 'Aufrechtes Rudern',
      'reverse_pec_deck': 'Reverse Butterfly',
      'band_pull_apart': 'Band Pull-Aparts',
      'handstand_push_up': 'Handstand-Liegestütze',
      'landmine_press': 'Landmine Press',
      'preacher_curl': 'Scott-Curls',
      'concentration_curl': 'Konzentrationscurls',
      'incline_dumbbell_curl': 'Schrägbank-Curls',
      'ez_bar_curl': 'SZ-Curls',
      'rope_hammer_curl': 'Hammer Curls am Seil',
      'machine_biceps_curl': 'Bizeps-Curls an der Maschine',
      'band_curl': 'Bizeps-Curls mit Band',
      'rope_pushdown': 'Trizepsdrücken am Seil',
      'overhead_cable_extension': 'Trizepsdrücken über Kopf am Kabel',
      'triceps_kickback': 'Trizeps-Kickbacks',
      'bench_dips': 'Bank-Dips',
      'machine_triceps_dip': 'Dip-Maschine',
      'single_arm_pushdown': 'Einarmiges Trizepsdrücken am Kabel',
      'diamond_push_up': 'Diamant-Liegestütze',
      'reverse_wrist_curl': 'Reverse Handgelenk-Curls',
      'hack_squat': 'Hackenschmidt-Kniebeuge',
      'smith_squat': 'Kniebeuge an der Multipresse',
      'walking_lunge': 'Ausfallschritte im Gehen',
      'reverse_lunge': 'Ausfallschritte nach hinten',
      'step_up': 'Step-ups',
      'split_squat': 'Split Squats',
      'sumo_squat': 'Sumo-Kniebeuge mit Kurzhantel',
      'pistol_squat': 'Pistol Squat (einbeinige Kniebeuge)',
      'single_leg_press': 'Einbeinige Beinpresse',
      'hip_adduction_machine': 'Adduktorenmaschine',
      'wall_sit': 'Wandsitzen',
      'jump_squat': 'Sprungkniebeugen',
      'box_jump': 'Box Jumps',
      'seated_leg_curl': 'Sitzende Beinbeuger-Curls',
      'nordic_curl': 'Nordic Hamstring Curls',
      'single_leg_rdl': 'Einbeiniges rumänisches Kreuzheben',
      'dumbbell_romanian_deadlift': 'Rumänisches Kreuzheben mit Kurzhanteln',
      'stiff_leg_deadlift': 'Kreuzheben mit gestreckten Beinen',
      'stability_ball_leg_curl': 'Beinbeuger-Curls auf dem Gymnastikball',
      'sumo_deadlift': 'Sumo-Kreuzheben',
      'cable_glute_kickback': 'Glute Kickbacks am Kabel',
      'hip_abduction_machine': 'Abduktorenmaschine',
      'machine_hip_thrust': 'Hip Thrust an der Maschine',
      'single_leg_glute_bridge': 'Einbeinige Glute Bridge',
      'donkey_kick': 'Donkey Kicks',
      'fire_hydrant': 'Fire Hydrants',
      'banded_lateral_walk': 'Seitwärtsgehen mit Band',
      'cable_pull_through': 'Cable Pull-Through',
      'seated_calf_raise': 'Wadenheben im Sitzen',
      'single_leg_calf_raise': 'Einbeiniges Wadenheben',
      'leg_press_calf_raise': 'Wadenheben an der Beinpresse',
      'sit_up': 'Sit-ups',
      'decline_sit_up': 'Sit-ups auf der Negativbank',
      'bicycle_crunch': 'Bicycle Crunches',
      'reverse_crunch': 'Reverse Crunches',
      'lying_leg_raise': 'Beinheben im Liegen',
      'captains_chair_knee_raise': 'Knieheben im Stütz (Captain’s Chair)',
      'ab_wheel_rollout': 'Bauchroller',
      'russian_twist': 'Russian Twists',
      'v_up': 'V-Ups',
      'hollow_hold': 'Hollow Body Hold',
      'pallof_press': 'Pallof Press',
      'cable_woodchopper': 'Holzhacker am Kabel',
      'plank_shoulder_tap': 'Plank mit Schultertippen',
      'bird_dog': 'Bird Dog',
      'power_clean': 'Umsetzen (Power Clean)',
      'thruster': 'Thruster',
      'turkish_get_up': 'Turkish Get-up',
      'bear_crawl': 'Bärengang',
      'high_knees': 'Kniehebelauf',
      'jump_rope': 'Seilspringen',
      'rowing_machine': 'Rudergerät',
      'stationary_bike': 'Heimtrainer',
      'treadmill_run': 'Laufen auf dem Laufband',
      'elliptical': 'Crosstrainer',
      'stair_climber': 'Stepper (Treppensteiger)',
      'air_bike': 'Air Bike',
    },
    exerciseInstructions: {
      'bench_press':
        '1. Leg dich auf die Bank, Augen unter der Stange, Füße flach auf dem Boden.\n'
        '2. Greif etwas breiter als schulterbreit, zieh die Schulterblätter zusammen.\n'
        '3. Senk die Stange kontrolliert zur Brustmitte, Ellbogen etwa 45° vom Körper.\n'
        '4. Drück sie bis zu gestreckten Armen hoch, ohne die Hüfte anzuheben.',
      'incline_dumbbell_press':
        '1. Stell die Bank auf 30–45° ein, Kurzhanteln auf Brusthöhe.\n'
        '2. Schulterblätter nach hinten, Füße auf dem Boden.\n'
        '3. Drück nach oben und leicht zusammen, dann langsam bis auf Brusthöhe absenken.',
      'cable_fly':
        '1. Stell dich zwischen die Seilzüge, Ellbogen leicht gebeugt.\n'
        '2. Führ die Griffe im Bogen vor der Brust zusammen.\n'
        '3. Langsam zurück, bis du eine Dehnung spürst, Ellbogen bleiben fixiert.',
      'push_up':
        '1. Hände etwas breiter als schulterbreit, Körper in einer geraden Linie.\n'
        '2. Senk die Brust bis knapp über den Boden, Ellbogen etwa 45° vom Körper.\n'
        '3. Drück dich wieder hoch, Bauch und Po bleiben angespannt.',
      'deadlift':
        '1. Stange über der Fußmitte, Füße hüftbreit.\n'
        '2. Beug dich in der Hüfte, greif die Stange, Rücken neutral.\n'
        '3. Drück den Boden weg und richte dich auf, Stange nah an den Beinen.\n'
        '4. Kontrolliert absenken, indem du die Hüfte nach hinten schiebst.',
      'barbell_row':
        '1. Beug dich auf etwa 45° vor, Rücken gerade, Knie leicht gebeugt.\n'
        '2. Zieh die Stange zur unteren Brust oder zum Bauch.\n'
        '3. Schulterblätter zusammenziehen, dann langsam absenken.',
      'lat_pulldown':
        '1. Greif etwas breiter als schulterbreit, Oberschenkel unter den Polstern.\n'
        '2. Zieh die Stange zur oberen Brust, Ellbogen nach unten und hinten.\n'
        '3. Langsam zurück bis zu gestreckten Armen, ohne Schwung.',
      'pull_up':
        '1. Häng dich im Obergriff an die Stange, Schultern aktiv.\n'
        '2. Zieh dich hoch, bis dein Kinn über der Stange ist.\n'
        '3. Kontrolliert bis in den vollen Hang absenken.',
      'overhead_press':
        '1. Stange vorne auf den Schultern, Griff knapp außerhalb der Schultern.\n'
        '2. Po und Bauch anspannen, Stange senkrecht nach oben drücken.\n'
        '3. Kopf leicht zurück, wenn die Stange vorbeigeht, über dem Kopf durchstrecken.',
      'lateral_raise':
        '1. Steh aufrecht, Kurzhanteln seitlich, Ellbogen leicht gebeugt.\n'
        '2. Seitlich bis auf Schulterhöhe anheben.\n'
        '3. Langsam absenken, kein Schwung.',
      'pike_push_up':
        '1. Starte in der Liegestützposition und heb die Hüfte zu einem umgedrehten V.\n'
        '2. Senk den Kopf zwischen den Händen Richtung Boden.\n'
        '3. Drück dich über die Schultern wieder hoch.',
      'dumbbell_curl':
        '1. Steh aufrecht, Ellbogen am Körper.\n'
        '2. Curl die Kurzhanteln hoch, ohne die Ellbogen zu bewegen.\n'
        '3. Langsam bis zu gestreckten Armen absenken.',
      'triceps_pushdown':
        '1. Stell dich an den Kabelzug, Ellbogen fest am Körper.\n'
        '2. Drück den Griff nach unten, bis die Arme gestreckt sind.\n'
        '3. Langsam zurück, Ellbogen bleiben ruhig.',
      'dips':
        '1. Stütz dich mit gestreckten Armen auf den Barren.\n'
        '2. Senk dich ab, bis die Oberarme etwa parallel zum Boden sind.\n'
        '3. Drück dich wieder hoch, Schultern nicht nach vorne fallen lassen.',
      'back_squat':
        '1. Stange auf dem oberen Rücken, Füße schulterbreit, Zehen leicht nach außen.\n'
        '2. Bauch anspannen und zwischen die Fersen setzen.\n'
        '3. Knie folgen den Zehen, Rücken bleibt neutral.\n'
        '4. Über den ganzen Fuß nach oben drücken.',
      'leg_press':
        '1. Füße schulterbreit in der Mitte der Plattform.\n'
        '2. Absenken, bis die Knie etwa 90° haben, unterer Rücken bleibt am Polster.\n'
        '3. Hochdrücken, ohne die Knie hart durchzustrecken.',
      'romanian_deadlift':
        '1. Steh mit der Stange, Knie leicht gebeugt.\n'
        '2. Schieb die Hüfte nach hinten und führ die Stange an den Beinen entlang nach unten.\n'
        '3. Stopp, wenn du eine Dehnung im hinteren Oberschenkel spürst, Rücken gerade.\n'
        '4. Zurück, indem du die Hüfte nach vorne schiebst.',
      'bodyweight_squat':
        '1. Füße schulterbreit, Arme zur Balance nach vorne.\n'
        '2. Setz dich mit geradem Rücken so tief wie möglich ab.\n'
        '3. Über die Fersen wieder aufstehen.',
      'lunge':
        '1. Mach einen Schritt nach vorne und senk dich ab, bis beide Knie etwa 90° haben.\n'
        '2. Vorderes Knie bleibt über dem Fuß, Oberkörper aufrecht.\n'
        '3. Zurück in die Ausgangsposition drücken und Bein wechseln.',
      'hip_thrust':
        '1. Oberer Rücken auf der Bank, Stange über der Hüfte.\n'
        '2. Über die Fersen drücken und die Hüfte heben, bis der Körper gerade ist.\n'
        '3. Oben den Po anspannen, kontrolliert absenken.',
      'glute_bridge':
        '1. Leg dich auf den Rücken, Knie gebeugt, Füße am Boden.\n'
        '2. Heb die Hüfte, indem du den Po anspannst.\n'
        '3. Oben kurz halten und langsam absenken.',
      'plank':
        '1. Unterarme unter den Schultern, Körper in einer geraden Linie.\n'
        '2. Bauch und Po anspannen, Hüfte nicht durchhängen lassen.\n'
        '3. Gleichmäßig atmen und halten.',
      'crunch':
        '1. Leg dich auf den Rücken, Knie gebeugt, Hände neben dem Kopf.\n'
        '2. Roll die Schultern mit den Bauchmuskeln vom Boden ab.\n'
        '3. Langsam absenken, nicht am Nacken ziehen.',
      'mountain_climber':
        '1. Starte in der Liegestützposition.\n'
        '2. Zieh abwechselnd die Knie Richtung Brust.\n'
        '3. Hüfte tief und Tempo gleichmäßig halten.',
      'jumping_jack':
        '1. Steh mit geschlossenen Füßen, Arme seitlich.\n'
        '2. Spring in die Grätsche und heb die Arme über den Kopf.\n'
        '3. Zurückspringen und im gleichmäßigen Tempo wiederholen.',
      'dumbbell_bench_press':
        '1. Leg dich auf eine Flachbank, Kurzhanteln auf Brusthöhe.\n'
        '2. Drück nach oben und leicht zusammen.\n'
        '3. Langsam absenken, bis du eine Dehnung in der Brust spürst.',
      'incline_bench_press':
        '1. Bank auf 30–45°, Griff etwas breiter als schulterbreit.\n'
        '2. Senk die Stange zur oberen Brust.\n'
        '3. Hochdrücken, Schulterblätter bleiben hinten.',
      'chest_press_machine':
        '1. Stell den Sitz so ein, dass die Griffe auf Höhe der Brustmitte sind.\n'
        '2. Nach vorne drücken, bis die Arme fast gestreckt sind.\n'
        '3. Langsam zurück, Rücken bleibt am Polster.',
      'pec_deck':
        '1. Setz dich mit dem Rücken ans Polster, Ellbogen leicht gebeugt.\n'
        '2. Führ die Griffe vor der Brust zusammen.\n'
        '3. Langsam zurück bis zu einer angenehmen Dehnung.',
      'seated_cable_row':
        '1. Sitz aufrecht, Füße auf der Plattform, Knie leicht gebeugt.\n'
        '2. Zieh den Griff zum Bauch, Ellbogen nah am Körper.\n'
        '3. Schulterblätter zusammenziehen, langsam zurück, ohne den Rücken zu runden.',
      'one_arm_dumbbell_row':
        '1. Ein Knie und eine Hand auf der Bank, Rücken gerade.\n'
        '2. Zieh die Kurzhantel Richtung Hüfte.\n'
        '3. Langsam bis zur vollen Dehnung absenken.',
      'chin_up':
        '1. Häng dich im Untergriff schulterbreit an die Stange.\n'
        '2. Zieh dich hoch, bis dein Kinn über der Stange ist.\n'
        '3. Kontrolliert bis in den vollen Hang absenken.',
      'dumbbell_shoulder_press':
        '1. Sitz oder steh, Kurzhanteln auf Schulterhöhe.\n'
        '2. Über den Kopf drücken, ohne ins Hohlkreuz zu gehen.\n'
        '3. Langsam wieder zu den Schultern absenken.',
      'rear_delt_fly':
        '1. Beug dich mit geradem Rücken vor, Kurzhanteln hängen nach unten.\n'
        '2. Heb die Arme mit leicht gebeugten Ellbogen seitlich an.\n'
        '3. Langsam absenken, keinen Schwung nutzen.',
      'face_pull':
        '1. Seil auf Kopfhöhe, Daumen zeigen zu dir.\n'
        '2. Zieh Richtung Gesicht, Ellbogen hoch und weit.\n'
        '3. Oberen Rücken anspannen, langsam zurück.',
      'barbell_curl':
        '1. Steh aufrecht, schulterbreiter Untergriff.\n'
        '2. Curl die Stange hoch, ohne mit dem Körper zu schwingen.\n'
        '3. Langsam bis zu gestreckten Armen absenken.',
      'hammer_curl':
        '1. Halte die Kurzhanteln mit den Handflächen zueinander.\n'
        '2. Hochcurlen, Ellbogen bleiben am Körper.\n'
        '3. Langsam absenken.',
      'cable_curl':
        '1. Steh mit Blick zum unteren Seilzug, Ellbogen am Körper.\n'
        '2. Curl den Griff bis zu den Schultern hoch.\n'
        '3. Langsam absenken, Spannung halten.',
      'skull_crusher':
        '1. Leg dich auf eine Bank, Stange mit gestreckten Armen über der Brust.\n'
        '2. Beug nur die Ellbogen und senk die Stange Richtung Stirn.\n'
        '3. Wieder strecken, Ellbogen zeigen nach oben.',
      'overhead_triceps_extension':
        '1. Halte eine Kurzhantel mit beiden Händen über dem Kopf.\n'
        '2. Senk sie durch Beugen der Ellbogen hinter den Kopf.\n'
        '3. Wieder strecken, Ellbogen bleiben nah am Kopf.',
      'close_grip_bench_press':
        '1. Leg dich auf die Bank, Griff etwa schulterbreit.\n'
        '2. Senk die Stange zur unteren Brust, Ellbogen nah am Körper.\n'
        '3. Durch Strecken der Ellbogen hochdrücken.',
      'front_squat':
        '1. Stange vorne auf den Schultern, Ellbogen hoch.\n'
        '2. Mit aufrechtem Oberkörper in die Hocke gehen.\n'
        '3. Hochdrücken, Ellbogen die ganze Zeit oben halten.',
      'goblet_squat':
        '1. Halte eine Kettlebell oder Kurzhantel vor der Brust.\n'
        '2. Mit geradem Rücken zwischen die Knie in die Hocke gehen.\n'
        '3. Über die Fersen wieder aufstehen.',
      'bulgarian_split_squat':
        '1. Hinterer Fuß auf einer Bank, vorderer Fuß eine Schrittlänge davor.\n'
        '2. Absenken, bis der vordere Oberschenkel etwa parallel ist.\n'
        '3. Über den vorderen Fuß hochdrücken, dann Bein wechseln.',
      'leg_extension':
        '1. Stell das Polster knapp über den Knöcheln ein.\n'
        '2. Streck die Beine vollständig.\n'
        '3. Langsam und kontrolliert absenken.',
      'leg_curl':
        '1. Stell das Polster knapp über den Fersen ein.\n'
        '2. Zieh die Fersen Richtung Po.\n'
        '3. Langsam zurück, Gewicht nicht fallen lassen.',
      'calf_raise':
        '1. Fußballen auf der Kante, Fersen frei.\n'
        '2. So hoch wie möglich auf die Zehenspitzen drücken.\n'
        '3. Langsam in die Dehnung absenken.',
      'hanging_leg_raise':
        '1. Häng dich an die Stange, Schultern aktiv.\n'
        '2. Heb die Beine oder Knie mit den Bauchmuskeln an, ohne zu schwingen.\n'
        '3. Langsam absenken.',
      'cable_crunch':
        '1. Knie dich mit Blick zum Kabelzug hin, Seil am Kopf.\n'
        '2. Roll dich durch Runden der Wirbelsäule nach unten ein, Hüfte bleibt ruhig.\n'
        '3. Langsam zurück.',
      'dead_bug':
        '1. Leg dich auf den Rücken, Arme nach oben, Knie im 90°-Winkel.\n'
        '2. Senk den gegenüberliegenden Arm und das Bein ab, unterer Rücken bleibt am Boden.\n'
        '3. Zurück und Seite wechseln.',
      'side_plank':
        '1. Leg dich auf die Seite, Ellbogen unter der Schulter.\n'
        '2. Heb die Hüfte, sodass dein Körper eine gerade Linie bildet.\n'
        '3. Halten, dann Seite wechseln.',
      'burpee':
        '1. Aus dem Stand in die Hocke gehen und die Hände auf den Boden setzen.\n'
        '2. Füße nach hinten in den Stütz springen, optional einen Liegestütz machen.\n'
        '3. Füße nach vorne springen und hochspringen.',
      'kettlebell_swing':
        '1. Kettlebell vor dir, Füße etwas breiter als hüftbreit.\n'
        '2. Schwing sie mit einer Hüftbeuge zwischen den Beinen nach hinten.\n'
        '3. Hüfte explosiv nach vorne strecken und die Kettlebell auf Brusthöhe schwingen, Arme locker.',
      'weighted_pull_up':
        '1. Häng eine Hantelscheibe an einen Dipgürtel oder klemm eine Kurzhantel zwischen die Füße.\n'
        '2. Häng dich im Obergriff an die Stange, Schultern aktiv.\n'
        '3. Zieh dich ohne Schwung hoch, bis dein Kinn über der Stange ist.\n'
        '4. Kontrolliert bis in den vollen Hang absenken. Trag nur das Zusatzgewicht ein.',
      'weighted_dips':
        '1. Häng eine Hantelscheibe an einen Dipgürtel oder klemm eine Kurzhantel zwischen die Füße.\n'
        '2. Stütz dich mit gestreckten Armen auf den Barren.\n'
        '3. Senk dich ab, bis die Oberarme etwa parallel zum Boden sind.\n'
        '4. Drück dich wieder hoch, Schultern nicht nach vorne fallen lassen. Trag nur das Zusatzgewicht ein.',
      'barbell_shrug':
        '1. Steh aufrecht, Stange mit gestreckten Armen, schulterbreiter Griff.\n'
        '2. Zieh die Schultern gerade nach oben Richtung Ohren, Arme bleiben gestreckt.\n'
        '3. Oben kurz halten, dann langsam absenken. Schultern nicht kreisen.',
      'dumbbell_shrug':
        '1. Steh mit einer Kurzhantel in jeder Hand, Handflächen zum Körper.\n'
        '2. Zieh die Schultern so hoch wie möglich gerade nach oben.\n'
        '3. Kurz halten und kontrolliert absenken.',
      'wrist_curl':
        '1. Setz dich, Unterarme mit den Handflächen nach oben auf Oberschenkel oder Bank, Handgelenke über der Kante.\n'
        '2. Lass die Kurzhanteln bis zu den Fingerspitzen rollen.\n'
        '3. Handgelenke so weit wie möglich hochbeugen, Unterarme bleiben ruhig.',
      'reverse_curl':
        '1. Steh aufrecht, Stange im schulterbreiten Obergriff.\n'
        '2. Curl die Stange hoch, Ellbogen am Körper, Handgelenke gerade.\n'
        '3. Langsam bis zu gestreckten Armen absenken.',
      'dead_hang':
        '1. Greif die Stange im schulterbreiten Obergriff.\n'
        '2. Häng mit gestreckten Armen, Füße in der Luft, Körper ruhig.\n'
        '3. Halte die vorgegebene Zeit, Schultern leicht aktiv.',
      'back_extension':
        '1. Polster knapp unter die Hüfte, Fersen fest einhaken.\n'
        '2. Oberkörper mit geradem Rücken absenken, bis du die Beinrückseite spürst.\n'
        '3. Bis in eine Linie mit den Beinen aufrichten, nicht überstrecken. Für mehr Last eine Scheibe halten.',
      'good_morning':
        '1. Stange auf dem oberen Rücken wie bei der Kniebeuge, Füße hüftbreit, Knie leicht gebeugt.\n'
        '2. Hüfte nach hinten schieben und mit geradem Rücken vorbeugen, bis der Oberkörper fast waagerecht ist.\n'
        '3. Hüfte nach vorne bringen und aufrichten. Mit wenig Gewicht beginnen.',
      'superman':
        '1. Leg dich auf den Bauch, Arme über dem Kopf gestreckt.\n'
        '2. Heb Arme, Brust und Beine gleichzeitig vom Boden.\n'
        '3. Oben eine Sekunde halten, dann langsam absenken.',
      'decline_bench_press':
        '1. Hak die Beine an der Negativbank ein, Griff etwas breiter als schulterbreit.\n'
        '2. Senk die Stange kontrolliert zur unteren Brust.\n'
        '3. Drück sie bis zu gestreckten Armen hoch, Schulterblätter bleiben zurückgezogen.',
      'smith_bench_press':
        '1. Stell die Bank so, dass die Stange über der Brustmitte liegt.\n'
        '2. Entriegle die Stange und senk sie kontrolliert zur Brust.\n'
        '3. Drück sie hoch, ohne die Ellbogen hart durchzustrecken, und häng sie am Ende ein.',
      'dumbbell_fly':
        '1. Leg dich auf eine Flachbank, Kurzhanteln über der Brust, Ellbogen leicht gebeugt.\n'
        '2. Öffne die Arme in einem weiten Bogen, bis du eine Dehnung in der Brust spürst.\n'
        '3. Führ die Hanteln wieder zusammen, der Ellbogenwinkel bleibt gleich.',
      'incline_dumbbell_fly':
        '1. Stell die Bank auf 30°, Kurzhanteln über der Brust, Ellbogen locker.\n'
        '2. Senk sie in einem weiten Bogen, bis du die obere Brust gedehnt spürst.\n'
        '3. Führ sie über der Brust wieder zusammen.',
      'low_to_high_cable_fly':
        '1. Stell beide Seilzüge unten ein und steh leicht vorgebeugt dazwischen.\n'
        '2. Führ die Griffe nach oben und vor der oberen Brust zusammen.\n'
        '3. Langsam zurück in die Dehnung, Ellbogen leicht gebeugt.',
      'incline_chest_press_machine':
        '1. Stell den Sitz so ein, dass die Griffe auf Höhe der oberen Brust sind.\n'
        '2. Drück die Griffe nach vorne oben, bis die Arme fast gestreckt sind.\n'
        '3. Langsam zurück, bis du eine Dehnung in der Brust spürst.',
      'chest_dips':
        '1. Stütz dich auf den Barren und lehn den Oberkörper nach vorne.\n'
        '2. Senk dich mit leicht ausgestellten Ellbogen ab, bis du die Brust gedehnt spürst.\n'
        '3. Drück dich wieder hoch, die Vorlage bleibt.',
      'incline_push_up':
        '1. Stütz die Hände auf eine Bank oder Box, Körper in einer Linie.\n'
        '2. Senk die Brust zur Kante, Ellbogen etwa 45° vom Körper.\n'
        '3. Drück dich wieder hoch. Je höher die Stütze, desto leichter.',
      'decline_push_up':
        '1. Leg die Füße auf eine Bank, Hände unter den Schultern am Boden.\n'
        '2. Senk die Brust mit fester Körpermitte zum Boden.\n'
        '3. Drück dich hoch, ohne dass die Hüfte durchhängt.',
      'dumbbell_floor_press':
        '1. Leg dich auf den Boden, Knie gebeugt, Kurzhanteln über der Brust.\n'
        '2. Senk ab, bis die Oberarme den Boden berühren, kurz halten.\n'
        '3. Drück wieder bis zu gestreckten Armen hoch.',
      't_bar_row':
        '1. Stell dich über die Stange, beug dich mit geradem Rücken vor und greif den Griff.\n'
        '2. Zieh das Gewicht zur Brust und zieh die Schulterblätter zusammen.\n'
        '3. Kontrolliert absenken, ohne den Rücken rund zu machen.',
      'pendlay_row':
        '1. Stange am Boden, Oberkörper fast waagerecht, Rücken gerade.\n'
        '2. Zieh die Stange explosiv zur unteren Brust.\n'
        '3. Leg sie nach jeder Wiederholung ab und richte dich neu aus.',
      'machine_row':
        '1. Setz dich mit der Brust ans Polster und greif die Griffe.\n'
        '2. Zieh die Griffe zum Körper, Ellbogen eng, Schulterblätter zusammen.\n'
        '3. Langsam zurück, bis die Arme gestreckt sind.',
      'chest_supported_row':
        '1. Leg dich bäuchlings auf eine Bank mit 30–45°, Kurzhanteln hängen nach unten.\n'
        '2. Zieh sie seitlich hoch und spann die Schulterblätter an.\n'
        '3. Langsam bis zur vollen Dehnung absenken.',
      'close_grip_lat_pulldown':
        '1. Setz dich mit engem oder V-Griff an den Latzug, Oberschenkel unter den Polstern.\n'
        '2. Zieh den Griff zur oberen Brust, Ellbogen nach unten und hinten.\n'
        '3. Lass ihn langsam nach oben, bis die Arme gestreckt sind.',
      'straight_arm_pulldown':
        '1. Steh vor dem oberen Kabel, Arme fast gestreckt, leicht vorgebeugt.\n'
        '2. Drück die Stange mit dem Latissimus im Bogen bis zu den Oberschenkeln.\n'
        '3. Langsam zurück, die Ellbogen bleiben fast gestreckt.',
      'band_assisted_pull_up':
        '1. Häng ein Widerstandsband über die Stange und stell Fuß oder Knie hinein.\n'
        '2. Zieh dich hoch, bis das Kinn über der Stange ist.\n'
        '3. Kontrolliert in den vollen Hang absenken. Dünneres Band = weniger Hilfe.',
      'inverted_row':
        '1. Häng dich unter eine tiefe Stange oder Ringe, Körper gerade, Fersen am Boden.\n'
        '2. Zieh die Brust zur Stange und spann die Schulterblätter an.\n'
        '3. Kontrolliert absenken. Je aufrechter, desto leichter.',
      'neutral_grip_pull_up':
        '1. Häng dich an parallele Griffe, Handflächen zueinander.\n'
        '2. Zieh dich hoch, bis das Kinn über den Griffen ist.\n'
        '3. Kontrolliert in den vollen Hang absenken.',
      'rack_pull':
        '1. Leg die Stange knapp unter oder über Kniehöhe auf die Ablagen.\n'
        '2. Greif sie, spann den Rumpf an und richte dich mit der Hüfte nach vorne auf.\n'
        '3. Mit geradem Rücken zurück auf die Ablagen.',
      'trap_bar_deadlift':
        '1. Stell dich in die Trap Bar, Füße hüftbreit, greif die Griffe.\n'
        '2. Spann an, drück den Boden weg und steh aufrecht auf.\n'
        '3. Mit geradem Rücken wieder absenken.',
      'single_arm_cable_row':
        '1. Greif einen Einzelgriff am Kabel auf Hüfthöhe, Arm gestreckt.\n'
        '2. Zieh ihn zur Seite, Ellbogen nah am Körper.\n'
        '3. Langsam zurück und die Schulter leicht nach vorne lassen.',
      'dumbbell_pullover':
        '1. Leg dich auf eine Bank und halt eine Kurzhantel mit beiden Händen über der Brust.\n'
        '2. Senk sie im Bogen hinter den Kopf, Ellbogen leicht gebeugt.\n'
        '3. Zieh sie zurück über die Brust.',
      'renegade_row':
        '1. Geh mit den Händen auf zwei Kurzhanteln in den Liegestütz, Füße breit.\n'
        '2. Zieh eine Hantel zur Hüfte, ohne die Hüfte zu drehen.\n'
        '3. Absetzen und mit dem anderen Arm wiederholen.',
      'arnold_press':
        '1. Setz dich, Kurzhanteln vor den Schultern, Handflächen zu dir.\n'
        '2. Drück nach oben und dreh dabei die Handflächen nach vorne.\n'
        '3. Beim Absenken zurück in die Ausgangsposition drehen.',
      'shoulder_press_machine':
        '1. Stell den Sitz so ein, dass die Griffe auf Schulterhöhe beginnen.\n'
        '2. Drück nach oben, bis die Arme fast gestreckt sind.\n'
        '3. Langsam zurück auf Schulterhöhe.',
      'push_press':
        '1. Stange vorne auf den Schultern, Füße hüftbreit.\n'
        '2. Kurz in die Knie gehen, dann mit Schwung aus den Beinen die Stange über den Kopf drücken.\n'
        '3. Kontrolliert zurück auf die Schultern.',
      'cable_lateral_raise':
        '1. Steh seitlich zum unteren Kabel, Griff in der entfernten Hand.\n'
        '2. Heb den Arm seitlich bis auf Schulterhöhe.\n'
        '3. Langsam absenken, Spannung halten.',
      'machine_lateral_raise':
        '1. Setz dich, die Polster liegen außen an den Armen.\n'
        '2. Heb die Arme bis auf Schulterhöhe.\n'
        '3. Langsam absenken, Gewicht nicht ablegen.',
      'front_raise':
        '1. Steh mit Kurzhanteln vor den Oberschenkeln.\n'
        '2. Heb sie nach vorne bis auf Schulterhöhe, Arme fast gestreckt.\n'
        '3. Langsam absenken, ohne Schwung.',
      'upright_row':
        '1. Halt die Stange vor den Oberschenkeln, Griff etwa schulterbreit.\n'
        '2. Zieh sie am Körper entlang bis auf Brusthöhe, die Ellbogen führen.\n'
        '3. Langsam absenken. Bei Druck in der Schulter nicht so hoch ziehen.',
      'reverse_pec_deck':
        '1. Setz dich mit Blick zur Maschine, Brust am Polster, greif die Griffe.\n'
        '2. Öffne die Arme im Bogen nach hinten bis in Linie mit dem Körper.\n'
        '3. Langsam zurück.',
      'band_pull_apart':
        '1. Halt ein Band vor dir auf Schulterhöhe, Arme gestreckt.\n'
        '2. Zieh es bis zur Brust auseinander und spann die Schulterblätter an.\n'
        '3. Langsam zurück.',
      'handstand_push_up':
        '1. Schwing dich an der Wand in den Handstand, Hände schulterbreit.\n'
        '2. Senk den Kopf kontrolliert Richtung Boden.\n'
        '3. Drück dich bis zu gestreckten Armen hoch. Leg eine Matte unter den Kopf.',
      'landmine_press':
        '1. Halt das Ende einer Landmine-Stange an der Schulter, Schrittstellung.\n'
        '2. Drück sie nach oben vorne, bis der Arm gestreckt ist.\n'
        '3. Kontrolliert zurück zur Schulter.',
      'preacher_curl':
        '1. Setz dich an die Scottbank, Oberarme flach auf dem Polster, SZ-Stange in den Händen.\n'
        '2. Curl die Stange hoch, ohne die Ellbogen anzuheben.\n'
        '3. Langsam fast bis zur Streckung absenken.',
      'concentration_curl':
        '1. Setz dich auf eine Bank, Ellbogen an der Innenseite des Oberschenkels.\n'
        '2. Curl die Kurzhantel zur Schulter.\n'
        '3. Langsam bis zur vollen Dehnung absenken.',
      'incline_dumbbell_curl':
        '1. Lehn dich an eine Bank mit 45–60°, Arme hängen gerade nach unten.\n'
        '2. Curl die Kurzhanteln hoch, die Oberarme bleiben ruhig.\n'
        '3. Langsam bis zur vollen Dehnung absenken.',
      'ez_bar_curl':
        '1. Steh mit der SZ-Stange an den abgewinkelten Griffen, Arme gestreckt.\n'
        '2. Curl sie hoch, ohne mit dem Körper zu schwingen.\n'
        '3. Langsam bis zu gestreckten Armen absenken.',
      'rope_hammer_curl':
        '1. Häng ein Seil an den unteren Kabelzug, Handflächen zueinander.\n'
        '2. Curl das Seil hoch, Ellbogen am Körper.\n'
        '3. Langsam absenken, Spannung halten.',
      'machine_biceps_curl':
        '1. Setz dich, Oberarme aufs Polster, greif die Griffe.\n'
        '2. Curl die Griffe zu den Schultern.\n'
        '3. Langsam fast bis zur Streckung absenken.',
      'band_curl':
        '1. Stell dich auf die Mitte des Bandes, Enden in den Händen.\n'
        '2. Curl die Hände zu den Schultern, Ellbogen am Körper.\n'
        '3. Langsam absenken.',
      'rope_pushdown':
        '1. Greif das Seil am oberen Kabel, Ellbogen am Körper.\n'
        '2. Drück das Seil nach unten und zieh unten die Enden auseinander.\n'
        '3. Lass es langsam bis etwa 90° im Ellbogen hoch.',
      'overhead_cable_extension':
        '1. Steh mit dem Rücken zum Kabel, Seil hinter dem Kopf, Ellbogen oben.\n'
        '2. Streck die Arme nach vorne oben.\n'
        '3. Beug die Ellbogen langsam wieder hinter den Kopf.',
      'triceps_kickback':
        '1. Beug dich vor, Oberarm parallel zum Körper, Ellbogen gebeugt.\n'
        '2. Streck den Arm nach hinten ganz durch.\n'
        '3. Langsam zurückbeugen, der Oberarm bleibt ruhig.',
      'bench_dips':
        '1. Stütz die Hände hinter dir auf die Bankkante, Beine nach vorne.\n'
        '2. Beug die Ellbogen auf etwa 90° und senk dich ab.\n'
        '3. Drück dich wieder bis zu gestreckten Armen hoch.',
      'machine_triceps_dip':
        '1. Setz dich in die Maschine und greif die seitlichen Griffe.\n'
        '2. Drück die Griffe nach unten, bis die Arme gestreckt sind.\n'
        '3. Lass sie langsam bis etwa 90° im Ellbogen hoch.',
      'single_arm_pushdown':
        '1. Greif einen Einzelgriff am oberen Kabel, Ellbogen am Körper.\n'
        '2. Drück ihn nach unten, bis der Arm gestreckt ist.\n'
        '3. Langsam hochlassen, der Ellbogen bleibt an seinem Platz.',
      'diamond_push_up':
        '1. Liegestützposition, Hände unter der Brust zusammen, Finger bilden eine Raute.\n'
        '2. Senk die Brust zu den Händen, Ellbogen am Körper.\n'
        '3. Mit geradem Körper wieder hochdrücken.',
      'reverse_wrist_curl':
        '1. Setz dich, Unterarme auf den Oberschenkeln, Handflächen nach unten, Handgelenke über den Knien.\n'
        '2. Heb die Handrücken so hoch wie möglich.\n'
        '3. Langsam absenken.',
      'hack_squat':
        '1. Stell dich auf die Plattform, Rücken am Polster, Schultern unter den Polstern.\n'
        '2. Geh in die Hocke, bis die Oberschenkel mindestens parallel zur Plattform sind.\n'
        '3. Drück dich über den ganzen Fuß wieder hoch.',
      'smith_squat':
        '1. Stange auf dem oberen Rücken, Füße etwas vor der Stange.\n'
        '2. Geh mit geradem Rücken mindestens bis zur Parallele runter.\n'
        '3. Steh auf und häng die Stange am Ende ein.',
      'walking_lunge':
        '1. Halt Kurzhanteln seitlich und mach einen langen Schritt nach vorne.\n'
        '2. Senk das hintere Knie fast bis zum Boden.\n'
        '3. Drück dich über den vorderen Fuß hoch und geh direkt in den nächsten Schritt.',
      'reverse_lunge':
        '1. Steh aufrecht, Kurzhanteln seitlich.\n'
        '2. Tritt nach hinten und senk das hintere Knie fast bis zum Boden.\n'
        '3. Über den vorderen Fuß zurückdrücken. Beine abwechseln.',
      'step_up':
        '1. Stell dich mit Kurzhanteln vor eine Bank oder Box.\n'
        '2. Setz einen Fuß darauf und steig mit Kraft aus diesem Bein hoch.\n'
        '3. Langsam wieder runter. Beine abwechseln oder eine Seite nach der anderen.',
      'split_squat':
        '1. Stell dich in eine lange Schrittstellung, Kurzhanteln in den Händen.\n'
        '2. Senk dich senkrecht ab, bis das hintere Knie fast den Boden berührt.\n'
        '3. Wieder hochdrücken. Alle Wiederholungen, dann Seite wechseln.',
      'sumo_squat':
        '1. Breiter Stand, Fußspitzen nach außen, eine Kurzhantel zwischen den Beinen.\n'
        '2. Geh mit aufrechtem Oberkörper in die Hocke, Knie zeigen in Richtung Zehen.\n'
        '3. Steh auf und spann den Po an.',
      'pistol_squat':
        '1. Steh auf einem Bein, das andere gestreckt nach vorne.\n'
        '2. Geh kontrolliert so tief wie möglich, Arme vorne zum Ausbalancieren.\n'
        '3. Wieder aufstehen. Anfangs darfst du dich festhalten.',
      'single_leg_press':
        '1. Setz dich in die Beinpresse, ein Fuß mittig auf der Plattform.\n'
        '2. Lass die Plattform ab, bis das Knie etwa 90° gebeugt ist.\n'
        '3. Drück zurück, ohne das Knie zu überstrecken. Beine wechseln.',
      'hip_adduction_machine':
        '1. Setz dich in die Maschine, die Polster innen an den Knien.\n'
        '2. Drück die Beine zusammen.\n'
        '3. Langsam wieder öffnen.',
      'wall_sit':
        '1. Lehn dich mit dem Rücken an eine Wand und rutsch nach unten.\n'
        '2. Stopp, wenn die Knie etwa 90° gebeugt sind, Füße unter den Knien.\n'
        '3. Halte die vorgegebene Zeit, Rücken flach an der Wand.',
      'jump_squat':
        '1. Steh mit schulterbreiten Füßen.\n'
        '2. Geh in die Hocke und spring explosiv hoch.\n'
        '3. Weich landen und direkt in die nächste Kniebeuge.',
      'box_jump':
        '1. Stell dich vor eine stabile Box.\n'
        '2. Schwing die Arme und spring auf die Box, weich landen.\n'
        '3. Ganz aufrichten, dann heruntersteigen.',
      'seated_leg_curl':
        '1. Setz dich in die Maschine, Polster über den Fersen, Oberschenkel fixiert.\n'
        '2. Zieh die Fersen so weit wie möglich nach unten hinten.\n'
        '3. Langsam zurück.',
      'nordic_curl':
        '1. Knie dich hin und fixier die Fersen unter etwas Stabilem.\n'
        '2. Senk den Körper so langsam wie möglich nach vorne, Hüfte gestreckt.\n'
        '3. Fang dich mit den Händen ab und zieh dich mit dem Beinbeuger zurück.',
      'single_leg_rdl':
        '1. Steh auf einem Bein mit einer Kurzhantel, Knie leicht gebeugt.\n'
        '2. Beug dich vor, das freie Bein geht nach hinten, Rücken gerade.\n'
        '3. Mit der Hüfte nach vorne wieder aufrichten.',
      'dumbbell_romanian_deadlift':
        '1. Steh mit Kurzhanteln vor den Oberschenkeln, Knie locker.\n'
        '2. Schieb die Hüfte nach hinten und führ die Hanteln an den Beinen entlang nach unten.\n'
        '3. Bei Dehnung im Beinbeuger stoppen und aufrichten.',
      'stiff_leg_deadlift':
        '1. Steh mit der Stange in den Händen, Beine fast gestreckt.\n'
        '2. Beug dich mit geradem Rücken vor und führ die Stange an den Beinen entlang.\n'
        '3. Mit Beinbeuger und Po wieder aufrichten.',
      'stability_ball_leg_curl':
        '1. Leg dich auf den Rücken, Fersen auf dem Ball, Hüfte angehoben.\n'
        '2. Roll den Ball durch Beugen der Knie zu dir.\n'
        '3. Langsam zurückrollen, die Hüfte bleibt oben.',
      'sumo_deadlift':
        '1. Breiter Stand, Fußspitzen nach außen, Stange zwischen den Beinen greifen.\n'
        '2. Spann an, drück die Knie nach außen und steh mit der Stange nah am Körper auf.\n'
        '3. Mit geradem Rücken wieder absetzen.',
      'cable_glute_kickback':
        '1. Leg eine Fußmanschette am unteren Kabel an und halt dich an der Maschine fest.\n'
        '2. Kick das Bein mit angespanntem Po nach hinten oben.\n'
        '3. Langsam zurück, ohne ins Hohlkreuz zu gehen.',
      'hip_abduction_machine':
        '1. Setz dich in die Maschine, die Polster außen an den Knien.\n'
        '2. Drück die Beine so weit wie möglich auseinander.\n'
        '3. Langsam wieder zusammenführen.',
      'machine_hip_thrust':
        '1. Leg den oberen Rücken ans Polster und den Gurt über die Hüfte.\n'
        '2. Drück die Hüfte hoch, bis Knie bis Schultern eine Linie bilden.\n'
        '3. Oben den Po anspannen und langsam absenken.',
      'single_leg_glute_bridge':
        '1. Leg dich auf den Rücken, ein Fuß am Boden, das andere Bein gestreckt nach oben.\n'
        '2. Drück die Hüfte über die Ferse des Standbeins hoch.\n'
        '3. Langsam absenken. Alle Wiederholungen, dann Seite wechseln.',
      'donkey_kick':
        '1. Geh in den Vierfüßlerstand, Hände unter den Schultern.\n'
        '2. Heb ein gebeugtes Bein nach hinten oben, Fußsohle zur Decke.\n'
        '3. Langsam absenken, ohne ins Hohlkreuz zu gehen.',
      'fire_hydrant':
        '1. Geh in den Vierfüßlerstand, Rücken gerade.\n'
        '2. Heb ein gebeugtes Bein seitlich bis auf Hüfthöhe.\n'
        '3. Langsam absenken, die Hüfte bleibt gerade.',
      'banded_lateral_walk':
        '1. Leg ein Mini-Band über die Knie oder Knöchel und beug die Knie leicht.\n'
        '2. Geh seitwärts, das Band bleibt gespannt.\n'
        '3. Zähl die Schritte in eine Richtung und geh zurück.',
      'cable_pull_through':
        '1. Steh mit dem Rücken zum unteren Kabel, Seil zwischen den Beinen.\n'
        '2. Beug dich mit geradem Rücken vor und lass das Seil nach hinten.\n'
        '3. Mit der Hüfte nach vorne aufrichten und den Po anspannen.',
      'seated_calf_raise':
        '1. Setz dich, Polster auf den Oberschenkeln, Fußballen auf der Stufe.\n'
        '2. Heb die Fersen so hoch wie möglich.\n'
        '3. Langsam bis zur vollen Dehnung absenken.',
      'single_leg_calf_raise':
        '1. Stell dich mit einem Fuß auf eine Stufenkante und halt dich fest.\n'
        '2. Geh so hoch wie möglich auf die Zehenspitze.\n'
        '3. Senk die Ferse unter die Stufe in die volle Dehnung.',
      'leg_press_calf_raise':
        '1. Setz dich in die Beinpresse, Fußballen an der Unterkante der Plattform.\n'
        '2. Drück die Plattform durch Strecken der Füße weg.\n'
        '3. Langsam zurück in die Dehnung. Knie gestreckt halten.',
      'sit_up':
        '1. Leg dich auf den Rücken, Knie gebeugt, Füße am Boden.\n'
        '2. Roll dich ganz bis zum Sitzen hoch.\n'
        '3. Langsam wieder ablegen.',
      'decline_sit_up':
        '1. Hak die Füße an der Negativbank ein und leg dich zurück.\n'
        '2. Roll dich hoch, bis der Oberkörper aufrecht ist.\n'
        '3. Langsam zurück. Für mehr Last eine Scheibe halten.',
      'bicycle_crunch':
        '1. Leg dich auf den Rücken, Hände am Kopf, Beine angehoben.\n'
        '2. Führ einen Ellbogen zum gegenüberliegenden Knie, das andere Bein streckt sich.\n'
        '3. Seiten wechseln wie beim Radfahren.',
      'reverse_crunch':
        '1. Leg dich auf den Rücken, Knie 90° gebeugt, Arme am Boden.\n'
        '2. Roll das Becken hoch und zieh die Knie zur Brust.\n'
        '3. Langsam absenken, ohne Schwung.',
      'lying_leg_raise':
        '1. Leg dich auf den Rücken, Beine gestreckt, unterer Rücken am Boden.\n'
        '2. Heb die Beine, bis sie zur Decke zeigen.\n'
        '3. Langsam absenken, ohne ins Hohlkreuz zu gehen.',
      'captains_chair_knee_raise':
        '1. Stütz dich mit den Unterarmen auf die Polster, Rücken an der Lehne.\n'
        '2. Zieh die Knie zur Brust.\n'
        '3. Langsam absenken, ohne Schwung.',
      'ab_wheel_rollout':
        '1. Knie dich hin und halt den Bauchroller unter den Schultern.\n'
        '2. Roll so weit nach vorne, wie es ohne Hohlkreuz geht.\n'
        '3. Mit der Bauchmuskulatur zurückziehen.',
      'russian_twist':
        '1. Setz dich leicht zurückgelehnt hin, Füße angehoben oder am Boden.\n'
        '2. Dreh den Oberkörper und tipp neben der Hüfte auf den Boden.\n'
        '3. Zur anderen Seite drehen. Für mehr Last ein Gewicht halten.',
      'v_up':
        '1. Leg dich auf den Rücken, Arme über dem Kopf, Beine gestreckt.\n'
        '2. Heb Arme und Beine gleichzeitig und berühr die Zehen.\n'
        '3. Langsam wieder ablegen.',
      'hollow_hold':
        '1. Leg dich auf den Rücken und drück den unteren Rücken in den Boden.\n'
        '2. Heb Schultern und gestreckte Beine etwas vom Boden.\n'
        '3. Halte die vorgegebene Zeit ohne Hohlkreuz.',
      'pallof_press':
        '1. Steh seitlich zum Kabel auf Brusthöhe, Griff an der Brust.\n'
        '2. Drück den Griff gerade nach vorne, ohne dass sich der Körper dreht.\n'
        '3. Zurück zur Brust. Beide Seiten trainieren.',
      'cable_woodchopper':
        '1. Steh seitlich zum oberen Kabel, Griff mit beiden Händen.\n'
        '2. Zieh ihn diagonal nach unten über den Körper und dreh den Oberkörper.\n'
        '3. Langsam zurück. Beide Seiten trainieren.',
      'plank_shoulder_tap':
        '1. Geh in den hohen Unterarmstütz, Füße etwas auseinander.\n'
        '2. Tipp mit einer Hand die gegenüberliegende Schulter an, ohne die Hüfte zu bewegen.\n'
        '3. Hand wechseln.',
      'bird_dog':
        '1. Geh in den Vierfüßlerstand, Rücken gerade.\n'
        '2. Streck einen Arm nach vorne und das gegenüberliegende Bein nach hinten.\n'
        '3. Kurz halten, zurück und Seite wechseln.',
      'power_clean':
        '1. Steh über der Stange, Griff knapp außerhalb der Knie, Rücken gerade.\n'
        '2. Zieh die Stange explosiv am Körper hoch und fang sie vorne auf den Schultern.\n'
        '3. Aufrichten und absetzen. Technik mit leichter Stange lernen.',
      'thruster':
        '1. Halt die Stange vorne auf den Schultern.\n'
        '2. Geh in die Hocke und drück sie beim Aufstehen in einer Bewegung über den Kopf.\n'
        '3. Zurück auf die Schultern und direkt in die nächste Kniebeuge.',
      'turkish_get_up':
        '1. Leg dich auf den Rücken und halt eine Kettlebell mit einer Hand senkrecht nach oben.\n'
        '2. Steh Schritt für Schritt auf, Blick auf die Kettlebell, Arm gestreckt.\n'
        '3. Auf demselben Weg zurück in die Rückenlage. Beide Seiten.',
      'bear_crawl':
        '1. Stütz dich auf Hände und Füße, Knie knapp über dem Boden, Rücken gerade.\n'
        '2. Krabbel vorwärts und beweg dabei gegenüberliegende Hand und Fuß gleichzeitig.\n'
        '3. Hüfte tief halten für die vorgegebene Zeit.',
      'high_knees':
        '1. Lauf auf der Stelle und zieh die Knie bis auf Hüfthöhe.\n'
        '2. Arbeite mit den Armen und bleib auf den Fußballen.\n'
        '3. Halte ein schnelles Tempo für die vorgegebene Zeit.',
      'jump_rope':
        '1. Halt die Griffe auf Hüfthöhe, Ellbogen nah am Körper.\n'
        '2. Dreh das Seil aus den Handgelenken und spring nur so hoch wie nötig.\n'
        '3. Weich auf den Fußballen landen für die vorgegebene Zeit.',
      'rowing_machine':
        '1. Schnall die Füße fest und greif den Griff mit gestreckten Armen.\n'
        '2. Drück mit den Beinen ab, lehn dich leicht zurück und zieh den Griff zu den unteren Rippen.\n'
        '3. In umgekehrter Reihenfolge zurück: Arme, Oberkörper, Beine. Gleichmäßiges Tempo.',
      'stationary_bike':
        '1. Stell den Sattel so ein, dass das Knie unten leicht gebeugt ist.\n'
        '2. Tritt in gleichmäßigem Tempo mit geradem Rücken.\n'
        '3. Stell den Widerstand nach deinem Ziel ein, für die vorgegebene Zeit.',
      'treadmill_run':
        '1. Fang mit Gehen an und steigere langsam die Geschwindigkeit.\n'
        '2. Lauf aufrecht mit lockeren Schultern, Landung unter der Hüfte.\n'
        '3. Vor dem Absteigen ins Gehen abbremsen.',
      'elliptical':
        '1. Steig auf die Pedale und greif die beweglichen Griffe.\n'
        '2. Beweg dich gleichmäßig und arbeite mit den Armen mit.\n'
        '3. Halte ein gleichmäßiges Tempo für die vorgegebene Zeit.',
      'stair_climber':
        '1. Steig auf und wähl ein Tempo, das du halten kannst.\n'
        '2. Steig aufrecht, die Geländer nur leicht zum Ausbalancieren nutzen.\n'
        '3. Mach weiter für die vorgegebene Zeit.',
      'air_bike':
        '1. Setz dich aufs Rad und greif die beweglichen Griffe.\n'
        '2. Tritt in die Pedale und drück und zieh gleichzeitig an den Griffen.\n'
        '3. Je mehr du gibst, desto mehr bremst der Lüfter. Für die vorgegebene Zeit.',
    },
    routineNames: {
      'home_upper': 'Oberkörper in 5 Minuten',
      'home_lower': 'Unterkörper in 5 Minuten',
      'home_full': 'Ganzkörper in 5 Minuten',
    },
    programNames: {
      'full_body': 'Ganzkörper (Einsteiger)',
      'upper_lower': 'Oberkörper / Unterkörper',
      'ppl': 'Push / Pull / Legs',
      'full_body_2x': 'Ganzkörper 2× pro Woche',
      'dumbbell_home': 'Kurzhanteln zu Hause',
      'strength_5x5': 'Kraft 5×5',
      'circuit': 'Zirkeltraining (Ausdauer)',
      'full_body_variation': 'Ganzkörper – Variante',
      'bodyweight_home': 'Eigengewicht zu Hause',
      'machines': 'Geräte (Einsteiger)',
      'upper_lower_variation': 'Oberkörper / Unterkörper – Variante',
      'ppl_variation': 'Push / Pull / Legs – Variante',
      'strength_dup': 'Kraft – Wochenwellen',
      'conditioning_intervals': 'Kondition – Intervalle',
      'phul': 'Kraft + Masse (PHUL)',
      'strength_advanced': 'Kraft – 4 Tage (Fortgeschrittene)',
      'ppl_6x': 'Push / Pull / Legs 6× pro Woche',
    },
    programDescriptions: {
      'full_body':
        '3× pro Woche, abwechselnd Training A und B. Ideal für die ersten Monate.',
      'upper_lower': '4× pro Woche: Oberkörper Mo + Do, Unterkörper Di + Fr.',
      'ppl': '3× pro Woche: Push Mo, Pull Mi, Legs Fr.',
      'full_body_2x':
        'Für volle Wochen: 2 Trainings von etwa einer Stunde, Mo + Do. Jede Muskelgruppe 2× pro Woche.',
      'dumbbell_home':
        '3× pro Woche mit zwei Kurzhanteln und einer Matte, abwechselnd A und B. Ohne Fitnessstudio.',
      'strength_5x5':
        '3× pro Woche, abwechselnd A und B: 5 Sätze à 5 bei den großen Übungen. Schaffst du alle Sätze mit 5 Wiederholungen, steigt das Gewicht.',
      'circuit':
        '3× pro Woche, abwechselnd A und B: Übungen im Zirkel direkt hintereinander, kurze Pausen, viele Wiederholungen. Für Ausdauer und Kondition.',
      'full_body_variation':
        '3× pro Woche, abwechselnd C und D. Gleicher Aufbau wie Ganzkörper (Einsteiger) mit anderen Übungen – alle 6–8 Wochen wechseln.',
      'bodyweight_home':
        '3× pro Woche, abwechselnd A und B, ohne Geräte – nur eine Matte (und ein stabiler Tisch zum Rudern). Für den Einstieg und auf Reisen.',
      'machines':
        '3× pro Woche, abwechselnd A und B, an Geräten im Studio: leicht zu lernen, sicher auch ohne Partner. Ein guter erster Schritt vor freien Gewichten.',
      'upper_lower_variation':
        '4× pro Woche wie Oberkörper / Unterkörper, mit anderen Übungen (Schrägbankdrücken, Frontkniebeuge, Hip Thrust). Alle 6–8 Wochen wechseln.',
      'ppl_variation':
        '3× pro Woche wie Push / Pull / Legs, mit anderen Übungen (zuerst Schulterdrücken, Langhantelrudern, Hackenschmidt-Kniebeuge). Alle 6–8 Wochen wechseln.',
      'strength_dup':
        '3× pro Woche: schwerer Tag (Sätze à 3), Volumentag (6–8 Wiederholungen) und mittlerer Tag (Sätze à 5). Wechselnde Belastung innerhalb der Woche lässt die Kraft auch nach dem ersten Jahr wachsen.',
      'conditioning_intervals':
        '3× pro Woche, abwechselnd A und B: je eine Kraft- und eine Cardio-Übung direkt hintereinander, zum Schluss ein durchgehender Cardio-Block. Für Kondition, Ausdauer und Abnehmen.',
      'phul':
        '4× pro Woche: schwere Ober- und Unterkörpertage für Kraft (Mo, Di), Tage mit mehr Wiederholungen für Muskeln (Do, Fr). Etwa 12–16 Sätze pro Muskel und Woche.',
      'strength_advanced':
        '4× pro Woche, jeden Tag eine große Übung (Kniebeuge, Bankdrücken, Kreuzheben, Schulterdrücken): schwere Sätze à 3, eine verwandte Variante und Zusatzübungen für Schwachstellen.',
      'ppl_6x':
        'Mo–Sa: Push, Pull, Legs, dann Push B, Pull B, Legs B. Jeder Muskel 2× pro Woche mit hohem Volumen – für Erfahrene mit guter Regeneration.',
    },
    planNames: {
      'Full body A': 'Ganzkörper A',
      'Full body B': 'Ganzkörper B',
      'Upper body': 'Oberkörper',
      'Lower body': 'Unterkörper',
      'Push': 'Push',
      'Pull': 'Pull',
      'Legs': 'Legs',
      'Full body 2× A': 'Ganzkörper 2× A',
      'Full body 2× B': 'Ganzkörper 2× B',
      'Dumbbells A': 'Kurzhanteln A',
      'Dumbbells B': 'Kurzhanteln B',
      '5×5 A': '5×5 A',
      '5×5 B': '5×5 B',
      'Circuit A': 'Zirkel A',
      'Circuit B': 'Zirkel B',
      'Full body C': 'Ganzkörper C',
      'Full body D': 'Ganzkörper D',
      'Bodyweight A': 'Eigengewicht A',
      'Bodyweight B': 'Eigengewicht B',
      'Machines A': 'Geräte A',
      'Machines B': 'Geräte B',
      'Upper body B': 'Oberkörper B',
      'Lower body B': 'Unterkörper B',
      'Push B': 'Push B',
      'Pull B': 'Pull B',
      'Legs B': 'Legs B',
      'Strength: heavy day': 'Kraft: schwerer Tag',
      'Strength: volume day': 'Kraft: Volumentag',
      'Strength: medium day': 'Kraft: mittlerer Tag',
      'Intervals A': 'Intervalle A',
      'Intervals B': 'Intervalle B',
      'Upper power': 'Oberkörper – Kraft',
      'Lower power': 'Unterkörper – Kraft',
      'Upper hypertrophy': 'Oberkörper – Masse',
      'Lower hypertrophy': 'Unterkörper – Masse',
      'Strength: squat': 'Kraft: Kniebeuge',
      'Strength: bench': 'Kraft: Bankdrücken',
      'Strength: deadlift': 'Kraft: Kreuzheben',
      'Strength: overhead press': 'Kraft: Schulterdrücken',
    },
  ),
  'es': (
    exerciseNames: {
      'bench_press': 'Press de banca',
      'incline_dumbbell_press': 'Press inclinado con mancuernas',
      'cable_fly': 'Aperturas en polea',
      'push_up': 'Flexiones',
      'deadlift': 'Peso muerto',
      'barbell_row': 'Remo con barra',
      'lat_pulldown': 'Jalón al pecho',
      'pull_up': 'Dominadas',
      'overhead_press': 'Press militar',
      'lateral_raise': 'Elevaciones laterales',
      'pike_push_up': 'Flexiones pica',
      'dumbbell_curl': 'Curl con mancuernas',
      'triceps_pushdown': 'Extensión de tríceps en polea',
      'dips': 'Fondos',
      'back_squat': 'Sentadilla trasera',
      'leg_press': 'Prensa de piernas',
      'romanian_deadlift': 'Peso muerto rumano',
      'bodyweight_squat': 'Sentadilla sin peso',
      'lunge': 'Zancadas',
      'hip_thrust': 'Hip thrust',
      'glute_bridge': 'Puente de glúteos',
      'plank': 'Plancha',
      'crunch': 'Crunch abdominal',
      'mountain_climber': 'Escaladores',
      'jumping_jack': 'Jumping jacks',
      'dumbbell_bench_press': 'Press de banca con mancuernas',
      'incline_bench_press': 'Press de banca inclinado',
      'chest_press_machine': 'Press de pecho en máquina',
      'pec_deck': 'Pec deck',
      'seated_cable_row': 'Remo sentado en polea',
      'one_arm_dumbbell_row': 'Remo con mancuerna a una mano',
      'chin_up': 'Dominadas supinas',
      'dumbbell_shoulder_press': 'Press de hombros con mancuernas',
      'rear_delt_fly': 'Pájaros',
      'face_pull': 'Face pull',
      'barbell_curl': 'Curl con barra',
      'hammer_curl': 'Curl martillo',
      'cable_curl': 'Curl en polea',
      'skull_crusher': 'Press francés',
      'overhead_triceps_extension': 'Extensión de tríceps sobre la cabeza',
      'close_grip_bench_press': 'Press de banca agarre cerrado',
      'front_squat': 'Sentadilla frontal',
      'goblet_squat': 'Sentadilla goblet',
      'bulgarian_split_squat': 'Sentadilla búlgara',
      'leg_extension': 'Extensión de cuádriceps',
      'leg_curl': 'Curl femoral',
      'calf_raise': 'Elevación de talones',
      'hanging_leg_raise': 'Elevación de piernas colgado',
      'cable_crunch': 'Crunch en polea',
      'dead_bug': 'Dead bug',
      'side_plank': 'Plancha lateral',
      'burpee': 'Burpees',
      'kettlebell_swing': 'Swing con kettlebell',
      'weighted_pull_up': 'Dominadas lastradas',
      'weighted_dips': 'Fondos lastrados',
      'barbell_shrug': 'Encogimientos con barra',
      'dumbbell_shrug': 'Encogimientos con mancuernas',
      'wrist_curl': 'Curl de muñeca',
      'reverse_curl': 'Curl inverso',
      'dead_hang': 'Colgarse de la barra',
      'back_extension': 'Hiperextensiones',
      'good_morning': 'Buenos días con barra',
      'superman': 'Superman',
      'decline_bench_press': 'Press de banca declinado',
      'smith_bench_press': 'Press de banca en máquina Smith',
      'dumbbell_fly': 'Aperturas con mancuernas',
      'incline_dumbbell_fly': 'Aperturas inclinadas con mancuernas',
      'low_to_high_cable_fly': 'Cruce de poleas de abajo arriba',
      'incline_chest_press_machine': 'Press inclinado en máquina',
      'chest_dips': 'Fondos para pecho',
      'incline_push_up': 'Flexiones inclinadas',
      'decline_push_up': 'Flexiones declinadas',
      'dumbbell_floor_press': 'Press en el suelo con mancuernas',
      't_bar_row': 'Remo en barra T',
      'pendlay_row': 'Remo Pendlay',
      'machine_row': 'Remo en máquina',
      'chest_supported_row': 'Remo con mancuernas apoyado en banco inclinado',
      'close_grip_lat_pulldown': 'Jalón al pecho con agarre estrecho',
      'straight_arm_pulldown': 'Jalón con brazos rectos',
      'band_assisted_pull_up': 'Dominadas asistidas con banda',
      'inverted_row': 'Remo invertido',
      'neutral_grip_pull_up': 'Dominadas con agarre neutro',
      'rack_pull': 'Rack pull',
      'trap_bar_deadlift': 'Peso muerto con barra hexagonal',
      'single_arm_cable_row': 'Remo en polea a una mano',
      'dumbbell_pullover': 'Pullover con mancuerna',
      'renegade_row': 'Remo renegado',
      'arnold_press': 'Press Arnold',
      'shoulder_press_machine': 'Press de hombros en máquina',
      'push_press': 'Push press',
      'cable_lateral_raise': 'Elevaciones laterales en polea',
      'machine_lateral_raise': 'Elevaciones laterales en máquina',
      'front_raise': 'Elevaciones frontales con mancuernas',
      'upright_row': 'Remo al mentón',
      'reverse_pec_deck': 'Pec deck inverso',
      'band_pull_apart': 'Aperturas con banda',
      'handstand_push_up': 'Flexiones en pino',
      'landmine_press': 'Press landmine',
      'preacher_curl': 'Curl en banco Scott',
      'concentration_curl': 'Curl concentrado',
      'incline_dumbbell_curl': 'Curl inclinado con mancuernas',
      'ez_bar_curl': 'Curl con barra Z',
      'rope_hammer_curl': 'Curl martillo con cuerda',
      'machine_biceps_curl': 'Curl de bíceps en máquina',
      'band_curl': 'Curl con banda',
      'rope_pushdown': 'Extensión de tríceps con cuerda',
      'overhead_cable_extension': 'Extensión de tríceps sobre la cabeza en polea',
      'triceps_kickback': 'Patada de tríceps',
      'bench_dips': 'Fondos en banco',
      'machine_triceps_dip': 'Fondos en máquina',
      'single_arm_pushdown': 'Extensión de tríceps en polea a una mano',
      'diamond_push_up': 'Flexiones diamante',
      'reverse_wrist_curl': 'Curl de muñeca inverso',
      'hack_squat': 'Sentadilla hack',
      'smith_squat': 'Sentadilla en máquina Smith',
      'walking_lunge': 'Zancadas caminando',
      'reverse_lunge': 'Zancadas hacia atrás',
      'step_up': 'Subidas al cajón',
      'split_squat': 'Sentadilla split',
      'sumo_squat': 'Sentadilla sumo con mancuerna',
      'pistol_squat': 'Sentadilla pistol',
      'single_leg_press': 'Prensa a una pierna',
      'hip_adduction_machine': 'Máquina de aductores',
      'wall_sit': 'Sentadilla isométrica en pared',
      'jump_squat': 'Sentadilla con salto',
      'box_jump': 'Salto al cajón',
      'seated_leg_curl': 'Curl femoral sentado',
      'nordic_curl': 'Curl nórdico',
      'single_leg_rdl': 'Peso muerto rumano a una pierna',
      'dumbbell_romanian_deadlift': 'Peso muerto rumano con mancuernas',
      'stiff_leg_deadlift': 'Peso muerto con piernas rígidas',
      'stability_ball_leg_curl': 'Curl femoral con fitball',
      'sumo_deadlift': 'Peso muerto sumo',
      'cable_glute_kickback': 'Patada de glúteo en polea',
      'hip_abduction_machine': 'Máquina de abductores',
      'machine_hip_thrust': 'Hip thrust en máquina',
      'single_leg_glute_bridge': 'Puente de glúteo a una pierna',
      'donkey_kick': 'Patada de burro',
      'fire_hydrant': 'Fire hydrant (abducción a cuatro patas)',
      'banded_lateral_walk': 'Paso lateral con banda',
      'cable_pull_through': 'Pull-through en polea',
      'seated_calf_raise': 'Elevación de talones sentado',
      'single_leg_calf_raise': 'Elevación de talón a una pierna',
      'leg_press_calf_raise': 'Elevación de talones en prensa',
      'sit_up': 'Abdominales completos (sit-up)',
      'decline_sit_up': 'Sit-up en banco declinado',
      'bicycle_crunch': 'Crunch bicicleta',
      'reverse_crunch': 'Crunch inverso',
      'lying_leg_raise': 'Elevación de piernas acostado',
      'captains_chair_knee_raise': 'Elevación de rodillas en silla romana',
      'ab_wheel_rollout': 'Rueda abdominal',
      'russian_twist': 'Giro ruso',
      'v_up': 'V-up',
      'hollow_hold': 'Hollow hold',
      'pallof_press': 'Press Pallof',
      'cable_woodchopper': 'Leñador en polea',
      'plank_shoulder_tap': 'Plancha con toque de hombro',
      'bird_dog': 'Bird dog',
      'power_clean': 'Cargada de potencia (power clean)',
      'thruster': 'Thruster',
      'turkish_get_up': 'Levantamiento turco',
      'bear_crawl': 'Paso de oso',
      'high_knees': 'Rodillas arriba (skipping)',
      'jump_rope': 'Saltar la cuerda',
      'rowing_machine': 'Remo ergómetro',
      'stationary_bike': 'Bicicleta estática',
      'treadmill_run': 'Correr en cinta',
      'elliptical': 'Elíptica',
      'stair_climber': 'Escaladora',
      'air_bike': 'Air bike',
    },
    exerciseInstructions: {
      'bench_press':
        '1. Acuéstate en el banco con los ojos bajo la barra y los pies apoyados en el suelo.\n'
        '2. Agarra un poco más abierto que los hombros y junta las escápulas.\n'
        '3. Baja la barra con control hasta la mitad del pecho, codos a unos 45° del cuerpo.\n'
        '4. Empuja hasta estirar los brazos sin levantar la cadera.',
      'incline_dumbbell_press':
        '1. Pon el banco a 30–45°, con las mancuernas a la altura del pecho.\n'
        '2. Mantén las escápulas atrás y los pies en el suelo.\n'
        '3. Empuja hacia arriba juntándolas un poco y baja despacio hasta el pecho.',
      'cable_fly':
        '1. Colócate entre las poleas con los codos ligeramente flexionados.\n'
        '2. Junta los agarres en arco delante del pecho.\n'
        '3. Vuelve despacio hasta notar el estiramiento, sin mover los codos.',
      'push_up':
        '1. Manos un poco más abiertas que los hombros, cuerpo en línea recta.\n'
        '2. Baja el pecho cerca del suelo, codos a unos 45° del cuerpo.\n'
        '3. Empuja de vuelta arriba manteniendo el core y los glúteos apretados.',
      'deadlift':
        '1. Barra sobre la mitad del pie, pies a la anchura de la cadera.\n'
        '2. Flexiona la cadera, agarra la barra y mantén la espalda neutra.\n'
        '3. Empuja el suelo y ponte de pie con la barra pegada a las piernas.\n'
        '4. Baja con control llevando la cadera hacia atrás.',
      'barbell_row':
        '1. Inclínate hacia delante a unos 45°, espalda recta y rodillas un poco flexionadas.\n'
        '2. Tira de la barra hacia la parte baja del pecho o el abdomen.\n'
        '3. Junta las escápulas y baja despacio.',
      'lat_pulldown':
        '1. Agarra un poco más abierto que los hombros, muslos bajo los rodillos.\n'
        '2. Tira de la barra hasta la parte alta del pecho, codos hacia abajo y atrás.\n'
        '3. Vuelve despacio hasta estirar los brazos sin balancearte.',
      'pull_up':
        '1. Cuélgate de la barra con agarre prono y hombros activos.\n'
        '2. Sube hasta que la barbilla pase la barra.\n'
        '3. Baja con control hasta colgar del todo.',
      'overhead_press':
        '1. Barra apoyada delante de los hombros, agarre justo por fuera de ellos.\n'
        '2. Aprieta glúteos y core y empuja la barra recta hacia arriba.\n'
        '3. Echa la cabeza un poco atrás al pasar la barra y bloquea arriba.',
      'lateral_raise':
        '1. De pie con la espalda recta, mancuernas a los lados, codos ligeramente flexionados.\n'
        '2. Eleva los brazos hacia los lados hasta la altura de los hombros.\n'
        '3. Baja despacio, sin balancearte.',
      'pike_push_up':
        '1. Empieza en posición de flexión y sube la cadera formando una V invertida.\n'
        '2. Baja la cabeza hacia el suelo entre las manos.\n'
        '3. Empuja de vuelta arriba con los hombros.',
      'dumbbell_curl':
        '1. De pie con la espalda recta, codos pegados al cuerpo.\n'
        '2. Sube las mancuernas sin mover los codos.\n'
        '3. Baja despacio hasta estirar los brazos.',
      'triceps_pushdown':
        '1. Ponte frente a la polea con los codos pegados al cuerpo.\n'
        '2. Empuja el agarre hacia abajo hasta estirar los brazos.\n'
        '3. Vuelve despacio sin mover los codos.',
      'dips':
        '1. Apóyate en las paralelas con los brazos estirados.\n'
        '2. Baja hasta que los brazos queden más o menos paralelos al suelo.\n'
        '3. Empuja de vuelta arriba sin dejar caer los hombros hacia delante.',
      'back_squat':
        '1. Barra en la parte alta de la espalda, pies a la anchura de los hombros, puntas un poco hacia fuera.\n'
        '2. Activa el core y siéntate entre los talones.\n'
        '3. Las rodillas siguen la dirección de las puntas, la espalda se mantiene neutra.\n'
        '4. Sube empujando con todo el pie.',
      'leg_press':
        '1. Pies a la anchura de los hombros en el centro de la plataforma.\n'
        '2. Baja hasta que las rodillas estén a unos 90°, con la zona lumbar pegada al respaldo.\n'
        '3. Empuja hacia arriba sin bloquear del todo las rodillas.',
      'romanian_deadlift':
        '1. De pie con la barra, rodillas ligeramente flexionadas.\n'
        '2. Lleva la cadera atrás y baja la barra pegada a las piernas.\n'
        '3. Para cuando notes el estiramiento en los isquiotibiales, con la espalda recta.\n'
        '4. Vuelve llevando la cadera hacia delante.',
      'bodyweight_squat':
        '1. Pies a la anchura de los hombros, brazos al frente para equilibrarte.\n'
        '2. Baja todo lo que puedas con la espalda recta.\n'
        '3. Sube empujando con los talones.',
      'lunge':
        '1. Da un paso al frente y baja hasta que ambas rodillas estén a unos 90°.\n'
        '2. La rodilla delantera queda sobre el pie, el torso erguido.\n'
        '3. Empuja para volver al inicio y cambia de pierna.',
      'hip_thrust':
        '1. Parte alta de la espalda en el banco, barra sobre la cadera.\n'
        '2. Empuja con los talones y sube la cadera hasta que el cuerpo quede recto.\n'
        '3. Aprieta los glúteos arriba y baja con control.',
      'glute_bridge':
        '1. Acuéstate boca arriba, rodillas flexionadas y pies en el suelo.\n'
        '2. Sube la cadera apretando los glúteos.\n'
        '3. Aguanta un momento arriba y baja despacio.',
      'plank':
        '1. Antebrazos bajo los hombros, cuerpo en línea recta.\n'
        '2. Aprieta el core y los glúteos, no dejes caer la cadera.\n'
        '3. Respira de forma constante y aguanta.',
      'crunch':
        '1. Acuéstate boca arriba, rodillas flexionadas, manos junto a la cabeza.\n'
        '2. Despega los hombros del suelo usando los abdominales.\n'
        '3. Baja despacio, no tires del cuello.',
      'mountain_climber':
        '1. Empieza en posición de flexión.\n'
        '2. Lleva las rodillas hacia el pecho de forma alterna.\n'
        '3. Mantén la cadera baja y un ritmo constante.',
      'jumping_jack':
        '1. De pie con los pies juntos y los brazos a los lados.\n'
        '2. Salta abriendo los pies y sube los brazos por encima de la cabeza.\n'
        '3. Salta de vuelta y repite a ritmo constante.',
      'dumbbell_bench_press':
        '1. Acuéstate en un banco plano con las mancuernas a la altura del pecho.\n'
        '2. Empuja hacia arriba juntándolas un poco.\n'
        '3. Baja despacio hasta notar el estiramiento en el pecho.',
      'incline_bench_press':
        '1. Banco a 30–45°, agarre un poco más abierto que los hombros.\n'
        '2. Baja la barra a la parte alta del pecho.\n'
        '3. Empuja hacia arriba con las escápulas atrás.',
      'chest_press_machine':
        '1. Ajusta el asiento para que los agarres queden a mitad del pecho.\n'
        '2. Empuja hacia delante hasta casi estirar los brazos.\n'
        '3. Vuelve despacio con la espalda pegada al respaldo.',
      'pec_deck':
        '1. Siéntate con la espalda en el respaldo y los codos ligeramente flexionados.\n'
        '2. Junta los agarres delante del pecho.\n'
        '3. Vuelve despacio hasta un estiramiento cómodo.',
      'seated_cable_row':
        '1. Siéntate con la espalda recta, pies en la plataforma, rodillas un poco flexionadas.\n'
        '2. Tira del agarre hacia el abdomen, codos pegados al cuerpo.\n'
        '3. Junta las escápulas y vuelve despacio sin redondear la espalda.',
      'one_arm_dumbbell_row':
        '1. Una rodilla y una mano en el banco, espalda plana.\n'
        '2. Tira de la mancuerna hacia la cadera.\n'
        '3. Baja despacio hasta estirar del todo.',
      'chin_up':
        '1. Cuélgate de la barra con agarre supino a la anchura de los hombros.\n'
        '2. Sube hasta que la barbilla pase la barra.\n'
        '3. Baja con control hasta colgar del todo.',
      'dumbbell_shoulder_press':
        '1. En un banco o de pie, mancuernas a la altura de los hombros.\n'
        '2. Empuja por encima de la cabeza sin arquear la zona lumbar.\n'
        '3. Baja despacio de nuevo a los hombros.',
      'rear_delt_fly':
        '1. Inclínate hacia delante con la espalda plana y las mancuernas colgando.\n'
        '2. Abre los brazos hacia los lados con los codos ligeramente flexionados.\n'
        '3. Baja despacio, sin impulso.',
      'face_pull':
        '1. Cuerda a la altura de la cabeza, agárrala con los pulgares hacia ti.\n'
        '2. Tira hacia la cara con los codos altos y abiertos.\n'
        '3. Aprieta la parte alta de la espalda y vuelve despacio.',
      'barbell_curl':
        '1. De pie con la espalda recta, agarre supino a la anchura de los hombros.\n'
        '2. Sube la barra sin balancear el cuerpo.\n'
        '3. Baja despacio hasta estirar los brazos.',
      'hammer_curl':
        '1. Sujeta las mancuernas con las palmas enfrentadas.\n'
        '2. Súbelas con los codos pegados al cuerpo.\n'
        '3. Baja despacio.',
      'cable_curl':
        '1. De pie frente a la polea baja, codos pegados al cuerpo.\n'
        '2. Sube el agarre hasta los hombros.\n'
        '3. Baja despacio manteniendo la tensión constante.',
      'skull_crusher':
        '1. Acuéstate en un banco con la barra sobre el pecho y los brazos estirados.\n'
        '2. Flexiona solo los codos y baja la barra hacia la frente.\n'
        '3. Vuelve a estirar manteniendo los codos apuntando hacia arriba.',
      'overhead_triceps_extension':
        '1. Sujeta una mancuerna por encima de la cabeza con ambas manos.\n'
        '2. Bájala por detrás de la cabeza flexionando los codos.\n'
        '3. Vuelve a estirar con los codos cerca de la cabeza.',
      'close_grip_bench_press':
        '1. Acuéstate en el banco con un agarre a la anchura de los hombros aprox.\n'
        '2. Baja la barra a la parte baja del pecho, codos pegados al cuerpo.\n'
        '3. Empuja hacia arriba estirando los codos.',
      'front_squat':
        '1. Barra apoyada delante de los hombros, codos altos.\n'
        '2. Baja en sentadilla con el torso erguido.\n'
        '3. Sube manteniendo los codos altos todo el tiempo.',
      'goblet_squat':
        '1. Sujeta una kettlebell o mancuerna a la altura del pecho.\n'
        '2. Baja entre las rodillas con la espalda recta.\n'
        '3. Sube empujando con los talones.',
      'bulgarian_split_squat':
        '1. Pie trasero sobre un banco, pie delantero un paso por delante.\n'
        '2. Baja hasta que el muslo delantero quede más o menos paralelo al suelo.\n'
        '3. Sube empujando con el pie delantero y luego cambia de pierna.',
      'leg_extension':
        '1. Ajusta el rodillo justo por encima de los tobillos.\n'
        '2. Estira las piernas por completo.\n'
        '3. Baja despacio y con control.',
      'leg_curl':
        '1. Ajusta el rodillo justo por encima de los talones.\n'
        '2. Lleva los talones hacia los glúteos.\n'
        '3. Vuelve despacio, sin dejar caer el peso.',
      'calf_raise':
        '1. Parte delantera de los pies en el borde, talones libres.\n'
        '2. Sube de puntillas lo más alto que puedas.\n'
        '3. Baja despacio hasta estirar.',
      'hanging_leg_raise':
        '1. Cuélgate de la barra con los hombros activos.\n'
        '2. Sube las piernas o las rodillas con los abdominales, sin balancearte.\n'
        '3. Baja despacio.',
      'cable_crunch':
        '1. De rodillas frente a la polea, con la cuerda junto a la cabeza.\n'
        '2. Encógete hacia abajo redondeando la columna, la cadera no se mueve.\n'
        '3. Vuelve despacio.',
      'dead_bug':
        '1. Acuéstate boca arriba, brazos hacia arriba y rodillas a 90°.\n'
        '2. Baja el brazo y la pierna contrarios, con la zona lumbar pegada al suelo.\n'
        '3. Vuelve y cambia de lado.',
      'side_plank':
        '1. Acuéstate de lado con el codo bajo el hombro.\n'
        '2. Sube la cadera para que el cuerpo forme una línea recta.\n'
        '3. Aguanta y luego cambia de lado.',
      'burpee':
        '1. Desde de pie, agáchate y apoya las manos en el suelo.\n'
        '2. Salta llevando los pies atrás a posición de plancha; si quieres, haz una flexión.\n'
        '3. Salta llevando los pies hacia delante y salta hacia arriba.',
      'kettlebell_swing':
        '1. Kettlebell delante, pies un poco más abiertos que la cadera.\n'
        '2. Llévala atrás entre las piernas flexionando la cadera.\n'
        '3. Empuja la cadera hacia delante con fuerza para subirla a la altura del pecho, brazos relajados.',
      'weighted_pull_up':
        '1. Cuelga un disco de un cinturón de lastre o sujeta una mancuerna entre los pies.\n'
        '2. Cuélgate de la barra con agarre prono y hombros activos.\n'
        '3. Sube sin balancearte hasta que la barbilla pase la barra.\n'
        '4. Baja con control hasta colgar del todo. Anota solo el peso añadido.',
      'weighted_dips':
        '1. Cuelga un disco de un cinturón de lastre o sujeta una mancuerna entre los pies.\n'
        '2. Apóyate en las paralelas con los brazos estirados.\n'
        '3. Baja hasta que los brazos queden más o menos paralelos al suelo.\n'
        '4. Empuja de vuelta arriba sin dejar caer los hombros hacia delante. Anota solo el peso añadido.',
      'barbell_shrug':
        '1. De pie, sujeta la barra con los brazos extendidos, agarre al ancho de hombros.\n'
        '2. Sube los hombros en vertical hacia las orejas, brazos rectos.\n'
        '3. Pausa arriba y baja despacio. No hagas círculos con los hombros.',
      'dumbbell_shrug':
        '1. De pie, una mancuerna en cada mano a los lados, palmas hacia el cuerpo.\n'
        '2. Sube los hombros en vertical lo más alto que puedas.\n'
        '3. Mantén un momento y baja con control.',
      'wrist_curl':
        '1. Siéntate con los antebrazos sobre los muslos o un banco, palmas arriba, muñecas fuera del borde.\n'
        '2. Deja que las mancuernas rueden hacia la punta de los dedos.\n'
        '3. Flexiona las muñecas lo más arriba posible, antebrazos quietos.',
      'reverse_curl':
        '1. De pie, sujeta la barra en prono al ancho de hombros.\n'
        '2. Sube la barra con los codos pegados al cuerpo y las muñecas rectas.\n'
        '3. Baja despacio hasta extender los brazos.',
      'dead_hang':
        '1. Agarra la barra en prono al ancho de hombros.\n'
        '2. Cuélgate con los brazos extendidos, pies en el aire, cuerpo quieto.\n'
        '3. Aguanta el tiempo marcado con los hombros ligeramente activos.',
      'back_extension':
        '1. Coloca el apoyo justo debajo de la cadera y fija los talones.\n'
        '2. Baja el tronco con la espalda recta hasta notar el estiramiento de los isquios.\n'
        '3. Sube hasta que el tronco quede alineado con las piernas, sin hiperextender. Sujeta un disco para más carga.',
      'good_morning':
        '1. Barra sobre la parte alta de la espalda como en la sentadilla, pies al ancho de cadera, rodillas algo flexionadas.\n'
        '2. Lleva la cadera atrás e inclínate con la espalda recta hasta que el tronco esté casi horizontal.\n'
        '3. Empuja la cadera adelante para subir. Empieza con poco peso.',
      'superman':
        '1. Acuéstate boca abajo con los brazos extendidos por encima de la cabeza.\n'
        '2. Levanta brazos, pecho y piernas del suelo a la vez.\n'
        '3. Mantén un segundo arriba y baja despacio.',
      'decline_bench_press':
        '1. Sujeta las piernas en el banco declinado, agarre algo más ancho que los hombros.\n'
        '2. Baja la barra con control hasta la parte baja del pecho.\n'
        '3. Empuja hasta extender los brazos, escápulas juntas.',
      'smith_bench_press':
        '1. Coloca el banco para que la barra quede sobre el centro del pecho.\n'
        '2. Desbloquea la barra y bájala al pecho con control.\n'
        '3. Empuja sin bloquear los codos de golpe y engancha la barra al final.',
      'dumbbell_fly':
        '1. Acuéstate en un banco plano, mancuernas sobre el pecho, codos algo flexionados.\n'
        '2. Abre los brazos en un arco amplio hasta notar estiramiento en el pecho.\n'
        '3. Vuelve a juntarlas sin cambiar el ángulo del codo.',
      'incline_dumbbell_fly':
        '1. Pon el banco a 30°, mancuernas sobre el pecho, codos relajados.\n'
        '2. Bájalas en un arco amplio hasta notar estiramiento en la parte alta del pecho.\n'
        '3. Vuelve a juntarlas sobre el pecho.',
      'low_to_high_cable_fly':
        '1. Pon las poleas abajo y colócate entre ellas con el torso algo inclinado.\n'
        '2. Lleva los agarres hacia arriba y juntos delante de la parte alta del pecho.\n'
        '3. Vuelve despacio al estiramiento, codos algo flexionados.',
      'incline_chest_press_machine':
        '1. Ajusta el asiento para que los agarres queden a la altura de la parte alta del pecho.\n'
        '2. Empuja hacia delante y arriba hasta casi extender los brazos.\n'
        '3. Vuelve despacio hasta notar el estiramiento.',
      'chest_dips':
        '1. Apóyate en las paralelas e inclina el torso hacia delante.\n'
        '2. Baja con los codos algo abiertos hasta notar estiramiento en el pecho.\n'
        '3. Sube manteniendo la inclinación.',
      'incline_push_up':
        '1. Apoya las manos en un banco o cajón, cuerpo recto.\n'
        '2. Baja el pecho al borde, codos a unos 45° del cuerpo.\n'
        '3. Vuelve a subir. Cuanto más alto el apoyo, más fácil.',
      'decline_push_up':
        '1. Pies sobre un banco, manos en el suelo bajo los hombros.\n'
        '2. Baja el pecho al suelo con el abdomen firme.\n'
        '3. Sube sin que la cadera se hunda.',
      'dumbbell_floor_press':
        '1. Acuéstate en el suelo, rodillas flexionadas, mancuernas sobre el pecho.\n'
        '2. Baja hasta que los brazos toquen el suelo y pausa.\n'
        '3. Empuja hasta extender los brazos.',
      't_bar_row':
        '1. Colócate sobre la barra, inclínate con la espalda recta y agarra el asa.\n'
        '2. Lleva el peso al pecho juntando las escápulas.\n'
        '3. Baja con control sin redondear la espalda.',
      'pendlay_row':
        '1. Barra en el suelo, torso casi horizontal, espalda recta.\n'
        '2. Tira de la barra de forma explosiva a la parte baja del pecho.\n'
        '3. Apóyala en el suelo en cada repetición y recoloca la postura.',
      'machine_row':
        '1. Siéntate con el pecho contra el respaldo y agarra las asas.\n'
        '2. Tira hacia el cuerpo, codos pegados, escápulas juntas.\n'
        '3. Vuelve despacio hasta extender los brazos.',
      'chest_supported_row':
        '1. Acuéstate boca abajo en un banco a 30–45°, mancuernas colgando.\n'
        '2. Llévalas hacia los costados juntando las escápulas.\n'
        '3. Baja despacio hasta el estiramiento completo.',
      'close_grip_lat_pulldown':
        '1. Siéntate en la polea con agarre estrecho o en V, muslos bajo los rodillos.\n'
        '2. Lleva el agarre a la parte alta del pecho, codos abajo y atrás.\n'
        '3. Deja que suba despacio hasta extender los brazos.',
      'straight_arm_pulldown':
        '1. De pie frente a la polea alta, brazos casi rectos, torso algo inclinado.\n'
        '2. Baja la barra en arco hasta los muslos usando el dorsal.\n'
        '3. Vuelve despacio, codos casi rectos.',
      'band_assisted_pull_up':
        '1. Pasa una banda por la barra y apoya un pie o una rodilla en ella.\n'
        '2. Sube hasta que la barbilla pase la barra.\n'
        '3. Baja con control hasta colgar. Banda más fina = menos ayuda.',
      'inverted_row':
        '1. Cuélgate bajo una barra baja o anillas, cuerpo recto, talones en el suelo.\n'
        '2. Lleva el pecho a la barra juntando las escápulas.\n'
        '3. Baja con control. Cuanto más vertical, más fácil.',
      'neutral_grip_pull_up':
        '1. Cuélgate de agarres paralelos, palmas enfrentadas.\n'
        '2. Sube hasta que la barbilla pase los agarres.\n'
        '3. Baja con control hasta colgar por completo.',
      'rack_pull':
        '1. Coloca la barra en los soportes justo por debajo o encima de las rodillas.\n'
        '2. Agárrala, aprieta el abdomen y sube empujando la cadera hacia delante.\n'
        '3. Bájala a los soportes con la espalda recta.',
      'trap_bar_deadlift':
        '1. Colócate dentro de la barra hexagonal, pies al ancho de cadera, agarra las asas.\n'
        '2. Aprieta, empuja el suelo y sube hasta estar de pie del todo.\n'
        '3. Baja la barra con la espalda recta.',
      'single_arm_cable_row':
        '1. Agarra un asa en la polea a media altura, brazo extendido.\n'
        '2. Llévala al costado, codo pegado al cuerpo.\n'
        '3. Vuelve despacio dejando que el hombro avance un poco.',
      'dumbbell_pullover':
        '1. Acuéstate en un banco con una mancuerna sobre el pecho, sujeta con las dos manos.\n'
        '2. Bájala en arco detrás de la cabeza, codos algo flexionados.\n'
        '3. Llévala de vuelta sobre el pecho.',
      'renegade_row':
        '1. En posición de flexión sobre dos mancuernas, pies separados.\n'
        '2. Lleva una mancuerna a la cadera sin girar la pelvis.\n'
        '3. Apóyala y repite con el otro brazo.',
      'arnold_press':
        '1. Siéntate con las mancuernas delante de los hombros, palmas hacia ti.\n'
        '2. Empuja hacia arriba girando las palmas hacia delante.\n'
        '3. Baja girando de vuelta a la posición inicial.',
      'shoulder_press_machine':
        '1. Ajusta el asiento para que los agarres empiecen a la altura de los hombros.\n'
        '2. Empuja hasta casi extender los brazos.\n'
        '3. Baja despacio a la altura de los hombros.',
      'push_press':
        '1. Barra sobre la parte delantera de los hombros, pies al ancho de cadera.\n'
        '2. Flexiona un poco las rodillas y con el impulso de las piernas empuja la barra sobre la cabeza.\n'
        '3. Bájala con control a los hombros.',
      'cable_lateral_raise':
        '1. De lado a la polea baja, agarre en la mano más alejada.\n'
        '2. Eleva el brazo lateralmente hasta la altura del hombro.\n'
        '3. Baja despacio manteniendo la tensión.',
      'machine_lateral_raise':
        '1. Siéntate con los rodillos por fuera de los brazos.\n'
        '2. Eleva los brazos hasta la altura de los hombros.\n'
        '3. Baja despacio sin soltar el peso.',
      'front_raise':
        '1. De pie, mancuernas delante de los muslos.\n'
        '2. Elévalas al frente hasta la altura de los hombros, brazos casi rectos.\n'
        '3. Baja despacio sin balancearte.',
      'upright_row':
        '1. Sujeta la barra delante de los muslos, agarre al ancho de hombros.\n'
        '2. Súbela pegada al cuerpo hasta el pecho, los codos guían.\n'
        '3. Baja despacio. Si molestan los hombros, no subas tanto.',
      'reverse_pec_deck':
        '1. Siéntate mirando a la máquina, pecho en el respaldo, agarra las asas.\n'
        '2. Abre los brazos hacia atrás en arco hasta alinearlos con el cuerpo.\n'
        '3. Vuelve despacio.',
      'band_pull_apart':
        '1. Sujeta una banda delante a la altura de los hombros, brazos rectos.\n'
        '2. Sepárala hasta tocar el pecho juntando las escápulas.\n'
        '3. Vuelve despacio.',
      'handstand_push_up':
        '1. Haz una parada de manos contra la pared, manos al ancho de hombros.\n'
        '2. Baja la cabeza hacia el suelo con control.\n'
        '3. Empuja hasta extender los brazos. Pon una colchoneta bajo la cabeza.',
      'landmine_press':
        '1. Sujeta el extremo de la barra landmine junto al hombro, pies escalonados.\n'
        '2. Empuja hacia arriba y delante hasta extender el brazo.\n'
        '3. Vuelve con control al hombro.',
      'preacher_curl':
        '1. Siéntate en el banco Scott, brazos apoyados, barra Z en las manos.\n'
        '2. Sube la barra sin despegar los codos.\n'
        '3. Baja despacio casi hasta extender.',
      'concentration_curl':
        '1. Siéntate en un banco, codo apoyado en la cara interna del muslo.\n'
        '2. Sube la mancuerna hacia el hombro.\n'
        '3. Baja despacio hasta el estiramiento completo.',
      'incline_dumbbell_curl':
        '1. Recuéstate en un banco a 45–60°, brazos colgando.\n'
        '2. Sube las mancuernas sin mover los brazos.\n'
        '3. Baja despacio hasta el estiramiento completo.',
      'ez_bar_curl':
        '1. De pie, sujeta la barra Z por la parte angulada, brazos extendidos.\n'
        '2. Súbela sin balancear el cuerpo.\n'
        '3. Baja despacio hasta extender los brazos.',
      'rope_hammer_curl':
        '1. Engancha una cuerda en la polea baja, palmas enfrentadas.\n'
        '2. Sube la cuerda con los codos pegados.\n'
        '3. Baja despacio manteniendo la tensión.',
      'machine_biceps_curl':
        '1. Siéntate con los brazos en el apoyo y agarra las asas.\n'
        '2. Sube los agarres hacia los hombros.\n'
        '3. Baja despacio casi hasta extender.',
      'band_curl':
        '1. Pisa el centro de la banda, extremos en las manos.\n'
        '2. Sube las manos a los hombros, codos pegados.\n'
        '3. Baja despacio.',
      'rope_pushdown':
        '1. Sujeta la cuerda en la polea alta, codos pegados.\n'
        '2. Empuja hacia abajo y separa los extremos al final.\n'
        '3. Deja que suba despacio hasta unos 90° de codo.',
      'overhead_cable_extension':
        '1. De espaldas a la polea, cuerda detrás de la cabeza, codos arriba.\n'
        '2. Extiende los brazos hacia delante y arriba.\n'
        '3. Flexiona despacio los codos de vuelta.',
      'triceps_kickback':
        '1. Inclínate, brazo paralelo al cuerpo, codo flexionado.\n'
        '2. Extiende el brazo hacia atrás por completo.\n'
        '3. Flexiona despacio sin mover el brazo.',
      'bench_dips':
        '1. Apoya las manos en el borde de un banco detrás de ti, piernas al frente.\n'
        '2. Baja flexionando los codos a unos 90°.\n'
        '3. Empuja hasta extender los brazos.',
      'machine_triceps_dip':
        '1. Siéntate en la máquina y agarra las asas laterales.\n'
        '2. Empuja hacia abajo hasta extender los brazos.\n'
        '3. Deja que suban despacio hasta unos 90° de codo.',
      'single_arm_pushdown':
        '1. Sujeta un asa en la polea alta, codo pegado.\n'
        '2. Empuja hacia abajo hasta extender el brazo.\n'
        '3. Deja que suba despacio, el codo no se mueve.',
      'diamond_push_up':
        '1. Posición de flexión con las manos juntas bajo el pecho formando un rombo.\n'
        '2. Baja el pecho a las manos, codos pegados.\n'
        '3. Sube con el cuerpo recto.',
      'reverse_wrist_curl':
        '1. Siéntate con los antebrazos sobre los muslos, palmas abajo, muñecas fuera de las rodillas.\n'
        '2. Sube el dorso de las manos lo más alto posible.\n'
        '3. Baja despacio.',
      'hack_squat':
        '1. Súbete a la plataforma, espalda en el respaldo, hombros bajo los rodillos.\n'
        '2. Baja hasta que los muslos queden al menos paralelos a la plataforma.\n'
        '3. Empuja con todo el pie para subir.',
      'smith_squat':
        '1. Barra en la parte alta de la espalda, pies algo por delante de la barra.\n'
        '2. Baja con la espalda recta al menos hasta la paralela.\n'
        '3. Sube y engancha la barra al final.',
      'walking_lunge':
        '1. Sujeta mancuernas a los lados y da un paso largo al frente.\n'
        '2. Baja la rodilla trasera casi al suelo.\n'
        '3. Empuja con el pie delantero y enlaza con la siguiente zancada.',
      'reverse_lunge':
        '1. De pie, mancuernas a los lados.\n'
        '2. Da un paso atrás y baja la rodilla trasera casi al suelo.\n'
        '3. Empuja con el pie delantero para volver. Alterna piernas.',
      'step_up':
        '1. Ponte frente a un banco o cajón con mancuernas.\n'
        '2. Apoya un pie arriba y sube empujando con esa pierna.\n'
        '3. Baja despacio. Alterna piernas o haz un lado y luego el otro.',
      'split_squat':
        '1. Colócate en zancada larga con mancuernas en las manos.\n'
        '2. Baja en vertical hasta que la rodilla trasera casi toque el suelo.\n'
        '3. Sube. Termina las repeticiones y cambia de pierna.',
      'sumo_squat':
        '1. Pies separados, puntas hacia fuera, una mancuerna entre las piernas.\n'
        '2. Baja con el torso erguido, rodillas en la dirección de los pies.\n'
        '3. Sube y aprieta los glúteos.',
      'pistol_squat':
        '1. Apóyate en una pierna con la otra estirada al frente.\n'
        '2. Baja con control lo más profundo posible, brazos al frente para equilibrarte.\n'
        '3. Sube. Al principio puedes sujetarte a algo.',
      'single_leg_press':
        '1. Siéntate en la prensa con un pie en el centro de la plataforma.\n'
        '2. Baja la plataforma hasta que la rodilla esté a unos 90°.\n'
        '3. Empuja sin bloquear la rodilla. Cambia de pierna.',
      'hip_adduction_machine':
        '1. Siéntate con los rodillos por dentro de las rodillas.\n'
        '2. Junta las piernas.\n'
        '3. Ábrelas despacio de nuevo.',
      'wall_sit':
        '1. Apoya la espalda en la pared y deslízate hacia abajo.\n'
        '2. Para cuando las rodillas estén a unos 90°, pies bajo las rodillas.\n'
        '3. Aguanta el tiempo marcado, espalda pegada a la pared.',
      'jump_squat':
        '1. De pie, pies al ancho de hombros.\n'
        '2. Baja en sentadilla y salta de forma explosiva.\n'
        '3. Aterriza suave y enlaza con la siguiente sentadilla.',
      'box_jump':
        '1. Ponte frente a un cajón estable.\n'
        '2. Balancea los brazos y salta al cajón aterrizando suave.\n'
        '3. Ponte de pie del todo y baja caminando.',
      'seated_leg_curl':
        '1. Siéntate en la máquina, rodillo sobre los talones, muslos sujetos.\n'
        '2. Lleva los talones hacia abajo y atrás todo lo posible.\n'
        '3. Vuelve despacio.',
      'nordic_curl':
        '1. De rodillas con los talones sujetos bajo algo estable.\n'
        '2. Deja caer el cuerpo hacia delante lo más despacio posible, cadera recta.\n'
        '3. Frénate con las manos y vuelve tirando con los isquios.',
      'single_leg_rdl':
        '1. Apóyate en una pierna con una mancuerna, rodilla algo flexionada.\n'
        '2. Inclínate mientras la pierna libre va hacia atrás, espalda recta.\n'
        '3. Vuelve a subir empujando la cadera hacia delante.',
      'dumbbell_romanian_deadlift':
        '1. De pie con mancuernas delante de los muslos, rodillas relajadas.\n'
        '2. Lleva la cadera atrás y desliza las mancuernas por las piernas.\n'
        '3. Para al notar el estiramiento de los isquios y sube.',
      'stiff_leg_deadlift':
        '1. De pie con la barra, piernas casi rectas.\n'
        '2. Inclínate con la espalda recta bajando la barra junto a las piernas.\n'
        '3. Sube apretando isquios y glúteos.',
      'stability_ball_leg_curl':
        '1. Boca arriba, talones sobre el fitball, cadera elevada.\n'
        '2. Acerca el balón flexionando las rodillas.\n'
        '3. Llévalo de vuelta despacio, la cadera sigue arriba.',
      'sumo_deadlift':
        '1. Pies muy separados, puntas hacia fuera, agarra la barra entre las piernas.\n'
        '2. Aprieta, empuja las rodillas hacia fuera y sube con la barra pegada.\n'
        '3. Bájala con la espalda recta.',
      'cable_glute_kickback':
        '1. Ponte una tobillera en la polea baja y sujétate a la máquina.\n'
        '2. Lleva la pierna atrás y arriba apretando el glúteo.\n'
        '3. Vuelve despacio sin arquear la zona lumbar.',
      'hip_abduction_machine':
        '1. Siéntate con los rodillos por fuera de las rodillas.\n'
        '2. Separa las piernas todo lo posible.\n'
        '3. Júntalas despacio.',
      'machine_hip_thrust':
        '1. Apoya la parte alta de la espalda en el respaldo y pon el cinturón sobre la cadera.\n'
        '2. Sube la cadera hasta alinear rodillas y hombros.\n'
        '3. Aprieta los glúteos arriba y baja despacio.',
      'single_leg_glute_bridge':
        '1. Boca arriba, un pie en el suelo y la otra pierna estirada hacia arriba.\n'
        '2. Sube la cadera empujando con el talón apoyado.\n'
        '3. Baja despacio. Termina y cambia de pierna.',
      'donkey_kick':
        '1. A cuatro patas, manos bajo los hombros.\n'
        '2. Sube una pierna flexionada hacia atrás, planta del pie al techo.\n'
        '3. Baja despacio sin arquear la espalda.',
      'fire_hydrant':
        '1. A cuatro patas, espalda recta.\n'
        '2. Eleva una pierna flexionada hacia el lado hasta la altura de la cadera.\n'
        '3. Baja despacio, la cadera no se inclina.',
      'banded_lateral_walk':
        '1. Pon una minibanda sobre las rodillas o tobillos y flexiona un poco las rodillas.\n'
        '2. Camina de lado manteniendo la banda tensa.\n'
        '3. Cuenta los pasos hacia un lado y vuelve.',
      'cable_pull_through':
        '1. De espaldas a la polea baja, cuerda entre las piernas.\n'
        '2. Inclínate con la espalda recta dejando que la cuerda vaya atrás.\n'
        '3. Empuja la cadera hacia delante para subir y aprieta los glúteos.',
      'seated_calf_raise':
        '1. Siéntate con el rodillo sobre los muslos, puntas de los pies en el escalón.\n'
        '2. Sube los talones todo lo posible.\n'
        '3. Baja despacio hasta el estiramiento completo.',
      'single_leg_calf_raise':
        '1. Apoya un pie en el borde de un escalón y sujétate.\n'
        '2. Sube de puntillas lo más alto posible.\n'
        '3. Baja el talón por debajo del escalón para estirar.',
      'leg_press_calf_raise':
        '1. Siéntate en la prensa con las puntas en el borde inferior de la plataforma.\n'
        '2. Empuja la plataforma estirando los pies.\n'
        '3. Deja que vuelva despacio para estirar. Rodillas rectas.',
      'sit_up':
        '1. Boca arriba, rodillas flexionadas, pies en el suelo.\n'
        '2. Sube hasta sentarte.\n'
        '3. Baja despacio.',
      'decline_sit_up':
        '1. Sujeta los pies en el banco declinado y acuéstate.\n'
        '2. Sube hasta que el torso quede vertical.\n'
        '3. Baja despacio. Sujeta un disco para más carga.',
      'bicycle_crunch':
        '1. Boca arriba, manos junto a la cabeza, piernas elevadas.\n'
        '2. Lleva un codo hacia la rodilla contraria mientras estiras la otra pierna.\n'
        '3. Alterna los lados como pedaleando.',
      'reverse_crunch':
        '1. Boca arriba, rodillas a 90°, brazos en el suelo.\n'
        '2. Despega la cadera y lleva las rodillas al pecho.\n'
        '3. Baja despacio sin balancearte.',
      'lying_leg_raise':
        '1. Boca arriba, piernas estiradas, zona lumbar pegada al suelo.\n'
        '2. Sube las piernas hasta que apunten al techo.\n'
        '3. Bájalas despacio sin arquear la espalda.',
      'captains_chair_knee_raise':
        '1. Apoya los antebrazos en los soportes y la espalda en el respaldo.\n'
        '2. Lleva las rodillas al pecho.\n'
        '3. Baja despacio sin balancearte.',
      'ab_wheel_rollout':
        '1. De rodillas, sujeta la rueda bajo los hombros.\n'
        '2. Rueda hacia delante todo lo que puedas sin hundir la zona lumbar.\n'
        '3. Vuelve tirando con el abdomen.',
      'russian_twist':
        '1. Siéntate con el torso algo reclinado, pies elevados o en el suelo.\n'
        '2. Gira el torso y toca el suelo junto a la cadera.\n'
        '3. Gira al otro lado. Sujeta un peso para más carga.',
      'v_up':
        '1. Boca arriba, brazos por encima de la cabeza, piernas estiradas.\n'
        '2. Sube brazos y piernas a la vez y toca los pies.\n'
        '3. Baja despacio.',
      'hollow_hold':
        '1. Boca arriba, pega la zona lumbar al suelo.\n'
        '2. Despega un poco los hombros y las piernas estiradas.\n'
        '3. Aguanta el tiempo marcado sin arquear la espalda.',
      'pallof_press':
        '1. De lado a una polea a la altura del pecho, agarre junto al pecho.\n'
        '2. Empuja el agarre al frente sin dejar que el cuerpo gire.\n'
        '3. Vuelve al pecho. Trabaja ambos lados.',
      'cable_woodchopper':
        '1. De lado a la polea alta, sujeta el agarre con las dos manos.\n'
        '2. Tira en diagonal hacia abajo cruzando el cuerpo y girando el torso.\n'
        '3. Vuelve despacio. Trabaja ambos lados.',
      'plank_shoulder_tap':
        '1. En plancha alta, pies algo separados.\n'
        '2. Toca el hombro contrario con una mano sin mover la cadera.\n'
        '3. Cambia de mano.',
      'bird_dog':
        '1. A cuatro patas, espalda recta.\n'
        '2. Estira un brazo al frente y la pierna contraria atrás.\n'
        '3. Mantén un momento, vuelve y cambia de lado.',
      'power_clean':
        '1. Colócate sobre la barra, agarre justo fuera de las rodillas, espalda recta.\n'
        '2. Tira de forma explosiva junto al cuerpo y recíbela sobre la parte delantera de los hombros.\n'
        '3. Ponte de pie y baja la barra. Aprende la técnica con poco peso.',
      'thruster':
        '1. Sujeta la barra sobre la parte delantera de los hombros.\n'
        '2. Baja en sentadilla y al subir empuja la barra sobre la cabeza en un solo movimiento.\n'
        '3. Bájala a los hombros y enlaza con la siguiente sentadilla.',
      'turkish_get_up':
        '1. Boca arriba, sujeta una kettlebell con una mano hacia arriba.\n'
        '2. Levántate paso a paso mirando la kettlebell con el brazo recto.\n'
        '3. Vuelve igual hasta acostarte. Trabaja ambos lados.',
      'bear_crawl':
        '1. Apóyate en manos y pies, rodillas justo sobre el suelo, espalda recta.\n'
        '2. Avanza moviendo a la vez la mano y el pie contrarios.\n'
        '3. Mantén la cadera baja durante el tiempo marcado.',
      'high_knees':
        '1. Corre en el sitio subiendo las rodillas a la altura de la cadera.\n'
        '2. Mueve los brazos y mantente sobre la punta de los pies.\n'
        '3. Mantén un ritmo rápido durante el tiempo marcado.',
      'jump_rope':
        '1. Sujeta los mangos a la altura de la cadera, codos cerca del cuerpo.\n'
        '2. Gira la cuerda con las muñecas y salta lo justo para que pase.\n'
        '3. Aterriza suave sobre la punta de los pies durante el tiempo marcado.',
      'rowing_machine':
        '1. Sujeta los pies y agarra la empuñadura con los brazos rectos.\n'
        '2. Empuja con las piernas, inclínate un poco atrás y lleva la empuñadura a las costillas bajas.\n'
        '3. Vuelve en orden inverso: brazos, torso, piernas. Ritmo constante.',
      'stationary_bike':
        '1. Ajusta el sillín para que la rodilla quede algo flexionada abajo.\n'
        '2. Pedalea a ritmo constante con la espalda recta.\n'
        '3. Ajusta la resistencia a tu objetivo durante el tiempo marcado.',
      'treadmill_run':
        '1. Empieza caminando y sube la velocidad poco a poco.\n'
        '2. Corre con el cuerpo erguido y los hombros relajados, apoyando bajo la cadera.\n'
        '3. Reduce a paso de caminar antes de bajarte.',
      'elliptical':
        '1. Súbete a los pedales y agarra las asas móviles.\n'
        '2. Muévete con fluidez empujando y tirando también con los brazos.\n'
        '3. Mantén un ritmo constante durante el tiempo marcado.',
      'stair_climber':
        '1. Súbete y elige una velocidad que puedas mantener.\n'
        '2. Sube con el cuerpo erguido, usa las barandillas solo para equilibrarte.\n'
        '3. Sigue durante el tiempo marcado.',
      'air_bike':
        '1. Siéntate y agarra las asas móviles.\n'
        '2. Pedalea mientras empujas y tiras de las asas.\n'
        '3. Cuanto más fuerte vas, más frena el ventilador. Durante el tiempo marcado.',
    },
    routineNames: {
      'home_upper': 'Tren superior en 5 minutos',
      'home_lower': 'Tren inferior en 5 minutos',
      'home_full': 'Cuerpo completo en 5 minutos',
    },
    programNames: {
      'full_body': 'Cuerpo completo (principiante)',
      'upper_lower': 'Tren superior / inferior',
      'ppl': 'Push / Pull / Pierna',
      'full_body_2x': 'Cuerpo completo 2× por semana',
      'dumbbell_home': 'Mancuernas en casa',
      'strength_5x5': 'Fuerza 5×5',
      'circuit': 'Circuito (resistencia)',
      'full_body_variation': 'Cuerpo completo – variante',
      'bodyweight_home': 'Peso corporal en casa',
      'machines': 'Máquinas (principiante)',
      'upper_lower_variation': 'Tren superior / inferior – variante',
      'ppl_variation': 'Push / Pull / Pierna – variante',
      'strength_dup': 'Fuerza – ondas semanales',
      'conditioning_intervals': 'Condición física – intervalos',
      'phul': 'Fuerza + volumen (PHUL)',
      'strength_advanced': 'Fuerza – 4 días (avanzado)',
      'ppl_6x': 'Push / Pull / Pierna 6× por semana',
    },
    programDescriptions: {
      'full_body':
        '3× por semana, alternando los entrenos A y B. Ideal para los primeros meses.',
      'upper_lower':
        '4× por semana: tren superior lun + jue, tren inferior mar + vie.',
      'ppl': '3× por semana: push lun, pull mié, pierna vie.',
      'full_body_2x':
        'Para semanas apretadas: 2 entrenos de una hora más o menos, lun + jue. Cada músculo 2× por semana.',
      'dumbbell_home':
        '3× por semana con un par de mancuernas y una esterilla, alternando A y B. Sin gimnasio.',
      'strength_5x5':
        '3× por semana, alternando A y B: 5 series de 5 en los ejercicios grandes. Cuando completas todas las series de 5, sube el peso.',
      'circuit':
        '3× por semana, alternando A y B: ejercicios en circuito seguidos, descansos cortos, muchas repeticiones. Para resistencia y forma física.',
      'full_body_variation':
        '3× por semana, alternando C y D. La misma estructura que Cuerpo completo (principiante) con otros ejercicios: cámbialo cada 6–8 semanas.',
      'bodyweight_home':
        '3× por semana, alternando A y B, sin material: solo una esterilla (y una mesa firme para los remos). Para empezar y para viajar.',
      'machines':
        '3× por semana, alternando A y B, en máquinas del gimnasio: fáciles de aprender y seguras sin compañero. Un buen primer paso antes del peso libre.',
      'upper_lower_variation':
        '4× por semana como Tren superior / inferior, con otros ejercicios (press inclinado, sentadilla frontal, hip thrust). Cámbialo cada 6–8 semanas.',
      'ppl_variation':
        '3× por semana como Push / Pull / Pierna, con otros ejercicios (primero press militar, remo con barra, sentadilla hack). Cámbialo cada 6–8 semanas.',
      'strength_dup':
        '3× por semana: día pesado (series de 3), día de volumen (6–8 repeticiones) y día medio (series de 5). Variar la carga dentro de la semana mantiene el progreso de fuerza después del primer año.',
      'conditioning_intervals':
        '3× por semana, alternando A y B: parejas de un ejercicio de fuerza y otro de cardio seguidos, y al final un bloque de cardio continuo. Para la forma física, la resistencia y perder grasa.',
      'phul':
        '4× por semana: días pesados de tren superior e inferior para la fuerza (lun, mar) y días con más repeticiones para el músculo (jue, vie). Unas 12–16 series por músculo a la semana.',
      'strength_advanced':
        '4× por semana, un gran ejercicio cada día (sentadilla, press de banca, peso muerto, press militar): series pesadas de 3, una variante relacionada y accesorios para los puntos débiles.',
      'ppl_6x':
        'Lun–sáb: Push, Pull, Pierna y luego Push B, Pull B, Pierna B. Cada músculo 2× por semana con mucho volumen: para personas con experiencia y buena recuperación.',
    },
    planNames: {
      'Full body A': 'Cuerpo completo A',
      'Full body B': 'Cuerpo completo B',
      'Upper body': 'Tren superior',
      'Lower body': 'Tren inferior',
      'Push': 'Push',
      'Pull': 'Pull',
      'Legs': 'Pierna',
      'Full body 2× A': 'Cuerpo completo 2× A',
      'Full body 2× B': 'Cuerpo completo 2× B',
      'Dumbbells A': 'Mancuernas A',
      'Dumbbells B': 'Mancuernas B',
      '5×5 A': '5×5 A',
      '5×5 B': '5×5 B',
      'Circuit A': 'Circuito A',
      'Circuit B': 'Circuito B',
      'Full body C': 'Cuerpo completo C',
      'Full body D': 'Cuerpo completo D',
      'Bodyweight A': 'Peso corporal A',
      'Bodyweight B': 'Peso corporal B',
      'Machines A': 'Máquinas A',
      'Machines B': 'Máquinas B',
      'Upper body B': 'Tren superior B',
      'Lower body B': 'Tren inferior B',
      'Push B': 'Push B',
      'Pull B': 'Pull B',
      'Legs B': 'Pierna B',
      'Strength: heavy day': 'Fuerza: día pesado',
      'Strength: volume day': 'Fuerza: día de volumen',
      'Strength: medium day': 'Fuerza: día medio',
      'Intervals A': 'Intervalos A',
      'Intervals B': 'Intervalos B',
      'Upper power': 'Superior – fuerza',
      'Lower power': 'Inferior – fuerza',
      'Upper hypertrophy': 'Superior – volumen',
      'Lower hypertrophy': 'Inferior – volumen',
      'Strength: squat': 'Fuerza: sentadilla',
      'Strength: bench': 'Fuerza: press de banca',
      'Strength: deadlift': 'Fuerza: peso muerto',
      'Strength: overhead press': 'Fuerza: press militar',
    },
  ),
  'fr': (
    exerciseNames: {
      'bench_press': 'Développé couché',
      'incline_dumbbell_press': 'Développé incliné haltères',
      'cable_fly': 'Écarté à la poulie',
      'push_up': 'Pompes',
      'deadlift': 'Soulevé de terre',
      'barbell_row': 'Rowing barre',
      'lat_pulldown': 'Tirage vertical',
      'pull_up': 'Tractions',
      'overhead_press': 'Développé militaire',
      'lateral_raise': 'Élévations latérales',
      'pike_push_up': 'Pompes en pike',
      'dumbbell_curl': 'Curl haltères',
      'triceps_pushdown': 'Extension triceps à la poulie',
      'dips': 'Dips',
      'back_squat': 'Squat',
      'leg_press': 'Presse à cuisses',
      'romanian_deadlift': 'Soulevé de terre roumain',
      'bodyweight_squat': 'Squat au poids du corps',
      'lunge': 'Fentes',
      'hip_thrust': 'Hip thrust',
      'glute_bridge': 'Pont fessier',
      'plank': 'Planche',
      'crunch': 'Crunch',
      'mountain_climber': 'Mountain climbers',
      'jumping_jack': 'Jumping jacks',
      'dumbbell_bench_press': 'Développé couché haltères',
      'incline_bench_press': 'Développé incliné',
      'chest_press_machine': 'Développé pectoraux machine',
      'pec_deck': 'Pec deck',
      'seated_cable_row': 'Tirage horizontal assis',
      'one_arm_dumbbell_row': 'Rowing haltère unilatéral',
      'chin_up': 'Tractions supination',
      'dumbbell_shoulder_press': 'Développé épaules haltères',
      'rear_delt_fly': 'Oiseau (deltoïdes postérieurs)',
      'face_pull': 'Face pull',
      'barbell_curl': 'Curl barre',
      'hammer_curl': 'Curl marteau',
      'cable_curl': 'Curl à la poulie',
      'skull_crusher': 'Barre au front',
      'overhead_triceps_extension': 'Extension triceps au-dessus de la tête',
      'close_grip_bench_press': 'Développé couché prise serrée',
      'front_squat': 'Front squat',
      'goblet_squat': 'Goblet squat',
      'bulgarian_split_squat': 'Squat bulgare',
      'leg_extension': 'Leg extension',
      'leg_curl': 'Leg curl',
      'calf_raise': 'Mollets debout',
      'hanging_leg_raise': 'Relevé de jambes suspendu',
      'cable_crunch': 'Crunch à la poulie',
      'dead_bug': 'Dead bug',
      'side_plank': 'Planche latérale',
      'burpee': 'Burpees',
      'kettlebell_swing': 'Swing kettlebell',
      'weighted_pull_up': 'Tractions lestées',
      'weighted_dips': 'Dips lestés',
      'barbell_shrug': 'Shrugs à la barre',
      'dumbbell_shrug': 'Shrugs aux haltères',
      'wrist_curl': 'Curl poignets',
      'reverse_curl': 'Curl inversé',
      'dead_hang': 'Suspension à la barre',
      'back_extension': 'Extensions lombaires',
      'good_morning': 'Good morning',
      'superman': 'Superman',
      'decline_bench_press': 'Développé couché décliné',
      'smith_bench_press': 'Développé couché à la Smith machine',
      'dumbbell_fly': 'Écarté couché aux haltères',
      'incline_dumbbell_fly': 'Écarté incliné aux haltères',
      'low_to_high_cable_fly': 'Écarté à la poulie de bas en haut',
      'incline_chest_press_machine': 'Presse pectorale inclinée',
      'chest_dips': 'Dips pour les pectoraux',
      'incline_push_up': 'Pompes inclinées',
      'decline_push_up': 'Pompes déclinées',
      'dumbbell_floor_press': 'Floor press aux haltères',
      't_bar_row': 'Rowing barre T',
      'pendlay_row': 'Rowing Pendlay',
      'machine_row': 'Rowing assis à la machine',
      'chest_supported_row': 'Rowing haltères sur banc incliné',
      'close_grip_lat_pulldown': 'Tirage vertical prise serrée',
      'straight_arm_pulldown': 'Pull-over à la poulie bras tendus',
      'band_assisted_pull_up': 'Tractions assistées avec élastique',
      'inverted_row': 'Rowing inversé',
      'neutral_grip_pull_up': 'Tractions prise neutre',
      'rack_pull': 'Rack pull',
      'trap_bar_deadlift': 'Soulevé de terre à la trap bar',
      'single_arm_cable_row': 'Rowing à la poulie à un bras',
      'dumbbell_pullover': 'Pull-over avec haltère',
      'renegade_row': 'Renegade row',
      'arnold_press': 'Développé Arnold',
      'shoulder_press_machine': 'Développé épaules à la machine',
      'push_press': 'Push press',
      'cable_lateral_raise': 'Élévations latérales à la poulie',
      'machine_lateral_raise': 'Élévations latérales à la machine',
      'front_raise': 'Élévations frontales aux haltères',
      'upright_row': 'Tirage menton',
      'reverse_pec_deck': 'Pec deck inversé',
      'band_pull_apart': 'Écartés à l’élastique',
      'handstand_push_up': 'Pompes en équilibre',
      'landmine_press': 'Développé landmine',
      'preacher_curl': 'Curl au pupitre',
      'concentration_curl': 'Curl concentré',
      'incline_dumbbell_curl': 'Curl incliné aux haltères',
      'ez_bar_curl': 'Curl barre EZ',
      'rope_hammer_curl': 'Curl marteau à la corde',
      'machine_biceps_curl': 'Curl biceps à la machine',
      'band_curl': 'Curl à l’élastique',
      'rope_pushdown': 'Extension triceps à la corde',
      'overhead_cable_extension': 'Extension triceps au-dessus de la tête à la poulie',
      'triceps_kickback': 'Kickback triceps',
      'bench_dips': 'Dips sur banc',
      'machine_triceps_dip': 'Dips à la machine',
      'single_arm_pushdown': 'Extension triceps à la poulie à un bras',
      'diamond_push_up': 'Pompes diamant',
      'reverse_wrist_curl': 'Curl poignets inversé',
      'hack_squat': 'Hack squat',
      'smith_squat': 'Squat à la Smith machine',
      'walking_lunge': 'Fentes marchées',
      'reverse_lunge': 'Fentes arrière',
      'step_up': 'Montées sur banc',
      'split_squat': 'Split squat',
      'sumo_squat': 'Squat sumo à l’haltère',
      'pistol_squat': 'Pistol squat',
      'single_leg_press': 'Presse à cuisses unilatérale',
      'hip_adduction_machine': 'Machine à adducteurs',
      'wall_sit': 'Chaise contre le mur',
      'jump_squat': 'Squat sauté',
      'box_jump': 'Box jump',
      'seated_leg_curl': 'Leg curl assis',
      'nordic_curl': 'Nordic curl',
      'single_leg_rdl': 'Soulevé de terre roumain sur une jambe',
      'dumbbell_romanian_deadlift': 'Soulevé de terre roumain aux haltères',
      'stiff_leg_deadlift': 'Soulevé de terre jambes tendues',
      'stability_ball_leg_curl': 'Leg curl sur swiss ball',
      'sumo_deadlift': 'Soulevé de terre sumo',
      'cable_glute_kickback': 'Kickback fessier à la poulie',
      'hip_abduction_machine': 'Machine à abducteurs',
      'machine_hip_thrust': 'Hip thrust à la machine',
      'single_leg_glute_bridge': 'Pont fessier sur une jambe',
      'donkey_kick': 'Donkey kick',
      'fire_hydrant': 'Fire hydrant',
      'banded_lateral_walk': 'Marche latérale avec élastique',
      'cable_pull_through': 'Pull-through à la poulie',
      'seated_calf_raise': 'Mollets assis',
      'single_leg_calf_raise': 'Mollets sur une jambe',
      'leg_press_calf_raise': 'Mollets à la presse',
      'sit_up': 'Sit-ups',
      'decline_sit_up': 'Sit-ups sur banc décliné',
      'bicycle_crunch': 'Crunch vélo',
      'reverse_crunch': 'Crunch inversé',
      'lying_leg_raise': 'Relevés de jambes allongé',
      'captains_chair_knee_raise': 'Relevés de genoux à la chaise romaine',
      'ab_wheel_rollout': 'Roue abdominale',
      'russian_twist': 'Russian twist',
      'v_up': 'V-up',
      'hollow_hold': 'Hollow hold',
      'pallof_press': 'Pallof press',
      'cable_woodchopper': 'Bûcheron à la poulie',
      'plank_shoulder_tap': 'Planche avec touches d’épaule',
      'bird_dog': 'Bird dog',
      'power_clean': 'Épaulé en puissance (power clean)',
      'thruster': 'Thruster',
      'turkish_get_up': 'Turkish get-up',
      'bear_crawl': 'Marche de l’ours',
      'high_knees': 'Montées de genoux',
      'jump_rope': 'Corde à sauter',
      'rowing_machine': 'Rameur',
      'stationary_bike': 'Vélo d’appartement',
      'treadmill_run': 'Course sur tapis',
      'elliptical': 'Vélo elliptique',
      'stair_climber': 'Simulateur d’escalier',
      'air_bike': 'Air bike',
    },
    exerciseInstructions: {
      'bench_press':
        '1. Allonge-toi sur le banc, les yeux sous la barre, les pieds à plat au sol.\n'
        '2. Prise un peu plus large que les épaules, serre les omoplates.\n'
        '3. Descends la barre au milieu de la poitrine avec contrôle, coudes à environ 45° du corps.\n'
        '4. Pousse jusqu’à bras tendus sans décoller les hanches.',
      'incline_dumbbell_press':
        '1. Règle le banc à 30–45°, haltères au niveau de la poitrine.\n'
        '2. Garde les omoplates serrées et les pieds au sol.\n'
        '3. Pousse vers le haut en rapprochant légèrement les haltères, puis redescends lentement au niveau de la poitrine.',
      'cable_fly':
        '1. Place-toi entre les poulies, coudes légèrement fléchis.\n'
        '2. Rapproche les poignées en arc de cercle devant ta poitrine.\n'
        '3. Reviens lentement jusqu’à sentir l’étirement, garde les coudes fixes.',
      'push_up':
        '1. Mains un peu plus larges que les épaules, corps bien aligné.\n'
        '2. Descends la poitrine près du sol, coudes à environ 45° du corps.\n'
        '3. Repousse vers le haut en gardant les abdos et les fessiers serrés.',
      'deadlift':
        '1. Barre au-dessus du milieu du pied, pieds écartés largeur de hanches.\n'
        '2. Bascule depuis les hanches, attrape la barre, garde le dos neutre.\n'
        '3. Pousse le sol et redresse-toi avec la barre près des jambes.\n'
        '4. Redescends avec contrôle en poussant les hanches vers l’arrière.',
      'barbell_row':
        '1. Penche-toi à environ 45°, dos droit, genoux légèrement fléchis.\n'
        '2. Tire la barre vers le bas de la poitrine ou le ventre.\n'
        '3. Serre les omoplates, puis redescends lentement.',
      'lat_pulldown':
        '1. Prise un peu plus large que les épaules, cuisses bloquées sous les boudins.\n'
        '2. Tire la barre vers le haut de la poitrine, coudes vers le bas et l’arrière.\n'
        '3. Remonte lentement jusqu’à bras tendus sans te balancer.',
      'pull_up':
        '1. Suspends-toi à la barre en pronation, épaules actives.\n'
        '2. Tire-toi jusqu’à ce que le menton passe au-dessus de la barre.\n'
        '3. Redescends avec contrôle jusqu’à bras tendus.',
      'overhead_press':
        '1. Barre sur l’avant des épaules, prise juste à l’extérieur des épaules.\n'
        '2. Serre les fessiers et les abdos, pousse la barre droit vers le haut.\n'
        '3. Recule un peu la tête au passage de la barre, verrouille bras tendus au-dessus de la tête.',
      'lateral_raise':
        '1. Tiens-toi droit, haltères le long du corps, coudes légèrement fléchis.\n'
        '2. Monte les bras sur les côtés jusqu’à hauteur d’épaules.\n'
        '3. Redescends lentement, sans élan.',
      'pike_push_up':
        '1. Pars en position de pompe et monte les hanches en V inversé.\n'
        '2. Descends la tête vers le sol entre tes mains.\n'
        '3. Repousse vers le haut avec les épaules.',
      'dumbbell_curl':
        '1. Tiens-toi droit, coudes le long du corps.\n'
        '2. Monte les haltères sans bouger les coudes.\n'
        '3. Redescends lentement jusqu’à bras tendus.',
      'triceps_pushdown':
        '1. Place-toi face à la poulie, coudes collés au corps.\n'
        '2. Pousse la poignée vers le bas jusqu’à bras tendus.\n'
        '3. Remonte lentement, garde les coudes immobiles.',
      'dips':
        '1. Appuie-toi sur les barres, bras tendus.\n'
        '2. Descends jusqu’à ce que tes bras soient à peu près parallèles au sol.\n'
        '3. Repousse vers le haut, sans laisser tomber les épaules vers l’avant.',
      'back_squat':
        '1. Barre sur le haut du dos, pieds largeur d’épaules, pointes légèrement vers l’extérieur.\n'
        '2. Gaine les abdos et descends entre tes talons.\n'
        '3. Les genoux suivent les pointes de pied, le dos reste neutre.\n'
        '4. Remonte en poussant avec tout le pied.',
      'leg_press':
        '1. Pieds largeur d’épaules au milieu de la plateforme.\n'
        '2. Descends jusqu’à environ 90° aux genoux, le bas du dos reste sur le dossier.\n'
        '3. Pousse sans verrouiller les genoux brutalement.',
      'romanian_deadlift':
        '1. Debout avec la barre, genoux légèrement fléchis.\n'
        '2. Pousse les hanches vers l’arrière et descends la barre le long des jambes.\n'
        '3. Arrête-toi quand tu sens l’étirement dans les ischios, dos droit.\n'
        '4. Remonte en poussant les hanches vers l’avant.',
      'bodyweight_squat':
        '1. Pieds largeur d’épaules, bras devant pour l’équilibre.\n'
        '2. Descends aussi bas que possible, dos droit.\n'
        '3. Remonte en poussant sur les talons.',
      'lunge':
        '1. Fais un pas en avant et descends jusqu’à ce que les deux genoux soient à environ 90°.\n'
        '2. Le genou avant reste au-dessus du pied, buste droit.\n'
        '3. Repousse pour revenir au départ et change de jambe.',
      'hip_thrust':
        '1. Haut du dos sur le banc, barre sur les hanches.\n'
        '2. Pousse sur les talons et monte les hanches jusqu’à ce que ton corps soit aligné.\n'
        '3. Serre les fessiers en haut, redescends avec contrôle.',
      'glute_bridge':
        '1. Allonge-toi sur le dos, genoux fléchis, pieds au sol.\n'
        '2. Monte les hanches en serrant les fessiers.\n'
        '3. Tiens un instant en haut et redescends lentement.',
      'plank':
        '1. Avant-bras sous les épaules, corps bien aligné.\n'
        '2. Serre les abdos et les fessiers, ne laisse pas les hanches s’affaisser.\n'
        '3. Respire régulièrement et tiens.',
      'crunch':
        '1. Allonge-toi sur le dos, genoux fléchis, mains près de la tête.\n'
        '2. Décolle les épaules du sol en contractant les abdos.\n'
        '3. Redescends lentement, sans tirer sur la nuque.',
      'mountain_climber':
        '1. Pars en position de pompe.\n'
        '2. Ramène les genoux vers la poitrine l’un après l’autre.\n'
        '3. Garde les hanches basses et un rythme régulier.',
      'jumping_jack':
        '1. Debout, pieds joints, bras le long du corps.\n'
        '2. Saute en écartant les pieds et monte les bras au-dessus de la tête.\n'
        '3. Reviens en sautant et répète à un rythme régulier.',
      'dumbbell_bench_press':
        '1. Allonge-toi sur un banc plat, haltères au niveau de la poitrine.\n'
        '2. Pousse vers le haut en rapprochant légèrement les haltères.\n'
        '3. Redescends lentement jusqu’à sentir l’étirement dans les pectoraux.',
      'incline_bench_press':
        '1. Banc à 30–45°, prise un peu plus large que les épaules.\n'
        '2. Descends la barre vers le haut de la poitrine.\n'
        '3. Pousse vers le haut, garde les omoplates serrées.',
      'chest_press_machine':
        '1. Règle le siège pour que les poignées soient au milieu de la poitrine.\n'
        '2. Pousse vers l’avant jusqu’à bras presque tendus.\n'
        '3. Reviens lentement, garde le dos contre le dossier.',
      'pec_deck':
        '1. Assieds-toi, dos contre le dossier, coudes légèrement fléchis.\n'
        '2. Rapproche les poignées devant ta poitrine.\n'
        '3. Reviens lentement jusqu’à un étirement confortable.',
      'seated_cable_row':
        '1. Assieds-toi bien droit, pieds sur la plateforme, genoux légèrement fléchis.\n'
        '2. Tire la poignée vers le ventre, coudes près du corps.\n'
        '3. Serre les omoplates, reviens lentement sans arrondir le dos.',
      'one_arm_dumbbell_row':
        '1. Un genou et une main sur le banc, dos plat.\n'
        '2. Tire l’haltère vers ta hanche.\n'
        '3. Redescends lentement jusqu’à l’étirement complet.',
      'chin_up':
        '1. Suspends-toi à la barre en supination, mains largeur d’épaules.\n'
        '2. Tire-toi jusqu’à ce que le menton passe au-dessus de la barre.\n'
        '3. Redescends avec contrôle jusqu’à bras tendus.',
      'dumbbell_shoulder_press':
        '1. Sur un banc ou debout, haltères à hauteur d’épaules.\n'
        '2. Pousse au-dessus de la tête sans cambrer le bas du dos.\n'
        '3. Redescends lentement vers les épaules.',
      'rear_delt_fly':
        '1. Penche-toi en avant, dos plat, haltères pendants.\n'
        '2. Monte les bras sur les côtés, coudes légèrement fléchis.\n'
        '3. Redescends lentement, sans élan.',
      'face_pull':
        '1. Corde à hauteur de tête, pouces vers toi.\n'
        '2. Tire vers ton visage, coudes hauts et écartés.\n'
        '3. Serre le haut du dos, reviens lentement.',
      'barbell_curl':
        '1. Tiens-toi droit, prise en supination largeur d’épaules.\n'
        '2. Monte la barre sans balancer le corps.\n'
        '3. Redescends lentement jusqu’à bras tendus.',
      'hammer_curl':
        '1. Tiens les haltères paumes face à face.\n'
        '2. Monte les haltères, les coudes restent le long du corps.\n'
        '3. Redescends lentement.',
      'cable_curl':
        '1. Face à la poulie basse, coudes le long du corps.\n'
        '2. Monte la poignée jusqu’aux épaules.\n'
        '3. Redescends lentement en gardant une tension constante.',
      'skull_crusher':
        '1. Allonge-toi sur un banc, barre au-dessus de la poitrine, bras tendus.\n'
        '2. Plie seulement les coudes et descends la barre vers ton front.\n'
        '3. Remonte en tendant les bras, coudes pointés vers le haut.',
      'overhead_triceps_extension':
        '1. Tiens un haltère au-dessus de la tête à deux mains.\n'
        '2. Descends-le derrière la tête en pliant les coudes.\n'
        '3. Remonte en tendant les bras, coudes près de la tête.',
      'close_grip_bench_press':
        '1. Allonge-toi sur le banc, prise environ largeur d’épaules.\n'
        '2. Descends la barre vers le bas de la poitrine, coudes près du corps.\n'
        '3. Pousse en tendant les coudes.',
      'front_squat':
        '1. Barre sur l’avant des épaules, coudes hauts.\n'
        '2. Descends en squat, buste droit.\n'
        '3. Remonte en gardant les coudes hauts tout du long.',
      'goblet_squat':
        '1. Tiens un kettlebell ou un haltère contre ta poitrine.\n'
        '2. Descends en squat entre tes genoux, dos droit.\n'
        '3. Remonte en poussant sur les talons.',
      'bulgarian_split_squat':
        '1. Pied arrière sur un banc, pied avant une grande foulée devant.\n'
        '2. Descends jusqu’à ce que la cuisse avant soit à peu près parallèle au sol.\n'
        '3. Remonte en poussant sur le pied avant, puis change de jambe.',
      'leg_extension':
        '1. Règle le boudin juste au-dessus des chevilles.\n'
        '2. Tends les jambes complètement.\n'
        '3. Redescends lentement avec contrôle.',
      'leg_curl':
        '1. Règle le boudin juste au-dessus des talons.\n'
        '2. Ramène les talons vers les fessiers.\n'
        '3. Reviens lentement, sans laisser tomber la charge.',
      'calf_raise':
        '1. Avant des pieds sur le rebord, talons dans le vide.\n'
        '2. Monte le plus haut possible sur la pointe des pieds.\n'
        '3. Redescends lentement jusqu’à l’étirement.',
      'hanging_leg_raise':
        '1. Suspends-toi à la barre, épaules actives.\n'
        '2. Monte les jambes ou les genoux avec les abdos, sans te balancer.\n'
        '3. Redescends lentement.',
      'cable_crunch':
        '1. À genoux face à la poulie, corde près de la tête.\n'
        '2. Enroule-toi vers le bas en arrondissant le dos, les hanches restent immobiles.\n'
        '3. Reviens lentement.',
      'dead_bug':
        '1. Allonge-toi sur le dos, bras tendus vers le haut, genoux à 90°.\n'
        '2. Descends le bras et la jambe opposés, le bas du dos reste au sol.\n'
        '3. Reviens et change de côté.',
      'side_plank':
        '1. Allonge-toi sur le côté, coude sous l’épaule.\n'
        '2. Monte les hanches pour que ton corps forme une ligne droite.\n'
        '3. Tiens, puis change de côté.',
      'burpee':
        '1. Debout, descends en squat et pose les mains au sol.\n'
        '2. Saute les pieds en arrière en planche, fais une pompe si tu veux.\n'
        '3. Ramène les pieds en sautant et saute vers le haut.',
      'kettlebell_swing':
        '1. Kettlebell devant toi, pieds un peu plus larges que les hanches.\n'
        '2. Envoie-le en arrière entre tes jambes en basculant depuis les hanches.\n'
        '3. Projette les hanches vers l’avant pour le balancer à hauteur de poitrine, bras relâchés.',
      'weighted_pull_up':
        '1. Accroche un disque à une ceinture de lest ou coince un haltère entre tes pieds.\n'
        '2. Suspends-toi à la barre en pronation, épaules actives.\n'
        '3. Tire-toi sans élan jusqu’à ce que le menton passe au-dessus de la barre.\n'
        '4. Redescends avec contrôle jusqu’à bras tendus. Note uniquement la charge ajoutée.',
      'weighted_dips':
        '1. Accroche un disque à une ceinture de lest ou coince un haltère entre tes pieds.\n'
        '2. Appuie-toi sur les barres, bras tendus.\n'
        '3. Descends jusqu’à ce que tes bras soient à peu près parallèles au sol.\n'
        '4. Repousse vers le haut, sans laisser tomber les épaules vers l’avant. Note uniquement la charge ajoutée.',
      'barbell_shrug':
        '1. Debout, tiens la barre bras tendus, prise largeur d’épaules.\n'
        '2. Monte les épaules à la verticale vers les oreilles, bras tendus.\n'
        '3. Marque une pause en haut puis redescends lentement. Ne fais pas rouler les épaules.',
      'dumbbell_shrug':
        '1. Debout, un haltère dans chaque main le long du corps, paumes vers toi.\n'
        '2. Monte les épaules à la verticale le plus haut possible.\n'
        '3. Tiens un instant puis redescends avec contrôle.',
      'wrist_curl':
        '1. Assieds-toi, avant-bras sur les cuisses ou un banc, paumes vers le haut, poignets dans le vide.\n'
        '2. Laisse les haltères rouler jusqu’au bout des doigts.\n'
        '3. Remonte les poignets le plus haut possible, avant-bras immobiles.',
      'reverse_curl':
        '1. Debout, tiens la barre en pronation, largeur d’épaules.\n'
        '2. Monte la barre, coudes le long du corps, poignets droits.\n'
        '3. Redescends lentement jusqu’aux bras tendus.',
      'dead_hang':
        '1. Saisis la barre en pronation, largeur d’épaules.\n'
        '2. Suspends-toi bras tendus, pieds décollés, corps immobile.\n'
        '3. Tiens le temps prévu, épaules légèrement engagées.',
      'back_extension':
        '1. Place le coussin juste sous les hanches et bloque les talons.\n'
        '2. Descends le buste dos droit jusqu’à sentir l’étirement des ischios.\n'
        '3. Remonte jusqu’à l’alignement avec les jambes, sans cambrer. Tiens un disque pour plus de charge.',
      'good_morning':
        '1. Barre sur le haut du dos comme au squat, pieds largeur de hanches, genoux légèrement fléchis.\n'
        '2. Recule les hanches et penche-toi dos droit jusqu’à ce que le buste soit presque horizontal.\n'
        '3. Pousse les hanches vers l’avant pour te redresser. Commence léger.',
      'superman':
        '1. Allonge-toi sur le ventre, bras tendus au-dessus de la tête.\n'
        '2. Décolle en même temps les bras, la poitrine et les jambes.\n'
        '3. Tiens une seconde en haut puis redescends lentement.',
      'decline_bench_press':
        '1. Cale tes jambes sur le banc décliné, prise un peu plus large que les épaules.\n'
        '2. Descends la barre en contrôle vers le bas des pectoraux.\n'
        '3. Pousse jusqu’aux bras tendus, omoplates serrées.',
      'smith_bench_press':
        '1. Place le banc pour que la barre arrive au milieu de la poitrine.\n'
        '2. Décroche la barre et descends-la en contrôle vers la poitrine.\n'
        '3. Pousse sans verrouiller brutalement les coudes, puis raccroche la barre.',
      'dumbbell_fly':
        '1. Allonge-toi sur un banc plat, haltères au-dessus de la poitrine, coudes légèrement fléchis.\n'
        '2. Ouvre les bras en un large arc jusqu’à sentir l’étirement des pectoraux.\n'
        '3. Ramène les haltères ensemble sans changer l’angle des coudes.',
      'incline_dumbbell_fly':
        '1. Règle le banc à 30°, haltères au-dessus de la poitrine, coudes souples.\n'
        '2. Descends en large arc jusqu’à sentir l’étirement du haut des pectoraux.\n'
        '3. Ramène-les ensemble au-dessus de la poitrine.',
      'low_to_high_cable_fly':
        '1. Règle les deux poulies en bas et place-toi entre elles, buste légèrement incliné.\n'
        '2. Monte les poignées et rapproche-les devant le haut de la poitrine.\n'
        '3. Reviens lentement en étirement, coudes légèrement fléchis.',
      'incline_chest_press_machine':
        '1. Règle le siège pour que les poignées soient à hauteur du haut de la poitrine.\n'
        '2. Pousse vers l’avant et le haut jusqu’aux bras presque tendus.\n'
        '3. Reviens lentement jusqu’à sentir l’étirement.',
      'chest_dips':
        '1. En appui sur les barres, penche le buste vers l’avant.\n'
        '2. Descends coudes légèrement écartés jusqu’à sentir l’étirement des pectoraux.\n'
        '3. Remonte en gardant l’inclinaison.',
      'incline_push_up':
        '1. Mains sur un banc ou une box, corps aligné.\n'
        '2. Descends la poitrine vers le bord, coudes à environ 45° du corps.\n'
        '3. Remonte. Plus l’appui est haut, plus c’est facile.',
      'decline_push_up':
        '1. Pieds sur un banc, mains au sol sous les épaules.\n'
        '2. Descends la poitrine vers le sol, gainage serré.\n'
        '3. Remonte sans laisser tomber le bassin.',
      'dumbbell_floor_press':
        '1. Allonge-toi au sol, genoux fléchis, haltères au-dessus de la poitrine.\n'
        '2. Descends jusqu’à ce que les bras touchent le sol, marque une pause.\n'
        '3. Pousse jusqu’aux bras tendus.',
      't_bar_row':
        '1. Place-toi au-dessus de la barre, penche-toi dos droit et saisis la poignée.\n'
        '2. Tire la charge vers la poitrine en serrant les omoplates.\n'
        '3. Redescends en contrôle sans arrondir le dos.',
      'pendlay_row':
        '1. Barre au sol, buste presque horizontal, dos droit.\n'
        '2. Tire la barre de façon explosive vers le bas de la poitrine.\n'
        '3. Repose-la au sol à chaque répétition et replace-toi.',
      'machine_row':
        '1. Assieds-toi poitrine contre le coussin et saisis les poignées.\n'
        '2. Tire vers toi, coudes serrés, omoplates rapprochées.\n'
        '3. Reviens lentement jusqu’aux bras tendus.',
      'chest_supported_row':
        '1. Allonge-toi à plat ventre sur un banc à 30–45°, haltères pendants.\n'
        '2. Tire-les vers les hanches en serrant les omoplates.\n'
        '3. Redescends lentement en étirement complet.',
      'close_grip_lat_pulldown':
        '1. Assieds-toi au tirage avec une poignée serrée ou en V, cuisses calées.\n'
        '2. Tire la poignée vers le haut de la poitrine, coudes vers le bas et l’arrière.\n'
        '3. Laisse remonter lentement jusqu’aux bras tendus.',
      'straight_arm_pulldown':
        '1. Face à la poulie haute, bras presque tendus, buste légèrement incliné.\n'
        '2. Abaisse la barre en arc jusqu’aux cuisses avec les dorsaux.\n'
        '3. Laisse remonter lentement, coudes presque tendus.',
      'band_assisted_pull_up':
        '1. Passe un élastique sur la barre et place un pied ou un genou dedans.\n'
        '2. Monte jusqu’à ce que le menton passe la barre.\n'
        '3. Redescends en contrôle en suspension complète. Élastique plus fin = moins d’aide.',
      'inverted_row':
        '1. Suspends-toi sous une barre basse ou des anneaux, corps droit, talons au sol.\n'
        '2. Tire la poitrine vers la barre en serrant les omoplates.\n'
        '3. Redescends en contrôle. Plus ton corps est vertical, plus c’est facile.',
      'neutral_grip_pull_up':
        '1. Suspends-toi à des poignées parallèles, paumes face à face.\n'
        '2. Monte jusqu’à ce que le menton passe les poignées.\n'
        '3. Redescends en contrôle en suspension complète.',
      'rack_pull':
        '1. Pose la barre sur les sécurités juste sous ou au-dessus des genoux.\n'
        '2. Saisis-la, gaine-toi et redresse-toi en poussant les hanches vers l’avant.\n'
        '3. Repose-la sur les sécurités, dos droit.',
      'trap_bar_deadlift':
        '1. Place-toi dans la trap bar, pieds largeur de hanches, saisis les poignées.\n'
        '2. Gaine-toi, pousse le sol et redresse-toi.\n'
        '3. Redescends la barre dos droit.',
      'single_arm_cable_row':
        '1. Saisis une poignée à la poulie à mi-hauteur, bras tendu.\n'
        '2. Tire-la vers la hanche, coude près du corps.\n'
        '3. Reviens lentement en laissant l’épaule avancer un peu.',
      'dumbbell_pullover':
        '1. Allonge-toi sur un banc et tiens un haltère à deux mains au-dessus de la poitrine.\n'
        '2. Descends-le en arc derrière la tête, coudes légèrement fléchis.\n'
        '3. Ramène-le au-dessus de la poitrine.',
      'renegade_row':
        '1. En position de pompe sur deux haltères, pieds écartés.\n'
        '2. Tire un haltère vers la hanche sans tourner le bassin.\n'
        '3. Repose-le et recommence de l’autre bras.',
      'arnold_press':
        '1. Assieds-toi, haltères devant les épaules, paumes vers toi.\n'
        '2. Pousse vers le haut en tournant les paumes vers l’avant.\n'
        '3. Redescends en revenant à la position de départ.',
      'shoulder_press_machine':
        '1. Règle le siège pour que les poignées partent à hauteur d’épaules.\n'
        '2. Pousse jusqu’aux bras presque tendus.\n'
        '3. Redescends lentement à hauteur d’épaules.',
      'push_press':
        '1. Barre sur l’avant des épaules, pieds largeur de hanches.\n'
        '2. Fléchis légèrement les genoux puis pousse la barre au-dessus de la tête avec l’élan des jambes.\n'
        '3. Ramène-la sur les épaules en contrôle.',
      'cable_lateral_raise':
        '1. De profil à la poulie basse, poignée dans la main éloignée.\n'
        '2. Monte le bras sur le côté jusqu’à hauteur d’épaule.\n'
        '3. Redescends lentement en gardant la tension.',
      'machine_lateral_raise':
        '1. Assieds-toi, coussins contre l’extérieur des bras.\n'
        '2. Monte les bras jusqu’à hauteur d’épaules.\n'
        '3. Redescends lentement sans poser la charge.',
      'front_raise':
        '1. Debout, haltères devant les cuisses.\n'
        '2. Monte-les devant toi jusqu’à hauteur d’épaules, bras presque tendus.\n'
        '3. Redescends lentement sans élan.',
      'upright_row':
        '1. Tiens la barre devant les cuisses, prise environ largeur d’épaules.\n'
        '2. Monte-la le long du corps jusqu’à la poitrine, coudes en premier.\n'
        '3. Redescends lentement. Si les épaules coincent, monte moins haut.',
      'reverse_pec_deck':
        '1. Assieds-toi face à la machine, poitrine contre le coussin, saisis les poignées.\n'
        '2. Ouvre les bras vers l’arrière en arc jusqu’à l’alignement du corps.\n'
        '3. Reviens lentement.',
      'band_pull_apart':
        '1. Tiens un élastique devant toi à hauteur d’épaules, bras tendus.\n'
        '2. Écarte-le jusqu’à la poitrine en serrant les omoplates.\n'
        '3. Reviens lentement.',
      'handstand_push_up':
        '1. Monte en équilibre sur les mains contre un mur, mains largeur d’épaules.\n'
        '2. Descends la tête vers le sol en contrôle.\n'
        '3. Pousse jusqu’aux bras tendus. Mets un tapis sous la tête.',
      'landmine_press':
        '1. Tiens l’extrémité de la barre landmine à l’épaule, pieds décalés.\n'
        '2. Pousse vers le haut et l’avant jusqu’au bras tendu.\n'
        '3. Ramène-la à l’épaule en contrôle.',
      'preacher_curl':
        '1. Assieds-toi au pupitre, bras à plat sur le coussin, barre EZ en main.\n'
        '2. Monte la barre sans décoller les coudes.\n'
        '3. Redescends lentement presque bras tendus.',
      'concentration_curl':
        '1. Assieds-toi sur un banc, coude calé contre l’intérieur de la cuisse.\n'
        '2. Monte l’haltère vers l’épaule.\n'
        '3. Redescends lentement en étirement complet.',
      'incline_dumbbell_curl':
        '1. Adosse-toi à un banc à 45–60°, bras pendants.\n'
        '2. Monte les haltères sans bouger les bras.\n'
        '3. Redescends lentement en étirement complet.',
      'ez_bar_curl':
        '1. Debout, tiens la barre EZ aux parties coudées, bras tendus.\n'
        '2. Monte-la sans balancer le corps.\n'
        '3. Redescends lentement jusqu’aux bras tendus.',
      'rope_hammer_curl':
        '1. Accroche une corde à la poulie basse, paumes face à face.\n'
        '2. Monte la corde, coudes le long du corps.\n'
        '3. Redescends lentement en gardant la tension.',
      'machine_biceps_curl':
        '1. Assieds-toi, bras sur le coussin, saisis les poignées.\n'
        '2. Monte les poignées vers les épaules.\n'
        '3. Redescends lentement presque bras tendus.',
      'band_curl':
        '1. Debout sur le milieu de l’élastique, extrémités en main.\n'
        '2. Monte les mains vers les épaules, coudes le long du corps.\n'
        '3. Redescends lentement.',
      'rope_pushdown':
        '1. Tiens la corde à la poulie haute, coudes le long du corps.\n'
        '2. Pousse vers le bas et écarte les extrémités en fin de mouvement.\n'
        '3. Laisse remonter lentement jusqu’à environ 90° au coude.',
      'overhead_cable_extension':
        '1. Dos à la poulie, corde derrière la tête, coudes en haut.\n'
        '2. Tends les bras vers l’avant et le haut.\n'
        '3. Fléchis lentement les coudes derrière la tête.',
      'triceps_kickback':
        '1. Penche-toi en avant, bras le long du corps, coude fléchi.\n'
        '2. Tends complètement le bras vers l’arrière.\n'
        '3. Fléchis lentement sans bouger le bras.',
      'bench_dips':
        '1. Mains sur le bord d’un banc derrière toi, jambes devant.\n'
        '2. Descends en fléchissant les coudes à environ 90°.\n'
        '3. Remonte jusqu’aux bras tendus.',
      'machine_triceps_dip':
        '1. Assieds-toi dans la machine et saisis les poignées latérales.\n'
        '2. Pousse vers le bas jusqu’aux bras tendus.\n'
        '3. Laisse remonter lentement jusqu’à environ 90° au coude.',
      'single_arm_pushdown':
        '1. Tiens une poignée à la poulie haute, coude le long du corps.\n'
        '2. Pousse vers le bas jusqu’au bras tendu.\n'
        '3. Laisse remonter lentement, le coude ne bouge pas.',
      'diamond_push_up':
        '1. Position de pompe, mains jointes sous la poitrine en losange.\n'
        '2. Descends la poitrine vers les mains, coudes serrés.\n'
        '3. Remonte corps gainé.',
      'reverse_wrist_curl':
        '1. Assieds-toi, avant-bras sur les cuisses, paumes vers le bas, poignets dans le vide.\n'
        '2. Monte le dos des mains le plus haut possible.\n'
        '3. Redescends lentement.',
      'hack_squat':
        '1. Monte sur la plateforme, dos contre le dossier, épaules sous les coussins.\n'
        '2. Descends jusqu’à ce que les cuisses soient au moins parallèles à la plateforme.\n'
        '3. Remonte en poussant avec tout le pied.',
      'smith_squat':
        '1. Barre sur le haut du dos, pieds un peu devant la barre.\n'
        '2. Descends dos droit au moins jusqu’à la parallèle.\n'
        '3. Remonte et raccroche la barre à la fin.',
      'walking_lunge':
        '1. Haltères le long du corps, fais un grand pas en avant.\n'
        '2. Descends le genou arrière presque au sol.\n'
        '3. Pousse sur le pied avant et enchaîne directement la fente suivante.',
      'reverse_lunge':
        '1. Debout, haltères le long du corps.\n'
        '2. Recule d’un pas et descends le genou arrière presque au sol.\n'
        '3. Pousse sur le pied avant pour revenir. Alterne les jambes.',
      'step_up':
        '1. Place-toi devant un banc ou une box avec des haltères.\n'
        '2. Pose un pied dessus et monte en poussant avec cette jambe.\n'
        '3. Redescends lentement. Alterne ou fais un côté puis l’autre.',
      'split_squat':
        '1. Mets-toi en fente longue, haltères en main.\n'
        '2. Descends à la verticale jusqu’à ce que le genou arrière frôle le sol.\n'
        '3. Remonte. Termine les répétitions puis change de jambe.',
      'sumo_squat':
        '1. Pieds écartés, pointes vers l’extérieur, un haltère entre les jambes.\n'
        '2. Descends buste droit, genoux dans l’axe des pieds.\n'
        '3. Remonte en serrant les fessiers.',
      'pistol_squat':
        '1. Debout sur une jambe, l’autre tendue devant.\n'
        '2. Descends en contrôle le plus bas possible, bras devant pour l’équilibre.\n'
        '3. Remonte. Au début, tu peux te tenir à quelque chose.',
      'single_leg_press':
        '1. Assieds-toi à la presse, un pied au centre de la plateforme.\n'
        '2. Descends jusqu’à environ 90° au genou.\n'
        '3. Pousse sans verrouiller le genou. Change de jambe.',
      'hip_adduction_machine':
        '1. Assieds-toi, coussins contre l’intérieur des genoux.\n'
        '2. Serre les jambes.\n'
        '3. Rouvre-les lentement.',
      'wall_sit':
        '1. Dos contre un mur, glisse vers le bas.\n'
        '2. Arrête-toi genoux à environ 90°, pieds sous les genoux.\n'
        '3. Tiens le temps prévu, dos plaqué au mur.',
      'jump_squat':
        '1. Debout, pieds largeur d’épaules.\n'
        '2. Descends en squat et saute de façon explosive.\n'
        '3. Réceptionne en douceur et enchaîne le squat suivant.',
      'box_jump':
        '1. Place-toi devant une box stable.\n'
        '2. Lance les bras et saute sur la box, réception en douceur.\n'
        '3. Redresse-toi complètement puis redescends à pied.',
      'seated_leg_curl':
        '1. Assieds-toi dans la machine, coussin au-dessus des talons, cuisses bloquées.\n'
        '2. Ramène les talons vers le bas et l’arrière au maximum.\n'
        '3. Reviens lentement.',
      'nordic_curl':
        '1. À genoux, talons calés sous un support stable.\n'
        '2. Descends le buste vers l’avant le plus lentement possible, hanches tendues.\n'
        '3. Rattrape-toi avec les mains et remonte avec les ischios.',
      'single_leg_rdl':
        '1. Debout sur une jambe avec un haltère, genou légèrement fléchi.\n'
        '2. Penche-toi en avant, jambe libre vers l’arrière, dos droit.\n'
        '3. Redresse-toi en poussant les hanches vers l’avant.',
      'dumbbell_romanian_deadlift':
        '1. Debout, haltères devant les cuisses, genoux souples.\n'
        '2. Recule les hanches et descends les haltères le long des jambes.\n'
        '3. Arrête-toi à l’étirement des ischios et redresse-toi.',
      'stiff_leg_deadlift':
        '1. Debout avec la barre, jambes presque tendues.\n'
        '2. Penche-toi dos droit en descendant la barre le long des jambes.\n'
        '3. Redresse-toi en contractant ischios et fessiers.',
      'stability_ball_leg_curl':
        '1. Sur le dos, talons sur le ballon, bassin levé.\n'
        '2. Ramène le ballon vers toi en fléchissant les genoux.\n'
        '3. Repousse-le lentement, bassin toujours levé.',
      'sumo_deadlift':
        '1. Pieds très écartés, pointes vers l’extérieur, barre saisie entre les jambes.\n'
        '2. Gaine-toi, pousse les genoux vers l’extérieur et redresse-toi barre près du corps.\n'
        '3. Redescends-la dos droit.',
      'cable_glute_kickback':
        '1. Attache une sangle de cheville à la poulie basse et tiens-toi à la machine.\n'
        '2. Envoie la jambe vers l’arrière et le haut en serrant le fessier.\n'
        '3. Reviens lentement sans cambrer.',
      'hip_abduction_machine':
        '1. Assieds-toi, coussins contre l’extérieur des genoux.\n'
        '2. Écarte les jambes au maximum.\n'
        '3. Ramène-les lentement.',
      'machine_hip_thrust':
        '1. Haut du dos contre le dossier, ceinture sur les hanches.\n'
        '2. Monte le bassin jusqu’à l’alignement genoux-épaules.\n'
        '3. Serre les fessiers en haut et redescends lentement.',
      'single_leg_glute_bridge':
        '1. Sur le dos, un pied au sol, l’autre jambe tendue vers le haut.\n'
        '2. Monte le bassin en poussant sur le talon au sol.\n'
        '3. Redescends lentement. Termine puis change de jambe.',
      'donkey_kick':
        '1. À quatre pattes, mains sous les épaules.\n'
        '2. Monte une jambe fléchie vers l’arrière, plante du pied vers le plafond.\n'
        '3. Redescends lentement sans cambrer.',
      'fire_hydrant':
        '1. À quatre pattes, dos plat.\n'
        '2. Monte une jambe fléchie sur le côté jusqu’à hauteur de hanche.\n'
        '3. Redescends lentement, bassin stable.',
      'banded_lateral_walk':
        '1. Place une mini-bande au-dessus des genoux ou aux chevilles, genoux légèrement fléchis.\n'
        '2. Marche sur le côté en gardant l’élastique tendu.\n'
        '3. Compte les pas d’un côté puis reviens.',
      'cable_pull_through':
        '1. Dos à la poulie basse, corde entre les jambes.\n'
        '2. Penche-toi dos droit en laissant la corde partir vers l’arrière.\n'
        '3. Pousse les hanches vers l’avant pour te redresser et serre les fessiers.',
      'seated_calf_raise':
        '1. Assieds-toi, coussin sur les cuisses, avant des pieds sur la marche.\n'
        '2. Monte les talons le plus haut possible.\n'
        '3. Redescends lentement en étirement complet.',
      'single_leg_calf_raise':
        '1. Un pied sur le bord d’une marche, tiens-toi.\n'
        '2. Monte sur la pointe le plus haut possible.\n'
        '3. Descends le talon sous la marche pour l’étirement.',
      'leg_press_calf_raise':
        '1. Assieds-toi à la presse, avant des pieds sur le bord bas de la plateforme.\n'
        '2. Pousse la plateforme en tendant les pieds.\n'
        '3. Laisse revenir lentement en étirement. Genoux tendus.',
      'sit_up':
        '1. Sur le dos, genoux fléchis, pieds au sol.\n'
        '2. Enroule-toi jusqu’à la position assise.\n'
        '3. Redescends lentement.',
      'decline_sit_up':
        '1. Cale les pieds sur le banc décliné et allonge-toi.\n'
        '2. Remonte jusqu’à ce que le buste soit vertical.\n'
        '3. Redescends lentement. Tiens un disque pour plus de charge.',
      'bicycle_crunch':
        '1. Sur le dos, mains près de la tête, jambes levées.\n'
        '2. Amène un coude vers le genou opposé en tendant l’autre jambe.\n'
        '3. Alterne comme si tu pédalais.',
      'reverse_crunch':
        '1. Sur le dos, genoux à 90°, bras au sol.\n'
        '2. Décolle le bassin et ramène les genoux vers la poitrine.\n'
        '3. Redescends lentement sans élan.',
      'lying_leg_raise':
        '1. Sur le dos, jambes tendues, bas du dos plaqué au sol.\n'
        '2. Monte les jambes jusqu’à ce qu’elles pointent vers le plafond.\n'
        '3. Redescends lentement sans cambrer.',
      'captains_chair_knee_raise':
        '1. En appui sur les avant-bras, dos contre le dossier.\n'
        '2. Ramène les genoux vers la poitrine.\n'
        '3. Redescends lentement sans balancer.',
      'ab_wheel_rollout':
        '1. À genoux, tiens la roue sous les épaules.\n'
        '2. Roule vers l’avant aussi loin que possible sans creuser le bas du dos.\n'
        '3. Reviens en tirant avec les abdos.',
      'russian_twist':
        '1. Assieds-toi, buste légèrement incliné en arrière, pieds levés ou au sol.\n'
        '2. Tourne le buste et touche le sol à côté de la hanche.\n'
        '3. Tourne de l’autre côté. Tiens un poids pour plus de charge.',
      'v_up':
        '1. Sur le dos, bras au-dessus de la tête, jambes tendues.\n'
        '2. Monte bras et jambes en même temps et touche tes pieds.\n'
        '3. Redescends lentement.',
      'hollow_hold':
        '1. Sur le dos, plaque le bas du dos au sol.\n'
        '2. Décolle légèrement les épaules et les jambes tendues.\n'
        '3. Tiens le temps prévu sans cambrer.',
      'pallof_press':
        '1. De profil à une poulie à hauteur de poitrine, poignée contre la poitrine.\n'
        '2. Pousse la poignée droit devant sans laisser le corps tourner.\n'
        '3. Ramène-la à la poitrine. Fais les deux côtés.',
      'cable_woodchopper':
        '1. De profil à la poulie haute, poignée à deux mains.\n'
        '2. Tire en diagonale vers le bas à travers le corps en tournant le buste.\n'
        '3. Reviens lentement. Fais les deux côtés.',
      'plank_shoulder_tap':
        '1. En planche haute, pieds légèrement écartés.\n'
        '2. Touche l’épaule opposée d’une main sans bouger le bassin.\n'
        '3. Change de main.',
      'bird_dog':
        '1. À quatre pattes, dos plat.\n'
        '2. Tends un bras devant et la jambe opposée derrière.\n'
        '3. Tiens un instant, reviens et change de côté.',
      'power_clean':
        '1. Au-dessus de la barre, prise juste à l’extérieur des genoux, dos droit.\n'
        '2. Tire la barre de façon explosive le long du corps et réceptionne-la sur l’avant des épaules.\n'
        '3. Redresse-toi et repose la barre. Apprends la technique avec une barre légère.',
      'thruster':
        '1. Tiens la barre sur l’avant des épaules.\n'
        '2. Descends en squat puis, en remontant, pousse la barre au-dessus de la tête d’un seul mouvement.\n'
        '3. Ramène-la sur les épaules et enchaîne le squat suivant.',
      'turkish_get_up':
        '1. Sur le dos, tiens un kettlebell bras tendu vers le haut.\n'
        '2. Relève-toi étape par étape, regard sur le kettlebell, bras tendu.\n'
        '3. Reviens au sol par le même chemin. Fais les deux côtés.',
      'bear_crawl':
        '1. En appui sur mains et pieds, genoux juste au-dessus du sol, dos plat.\n'
        '2. Avance en bougeant en même temps la main et le pied opposés.\n'
        '3. Garde le bassin bas pendant le temps prévu.',
      'high_knees':
        '1. Cours sur place en montant les genoux à hauteur de hanches.\n'
        '2. Utilise les bras et reste sur l’avant des pieds.\n'
        '3. Garde un rythme rapide pendant le temps prévu.',
      'jump_rope':
        '1. Tiens les poignées à hauteur de hanches, coudes près du corps.\n'
        '2. Fais tourner la corde avec les poignets et saute juste assez haut.\n'
        '3. Réceptionne en douceur sur l’avant des pieds pendant le temps prévu.',
      'rowing_machine':
        '1. Attache tes pieds et saisis la poignée bras tendus.\n'
        '2. Pousse avec les jambes, penche-toi un peu en arrière et tire la poignée vers le bas des côtes.\n'
        '3. Reviens dans l’ordre inverse : bras, buste, jambes. Rythme régulier.',
      'stationary_bike':
        '1. Règle la selle pour que le genou reste légèrement fléchi en bas.\n'
        '2. Pédale à rythme régulier, dos droit.\n'
        '3. Règle la résistance selon ton objectif pendant le temps prévu.',
      'treadmill_run':
        '1. Commence en marchant et augmente la vitesse progressivement.\n'
        '2. Cours droit, épaules relâchées, appuis sous les hanches.\n'
        '3. Ralentis à la marche avant de descendre.',
      'elliptical':
        '1. Monte sur les pédales et saisis les poignées mobiles.\n'
        '2. Bouge de façon fluide en poussant et tirant aussi avec les bras.\n'
        '3. Garde un rythme régulier pendant le temps prévu.',
      'stair_climber':
        '1. Monte et choisis une vitesse que tu peux tenir.\n'
        '2. Grimpe droit, utilise les rampes seulement pour l’équilibre.\n'
        '3. Continue pendant le temps prévu.',
      'air_bike':
        '1. Assieds-toi et saisis les poignées mobiles.\n'
        '2. Pédale en poussant et tirant les poignées en même temps.\n'
        '3. Plus tu accélères, plus le ventilateur freine. Pendant le temps prévu.',
    },
    routineNames: {
      'home_upper': 'Haut du corps en 5 minutes',
      'home_lower': 'Bas du corps en 5 minutes',
      'home_full': 'Corps entier en 5 minutes',
    },
    programNames: {
      'full_body': 'Full body (débutant)',
      'upper_lower': 'Haut / Bas',
      'ppl': 'Push / Pull / Legs',
      'full_body_2x': 'Full body 2× par semaine',
      'dumbbell_home': 'Haltères à la maison',
      'strength_5x5': 'Force 5×5',
      'circuit': 'Circuit training (endurance)',
      'full_body_variation': 'Full body – variante',
      'bodyweight_home': 'Poids du corps à la maison',
      'machines': 'Machines (débutant)',
      'upper_lower_variation': 'Haut / Bas – variante',
      'ppl_variation': 'Push / Pull / Legs – variante',
      'strength_dup': 'Force – vagues hebdomadaires',
      'conditioning_intervals': 'Condition physique – intervalles',
      'phul': 'Force + volume (PHUL)',
      'strength_advanced': 'Force – 4 jours (avancé)',
      'ppl_6x': 'Push / Pull / Legs 6× par semaine',
    },
    programDescriptions: {
      'full_body':
        '3× par semaine, en alternant les séances A et B. Idéal pour les premiers mois.',
      'upper_lower':
        '4× par semaine : haut du corps lun. + jeu., bas du corps mar. + ven.',
      'ppl': '3× par semaine : push lun., pull mer., jambes ven.',
      'full_body_2x':
        'Pour les semaines chargées : 2 séances d’environ une heure, lun. + jeu. Chaque muscle 2× par semaine.',
      'dumbbell_home':
        '3× par semaine avec une paire d’haltères et un tapis, en alternant A et B. Sans salle.',
      'strength_5x5':
        '3× par semaine, en alternant A et B : 5 séries de 5 sur les gros exercices. Quand tu réussis toutes les séries de 5, la charge augmente.',
      'circuit':
        '3× par semaine, en alternant A et B : exercices en circuit enchaînés, pauses courtes, beaucoup de répétitions. Pour l’endurance et la forme.',
      'full_body_variation':
        '3× par semaine, en alternant C et D. Même structure que Full body (débutant) avec d’autres exercices – à alterner toutes les 6 à 8 semaines.',
      'bodyweight_home':
        '3× par semaine, en alternant A et B, sans matériel – juste un tapis (et une table solide pour les tirages). Pour débuter ou en voyage.',
      'machines':
        '3× par semaine, en alternant A et B, sur les machines de la salle : faciles à apprendre, sûres même sans partenaire. Une bonne première étape avant les poids libres.',
      'upper_lower_variation':
        '4× par semaine comme Haut / Bas, avec d’autres exercices (développé incliné, squat avant, hip thrust). À alterner toutes les 6 à 8 semaines.',
      'ppl_variation':
        '3× par semaine comme Push / Pull / Legs, avec d’autres exercices (développé militaire en premier, rowing barre, hack squat). À alterner toutes les 6 à 8 semaines.',
      'strength_dup':
        '3× par semaine : jour lourd (séries de 3), jour de volume (6 à 8 répétitions) et jour moyen (séries de 5). Varier la charge dans la semaine fait progresser la force même après la première année.',
      'conditioning_intervals':
        '3× par semaine, en alternant A et B : un exercice de force et un exercice cardio enchaînés, puis un bloc de cardio continu pour finir. Pour la forme, l’endurance et la perte de gras.',
      'phul':
        '4× par semaine : jours lourds haut et bas du corps pour la force (lun., mar.), jours avec plus de répétitions pour le muscle (jeu., ven.). Environ 12 à 16 séries par muscle et par semaine.',
      'strength_advanced':
        '4× par semaine, un grand mouvement par jour (squat, développé couché, soulevé de terre, développé militaire) : séries lourdes de 3, une variante proche et des exercices d’assistance pour les points faibles.',
      'ppl_6x':
        'Lun.–sam. : Push, Pull, Legs, puis Push B, Pull B, Jambes B. Chaque muscle 2× par semaine avec un gros volume – pour les pratiquants expérimentés qui récupèrent bien.',
    },
    planNames: {
      'Full body A': 'Full body A',
      'Full body B': 'Full body B',
      'Upper body': 'Haut du corps',
      'Lower body': 'Bas du corps',
      'Push': 'Push',
      'Pull': 'Pull',
      'Legs': 'Jambes',
      'Full body 2× A': 'Full body 2× A',
      'Full body 2× B': 'Full body 2× B',
      'Dumbbells A': 'Haltères A',
      'Dumbbells B': 'Haltères B',
      '5×5 A': '5×5 A',
      '5×5 B': '5×5 B',
      'Circuit A': 'Circuit A',
      'Circuit B': 'Circuit B',
      'Full body C': 'Full body C',
      'Full body D': 'Full body D',
      'Bodyweight A': 'Poids du corps A',
      'Bodyweight B': 'Poids du corps B',
      'Machines A': 'Machines A',
      'Machines B': 'Machines B',
      'Upper body B': 'Haut du corps B',
      'Lower body B': 'Bas du corps B',
      'Push B': 'Push B',
      'Pull B': 'Pull B',
      'Legs B': 'Jambes B',
      'Strength: heavy day': 'Force : jour lourd',
      'Strength: volume day': 'Force : jour de volume',
      'Strength: medium day': 'Force : jour moyen',
      'Intervals A': 'Intervalles A',
      'Intervals B': 'Intervalles B',
      'Upper power': 'Haut – force',
      'Lower power': 'Bas – force',
      'Upper hypertrophy': 'Haut – volume',
      'Lower hypertrophy': 'Bas – volume',
      'Strength: squat': 'Force : squat',
      'Strength: bench': 'Force : développé couché',
      'Strength: deadlift': 'Force : soulevé de terre',
      'Strength: overhead press': 'Force : développé militaire',
    },
  ),
  'pl': (
    exerciseNames: {
      'bench_press': 'Wyciskanie sztangi na ławce płaskiej',
      'incline_dumbbell_press': 'Wyciskanie hantli na ławce skośnej',
      'cable_fly': 'Rozpiętki na wyciągu',
      'push_up': 'Pompki',
      'deadlift': 'Martwy ciąg',
      'barbell_row': 'Wiosłowanie sztangą w opadzie',
      'lat_pulldown': 'Ściąganie drążka wyciągu górnego',
      'pull_up': 'Podciąganie na drążku nachwytem',
      'overhead_press': 'Wyciskanie żołnierskie',
      'lateral_raise': 'Wznosy hantli bokiem',
      'pike_push_up': 'Pompki pike',
      'dumbbell_curl': 'Uginanie ramion z hantlami',
      'triceps_pushdown': 'Prostowanie ramion na wyciągu górnym',
      'dips': 'Pompki na poręczach (dipy)',
      'back_squat': 'Przysiad ze sztangą',
      'leg_press': 'Wypychanie nogami na suwnicy',
      'romanian_deadlift': 'Martwy ciąg rumuński',
      'bodyweight_squat': 'Przysiad bez obciążenia',
      'lunge': 'Wykroki',
      'hip_thrust': 'Hip thrust',
      'glute_bridge': 'Mostek biodrowy',
      'plank': 'Plank',
      'crunch': 'Brzuszki',
      'mountain_climber': 'Mountain climbers',
      'jumping_jack': 'Pajacyki',
      'dumbbell_bench_press': 'Wyciskanie hantli na ławce płaskiej',
      'incline_bench_press': 'Wyciskanie sztangi na ławce skośnej',
      'chest_press_machine': 'Wyciskanie na maszynie (klatka)',
      'pec_deck': 'Rozpiętki na maszynie (butterfly)',
      'seated_cable_row': 'Wiosłowanie na wyciągu dolnym siedząc',
      'one_arm_dumbbell_row': 'Wiosłowanie hantlem jednorącz',
      'chin_up': 'Podciąganie podchwytem',
      'dumbbell_shoulder_press': 'Wyciskanie hantli nad głowę',
      'rear_delt_fly': 'Odwrotne rozpiętki w opadzie',
      'face_pull': 'Face pull',
      'barbell_curl': 'Uginanie ramion ze sztangą',
      'hammer_curl': 'Uginanie młotkowe',
      'cable_curl': 'Uginanie ramion na wyciągu dolnym',
      'skull_crusher': 'Wyciskanie francuskie leżąc',
      'overhead_triceps_extension': 'Wyciskanie francuskie hantlem nad głową',
      'close_grip_bench_press': 'Wyciskanie sztangi wąskim chwytem',
      'front_squat': 'Przysiad przedni',
      'goblet_squat': 'Goblet squat',
      'bulgarian_split_squat': 'Przysiad bułgarski',
      'leg_extension': 'Prostowanie nóg na maszynie',
      'leg_curl': 'Uginanie nóg na maszynie',
      'calf_raise': 'Wspięcia na palce',
      'hanging_leg_raise': 'Unoszenie nóg w zwisie',
      'cable_crunch': 'Brzuszki na wyciągu',
      'dead_bug': 'Dead bug',
      'side_plank': 'Plank bokiem',
      'burpee': 'Burpees',
      'kettlebell_swing': 'Swing kettlebell',
      'weighted_pull_up': 'Podciąganie z obciążeniem',
      'weighted_dips': 'Pompki na poręczach z obciążeniem',
      'barbell_shrug': 'Szrugsy ze sztangą',
      'dumbbell_shrug': 'Szrugsy z hantlami',
      'wrist_curl': 'Uginanie nadgarstków',
      'reverse_curl': 'Uginanie ramion nachwytem',
      'dead_hang': 'Zwis na drążku',
      'back_extension': 'Wyprosty tułowia (hiperekstensje)',
      'good_morning': 'Good morning ze sztangą',
      'superman': 'Superman',
      'decline_bench_press': 'Wyciskanie na ławce skośnej głową w dół',
      'smith_bench_press': 'Wyciskanie na ławce na maszynie Smitha',
      'dumbbell_fly': 'Rozpiętki z hantlami',
      'incline_dumbbell_fly': 'Rozpiętki na ławce skośnej',
      'low_to_high_cable_fly': 'Rozpiętki na wyciągu od dołu do góry',
      'incline_chest_press_machine': 'Wyciskanie na maszynie skośnej',
      'chest_dips': 'Pompki na poręczach na klatkę',
      'incline_push_up': 'Pompki z rękami na podwyższeniu',
      'decline_push_up': 'Pompki z nogami na podwyższeniu',
      'dumbbell_floor_press': 'Wyciskanie hantli leżąc na podłodze',
      't_bar_row': 'Wiosłowanie T-sztangą',
      'pendlay_row': 'Wiosłowanie Pendlaya',
      'machine_row': 'Wiosłowanie na maszynie siedząc',
      'chest_supported_row': 'Wiosłowanie hantlami w leżeniu na ławce skośnej',
      'close_grip_lat_pulldown': 'Ściąganie drążka wąskim chwytem',
      'straight_arm_pulldown': 'Ściąganie drążka prostymi rękami',
      'band_assisted_pull_up': 'Podciąganie z gumą',
      'inverted_row': 'Podciąganie australijskie',
      'neutral_grip_pull_up': 'Podciąganie chwytem neutralnym',
      'rack_pull': 'Martwy ciąg ze stojaków',
      'trap_bar_deadlift': 'Martwy ciąg z trap barem',
      'single_arm_cable_row': 'Wiosłowanie jednorącz na wyciągu',
      'dumbbell_pullover': 'Przenoszenie hantla za głowę (pullover)',
      'renegade_row': 'Wiosłowanie w podporze (renegade row)',
      'arnold_press': 'Wyciskanie Arnolda',
      'shoulder_press_machine': 'Wyciskanie na barki na maszynie',
      'push_press': 'Push press',
      'cable_lateral_raise': 'Unoszenie ramienia bokiem na wyciągu',
      'machine_lateral_raise': 'Unoszenie ramion bokiem na maszynie',
      'front_raise': 'Unoszenie hantli przodem',
      'upright_row': 'Wiosłowanie sztangą do brody',
      'reverse_pec_deck': 'Odwrotne rozpiętki na maszynie',
      'band_pull_apart': 'Rozciąganie gumy',
      'handstand_push_up': 'Pompki w staniu na rękach',
      'landmine_press': 'Wyciskanie landmine',
      'preacher_curl': 'Uginanie na modlitewniku',
      'concentration_curl': 'Uginanie koncentryczne',
      'incline_dumbbell_curl': 'Uginanie hantli na ławce skośnej',
      'ez_bar_curl': 'Uginanie ze sztangą łamaną',
      'rope_hammer_curl': 'Uginanie młotkowe na wyciągu z liną',
      'machine_biceps_curl': 'Uginanie ramion na maszynie',
      'band_curl': 'Uginanie ramion z gumą',
      'rope_pushdown': 'Prostowanie ramion z liną na wyciągu',
      'overhead_cable_extension': 'Prostowanie ramion nad głową na wyciągu',
      'triceps_kickback': 'Prostowanie ramienia w opadzie (kickback)',
      'bench_dips': 'Pompki w podporze tyłem o ławkę',
      'machine_triceps_dip': 'Prostowanie ramion na maszynie (dipy)',
      'single_arm_pushdown': 'Prostowanie ramienia jednorącz na wyciągu',
      'diamond_push_up': 'Pompki diamentowe',
      'reverse_wrist_curl': 'Prostowanie nadgarstków nachwytem',
      'hack_squat': 'Przysiad na maszynie hack',
      'smith_squat': 'Przysiad na maszynie Smitha',
      'walking_lunge': 'Wykroki w marszu',
      'reverse_lunge': 'Wykroki w tył',
      'step_up': 'Wejścia na ławkę',
      'split_squat': 'Przysiad w wykroku',
      'sumo_squat': 'Przysiad sumo z hantlem',
      'pistol_squat': 'Przysiad na jednej nodze (pistol)',
      'single_leg_press': 'Wypychanie nogą na suwnicy (jednonóż)',
      'hip_adduction_machine': 'Przywodzenie nóg na maszynie',
      'wall_sit': 'Krzesełko przy ścianie',
      'jump_squat': 'Przysiad z wyskokiem',
      'box_jump': 'Wskoki na skrzynię',
      'seated_leg_curl': 'Uginanie nóg siedząc na maszynie',
      'nordic_curl': 'Nordic curl (uginanie nordyckie)',
      'single_leg_rdl': 'Rumuński martwy ciąg na jednej nodze',
      'dumbbell_romanian_deadlift': 'Rumuński martwy ciąg z hantlami',
      'stiff_leg_deadlift': 'Martwy ciąg na prostych nogach',
      'stability_ball_leg_curl': 'Uginanie nóg na piłce gimnastycznej',
      'sumo_deadlift': 'Martwy ciąg sumo',
      'cable_glute_kickback': 'Odwodzenie nogi w tył na wyciągu',
      'hip_abduction_machine': 'Odwodzenie nóg na maszynie',
      'machine_hip_thrust': 'Hip thrust na maszynie',
      'single_leg_glute_bridge': 'Most biodrowy na jednej nodze',
      'donkey_kick': 'Wymachy nogą w tył w klęku (donkey kick)',
      'fire_hydrant': 'Odwodzenie nogi w bok w klęku (fire hydrant)',
      'banded_lateral_walk': 'Chód boczny z gumą',
      'cable_pull_through': 'Przeciąganie liny między nogami (pull-through)',
      'seated_calf_raise': 'Wspięcia na palce siedząc',
      'single_leg_calf_raise': 'Wspięcia na palce na jednej nodze',
      'leg_press_calf_raise': 'Wspięcia na palce na suwnicy',
      'sit_up': 'Siady z leżenia',
      'decline_sit_up': 'Siady na ławce skośnej',
      'bicycle_crunch': 'Brzuszki rowerowe',
      'reverse_crunch': 'Odwrotne brzuszki',
      'lying_leg_raise': 'Unoszenie nóg w leżeniu',
      'captains_chair_knee_raise': 'Unoszenie kolan w podporze na poręczach',
      'ab_wheel_rollout': 'Kółko do ćwiczeń brzucha',
      'russian_twist': 'Russian twist (skręty rosyjskie)',
      'v_up': 'Scyzoryk (V-up)',
      'hollow_hold': 'Hollow hold (łódka)',
      'pallof_press': 'Pallof press',
      'cable_woodchopper': 'Drwal na wyciągu',
      'plank_shoulder_tap': 'Deska z dotykaniem barków',
      'bird_dog': 'Bird dog (unoszenie ręki i nogi w klęku)',
      'power_clean': 'Zarzut siłowy (power clean)',
      'thruster': 'Thruster (przysiad z wyciskaniem)',
      'turkish_get_up': 'Tureckie wstawanie',
      'bear_crawl': 'Chód niedźwiedzia',
      'high_knees': 'Skip A (wysokie kolana)',
      'jump_rope': 'Skakanka',
      'rowing_machine': 'Ergometr wioślarski',
      'stationary_bike': 'Rower stacjonarny',
      'treadmill_run': 'Bieg na bieżni',
      'elliptical': 'Orbitrek',
      'stair_climber': 'Stepper schodowy',
      'air_bike': 'Rower powietrzny (air bike)',
    },
    exerciseInstructions: {
      'bench_press':
        '1. Połóż się na ławce, oczy pod sztangą, stopy płasko na podłodze.\n'
        '2. Chwyć sztangę nieco szerzej niż barki, ściągnij łopatki.\n'
        '3. Opuszczaj sztangę pod kontrolą na środek klatki, łokcie ok. 45° od tułowia.\n'
        '4. Wypchnij do wyprostu ramion, nie odrywając bioder.',
      'incline_dumbbell_press':
        '1. Ustaw ławkę na 30–45°, hantle na wysokości klatki.\n'
        '2. Trzymaj łopatki ściągnięte, a stopy na podłodze.\n'
        '3. Wypchnij hantle w górę i lekko do siebie, potem powoli opuść do wysokości klatki.',
      'cable_fly':
        '1. Stań między wyciągami, łokcie lekko ugięte.\n'
        '2. Złącz uchwyty łukiem przed klatką.\n'
        '3. Wracaj powoli do odczucia rozciągnięcia, łokcie trzymaj w stałym ugięciu.',
      'push_up':
        '1. Dłonie nieco szerzej niż barki, ciało w linii prostej.\n'
        '2. Opuść klatkę blisko podłogi, łokcie ok. 45° od tułowia.\n'
        '3. Wypchnij się w górę, trzymaj napięty brzuch i pośladki.',
      'deadlift':
        '1. Sztanga nad środkiem stopy, stopy na szerokość bioder.\n'
        '2. Zegnij się w biodrach, chwyć sztangę, plecy w neutralnej pozycji.\n'
        '3. Odepchnij podłogę i wstań, prowadząc sztangę blisko nóg.\n'
        '4. Opuść pod kontrolą, cofając biodra.',
      'barbell_row':
        '1. Pochyl się do ok. 45°, plecy proste, kolana lekko ugięte.\n'
        '2. Przyciągnij sztangę do dolnej części klatki lub brzucha.\n'
        '3. Ściągnij łopatki, potem powoli opuść.',
      'lat_pulldown':
        '1. Chwyt nieco szerszy niż barki, uda pod wałkami.\n'
        '2. Ściągnij drążek do górnej części klatki, łokcie w dół i do tyłu.\n'
        '3. Wracaj powoli do wyprostu ramion, bez bujania.',
      'pull_up':
        '1. Zawiśnij na drążku nachwytem, barki aktywne.\n'
        '2. Podciągnij się, aż broda znajdzie się nad drążkiem.\n'
        '3. Opuść się pod kontrolą do pełnego zwisu.',
      'overhead_press':
        '1. Sztanga na przedniej części barków, chwyt tuż szerzej niż barki.\n'
        '2. Napnij pośladki i brzuch, wyciśnij sztangę prosto w górę.\n'
        '3. Gdy sztanga mija głowę, lekko cofnij głowę, zablokuj ramiona nad głową.',
      'lateral_raise':
        '1. Stań prosto, hantle wzdłuż ciała, łokcie lekko ugięte.\n'
        '2. Unieś ramiona bokiem do wysokości barków.\n'
        '3. Opuszczaj powoli, nie bujaj się.',
      'pike_push_up':
        '1. Zacznij w pozycji do pompki i unieś biodra w odwrócone V.\n'
        '2. Opuść głowę w stronę podłogi między dłońmi.\n'
        '3. Wypchnij się z powrotem siłą barków.',
      'dumbbell_curl':
        '1. Stań prosto, łokcie przy bokach.\n'
        '2. Unieś hantle, uginając ramiona, bez ruszania łokciami.\n'
        '3. Opuszczaj powoli do wyprostu ramion.',
      'triceps_pushdown':
        '1. Stań przy wyciągu, łokcie przyklejone do boków.\n'
        '2. Wypchnij uchwyt w dół do wyprostu ramion.\n'
        '3. Wracaj powoli, łokcie trzymaj nieruchomo.',
      'dips':
        '1. Oprzyj się na poręczach na wyprostowanych ramionach.\n'
        '2. Opuść się, aż ramiona będą mniej więcej równoległe do podłogi.\n'
        '3. Wypchnij się w górę, nie wysuwaj barków do przodu.',
      'back_squat':
        '1. Sztanga na górnej części pleców, stopy na szerokość barków, palce lekko na zewnątrz.\n'
        '2. Napnij brzuch i usiądź między pięty.\n'
        '3. Kolana idą za palcami, plecy w neutralnej pozycji.\n'
        '4. Wstań, wypychając całą stopą.',
      'leg_press':
        '1. Stopy na szerokość barków na środku platformy.\n'
        '2. Opuść, aż kolana będą ugięte do ok. 90°, dolny odcinek pleców zostaje na oparciu.\n'
        '3. Wypchnij bez mocnego blokowania kolan.',
      'romanian_deadlift':
        '1. Stań ze sztangą, kolana lekko ugięte.\n'
        '2. Cofnij biodra i opuszczaj sztangę wzdłuż nóg.\n'
        '3. Zatrzymaj się, gdy poczujesz rozciąganie tyłu ud, plecy proste.\n'
        '4. Wróć, wypychając biodra do przodu.',
      'bodyweight_squat':
        '1. Stopy na szerokość barków, ręce przed sobą dla równowagi.\n'
        '2. Zejdź jak najniżej z prostymi plecami.\n'
        '3. Wstań, wypychając piętami.',
      'lunge':
        '1. Zrób krok do przodu i opuść się, aż oba kolana będą ugięte do ok. 90°.\n'
        '2. Przednie kolano nad stopą, tułów wyprostowany.\n'
        '3. Odepchnij się do pozycji wyjściowej i zmień nogę.',
      'hip_thrust':
        '1. Górna część pleców na ławce, sztanga na biodrach.\n'
        '2. Wypychaj piętami i unieś biodra, aż ciało będzie w linii prostej.\n'
        '3. Na górze mocno napnij pośladki, opuść pod kontrolą.',
      'glute_bridge':
        '1. Połóż się na plecach, kolana ugięte, stopy na podłodze.\n'
        '2. Unieś biodra, napinając pośladki.\n'
        '3. Zatrzymaj się chwilę na górze i powoli opuść.',
      'plank':
        '1. Przedramiona pod barkami, ciało w linii prostej.\n'
        '2. Napnij brzuch i pośladki, nie pozwól biodrom opaść.\n'
        '3. Oddychaj spokojnie i wytrzymaj.',
      'crunch':
        '1. Połóż się na plecach, kolana ugięte, dłonie przy głowie.\n'
        '2. Unieś barki od podłogi siłą mięśni brzucha.\n'
        '3. Opuszczaj powoli, nie ciągnij za szyję.',
      'mountain_climber':
        '1. Zacznij w pozycji do pompki.\n'
        '2. Na zmianę przyciągaj kolana do klatki.\n'
        '3. Trzymaj biodra nisko i równe tempo.',
      'jumping_jack':
        '1. Stań ze złączonymi stopami, ręce wzdłuż ciała.\n'
        '2. W wyskoku rozstaw stopy i unieś ręce nad głowę.\n'
        '3. Wróć wyskokiem i powtarzaj w równym tempie.',
      'dumbbell_bench_press':
        '1. Połóż się na ławce płaskiej z hantlami na wysokości klatki.\n'
        '2. Wypchnij hantle w górę i lekko do siebie.\n'
        '3. Opuszczaj powoli, aż poczujesz rozciągnięcie klatki.',
      'incline_bench_press':
        '1. Ławka na 30–45°, chwyt nieco szerszy niż barki.\n'
        '2. Opuść sztangę do górnej części klatki.\n'
        '3. Wypchnij w górę, łopatki trzymaj ściągnięte.',
      'chest_press_machine':
        '1. Ustaw siedzisko tak, by uchwyty były na wysokości środka klatki.\n'
        '2. Wypchnij do przodu prawie do wyprostu ramion.\n'
        '3. Wracaj powoli, plecy trzymaj na oparciu.',
      'pec_deck':
        '1. Usiądź z plecami na oparciu, łokcie lekko ugięte.\n'
        '2. Złącz uchwyty przed klatką.\n'
        '3. Wracaj powoli do komfortowego rozciągnięcia.',
      'seated_cable_row':
        '1. Usiądź prosto, stopy na platformie, kolana lekko ugięte.\n'
        '2. Przyciągnij uchwyt do brzucha, łokcie blisko tułowia.\n'
        '3. Ściągnij łopatki, wracaj powoli bez zaokrąglania pleców.',
      'one_arm_dumbbell_row':
        '1. Jedno kolano i dłoń na ławce, plecy płasko.\n'
        '2. Przyciągnij hantel w stronę biodra.\n'
        '3. Opuszczaj powoli do pełnego rozciągnięcia.',
      'chin_up':
        '1. Zawiśnij na drążku podchwytem na szerokość barków.\n'
        '2. Podciągnij się, aż broda znajdzie się nad drążkiem.\n'
        '3. Opuść się pod kontrolą do pełnego zwisu.',
      'dumbbell_shoulder_press':
        '1. Usiądź lub stań, hantle na wysokości barków.\n'
        '2. Wyciśnij nad głowę bez wyginania dolnego odcinka pleców.\n'
        '3. Opuszczaj powoli z powrotem do barków.',
      'rear_delt_fly':
        '1. Pochyl się z prostymi plecami, hantle zwisają w dół.\n'
        '2. Unieś ramiona bokiem z lekko ugiętymi łokciami.\n'
        '3. Opuszczaj powoli, bez zamachu.',
      'face_pull':
        '1. Lina na wysokości głowy, trzymaj ją kciukami do siebie.\n'
        '2. Przyciągnij w stronę twarzy, łokcie wysoko i szeroko.\n'
        '3. Napnij górę pleców, wracaj powoli.',
      'barbell_curl':
        '1. Stań prosto, chwyt podchwytem na szerokość barków.\n'
        '2. Unieś sztangę, uginając ramiona, bez bujania tułowiem.\n'
        '3. Opuszczaj powoli do wyprostu ramion.',
      'hammer_curl':
        '1. Trzymaj hantle chwytem neutralnym (dłonie do siebie).\n'
        '2. Uginaj ramiona, łokcie zostają przy bokach.\n'
        '3. Opuszczaj powoli.',
      'cable_curl':
        '1. Stań przodem do wyciągu dolnego, łokcie przy bokach.\n'
        '2. Uginając ramiona, przyciągnij uchwyt do barków.\n'
        '3. Opuszczaj powoli, utrzymuj stałe napięcie.',
      'skull_crusher':
        '1. Połóż się na ławce, sztanga nad klatką na wyprostowanych ramionach.\n'
        '2. Uginaj tylko łokcie i opuszczaj sztangę w stronę czoła.\n'
        '3. Wyprostuj ramiona, łokcie skierowane w górę.',
      'overhead_triceps_extension':
        '1. Trzymaj jeden hantel nad głową obiema rękami.\n'
        '2. Opuść go za głowę, uginając łokcie.\n'
        '3. Wyprostuj ramiona, łokcie trzymaj blisko głowy.',
      'close_grip_bench_press':
        '1. Połóż się na ławce, chwyt mniej więcej na szerokość barków.\n'
        '2. Opuść sztangę do dolnej części klatki, łokcie blisko tułowia.\n'
        '3. Wypchnij w górę, prostując łokcie.',
      'front_squat':
        '1. Sztanga na przedniej części barków, łokcie wysoko.\n'
        '2. Zejdź do przysiadu z wyprostowanym tułowiem.\n'
        '3. Wypchnij się w górę, łokcie cały czas wysoko.',
      'goblet_squat':
        '1. Trzymaj kettlebell lub hantel przy klatce.\n'
        '2. Zejdź do przysiadu między kolana z prostymi plecami.\n'
        '3. Wstań, wypychając piętami.',
      'bulgarian_split_squat':
        '1. Tylna stopa na ławce, przednia stopa krok przed nią.\n'
        '2. Opuść się, aż przednie udo będzie mniej więcej równoległe do podłogi.\n'
        '3. Wypchnij się przednią stopą, potem zmień nogę.',
      'leg_extension':
        '1. Ustaw wałek tuż nad kostkami.\n'
        '2. Wyprostuj nogi.\n'
        '3. Opuszczaj powoli i pod kontrolą.',
      'leg_curl':
        '1. Ustaw wałek tuż nad piętami.\n'
        '2. Przyciągnij pięty w stronę pośladków.\n'
        '3. Wracaj powoli, nie pozwól ciężarowi opaść.',
      'calf_raise':
        '1. Przednia część stopy na krawędzi, pięty wolne.\n'
        '2. Wespnij się jak najwyżej na palce.\n'
        '3. Opuszczaj powoli do rozciągnięcia.',
      'hanging_leg_raise':
        '1. Zawiśnij na drążku, barki aktywne.\n'
        '2. Unieś nogi lub kolana siłą mięśni brzucha, bez bujania.\n'
        '3. Opuszczaj powoli.',
      'cable_crunch':
        '1. Uklęknij przodem do wyciągu, lina przy głowie.\n'
        '2. Zrób skłon, zaokrąglając kręgosłup, biodra nieruchomo.\n'
        '3. Wracaj powoli.',
      'dead_bug':
        '1. Połóż się na plecach, ręce w górę, kolana ugięte pod kątem 90°.\n'
        '2. Opuść przeciwną rękę i nogę, dolny odcinek pleców zostaje na podłodze.\n'
        '3. Wróć i zmień stronę.',
      'side_plank':
        '1. Połóż się na boku, łokieć pod barkiem.\n'
        '2. Unieś biodra, aby ciało tworzyło linię prostą.\n'
        '3. Wytrzymaj, potem zmień stronę.',
      'burpee':
        '1. Ze stania zrób przysiad i połóż dłonie na podłodze.\n'
        '2. Wyrzuć nogi do tyłu do pozycji plank, opcjonalnie zrób pompkę.\n'
        '3. Przyskocz stopami do przodu i wyskocz w górę.',
      'kettlebell_swing':
        '1. Kettlebell przed tobą, stopy nieco szerzej niż biodra.\n'
        '2. Przenieś go do tyłu między nogami, zginając się w biodrach.\n'
        '3. Dynamicznie wypchnij biodra do przodu, by wymachnąć go do wysokości klatki, ręce rozluźnione.',
      'weighted_pull_up':
        '1. Przypnij talerz do pasa z łańcuchem albo ściśnij hantlę między stopami.\n'
        '2. Zawiśnij na drążku nachwytem, barki aktywne.\n'
        '3. Podciągnij się bez bujania, aż broda znajdzie się nad drążkiem.\n'
        '4. Opuść się pod kontrolą do pełnego zwisu. Zapisuj tylko dodatkowy ciężar.',
      'weighted_dips':
        '1. Przypnij talerz do pasa z łańcuchem albo ściśnij hantlę między stopami.\n'
        '2. Oprzyj się na poręczach na wyprostowanych ramionach.\n'
        '3. Opuść się, aż ramiona będą mniej więcej równoległe do podłogi.\n'
        '4. Wypchnij się w górę, nie wysuwaj barków do przodu. Zapisuj tylko dodatkowy ciężar.',
      'barbell_shrug':
        '1. Stań prosto, trzymaj sztangę w wyprostowanych rękach, chwyt na szerokość barków.\n'
        '2. Unieś barki pionowo w stronę uszu, ręce pozostają proste.\n'
        '3. Zatrzymaj się na górze i powoli opuść. Nie kręć barkami.',
      'dumbbell_shrug':
        '1. Stań z hantlami wzdłuż ciała, dłonie skierowane do siebie.\n'
        '2. Unieś barki pionowo jak najwyżej.\n'
        '3. Zatrzymaj na chwilę i powoli opuść.',
      'wrist_curl':
        '1. Usiądź, oprzyj przedramiona na udach lub ławce dłońmi do góry, nadgarstki poza krawędzią.\n'
        '2. Pozwól hantlom stoczyć się do czubków palców.\n'
        '3. Unieś nadgarstki jak najwyżej, przedramiona się nie ruszają.',
      'reverse_curl':
        '1. Stań i trzymaj sztangę nachwytem na szerokość barków.\n'
        '2. Uginaj ramiona, łokcie przy bokach, nadgarstki proste.\n'
        '3. Powoli opuść do wyprostowanych rąk.',
      'dead_hang':
        '1. Chwyć drążek nachwytem na szerokość barków.\n'
        '2. Wiś na prostych rękach, stopy nad ziemią, ciało nieruchomo.\n'
        '3. Wytrzymaj zadany czas, barki lekko aktywne.',
      'back_extension':
        '1. Ustaw poduszkę tuż pod biodrami i zablokuj pięty.\n'
        '2. Opuść tułów z prostymi plecami, aż poczujesz rozciąganie z tyłu ud.\n'
        '3. Unieś się do linii z nogami, nie przeprostowuj. Dla większego obciążenia trzymaj talerz.',
      'good_morning':
        '1. Sztanga na górze pleców jak przy przysiadzie, stopy na szerokość bioder, kolana lekko ugięte.\n'
        '2. Cofnij biodra i pochyl się z prostymi plecami, aż tułów będzie prawie poziomo.\n'
        '3. Wypchnij biodra do przodu i wróć do pionu. Zacznij od małego ciężaru.',
      'superman':
        '1. Połóż się na brzuchu, ręce wyciągnięte przed siebie.\n'
        '2. Jednocześnie unieś ręce, klatkę piersiową i nogi nad podłogę.\n'
        '3. Zatrzymaj sekundę na górze i powoli opuść.',
      'decline_bench_press':
        '1. Zablokuj nogi na ławce skośnej ujemnej, chwyt nieco szerszy niż barki.\n'
        '2. Opuść sztangę pod kontrolą do dolnej części klatki.\n'
        '3. Wyciśnij do wyprostowanych rąk, łopatki ściągnięte.',
      'smith_bench_press':
        '1. Ustaw ławkę tak, by sztanga była nad środkiem klatki.\n'
        '2. Odblokuj sztangę i opuść ją pod kontrolą do klatki.\n'
        '3. Wyciśnij bez gwałtownego blokowania łokci i na końcu zaczep sztangę.',
      'dumbbell_fly':
        '1. Połóż się na ławce płaskiej, hantle nad klatką, łokcie lekko ugięte.\n'
        '2. Rozłóż ręce szerokim łukiem, aż poczujesz rozciąganie klatki.\n'
        '3. Zbliż hantle z powrotem, nie zmieniając kąta w łokciach.',
      'incline_dumbbell_fly':
        '1. Ustaw ławkę na 30°, hantle nad klatką, łokcie miękkie.\n'
        '2. Opuszczaj je szerokim łukiem, aż poczujesz rozciąganie górnej części klatki.\n'
        '3. Zbliż je z powrotem nad klatką.',
      'low_to_high_cable_fly':
        '1. Ustaw oba wyciągi nisko i stań między nimi w lekkim pochyleniu.\n'
        '2. Prowadź uchwyty w górę i do siebie przed górną częścią klatki.\n'
        '3. Powoli wróć do rozciągnięcia, łokcie lekko ugięte.',
      'incline_chest_press_machine':
        '1. Ustaw siedzisko tak, by uchwyty były na wysokości górnej części klatki.\n'
        '2. Wypychaj uchwyty do przodu i w górę do prawie prostych rąk.\n'
        '3. Powoli wróć, aż poczujesz rozciąganie klatki.',
      'chest_dips':
        '1. Oprzyj się na poręczach i pochyl tułów do przodu.\n'
        '2. Opuszczaj się z łokciami lekko na zewnątrz, aż poczujesz rozciąganie klatki.\n'
        '3. Wypchnij się w górę, utrzymując pochylenie.',
      'incline_push_up':
        '1. Oprzyj dłonie o ławkę lub skrzynię, ciało w jednej linii.\n'
        '2. Opuść klatkę do krawędzi, łokcie ok. 45° od ciała.\n'
        '3. Wypchnij się. Im wyższe podparcie, tym łatwiej.',
      'decline_push_up':
        '1. Stopy na ławce, dłonie na podłodze pod barkami.\n'
        '2. Opuść klatkę do podłogi z napiętym brzuchem.\n'
        '3. Wypchnij się, biodra nie opadają.',
      'dumbbell_floor_press':
        '1. Połóż się na podłodze, kolana ugięte, hantle nad klatką.\n'
        '2. Opuszczaj, aż ramiona dotkną podłogi, krótka pauza.\n'
        '3. Wyciśnij do wyprostowanych rąk.',
      't_bar_row':
        '1. Stań nad sztangą, pochyl się z prostymi plecami i chwyć uchwyt.\n'
        '2. Przyciągnij ciężar do klatki, ściągając łopatki.\n'
        '3. Opuść pod kontrolą, nie zaokrąglaj pleców.',
      'pendlay_row':
        '1. Sztanga na podłodze, tułów prawie poziomo, plecy proste.\n'
        '2. Dynamicznie przyciągnij sztangę do dolnej części klatki.\n'
        '3. Po każdym powtórzeniu odłóż ją na podłogę i ustaw pozycję.',
      'machine_row':
        '1. Usiądź klatką przy oparciu i chwyć uchwyty.\n'
        '2. Przyciągnij uchwyty do ciała, łokcie blisko, łopatki razem.\n'
        '3. Powoli wróć do wyprostowanych rąk.',
      'chest_supported_row':
        '1. Połóż się na brzuchu na ławce ustawionej na 30–45°, hantle zwisają.\n'
        '2. Przyciągnij je do boków, ściągając łopatki.\n'
        '3. Powoli opuść do pełnego rozciągnięcia.',
      'close_grip_lat_pulldown':
        '1. Usiądź przy wyciągu z wąskim uchwytem lub V, uda pod wałkami.\n'
        '2. Ściągnij uchwyt do górnej części klatki, łokcie w dół i do tyłu.\n'
        '3. Powoli puść go w górę do wyprostowanych rąk.',
      'straight_arm_pulldown':
        '1. Stań przodem do górnego wyciągu, ręce prawie proste, lekki skłon.\n'
        '2. Ściągnij drążek łukiem do ud, pracując mięśniami najszerszymi.\n'
        '3. Powoli wróć, łokcie prawie proste.',
      'band_assisted_pull_up':
        '1. Przełóż gumę oporową przez drążek i oprzyj w niej stopę lub kolano.\n'
        '2. Podciągnij się, aż broda znajdzie się nad drążkiem.\n'
        '3. Opuść się pod kontrolą do zwisu. Cieńsza guma = mniejsza pomoc.',
      'inverted_row':
        '1. Zawiśnij pod niskim drążkiem lub na kółkach, ciało proste, pięty na podłodze.\n'
        '2. Przyciągnij klatkę do drążka, ściągając łopatki.\n'
        '3. Opuść się pod kontrolą. Im bardziej pionowo, tym łatwiej.',
      'neutral_grip_pull_up':
        '1. Zawiśnij na równoległych uchwytach, dłonie do siebie.\n'
        '2. Podciągnij się, aż broda znajdzie się nad uchwytami.\n'
        '3. Opuść się pod kontrolą do pełnego zwisu.',
      'rack_pull':
        '1. Połóż sztangę na zabezpieczeniach tuż pod lub nad kolanami.\n'
        '2. Chwyć ją, napnij brzuch i wstań, pchając biodra do przodu.\n'
        '3. Odłóż ją na zabezpieczenia z prostymi plecami.',
      'trap_bar_deadlift':
        '1. Stań w środku trap bara, stopy na szerokość bioder, chwyć uchwyty.\n'
        '2. Napnij się, odepchnij podłogę i wyprostuj się.\n'
        '3. Opuść sztangę z prostymi plecami.',
      'single_arm_cable_row':
        '1. Chwyć pojedynczy uchwyt na wyciągu na wysokości pasa, ręka prosta.\n'
        '2. Przyciągnij go do boku, łokieć blisko ciała.\n'
        '3. Powoli wróć, pozwalając barkowi lekko wysunąć się do przodu.',
      'dumbbell_pullover':
        '1. Połóż się na ławce i trzymaj jeden hantel oburącz nad klatką.\n'
        '2. Opuść go łukiem za głowę, łokcie lekko ugięte.\n'
        '3. Przenieś go z powrotem nad klatkę.',
      'renegade_row':
        '1. Przyjmij pozycję pompki na dwóch hantlach, stopy szeroko.\n'
        '2. Przyciągnij jeden hantel do biodra, nie skręcając bioder.\n'
        '3. Odłóż go i powtórz drugą ręką.',
      'arnold_press':
        '1. Usiądź, hantle przed barkami, dłonie skierowane do siebie.\n'
        '2. Wyciskaj w górę, obracając dłonie do przodu.\n'
        '3. Opuszczaj, wracając do pozycji wyjściowej.',
      'shoulder_press_machine':
        '1. Ustaw siedzisko tak, by uchwyty zaczynały się na wysokości barków.\n'
        '2. Wyciskaj do prawie prostych rąk.\n'
        '3. Powoli wróć do wysokości barków.',
      'push_press':
        '1. Sztanga z przodu na barkach, stopy na szerokość bioder.\n'
        '2. Lekko ugnij kolana i siłą nóg wypchnij sztangę nad głowę.\n'
        '3. Opuść ją pod kontrolą na barki.',
      'cable_lateral_raise':
        '1. Stań bokiem do dolnego wyciągu, uchwyt w dalszej ręce.\n'
        '2. Unieś rękę w bok do wysokości barku.\n'
        '3. Powoli opuść, utrzymując napięcie linki.',
      'machine_lateral_raise':
        '1. Usiądź, poduszki przylegają do zewnętrznej strony ramion.\n'
        '2. Unieś ręce do wysokości barków.\n'
        '3. Powoli opuść, nie odkładając ciężaru.',
      'front_raise':
        '1. Stań z hantlami przed udami.\n'
        '2. Unieś je przed siebie do wysokości barków, ręce prawie proste.\n'
        '3. Powoli opuść bez bujania.',
      'upright_row':
        '1. Trzymaj sztangę przed udami, chwyt mniej więcej na szerokość barków.\n'
        '2. Ciągnij ją wzdłuż ciała do wysokości klatki, prowadzą łokcie.\n'
        '3. Powoli opuść. Jeśli barki bolą, nie ciągnij tak wysoko.',
      'reverse_pec_deck':
        '1. Usiądź przodem do maszyny, klatka na oparciu, chwyć uchwyty.\n'
        '2. Rozłóż ręce łukiem do tyłu do linii ciała.\n'
        '3. Powoli wróć.',
      'band_pull_apart':
        '1. Trzymaj gumę przed sobą na wysokości barków, ręce proste.\n'
        '2. Rozciągnij ją do klatki, ściągając łopatki.\n'
        '3. Powoli wróć.',
      'handstand_push_up':
        '1. Wejdź wymachem do stania na rękach przy ścianie, dłonie na szerokość barków.\n'
        '2. Opuszczaj głowę pod kontrolą do podłogi.\n'
        '3. Wypchnij się do prostych rąk. Połóż matę pod głowę.',
      'landmine_press':
        '1. Trzymaj koniec sztangi landmine przy barku, nogi w lekkim wykroku.\n'
        '2. Wypchnij ją w górę i do przodu do prostej ręki.\n'
        '3. Wróć pod kontrolą do barku.',
      'preacher_curl':
        '1. Usiądź przy modlitewniku, ramiona płasko na oparciu, sztanga łamana w dłoniach.\n'
        '2. Ugnij ręce, nie odrywając łokci od oparcia.\n'
        '3. Powoli opuść prawie do wyprostu.',
      'concentration_curl':
        '1. Usiądź na ławce, łokieć oparty o wewnętrzną stronę uda.\n'
        '2. Unieś hantel do barku.\n'
        '3. Powoli opuść do pełnego rozciągnięcia.',
      'incline_dumbbell_curl':
        '1. Oprzyj się o ławkę ustawioną na 45–60°, ręce zwisają w dół.\n'
        '2. Unieś hantle, ramiona się nie ruszają.\n'
        '3. Powoli opuść do pełnego rozciągnięcia.',
      'ez_bar_curl':
        '1. Stań i trzymaj sztangę łamaną za wygięte miejsca, ręce proste.\n'
        '2. Unieś ją bez bujania ciałem.\n'
        '3. Powoli opuść do prostych rąk.',
      'rope_hammer_curl':
        '1. Przypnij linę do dolnego wyciągu, dłonie do siebie.\n'
        '2. Unieś linę, łokcie przy bokach.\n'
        '3. Powoli opuść, utrzymując napięcie.',
      'machine_biceps_curl':
        '1. Usiądź, oprzyj ramiona o poduszkę i chwyć uchwyty.\n'
        '2. Unieś uchwyty do barków.\n'
        '3. Powoli opuść prawie do wyprostu.',
      'band_curl':
        '1. Stań na środku gumy, końce trzymaj w dłoniach.\n'
        '2. Unieś dłonie do barków, łokcie przy bokach.\n'
        '3. Powoli opuść.',
      'rope_pushdown':
        '1. Chwyć linę na górnym wyciągu, łokcie przy bokach.\n'
        '2. Ściągnij linę w dół i na dole rozciągnij końce na boki.\n'
        '3. Powoli puść ją w górę do ok. 90° w łokciu.',
      'overhead_cable_extension':
        '1. Stań tyłem do wyciągu, lina za głową, łokcie w górze.\n'
        '2. Wyprostuj ręce do przodu i w górę.\n'
        '3. Powoli ugnij łokcie z powrotem za głowę.',
      'triceps_kickback':
        '1. Pochyl się, ramię równolegle do tułowia, łokieć ugięty.\n'
        '2. Wyprostuj rękę do tyłu.\n'
        '3. Powoli ugnij z powrotem, ramię się nie rusza.',
      'bench_dips':
        '1. Oprzyj dłonie o krawędź ławki za sobą, nogi wyprostowane do przodu.\n'
        '2. Ugnij łokcie do ok. 90° i opuść się.\n'
        '3. Wypchnij się do prostych rąk.',
      'machine_triceps_dip':
        '1. Usiądź w maszynie i chwyć boczne uchwyty.\n'
        '2. Wypchnij uchwyty w dół do prostych rąk.\n'
        '3. Powoli puść je w górę do ok. 90° w łokciu.',
      'single_arm_pushdown':
        '1. Chwyć pojedynczy uchwyt na górnym wyciągu, łokieć przy boku.\n'
        '2. Wypchnij go w dół do prostej ręki.\n'
        '3. Powoli puść w górę, łokieć zostaje w miejscu.',
      'diamond_push_up':
        '1. Pozycja pompki, dłonie razem pod klatką, palce tworzą romb.\n'
        '2. Opuść klatkę do dłoni, łokcie blisko ciała.\n'
        '3. Wypchnij się z prostym ciałem.',
      'reverse_wrist_curl':
        '1. Usiądź, przedramiona na udach dłońmi w dół, nadgarstki za kolanami.\n'
        '2. Unieś grzbiety dłoni jak najwyżej.\n'
        '3. Powoli opuść.',
      'hack_squat':
        '1. Stań na platformie, plecy na oparciu, barki pod poduszkami.\n'
        '2. Zejdź, aż uda będą co najmniej równoległe do platformy.\n'
        '3. Wypchnij się całą stopą.',
      'smith_squat':
        '1. Sztanga na górnej części pleców, stopy lekko przed sztangą.\n'
        '2. Zejdź z prostymi plecami co najmniej do równoległości ud.\n'
        '3. Wstań i na końcu zaczep sztangę.',
      'walking_lunge':
        '1. Trzymaj hantle wzdłuż ciała i zrób długi krok do przodu.\n'
        '2. Opuść tylne kolano prawie do podłogi.\n'
        '3. Odepchnij się przednią nogą i od razu przejdź do kolejnego wykroku.',
      'reverse_lunge':
        '1. Stań prosto z hantlami wzdłuż ciała.\n'
        '2. Zrób krok w tył i opuść tylne kolano prawie do podłogi.\n'
        '3. Wróć, odpychając się przednią nogą. Zmieniaj nogi.',
      'step_up':
        '1. Stań przed ławką lub skrzynią z hantlami w dłoniach.\n'
        '2. Postaw jedną stopę na górze i wejdź, pchając tą nogą.\n'
        '3. Powoli zejdź. Zmieniaj nogi lub ćwicz jedną stronę po drugiej.',
      'split_squat':
        '1. Ustaw się w długim wykroku z hantlami w dłoniach.\n'
        '2. Opuszczaj się pionowo, aż tylne kolano prawie dotknie podłogi.\n'
        '3. Wypchnij się. Skończ powtórzenia i zmień nogę.',
      'sumo_squat':
        '1. Szeroki rozkrok, palce na zewnątrz, jeden hantel między nogami.\n'
        '2. Zejdź z wyprostowanym tułowiem, kolana w kierunku palców.\n'
        '3. Wstań i napnij pośladki.',
      'pistol_squat':
        '1. Stań na jednej nodze, drugą wyprostuj przed sobą.\n'
        '2. Zejdź pod kontrolą jak najniżej, ręce z przodu dla równowagi.\n'
        '3. Wstań. Na początku możesz się czegoś przytrzymać.',
      'single_leg_press':
        '1. Usiądź na suwnicy, jedną stopę postaw na środku platformy.\n'
        '2. Opuszczaj platformę, aż kolano będzie ugięte ok. 90°.\n'
        '3. Wypchnij bez blokowania kolana. Zmień nogę.',
      'hip_adduction_machine':
        '1. Usiądź w maszynie, poduszki po wewnętrznej stronie kolan.\n'
        '2. Ściśnij nogi do siebie.\n'
        '3. Powoli je rozsuń.',
      'wall_sit':
        '1. Oprzyj się plecami o ścianę i zsuń się w dół.\n'
        '2. Zatrzymaj się, gdy kolana są ugięte ok. 90°, stopy pod kolanami.\n'
        '3. Wytrzymaj zadany czas, plecy przy ścianie.',
      'jump_squat':
        '1. Stań, stopy na szerokość barków.\n'
        '2. Zrób przysiad i dynamicznie wyskocz.\n'
        '3. Wyląduj miękko i od razu przejdź do kolejnego przysiadu.',
      'box_jump':
        '1. Stań przed stabilną skrzynią.\n'
        '2. Machnij rękami i wskocz na skrzynię, lądując miękko.\n'
        '3. Wyprostuj się i zejdź.',
      'seated_leg_curl':
        '1. Usiądź w maszynie, wałek nad piętami, uda zablokowane.\n'
        '2. Przyciągnij pięty jak najdalej w dół i do tyłu.\n'
        '3. Powoli wróć.',
      'nordic_curl':
        '1. Uklęknij z piętami zablokowanymi pod czymś stabilnym.\n'
        '2. Jak najwolniej opadaj tułowiem do przodu, biodra wyprostowane.\n'
        '3. Złap się rękami i podciągnij z powrotem mięśniami dwugłowymi ud.',
      'single_leg_rdl':
        '1. Stań na jednej nodze z hantlem, kolano lekko ugięte.\n'
        '2. Pochyl się, a wolną nogę wyprostuj do tyłu, plecy proste.\n'
        '3. Wyprostuj się, pchając biodra do przodu.',
      'dumbbell_romanian_deadlift':
        '1. Stań z hantlami przed udami, kolana miękkie.\n'
        '2. Cofnij biodra i prowadź hantle wzdłuż nóg w dół.\n'
        '3. Zatrzymaj się przy rozciągnięciu tyłu ud i wyprostuj.',
      'stiff_leg_deadlift':
        '1. Stań ze sztangą w dłoniach, nogi prawie proste.\n'
        '2. Pochyl się z prostymi plecami, prowadząc sztangę wzdłuż nóg.\n'
        '3. Wyprostuj się, napinając tył ud i pośladki.',
      'stability_ball_leg_curl':
        '1. Połóż się na plecach, pięty na piłce, biodra uniesione.\n'
        '2. Ugnij kolana i przyciągnij piłkę do siebie.\n'
        '3. Powoli odtocz ją z powrotem, biodra zostają w górze.',
      'sumo_deadlift':
        '1. Szeroki rozkrok, palce na zewnątrz, chwyć sztangę między nogami.\n'
        '2. Napnij się, wypchnij kolana na zewnątrz i wstań ze sztangą blisko ciała.\n'
        '3. Opuść ją z prostymi plecami.',
      'cable_glute_kickback':
        '1. Przypnij mankiet do kostki na dolnym wyciągu i przytrzymaj się maszyny.\n'
        '2. Napinając pośladek, wyprostuj nogę w tył i w górę.\n'
        '3. Powoli wróć, nie wyginając odcinka lędźwiowego.',
      'hip_abduction_machine':
        '1. Usiądź w maszynie, poduszki po zewnętrznej stronie kolan.\n'
        '2. Rozsuń nogi jak najszerzej.\n'
        '3. Powoli złącz je z powrotem.',
      'machine_hip_thrust':
        '1. Oprzyj górną część pleców o oparcie, pas na biodrach.\n'
        '2. Wypchnij biodra w górę, aż ciało będzie proste od kolan do barków.\n'
        '3. Napnij pośladki na górze i powoli opuść.',
      'single_leg_glute_bridge':
        '1. Połóż się na plecach, jedna stopa na podłodze, druga noga wyprostowana w górę.\n'
        '2. Unieś biodra, pchając piętą opartej nogi.\n'
        '3. Powoli opuść. Skończ powtórzenia i zmień nogę.',
      'donkey_kick':
        '1. Uklęknij w podporze, dłonie pod barkami.\n'
        '2. Unieś ugiętą nogę do tyłu, podeszwa w stronę sufitu.\n'
        '3. Powoli opuść, nie wyginając pleców.',
      'fire_hydrant':
        '1. Uklęknij w podporze, plecy proste.\n'
        '2. Unieś ugiętą nogę w bok do wysokości biodra.\n'
        '3. Powoli opuść, biodra pozostają poziomo.',
      'banded_lateral_walk':
        '1. Załóż mini gumę nad kolana lub na kostki i lekko ugnij kolana.\n'
        '2. Idź w bok, utrzymując napięcie gumy.\n'
        '3. Policz kroki w jedną stronę i wróć.',
      'cable_pull_through':
        '1. Stań tyłem do dolnego wyciągu, lina między nogami.\n'
        '2. Pochyl się z prostymi plecami, pozwalając linie odjechać do tyłu.\n'
        '3. Wyprostuj się, pchając biodra do przodu, i napnij pośladki.',
      'seated_calf_raise':
        '1. Usiądź, poduszka na udach, przednia część stóp na podeście.\n'
        '2. Unieś pięty jak najwyżej.\n'
        '3. Powoli opuść do pełnego rozciągnięcia.',
      'single_leg_calf_raise':
        '1. Stań jedną stopą na krawędzi stopnia i przytrzymaj się.\n'
        '2. Wspnij się na palce jak najwyżej.\n'
        '3. Opuść piętę poniżej stopnia do pełnego rozciągnięcia.',
      'leg_press_calf_raise':
        '1. Usiądź na suwnicy, przednia część stóp na dolnej krawędzi platformy.\n'
        '2. Odepchnij platformę, prostując stopy.\n'
        '3. Powoli pozwól jej wrócić do rozciągnięcia. Kolana proste.',
      'sit_up':
        '1. Połóż się na plecach, kolana ugięte, stopy na podłodze.\n'
        '2. Unieś się aż do siadu.\n'
        '3. Powoli wróć do leżenia.',
      'decline_sit_up':
        '1. Zablokuj stopy na ławce skośnej ujemnej i połóż się.\n'
        '2. Unieś się, aż tułów będzie pionowo.\n'
        '3. Powoli wróć. Dla większego obciążenia trzymaj talerz.',
      'bicycle_crunch':
        '1. Połóż się na plecach, dłonie przy głowie, nogi uniesione.\n'
        '2. Przyciągnij łokieć do przeciwnego kolana, drugą nogę wyprostuj.\n'
        '3. Zmieniaj strony jak przy pedałowaniu.',
      'reverse_crunch':
        '1. Połóż się na plecach, kolana ugięte pod kątem prostym, ręce na podłodze.\n'
        '2. Unieś biodra i przyciągnij kolana do klatki.\n'
        '3. Powoli opuść bez bujania.',
      'lying_leg_raise':
        '1. Połóż się na plecach, nogi proste, lędźwie przyciśnięte do podłogi.\n'
        '2. Unieś nogi, aż będą skierowane w sufit.\n'
        '3. Powoli opuść, lędźwie się nie odrywają.',
      'captains_chair_knee_raise':
        '1. Oprzyj przedramiona na poduszkach, plecy o oparcie.\n'
        '2. Przyciągnij kolana do klatki.\n'
        '3. Powoli opuść bez bujania.',
      'ab_wheel_rollout':
        '1. Uklęknij i trzymaj kółko pod barkami.\n'
        '2. Wyjedź do przodu jak najdalej, lędźwie nie opadają.\n'
        '3. Wróć, pracując mięśniami brzucha.',
      'russian_twist':
        '1. Usiądź z lekkim odchyleniem, stopy uniesione lub na podłodze.\n'
        '2. Skręć tułów i dotknij podłogi obok biodra.\n'
        '3. Skręć w drugą stronę. Dla większego obciążenia trzymaj ciężarek.',
      'v_up':
        '1. Połóż się na plecach, ręce za głową, nogi proste.\n'
        '2. Jednocześnie unieś ręce i nogi i dotknij palców stóp.\n'
        '3. Powoli wróć do leżenia.',
      'hollow_hold':
        '1. Połóż się na plecach i przyciśnij lędźwie do podłogi.\n'
        '2. Unieś barki i proste nogi nieco nad podłogę.\n'
        '3. Wytrzymaj zadany czas, lędźwie się nie odrywają.',
      'pallof_press':
        '1. Stań bokiem do wyciągu na wysokości klatki, uchwyt przy klatce.\n'
        '2. Wypchnij uchwyt prosto przed siebie, nie pozwalając ciału się obrócić.\n'
        '3. Wróć do klatki. Ćwicz obie strony.',
      'cable_woodchopper':
        '1. Stań bokiem do górnego wyciągu, uchwyt trzymaj oburącz.\n'
        '2. Ciągnij go skośnie w dół przez ciało, skręcając tułów.\n'
        '3. Powoli wróć. Ćwicz obie strony.',
      'plank_shoulder_tap':
        '1. Przyjmij pozycję wysokiej deski, stopy lekko rozstawione.\n'
        '2. Dotknij jedną ręką przeciwnego barku, biodra się nie kołyszą.\n'
        '3. Zmień rękę.',
      'bird_dog':
        '1. Uklęknij w podporze, plecy proste.\n'
        '2. Wyprostuj jedną rękę do przodu i przeciwną nogę do tyłu.\n'
        '3. Chwilę wytrzymaj, wróć i zmień strony.',
      'power_clean':
        '1. Stań nad sztangą, chwyt tuż na zewnątrz kolan, plecy proste.\n'
        '2. Dynamicznie ciągnij sztangę wzdłuż ciała i przyjmij ją z przodu na barkach.\n'
        '3. Wyprostuj się i odłóż sztangę. Technikę ćwicz z lekką sztangą.',
      'thruster':
        '1. Trzymaj sztangę z przodu na barkach.\n'
        '2. Zrób przysiad i przy wstawaniu jednym ruchem wypchnij ją nad głowę.\n'
        '3. Opuść sztangę na barki i od razu przejdź do kolejnego przysiadu.',
      'turkish_get_up':
        '1. Połóż się na plecach, trzymając kettlebell w jednej ręce nad sobą.\n'
        '2. Krok po kroku wstań, patrząc na kettlebell, ręka prosta.\n'
        '3. Tą samą drogą wróć do leżenia. Ćwicz obie strony.',
      'bear_crawl':
        '1. Oprzyj się na dłoniach i stopach, kolana tuż nad podłogą, plecy proste.\n'
        '2. Idź do przodu, przesuwając jednocześnie przeciwną rękę i nogę.\n'
        '3. Trzymaj biodra nisko przez zadany czas.',
      'high_knees':
        '1. Biegnij w miejscu, unosząc kolana do wysokości bioder.\n'
        '2. Pracuj rękami i zostań na przedniej części stóp.\n'
        '3. Utrzymuj szybkie tempo przez zadany czas.',
      'jump_rope':
        '1. Trzymaj rączki na wysokości bioder, łokcie blisko ciała.\n'
        '2. Kręć skakanką nadgarstkami i skacz tylko tak wysoko, by przeszła.\n'
        '3. Ląduj miękko na przedniej części stóp przez zadany czas.',
      'rowing_machine':
        '1. Zapnij stopy i chwyć uchwyt prostymi rękami.\n'
        '2. Odepchnij się nogami, lekko odchyl się i przyciągnij uchwyt do dolnych żeber.\n'
        '3. Wracaj w odwrotnej kolejności: ręce, tułów, nogi. Utrzymuj równe tempo.',
      'stationary_bike':
        '1. Ustaw siodełko tak, by kolano w dolnym położeniu pedału było lekko ugięte.\n'
        '2. Pedałuj równym tempem z prostymi plecami.\n'
        '3. Ustaw opór według celu i jedź przez zadany czas.',
      'treadmill_run':
        '1. Zacznij od marszu i stopniowo zwiększaj prędkość.\n'
        '2. Biegnij z wyprostowaną sylwetką i luźnymi barkami, lądując pod biodrami.\n'
        '3. Przed zejściem zwolnij do marszu.',
      'elliptical':
        '1. Stań na pedałach i chwyć ruchome uchwyty.\n'
        '2. Poruszaj się płynnie, pracując też rękami.\n'
        '3. Utrzymuj równe tempo przez zadany czas.',
      'stair_climber':
        '1. Wejdź na schody i wybierz prędkość, którą utrzymasz.\n'
        '2. Wchodź z wyprostowaną sylwetką, poręczy używaj tylko lekko dla równowagi.\n'
        '3. Kontynuuj przez zadany czas.',
      'air_bike':
        '1. Usiądź na rowerze i chwyć ruchome uchwyty.\n'
        '2. Pedałuj, jednocześnie pchając i ciągnąc uchwyty.\n'
        '3. Im mocniej jedziesz, tym bardziej hamuje wiatrak. Jedź przez zadany czas.',
    },
    routineNames: {
      'home_upper': 'Góra ciała w 5 minut',
      'home_lower': 'Dół ciała w 5 minut',
      'home_full': 'Całe ciało w 5 minut',
    },
    programNames: {
      'full_body': 'Full body (dla początkujących)',
      'upper_lower': 'Góra / Dół',
      'ppl': 'Push / Pull / Legs',
      'full_body_2x': 'Full body 2× w tygodniu',
      'dumbbell_home': 'Hantle w domu',
      'strength_5x5': 'Siła 5×5',
      'circuit': 'Trening obwodowy (wytrzymałość)',
      'full_body_variation': 'Full body – wariant',
      'bodyweight_home': 'Masa ciała w domu',
      'machines': 'Maszyny (dla początkujących)',
      'upper_lower_variation': 'Góra / Dół – wariant',
      'ppl_variation': 'Push / Pull / Legs – wariant',
      'strength_dup': 'Siła – fale tygodniowe',
      'conditioning_intervals': 'Kondycja – interwały',
      'phul': 'Siła + masa (PHUL)',
      'strength_advanced': 'Siła – 4 dni (zaawansowani)',
      'ppl_6x': 'Push / Pull / Legs 6× w tygodniu',
    },
    programDescriptions: {
      'full_body':
        '3× w tygodniu, na zmianę trening A i B. Idealny na pierwsze miesiące.',
      'upper_lower':
        '4× w tygodniu: góra ciała pon. + czw., dół ciała wt. + pt.',
      'ppl': '3× w tygodniu: push pon., pull śr., nogi pt.',
      'full_body_2x':
        'Na zabiegane tygodnie: 2 treningi po około godzinie, pon. + czw. Każda partia 2× w tygodniu.',
      'dumbbell_home':
        '3× w tygodniu z parą hantli i matą, na zmianę A i B. Bez siłowni.',
      'strength_5x5':
        '3× w tygodniu, na zmianę A i B: 5 serii po 5 w dużych ćwiczeniach. Gdy zrobisz wszystkie serie po 5, ciężar rośnie.',
      'circuit':
        '3× w tygodniu, na zmianę A i B: ćwiczenia w obwodzie jedno po drugim, krótkie przerwy, dużo powtórzeń. Na wytrzymałość i kondycję.',
      'full_body_variation':
        '3× w tygodniu, na zmianę C i D. Ta sama budowa co Full body (dla początkujących), inne ćwiczenia – zmieniaj co 6–8 tygodni.',
      'bodyweight_home':
        '3× w tygodniu, na zmianę A i B, bez sprzętu – wystarczy mata (i solidny stół do podciągania australijskiego). Na start i w podróży.',
      'machines':
        '3× w tygodniu, na zmianę A i B, na maszynach na siłowni: łatwe do nauczenia, bezpieczne nawet bez asekuracji. Dobry pierwszy krok przed wolnymi ciężarami.',
      'upper_lower_variation':
        '4× w tygodniu jak Góra / Dół, z innymi ćwiczeniami (wyciskanie na skosie, przysiad przedni, hip thrust). Zmieniaj co 6–8 tygodni.',
      'ppl_variation':
        '3× w tygodniu jak Push / Pull / Legs, z innymi ćwiczeniami (najpierw wyciskanie nad głowę, wiosłowanie sztangą, hack przysiad). Zmieniaj co 6–8 tygodni.',
      'strength_dup':
        '3× w tygodniu: dzień ciężki (serie po 3), dzień objętościowy (6–8 powtórzeń) i dzień średni (serie po 5). Zmienne obciążenie w tygodniu pozwala rosnąć sile także po pierwszym roku.',
      'conditioning_intervals':
        '3× w tygodniu, na zmianę A i B: pary ćwiczenia siłowego i cardio jedno po drugim, na koniec ciągłe cardio. Na kondycję, wytrzymałość i redukcję tkanki tłuszczowej.',
      'phul':
        '4× w tygodniu: ciężkie dni góry i dołu ciała na siłę (pon., wt.), dni z większą liczbą powtórzeń na mięśnie (czw., pt.). Około 12–16 serii na partię tygodniowo.',
      'strength_advanced':
        '4× w tygodniu, każdego dnia jeden duży bój (przysiad, wyciskanie leżąc, martwy ciąg, wyciskanie nad głowę): ciężkie serie po 3, pokrewny wariant i ćwiczenia na słabe punkty.',
      'ppl_6x':
        'Pon.–sob.: Push, Pull, Nogi, potem Push B, Pull B, Nogi B. Każda partia 2× w tygodniu z dużą objętością – dla doświadczonych z dobrą regeneracją.',
    },
    planNames: {
      'Full body A': 'Full body A',
      'Full body B': 'Full body B',
      'Upper body': 'Góra ciała',
      'Lower body': 'Dół ciała',
      'Push': 'Push',
      'Pull': 'Pull',
      'Legs': 'Nogi',
      'Full body 2× A': 'Full body 2× A',
      'Full body 2× B': 'Full body 2× B',
      'Dumbbells A': 'Hantle A',
      'Dumbbells B': 'Hantle B',
      '5×5 A': '5×5 A',
      '5×5 B': '5×5 B',
      'Circuit A': 'Obwód A',
      'Circuit B': 'Obwód B',
      'Full body C': 'Full body C',
      'Full body D': 'Full body D',
      'Bodyweight A': 'Masa ciała A',
      'Bodyweight B': 'Masa ciała B',
      'Machines A': 'Maszyny A',
      'Machines B': 'Maszyny B',
      'Upper body B': 'Góra ciała B',
      'Lower body B': 'Dół ciała B',
      'Push B': 'Push B',
      'Pull B': 'Pull B',
      'Legs B': 'Nogi B',
      'Strength: heavy day': 'Siła: dzień ciężki',
      'Strength: volume day': 'Siła: dzień objętościowy',
      'Strength: medium day': 'Siła: dzień średni',
      'Intervals A': 'Interwały A',
      'Intervals B': 'Interwały B',
      'Upper power': 'Góra – siła',
      'Lower power': 'Dół – siła',
      'Upper hypertrophy': 'Góra – masa',
      'Lower hypertrophy': 'Dół – masa',
      'Strength: squat': 'Siła: przysiad',
      'Strength: bench': 'Siła: wyciskanie leżąc',
      'Strength: deadlift': 'Siła: martwy ciąg',
      'Strength: overhead press': 'Siła: wyciskanie nad głowę',
    },
  ),
  'pt': (
    exerciseNames: {
      'bench_press': 'Supino reto',
      'incline_dumbbell_press': 'Supino inclinado com halteres',
      'cable_fly': 'Crucifixo na polia',
      'push_up': 'Flexão de braço',
      'deadlift': 'Levantamento terra',
      'barbell_row': 'Remada curvada',
      'lat_pulldown': 'Puxada frontal',
      'pull_up': 'Barra fixa',
      'overhead_press': 'Desenvolvimento militar',
      'lateral_raise': 'Elevação lateral',
      'pike_push_up': 'Flexão pike',
      'dumbbell_curl': 'Rosca alternada com halteres',
      'triceps_pushdown': 'Tríceps na polia',
      'dips': 'Paralelas',
      'back_squat': 'Agachamento livre',
      'leg_press': 'Leg press',
      'romanian_deadlift': 'Stiff (terra romeno)',
      'bodyweight_squat': 'Agachamento sem peso',
      'lunge': 'Avanço',
      'hip_thrust': 'Hip thrust',
      'glute_bridge': 'Ponte de glúteo',
      'plank': 'Prancha',
      'crunch': 'Abdominal crunch',
      'mountain_climber': 'Escalador',
      'jumping_jack': 'Polichinelo',
      'dumbbell_bench_press': 'Supino reto com halteres',
      'incline_bench_press': 'Supino inclinado',
      'chest_press_machine': 'Supino na máquina',
      'pec_deck': 'Voador (peck deck)',
      'seated_cable_row': 'Remada baixa',
      'one_arm_dumbbell_row': 'Remada unilateral com halter (serrote)',
      'chin_up': 'Barra fixa supinada',
      'dumbbell_shoulder_press': 'Desenvolvimento com halteres',
      'rear_delt_fly': 'Crucifixo inverso',
      'face_pull': 'Face pull',
      'barbell_curl': 'Rosca direta',
      'hammer_curl': 'Rosca martelo',
      'cable_curl': 'Rosca na polia',
      'skull_crusher': 'Tríceps testa',
      'overhead_triceps_extension': 'Tríceps francês',
      'close_grip_bench_press': 'Supino fechado',
      'front_squat': 'Agachamento frontal',
      'goblet_squat': 'Agachamento goblet',
      'bulgarian_split_squat': 'Agachamento búlgaro',
      'leg_extension': 'Cadeira extensora',
      'leg_curl': 'Mesa flexora',
      'calf_raise': 'Panturrilha em pé',
      'hanging_leg_raise': 'Elevação de pernas na barra',
      'cable_crunch': 'Abdominal na polia',
      'dead_bug': 'Dead bug',
      'side_plank': 'Prancha lateral',
      'burpee': 'Burpee',
      'kettlebell_swing': 'Swing com kettlebell',
      'weighted_pull_up': 'Barra fixa com carga',
      'weighted_dips': 'Paralelas com carga',
      'barbell_shrug': 'Encolhimento com barra',
      'dumbbell_shrug': 'Encolhimento com halteres',
      'wrist_curl': 'Rosca de punho',
      'reverse_curl': 'Rosca inversa',
      'dead_hang': 'Suspensão na barra',
      'back_extension': 'Hiperextensão lombar',
      'good_morning': 'Good morning com barra',
      'superman': 'Super-homem',
      'decline_bench_press': 'Supino declinado',
      'smith_bench_press': 'Supino no Smith',
      'dumbbell_fly': 'Crucifixo com halteres',
      'incline_dumbbell_fly': 'Crucifixo inclinado com halteres',
      'low_to_high_cable_fly': 'Crucifixo no cabo de baixo para cima',
      'incline_chest_press_machine': 'Supino inclinado na máquina',
      'chest_dips': 'Paralelas para peito',
      'incline_push_up': 'Flexão inclinada',
      'decline_push_up': 'Flexão declinada',
      'dumbbell_floor_press': 'Supino no chão com halteres',
      't_bar_row': 'Remada cavalinho (T-bar)',
      'pendlay_row': 'Remada Pendlay',
      'machine_row': 'Remada sentada na máquina',
      'chest_supported_row': 'Remada com halteres apoiada no banco inclinado',
      'close_grip_lat_pulldown': 'Puxada com pegada fechada',
      'straight_arm_pulldown': 'Pulldown com braços estendidos',
      'band_assisted_pull_up': 'Barra fixa com elástico',
      'inverted_row': 'Remada invertida',
      'neutral_grip_pull_up': 'Barra fixa pegada neutra',
      'rack_pull': 'Rack pull',
      'trap_bar_deadlift': 'Levantamento terra com trap bar',
      'single_arm_cable_row': 'Remada unilateral no cabo',
      'dumbbell_pullover': 'Pullover com halter',
      'renegade_row': 'Remada renegada',
      'arnold_press': 'Desenvolvimento Arnold',
      'shoulder_press_machine': 'Desenvolvimento na máquina',
      'push_press': 'Push press',
      'cable_lateral_raise': 'Elevação lateral no cabo',
      'machine_lateral_raise': 'Elevação lateral na máquina',
      'front_raise': 'Elevação frontal com halteres',
      'upright_row': 'Remada alta',
      'reverse_pec_deck': 'Crucifixo inverso na máquina',
      'band_pull_apart': 'Abertura com elástico',
      'handstand_push_up': 'Flexão em parada de mão',
      'landmine_press': 'Desenvolvimento landmine',
      'preacher_curl': 'Rosca Scott',
      'concentration_curl': 'Rosca concentrada',
      'incline_dumbbell_curl': 'Rosca inclinada com halteres',
      'ez_bar_curl': 'Rosca com barra W',
      'rope_hammer_curl': 'Rosca martelo na corda',
      'machine_biceps_curl': 'Rosca bíceps na máquina',
      'band_curl': 'Rosca com elástico',
      'rope_pushdown': 'Tríceps na corda',
      'overhead_cable_extension': 'Tríceps francês no cabo',
      'triceps_kickback': 'Tríceps coice',
      'bench_dips': 'Mergulho no banco',
      'machine_triceps_dip': 'Mergulho na máquina',
      'single_arm_pushdown': 'Tríceps unilateral no cabo',
      'diamond_push_up': 'Flexão diamante',
      'reverse_wrist_curl': 'Rosca de punho inversa',
      'hack_squat': 'Agachamento hack',
      'smith_squat': 'Agachamento no Smith',
      'walking_lunge': 'Afundo caminhando',
      'reverse_lunge': 'Afundo para trás',
      'step_up': 'Subida no banco',
      'split_squat': 'Agachamento afundo',
      'sumo_squat': 'Agachamento sumô com halter',
      'pistol_squat': 'Agachamento pistol',
      'single_leg_press': 'Leg press unilateral',
      'hip_adduction_machine': 'Cadeira adutora',
      'wall_sit': 'Cadeirinha na parede',
      'jump_squat': 'Agachamento com salto',
      'box_jump': 'Salto na caixa',
      'seated_leg_curl': 'Cadeira flexora',
      'nordic_curl': 'Flexão nórdica',
      'single_leg_rdl': 'Stiff unilateral',
      'dumbbell_romanian_deadlift': 'Levantamento terra romeno com halteres',
      'stiff_leg_deadlift': 'Stiff com barra',
      'stability_ball_leg_curl': 'Flexão de pernas na bola suíça',
      'sumo_deadlift': 'Levantamento terra sumô',
      'cable_glute_kickback': 'Glúteo no cabo (coice)',
      'hip_abduction_machine': 'Cadeira abdutora',
      'machine_hip_thrust': 'Elevação pélvica na máquina',
      'single_leg_glute_bridge': 'Ponte de glúteo unilateral',
      'donkey_kick': 'Coice de glúteo no solo',
      'fire_hydrant': 'Abdução de quadril em quatro apoios',
      'banded_lateral_walk': 'Caminhada lateral com elástico',
      'cable_pull_through': 'Pull-through no cabo',
      'seated_calf_raise': 'Panturrilha sentado',
      'single_leg_calf_raise': 'Panturrilha unilateral',
      'leg_press_calf_raise': 'Panturrilha no leg press',
      'sit_up': 'Abdominal completo',
      'decline_sit_up': 'Abdominal no banco declinado',
      'bicycle_crunch': 'Abdominal bicicleta',
      'reverse_crunch': 'Abdominal invertido',
      'lying_leg_raise': 'Elevação de pernas deitado',
      'captains_chair_knee_raise': 'Elevação de joelhos na cadeira romana',
      'ab_wheel_rollout': 'Roda abdominal',
      'russian_twist': 'Giro russo',
      'v_up': 'Abdominal canivete (V-up)',
      'hollow_hold': 'Hollow hold',
      'pallof_press': 'Pallof press',
      'cable_woodchopper': 'Lenhador no cabo',
      'plank_shoulder_tap': 'Prancha com toque no ombro',
      'bird_dog': 'Bird dog',
      'power_clean': 'Power clean (arremesso ao peito)',
      'thruster': 'Thruster',
      'turkish_get_up': 'Levantamento turco',
      'bear_crawl': 'Caminhada do urso',
      'high_knees': 'Corrida com joelhos altos',
      'jump_rope': 'Pular corda',
      'rowing_machine': 'Remo ergômetro',
      'stationary_bike': 'Bicicleta ergométrica',
      'treadmill_run': 'Corrida na esteira',
      'elliptical': 'Elíptico',
      'stair_climber': 'Simulador de escada',
      'air_bike': 'Air bike',
    },
    exerciseInstructions: {
      'bench_press':
        '1. Deite no banco com os olhos embaixo da barra e os pés apoiados no chão.\n'
        '2. Pegada um pouco mais aberta que os ombros, escápulas contraídas.\n'
        '3. Desça a barra com controle até o meio do peito, cotovelos a cerca de 45° do corpo.\n'
        '4. Empurre até estender os braços sem tirar o quadril do banco.',
      'incline_dumbbell_press':
        '1. Ajuste o banco a 30–45°, halteres na altura do peito.\n'
        '2. Mantenha as escápulas para trás e os pés no chão.\n'
        '3. Empurre para cima aproximando levemente os halteres e desça devagar até a altura do peito.',
      'cable_fly':
        '1. Fique entre as polias com os cotovelos levemente flexionados.\n'
        '2. Junte as pegadas em arco na frente do peito.\n'
        '3. Volte devagar até sentir o alongamento, mantendo os cotovelos fixos.',
      'push_up':
        '1. Mãos um pouco mais abertas que os ombros, corpo em linha reta.\n'
        '2. Desça o peito perto do chão, cotovelos a cerca de 45° do corpo.\n'
        '3. Empurre de volta, mantendo abdômen e glúteos contraídos.',
      'deadlift':
        '1. Barra sobre o meio do pé, pés na largura do quadril.\n'
        '2. Incline o quadril para trás, segure a barra e mantenha as costas neutras.\n'
        '3. Empurre o chão e suba com a barra perto das pernas.\n'
        '4. Desça com controle levando o quadril para trás.',
      'barbell_row':
        '1. Incline o tronco a cerca de 45°, costas retas, joelhos levemente flexionados.\n'
        '2. Puxe a barra até a parte baixa do peito ou a barriga.\n'
        '3. Contraia as escápulas e desça devagar.',
      'lat_pulldown':
        '1. Pegada um pouco mais aberta que os ombros, coxas presas sob os apoios.\n'
        '2. Puxe a barra até a parte alta do peito, cotovelos para baixo e para trás.\n'
        '3. Volte devagar até estender os braços, sem balançar.',
      'pull_up':
        '1. Pendure-se na barra com pegada pronada, ombros ativos.\n'
        '2. Suba até o queixo passar da barra.\n'
        '3. Desça com controle até estender totalmente os braços.',
      'overhead_press':
        '1. Barra apoiada na frente dos ombros, pegada logo fora dos ombros.\n'
        '2. Contraia glúteos e abdômen e empurre a barra reto para cima.\n'
        '3. Leve a cabeça um pouco para trás quando a barra passar e trave os braços no alto.',
      'lateral_raise':
        '1. Fique em pé, halteres ao lado do corpo, cotovelos levemente flexionados.\n'
        '2. Eleve os braços para os lados até a altura dos ombros.\n'
        '3. Desça devagar, sem balançar.',
      'pike_push_up':
        '1. Comece na posição de flexão e eleve o quadril formando um V invertido.\n'
        '2. Desça a cabeça em direção ao chão entre as mãos.\n'
        '3. Empurre de volta usando os ombros.',
      'dumbbell_curl':
        '1. Fique em pé, cotovelos junto ao corpo.\n'
        '2. Flexione os braços subindo os halteres sem mover os cotovelos.\n'
        '3. Desça devagar até estender os braços.',
      'triceps_pushdown':
        '1. Fique de frente para a polia, cotovelos colados ao corpo.\n'
        '2. Empurre a barra para baixo até estender os braços.\n'
        '3. Volte devagar, mantendo os cotovelos parados.',
      'dips':
        '1. Apoie-se nas barras com os braços estendidos.\n'
        '2. Desça até os braços ficarem mais ou menos paralelos ao chão.\n'
        '3. Empurre de volta, sem deixar os ombros caírem para a frente.',
      'back_squat':
        '1. Barra na parte alta das costas, pés na largura dos ombros, pontas levemente para fora.\n'
        '2. Contraia o abdômen e sente entre os calcanhares.\n'
        '3. Os joelhos acompanham as pontas dos pés, as costas ficam neutras.\n'
        '4. Suba empurrando com o pé inteiro.',
      'leg_press':
        '1. Pés na largura dos ombros, no meio da plataforma.\n'
        '2. Desça até os joelhos ficarem a cerca de 90°, com a lombar apoiada no encosto.\n'
        '3. Empurre para cima sem travar os joelhos com força.',
      'romanian_deadlift':
        '1. Fique em pé com a barra, joelhos levemente flexionados.\n'
        '2. Leve o quadril para trás e desça a barra rente às pernas.\n'
        '3. Pare ao sentir o alongamento nos posteriores de coxa, costas retas.\n'
        '4. Volte empurrando o quadril para a frente.',
      'bodyweight_squat':
        '1. Pés na largura dos ombros, braços à frente para equilibrar.\n'
        '2. Agache o mais baixo que conseguir com as costas retas.\n'
        '3. Suba empurrando com os calcanhares.',
      'lunge':
        '1. Dê um passo à frente e desça até os dois joelhos ficarem a cerca de 90°.\n'
        '2. O joelho da frente fica sobre o pé, tronco ereto.\n'
        '3. Empurre de volta à posição inicial e troque de perna.',
      'hip_thrust':
        '1. Parte alta das costas apoiada no banco, barra sobre o quadril.\n'
        '2. Empurre com os calcanhares e eleve o quadril até o corpo ficar reto.\n'
        '3. Contraia os glúteos no alto e desça com controle.',
      'glute_bridge':
        '1. Deite de costas, joelhos flexionados, pés no chão.\n'
        '2. Eleve o quadril contraindo os glúteos.\n'
        '3. Segure um instante no alto e desça devagar.',
      'plank':
        '1. Antebraços sob os ombros, corpo em linha reta.\n'
        '2. Contraia abdômen e glúteos, sem deixar o quadril cair.\n'
        '3. Respire de forma constante e segure.',
      'crunch':
        '1. Deite de costas, joelhos flexionados, mãos ao lado da cabeça.\n'
        '2. Tire os ombros do chão usando o abdômen.\n'
        '3. Desça devagar, sem puxar o pescoço.',
      'mountain_climber':
        '1. Comece na posição de flexão.\n'
        '2. Leve os joelhos em direção ao peito, alternando.\n'
        '3. Mantenha o quadril baixo e o ritmo constante.',
      'jumping_jack':
        '1. Fique em pé com os pés juntos e os braços ao lado do corpo.\n'
        '2. Salte abrindo os pés e levante os braços acima da cabeça.\n'
        '3. Salte de volta e repita em ritmo constante.',
      'dumbbell_bench_press':
        '1. Deite em um banco reto com os halteres na altura do peito.\n'
        '2. Empurre para cima aproximando levemente os halteres.\n'
        '3. Desça devagar até sentir o alongamento no peito.',
      'incline_bench_press':
        '1. Banco a 30–45°, pegada um pouco mais aberta que os ombros.\n'
        '2. Desça a barra até a parte alta do peito.\n'
        '3. Empurre para cima mantendo as escápulas para trás.',
      'chest_press_machine':
        '1. Ajuste o banco para que as pegadas fiquem no meio do peito.\n'
        '2. Empurre para a frente até os braços ficarem quase estendidos.\n'
        '3. Volte devagar, mantendo as costas no encosto.',
      'pec_deck':
        '1. Sente com as costas no encosto, cotovelos levemente flexionados.\n'
        '2. Junte as pegadas na frente do peito.\n'
        '3. Volte devagar até um alongamento confortável.',
      'seated_cable_row':
        '1. Sente com o tronco ereto, pés na plataforma, joelhos levemente flexionados.\n'
        '2. Puxe o puxador até a barriga, cotovelos perto do corpo.\n'
        '3. Contraia as escápulas e volte devagar sem curvar as costas.',
      'one_arm_dumbbell_row':
        '1. Um joelho e uma mão apoiados no banco, costas retas.\n'
        '2. Puxe o halter em direção ao quadril.\n'
        '3. Desça devagar até alongar totalmente.',
      'chin_up':
        '1. Pendure-se na barra com pegada supinada, na largura dos ombros.\n'
        '2. Suba até o queixo passar da barra.\n'
        '3. Desça com controle até estender totalmente os braços.',
      'dumbbell_shoulder_press':
        '1. Em um banco ou em pé, halteres na altura dos ombros.\n'
        '2. Empurre acima da cabeça sem arquear a lombar.\n'
        '3. Desça devagar de volta aos ombros.',
      'rear_delt_fly':
        '1. Incline o tronco à frente com as costas retas, halteres pendurados.\n'
        '2. Abra os braços para os lados com os cotovelos levemente flexionados.\n'
        '3. Desça devagar, sem usar impulso.',
      'face_pull':
        '1. Corda na altura da cabeça, segure com os polegares voltados para você.\n'
        '2. Puxe em direção ao rosto, cotovelos altos e abertos.\n'
        '3. Contraia a parte alta das costas e volte devagar.',
      'barbell_curl':
        '1. Fique em pé, pegada supinada na largura dos ombros.\n'
        '2. Suba a barra sem balançar o corpo.\n'
        '3. Desça devagar até estender os braços.',
      'hammer_curl':
        '1. Segure os halteres com as palmas voltadas uma para a outra.\n'
        '2. Suba os halteres, cotovelos junto ao corpo.\n'
        '3. Desça devagar.',
      'cable_curl':
        '1. Fique de frente para a polia baixa, cotovelos junto ao corpo.\n'
        '2. Suba o puxador até os ombros.\n'
        '3. Desça devagar, mantendo a tensão constante.',
      'skull_crusher':
        '1. Deite no banco com a barra acima do peito e os braços estendidos.\n'
        '2. Flexione só os cotovelos e desça a barra em direção à testa.\n'
        '3. Estenda de volta, com os cotovelos apontando para cima.',
      'overhead_triceps_extension':
        '1. Segure um halter acima da cabeça com as duas mãos.\n'
        '2. Desça-o atrás da cabeça flexionando os cotovelos.\n'
        '3. Estenda de volta, com os cotovelos perto da cabeça.',
      'close_grip_bench_press':
        '1. Deite no banco, pegada mais ou menos na largura dos ombros.\n'
        '2. Desça a barra até a parte baixa do peito, cotovelos perto do corpo.\n'
        '3. Empurre para cima estendendo os cotovelos.',
      'front_squat':
        '1. Barra apoiada na frente dos ombros, cotovelos altos.\n'
        '2. Agache com o tronco ereto.\n'
        '3. Suba com força, mantendo os cotovelos altos o tempo todo.',
      'goblet_squat':
        '1. Segure um kettlebell ou halter junto ao peito.\n'
        '2. Agache entre os joelhos com as costas retas.\n'
        '3. Suba empurrando com os calcanhares.',
      'bulgarian_split_squat':
        '1. Pé de trás apoiado no banco, pé da frente um passo à frente.\n'
        '2. Desça até a coxa da frente ficar mais ou menos paralela ao chão.\n'
        '3. Suba empurrando com o pé da frente e depois troque de perna.',
      'leg_extension':
        '1. Ajuste o rolo logo acima dos tornozelos.\n'
        '2. Estenda as pernas até ficarem retas.\n'
        '3. Desça devagar, com controle.',
      'leg_curl':
        '1. Ajuste o rolo logo acima dos calcanhares.\n'
        '2. Flexione levando os calcanhares em direção aos glúteos.\n'
        '3. Volte devagar, sem deixar o peso cair.',
      'calf_raise':
        '1. Pontas dos pés na borda, calcanhares livres.\n'
        '2. Suba o máximo possível na ponta dos pés.\n'
        '3. Desça devagar até alongar.',
      'hanging_leg_raise':
        '1. Pendure-se na barra, ombros ativos.\n'
        '2. Eleve as pernas ou os joelhos usando o abdômen, sem balançar.\n'
        '3. Desça devagar.',
      'cable_crunch':
        '1. Ajoelhe de frente para a polia, com a corda junto à cabeça.\n'
        '2. Contraia o abdômen para baixo curvando a coluna, o quadril fica parado.\n'
        '3. Volte devagar.',
      'dead_bug':
        '1. Deite de costas, braços para cima, joelhos a 90°.\n'
        '2. Desça o braço e a perna opostos, com a lombar colada no chão.\n'
        '3. Volte e troque de lado.',
      'side_plank':
        '1. Deite de lado, cotovelo embaixo do ombro.\n'
        '2. Eleve o quadril até o corpo formar uma linha reta.\n'
        '3. Segure e depois troque de lado.',
      'burpee':
        '1. Em pé, agache e apoie as mãos no chão.\n'
        '2. Salte os pés para trás até a prancha; se quiser, faça uma flexão.\n'
        '3. Salte os pés de volta para a frente e pule para cima.',
      'kettlebell_swing':
        '1. Kettlebell à frente, pés um pouco mais abertos que o quadril.\n'
        '2. Leve-o para trás entre as pernas flexionando o quadril.\n'
        '3. Projete o quadril para a frente com força para balançá-lo até a altura do peito, braços relaxados.',
      'weighted_pull_up':
        '1. Prenda uma anilha em um cinto de carga ou segure um halter entre os pés.\n'
        '2. Pendure-se na barra com pegada pronada, ombros ativos.\n'
        '3. Suba sem balançar até o queixo passar da barra.\n'
        '4. Desça com controle até estender totalmente os braços. Registre só a carga adicional.',
      'weighted_dips':
        '1. Prenda uma anilha em um cinto de carga ou segure um halter entre os pés.\n'
        '2. Apoie-se nas barras com os braços estendidos.\n'
        '3. Desça até os braços ficarem mais ou menos paralelos ao chão.\n'
        '4. Empurre de volta, sem deixar os ombros caírem para a frente. Registre só a carga adicional.',
      'barbell_shrug':
        '1. Em pé, segure a barra com os braços estendidos, pegada na largura dos ombros.\n'
        '2. Suba os ombros na vertical em direção às orelhas, braços retos.\n'
        '3. Pause em cima e desça devagar. Não gire os ombros.',
      'dumbbell_shrug':
        '1. Em pé, um halter em cada mão ao lado do corpo, palmas para dentro.\n'
        '2. Suba os ombros na vertical o mais alto possível.\n'
        '3. Segure um instante e desça com controle.',
      'wrist_curl':
        '1. Sente-se com os antebraços nas coxas ou num banco, palmas para cima, punhos para fora da borda.\n'
        '2. Deixe os halteres rolarem até a ponta dos dedos.\n'
        '3. Flexione os punhos o mais alto possível, antebraços parados.',
      'reverse_curl':
        '1. Em pé, segure a barra com pegada pronada na largura dos ombros.\n'
        '2. Suba a barra com os cotovelos junto ao corpo e punhos retos.\n'
        '3. Desça devagar até estender os braços.',
      'dead_hang':
        '1. Segure a barra com pegada pronada na largura dos ombros.\n'
        '2. Pendure-se com os braços estendidos, pés fora do chão, corpo parado.\n'
        '3. Segure pelo tempo definido com os ombros levemente ativos.',
      'back_extension':
        '1. Ajuste o apoio logo abaixo do quadril e prenda os calcanhares.\n'
        '2. Desça o tronco com a coluna reta até sentir o alongamento dos posteriores.\n'
        '3. Suba até alinhar com as pernas, sem arquear demais. Segure uma anilha para mais carga.',
      'good_morning':
        '1. Barra na parte alta das costas como no agachamento, pés na largura do quadril, joelhos levemente flexionados.\n'
        '2. Leve o quadril para trás e incline o tronco com a coluna reta até ficar quase paralelo ao chão.\n'
        '3. Empurre o quadril para a frente para subir. Comece com pouco peso.',
      'superman':
        '1. Deite de bruços com os braços estendidos acima da cabeça.\n'
        '2. Tire braços, peito e pernas do chão ao mesmo tempo.\n'
        '3. Segure um segundo em cima e desça devagar.',
      'decline_bench_press':
        '1. Prenda as pernas no banco declinado, pegada um pouco mais larga que os ombros.\n'
        '2. Desça a barra com controle até a parte baixa do peito.\n'
        '3. Empurre até estender os braços, escápulas juntas.',
      'smith_bench_press':
        '1. Posicione o banco para que a barra fique sobre o meio do peito.\n'
        '2. Destrave a barra e desça com controle até o peito.\n'
        '3. Empurre sem travar os cotovelos de forma brusca e trave a barra no final.',
      'dumbbell_fly':
        '1. Deite em um banco reto, halteres sobre o peito, cotovelos levemente flexionados.\n'
        '2. Abra os braços em um arco amplo até sentir o peito alongar.\n'
        '3. Junte os halteres de novo sem mudar o ângulo dos cotovelos.',
      'incline_dumbbell_fly':
        '1. Banco a 30°, halteres sobre o peito, cotovelos soltos.\n'
        '2. Desça em arco amplo até sentir a parte alta do peito alongar.\n'
        '3. Junte-os de novo sobre o peito.',
      'low_to_high_cable_fly':
        '1. Coloque as polias embaixo e fique entre elas com o tronco levemente inclinado.\n'
        '2. Leve as alças para cima e juntas na frente da parte alta do peito.\n'
        '3. Volte devagar ao alongamento, cotovelos levemente flexionados.',
      'incline_chest_press_machine':
        '1. Ajuste o banco para que as alças fiquem na altura da parte alta do peito.\n'
        '2. Empurre para frente e para cima até quase estender os braços.\n'
        '3. Volte devagar até sentir o peito alongar.',
      'chest_dips':
        '1. Apoie-se nas barras e incline o tronco para frente.\n'
        '2. Desça com os cotovelos um pouco abertos até sentir o peito alongar.\n'
        '3. Suba mantendo a inclinação.',
      'incline_push_up':
        '1. Mãos em um banco ou caixa, corpo alinhado.\n'
        '2. Desça o peito até a borda, cotovelos a cerca de 45° do corpo.\n'
        '3. Suba de novo. Quanto mais alto o apoio, mais fácil.',
      'decline_push_up':
        '1. Pés em um banco, mãos no chão abaixo dos ombros.\n'
        '2. Desça o peito até o chão com o abdômen firme.\n'
        '3. Suba sem deixar o quadril cair.',
      'dumbbell_floor_press':
        '1. Deite no chão, joelhos dobrados, halteres sobre o peito.\n'
        '2. Desça até os braços tocarem o chão e faça uma pausa.\n'
        '3. Empurre até estender os braços.',
      't_bar_row':
        '1. Fique sobre a barra, incline com a coluna reta e segure a alça.\n'
        '2. Puxe o peso até o peito juntando as escápulas.\n'
        '3. Desça com controle sem arredondar as costas.',
      'pendlay_row':
        '1. Barra no chão, tronco quase paralelo ao chão, coluna reta.\n'
        '2. Puxe a barra de forma explosiva até a parte baixa do peito.\n'
        '3. Apoie no chão a cada repetição e reposicione.',
      'machine_row':
        '1. Sente com o peito no apoio e segure as alças.\n'
        '2. Puxe até o corpo, cotovelos próximos, escápulas juntas.\n'
        '3. Volte devagar até estender os braços.',
      'chest_supported_row':
        '1. Deite de bruços em um banco a 30–45°, halteres pendurados.\n'
        '2. Puxe-os até as laterais juntando as escápulas.\n'
        '3. Desça devagar até o alongamento completo.',
      'close_grip_lat_pulldown':
        '1. Sente no pulley com pegada fechada ou triângulo, coxas presas.\n'
        '2. Puxe até a parte alta do peito, cotovelos para baixo e para trás.\n'
        '3. Deixe subir devagar até estender os braços.',
      'straight_arm_pulldown':
        '1. Em pé de frente para a polia alta, braços quase retos, leve inclinação.\n'
        '2. Leve a barra em arco até as coxas usando as costas.\n'
        '3. Volte devagar, cotovelos quase retos.',
      'band_assisted_pull_up':
        '1. Passe um elástico na barra e apoie um pé ou joelho nele.\n'
        '2. Suba até o queixo passar a barra.\n'
        '3. Desça com controle até estender os braços. Elástico mais fino = menos ajuda.',
      'inverted_row':
        '1. Pendure-se sob uma barra baixa ou argolas, corpo reto, calcanhares no chão.\n'
        '2. Puxe o peito até a barra juntando as escápulas.\n'
        '3. Desça com controle. Quanto mais em pé, mais fácil.',
      'neutral_grip_pull_up':
        '1. Pendure-se em pegadores paralelos, palmas voltadas uma para a outra.\n'
        '2. Suba até o queixo passar os pegadores.\n'
        '3. Desça com controle até estender totalmente os braços.',
      'rack_pull':
        '1. Coloque a barra nos apoios logo abaixo ou acima dos joelhos.\n'
        '2. Segure, contraia o abdômen e suba empurrando o quadril para frente.\n'
        '3. Devolva aos apoios com a coluna reta.',
      'trap_bar_deadlift':
        '1. Fique dentro da trap bar, pés na largura do quadril, segure as alças.\n'
        '2. Contraia, empurre o chão e fique em pé.\n'
        '3. Desça a barra com a coluna reta.',
      'single_arm_cable_row':
        '1. Segure uma alça na polia à altura da cintura, braço estendido.\n'
        '2. Puxe até a lateral, cotovelo perto do corpo.\n'
        '3. Volte devagar deixando o ombro ir um pouco à frente.',
      'dumbbell_pullover':
        '1. Deite em um banco segurando um halter com as duas mãos sobre o peito.\n'
        '2. Leve-o em arco para trás da cabeça, cotovelos levemente flexionados.\n'
        '3. Traga-o de volta sobre o peito.',
      'renegade_row':
        '1. Em posição de flexão sobre dois halteres, pés afastados.\n'
        '2. Puxe um halter até a lateral do corpo sem girar o quadril.\n'
        '3. Apoie e repita com o outro braço.',
      'arnold_press':
        '1. Sente-se com os halteres na frente dos ombros, palmas para você.\n'
        '2. Empurre para cima girando as palmas para frente.\n'
        '3. Desça girando de volta à posição inicial.',
      'shoulder_press_machine':
        '1. Ajuste o banco para que as alças comecem na altura dos ombros.\n'
        '2. Empurre até quase estender os braços.\n'
        '3. Desça devagar até a altura dos ombros.',
      'push_press':
        '1. Barra na frente dos ombros, pés na largura do quadril.\n'
        '2. Flexione um pouco os joelhos e use o impulso das pernas para levar a barra acima da cabeça.\n'
        '3. Volte a barra aos ombros com controle.',
      'cable_lateral_raise':
        '1. De lado para a polia baixa, alça na mão mais distante.\n'
        '2. Eleve o braço para o lado até a altura do ombro.\n'
        '3. Desça devagar mantendo a tensão.',
      'machine_lateral_raise':
        '1. Sente com os apoios na parte de fora dos braços.\n'
        '2. Eleve os braços até a altura dos ombros.\n'
        '3. Desça devagar sem apoiar o peso.',
      'front_raise':
        '1. Em pé, halteres na frente das coxas.\n'
        '2. Eleve-os à frente até a altura dos ombros, braços quase retos.\n'
        '3. Desça devagar sem balançar.',
      'upright_row':
        '1. Segure a barra na frente das coxas, pegada na largura dos ombros.\n'
        '2. Puxe-a junto ao corpo até a altura do peito, cotovelos à frente.\n'
        '3. Desça devagar. Se os ombros incomodarem, não suba tanto.',
      'reverse_pec_deck':
        '1. Sente de frente para a máquina, peito no apoio, segure as alças.\n'
        '2. Abra os braços para trás em arco até alinhar com o corpo.\n'
        '3. Volte devagar.',
      'band_pull_apart':
        '1. Segure um elástico à frente na altura dos ombros, braços retos.\n'
        '2. Abra-o até o peito juntando as escápulas.\n'
        '3. Volte devagar.',
      'handstand_push_up':
        '1. Suba em parada de mão na parede, mãos na largura dos ombros.\n'
        '2. Desça a cabeça em direção ao chão com controle.\n'
        '3. Empurre até estender os braços. Use um colchonete sob a cabeça.',
      'landmine_press':
        '1. Segure a ponta da barra landmine junto ao ombro, pés afastados um à frente.\n'
        '2. Empurre para cima e para frente até estender o braço.\n'
        '3. Volte ao ombro com controle.',
      'preacher_curl':
        '1. Sente no banco Scott, braços apoiados, barra W nas mãos.\n'
        '2. Suba a barra sem tirar os cotovelos do apoio.\n'
        '3. Desça devagar quase até estender.',
      'concentration_curl':
        '1. Sente-se em um banco, cotovelo apoiado na parte interna da coxa.\n'
        '2. Suba o halter em direção ao ombro.\n'
        '3. Desça devagar até o alongamento completo.',
      'incline_dumbbell_curl':
        '1. Recoste em um banco a 45–60°, braços pendendo para baixo.\n'
        '2. Suba os halteres sem mexer os braços.\n'
        '3. Desça devagar até o alongamento completo.',
      'ez_bar_curl':
        '1. Em pé, segure a barra W nas partes curvas, braços estendidos.\n'
        '2. Suba sem balançar o corpo.\n'
        '3. Desça devagar até estender os braços.',
      'rope_hammer_curl':
        '1. Prenda uma corda na polia baixa, palmas voltadas uma para a outra.\n'
        '2. Suba a corda, cotovelos junto ao corpo.\n'
        '3. Desça devagar mantendo a tensão.',
      'machine_biceps_curl':
        '1. Sente com os braços no apoio e segure as alças.\n'
        '2. Suba as alças até os ombros.\n'
        '3. Desça devagar quase até estender.',
      'band_curl':
        '1. Pise no meio do elástico, pontas nas mãos.\n'
        '2. Suba as mãos até os ombros, cotovelos junto ao corpo.\n'
        '3. Desça devagar.',
      'rope_pushdown':
        '1. Segure a corda na polia alta, cotovelos junto ao corpo.\n'
        '2. Empurre para baixo e abra as pontas no final.\n'
        '3. Deixe subir devagar até cerca de 90° no cotovelo.',
      'overhead_cable_extension':
        '1. De costas para a polia, corda atrás da cabeça, cotovelos para cima.\n'
        '2. Estenda os braços para frente e para cima.\n'
        '3. Dobre os cotovelos devagar de volta atrás da cabeça.',
      'triceps_kickback':
        '1. Incline o tronco, braço paralelo ao corpo, cotovelo dobrado.\n'
        '2. Estenda o braço para trás por completo.\n'
        '3. Dobre devagar sem mover o braço.',
      'bench_dips':
        '1. Mãos na borda de um banco atrás de você, pernas à frente.\n'
        '2. Desça dobrando os cotovelos até cerca de 90°.\n'
        '3. Suba até estender os braços.',
      'machine_triceps_dip':
        '1. Sente na máquina e segure as alças laterais.\n'
        '2. Empurre para baixo até estender os braços.\n'
        '3. Deixe subir devagar até cerca de 90° no cotovelo.',
      'single_arm_pushdown':
        '1. Segure uma alça na polia alta, cotovelo junto ao corpo.\n'
        '2. Empurre para baixo até estender o braço.\n'
        '3. Deixe subir devagar, o cotovelo fica no lugar.',
      'diamond_push_up':
        '1. Posição de flexão com as mãos juntas sob o peito formando um losango.\n'
        '2. Desça o peito até as mãos, cotovelos junto ao corpo.\n'
        '3. Suba com o corpo reto.',
      'reverse_wrist_curl':
        '1. Sente-se com os antebraços nas coxas, palmas para baixo, punhos para fora dos joelhos.\n'
        '2. Levante o dorso das mãos o mais alto possível.\n'
        '3. Desça devagar.',
      'hack_squat':
        '1. Suba na plataforma, costas no encosto, ombros sob as almofadas.\n'
        '2. Desça até as coxas ficarem ao menos paralelas à plataforma.\n'
        '3. Suba empurrando com o pé inteiro.',
      'smith_squat':
        '1. Barra na parte alta das costas, pés um pouco à frente da barra.\n'
        '2. Desça com a coluna reta pelo menos até as coxas ficarem paralelas.\n'
        '3. Suba e trave a barra no final.',
      'walking_lunge':
        '1. Segure halteres ao lado do corpo e dê um passo longo à frente.\n'
        '2. Desça o joelho de trás quase até o chão.\n'
        '3. Empurre com o pé da frente e siga direto para o próximo afundo.',
      'reverse_lunge':
        '1. Em pé, halteres ao lado do corpo.\n'
        '2. Dê um passo para trás e desça o joelho de trás quase até o chão.\n'
        '3. Empurre com o pé da frente para voltar. Alterne as pernas.',
      'step_up':
        '1. Fique de frente para um banco ou caixa com halteres.\n'
        '2. Coloque um pé em cima e suba empurrando com essa perna.\n'
        '3. Desça devagar. Alterne ou faça um lado de cada vez.',
      'split_squat':
        '1. Fique em passada longa com halteres nas mãos.\n'
        '2. Desça na vertical até o joelho de trás quase tocar o chão.\n'
        '3. Suba. Termine as repetições e troque de perna.',
      'sumo_squat':
        '1. Pés afastados, pontas para fora, um halter entre as pernas.\n'
        '2. Desça com o tronco ereto, joelhos na direção dos pés.\n'
        '3. Suba e contraia os glúteos.',
      'pistol_squat':
        '1. Em pé em uma perna, a outra estendida à frente.\n'
        '2. Desça com controle o mais fundo possível, braços à frente para equilibrar.\n'
        '3. Suba. No início pode se apoiar em algo.',
      'single_leg_press':
        '1. Sente no leg press com um pé no centro da plataforma.\n'
        '2. Desça até o joelho ficar a cerca de 90°.\n'
        '3. Empurre sem travar o joelho. Troque de perna.',
      'hip_adduction_machine':
        '1. Sente com as almofadas na parte de dentro dos joelhos.\n'
        '2. Feche as pernas.\n'
        '3. Abra devagar de novo.',
      'wall_sit':
        '1. Encoste as costas na parede e deslize para baixo.\n'
        '2. Pare com os joelhos a cerca de 90°, pés abaixo dos joelhos.\n'
        '3. Segure pelo tempo definido, costas coladas na parede.',
      'jump_squat':
        '1. Em pé, pés na largura dos ombros.\n'
        '2. Agache e salte de forma explosiva.\n'
        '3. Aterrisse suave e emende o próximo agachamento.',
      'box_jump':
        '1. Fique de frente para uma caixa estável.\n'
        '2. Balance os braços e salte na caixa, aterrissando suave.\n'
        '3. Fique totalmente em pé e desça caminhando.',
      'seated_leg_curl':
        '1. Sente na máquina, almofada acima dos calcanhares, coxas presas.\n'
        '2. Leve os calcanhares para baixo e para trás o máximo possível.\n'
        '3. Volte devagar.',
      'nordic_curl':
        '1. Ajoelhe com os calcanhares presos sob algo firme.\n'
        '2. Deixe o corpo cair para frente o mais devagar possível, quadril estendido.\n'
        '3. Apare com as mãos e volte puxando com os posteriores.',
      'single_leg_rdl':
        '1. Em pé em uma perna com um halter, joelho levemente flexionado.\n'
        '2. Incline à frente enquanto a perna livre vai para trás, coluna reta.\n'
        '3. Volte empurrando o quadril para frente.',
      'dumbbell_romanian_deadlift':
        '1. Em pé com halteres na frente das coxas, joelhos soltos.\n'
        '2. Leve o quadril para trás e deslize os halteres pelas pernas.\n'
        '3. Pare ao sentir os posteriores alongarem e suba.',
      'stiff_leg_deadlift':
        '1. Em pé com a barra, pernas quase estendidas.\n'
        '2. Incline com a coluna reta descendo a barra junto às pernas.\n'
        '3. Suba contraindo posteriores e glúteos.',
      'stability_ball_leg_curl':
        '1. Deite de costas, calcanhares na bola, quadril elevado.\n'
        '2. Traga a bola para perto dobrando os joelhos.\n'
        '3. Role de volta devagar, quadril sempre elevado.',
      'sumo_deadlift':
        '1. Pés bem afastados, pontas para fora, segure a barra entre as pernas.\n'
        '2. Contraia, empurre os joelhos para fora e suba com a barra junto ao corpo.\n'
        '3. Desça com a coluna reta.',
      'cable_glute_kickback':
        '1. Prenda uma tornozeleira na polia baixa e segure na máquina.\n'
        '2. Leve a perna para trás e para cima contraindo o glúteo.\n'
        '3. Volte devagar sem arquear a lombar.',
      'hip_abduction_machine':
        '1. Sente com as almofadas na parte de fora dos joelhos.\n'
        '2. Abra as pernas o máximo possível.\n'
        '3. Feche devagar.',
      'machine_hip_thrust':
        '1. Apoie a parte alta das costas no encosto e o cinto sobre o quadril.\n'
        '2. Suba o quadril até alinhar joelhos e ombros.\n'
        '3. Contraia os glúteos em cima e desça devagar.',
      'single_leg_glute_bridge':
        '1. Deite de costas, um pé no chão e a outra perna estendida para cima.\n'
        '2. Suba o quadril empurrando com o calcanhar apoiado.\n'
        '3. Desça devagar. Termine e troque de perna.',
      'donkey_kick':
        '1. Fique de quatro, mãos abaixo dos ombros.\n'
        '2. Eleve uma perna dobrada para trás, sola do pé para o teto.\n'
        '3. Desça devagar sem arquear as costas.',
      'fire_hydrant':
        '1. Fique de quatro, coluna reta.\n'
        '2. Eleve uma perna dobrada para o lado até a altura do quadril.\n'
        '3. Desça devagar, quadril nivelado.',
      'banded_lateral_walk':
        '1. Coloque uma miniband acima dos joelhos ou nos tornozelos e flexione levemente os joelhos.\n'
        '2. Caminhe de lado mantendo o elástico tenso.\n'
        '3. Conte os passos para um lado e volte.',
      'cable_pull_through':
        '1. De costas para a polia baixa, corda entre as pernas.\n'
        '2. Incline com a coluna reta deixando a corda ir para trás.\n'
        '3. Empurre o quadril para frente para subir e contraia os glúteos.',
      'seated_calf_raise':
        '1. Sente com a almofada nas coxas, ponta dos pés no degrau.\n'
        '2. Suba os calcanhares o máximo possível.\n'
        '3. Desça devagar até o alongamento completo.',
      'single_leg_calf_raise':
        '1. Fique com um pé na borda de um degrau e segure-se.\n'
        '2. Suba na ponta do pé o mais alto possível.\n'
        '3. Desça o calcanhar abaixo do degrau para alongar.',
      'leg_press_calf_raise':
        '1. Sente no leg press com a ponta dos pés na borda de baixo da plataforma.\n'
        '2. Empurre a plataforma estendendo os pés.\n'
        '3. Deixe voltar devagar para alongar. Joelhos estendidos.',
      'sit_up':
        '1. Deite de costas, joelhos dobrados, pés no chão.\n'
        '2. Suba até se sentar.\n'
        '3. Desça devagar.',
      'decline_sit_up':
        '1. Prenda os pés no banco declinado e deite.\n'
        '2. Suba até o tronco ficar na vertical.\n'
        '3. Desça devagar. Segure uma anilha para mais carga.',
      'bicycle_crunch':
        '1. Deite de costas, mãos perto da cabeça, pernas elevadas.\n'
        '2. Leve um cotovelo ao joelho oposto enquanto estende a outra perna.\n'
        '3. Alterne os lados como se pedalasse.',
      'reverse_crunch':
        '1. Deite de costas, joelhos a 90°, braços no chão.\n'
        '2. Tire o quadril do chão e traga os joelhos ao peito.\n'
        '3. Desça devagar sem balançar.',
      'lying_leg_raise':
        '1. Deite de costas, pernas estendidas, lombar colada ao chão.\n'
        '2. Suba as pernas até apontarem para o teto.\n'
        '3. Desça devagar sem arquear a lombar.',
      'captains_chair_knee_raise':
        '1. Apoie os antebraços nas almofadas e as costas no encosto.\n'
        '2. Traga os joelhos ao peito.\n'
        '3. Desça devagar sem balançar.',
      'ab_wheel_rollout':
        '1. Ajoelhe e segure a roda abaixo dos ombros.\n'
        '2. Role para frente o máximo possível sem deixar a lombar cair.\n'
        '3. Volte puxando com o abdômen.',
      'russian_twist':
        '1. Sente com o tronco levemente inclinado para trás, pés elevados ou no chão.\n'
        '2. Gire o tronco e toque o chão ao lado do quadril.\n'
        '3. Gire para o outro lado. Segure um peso para mais carga.',
      'v_up':
        '1. Deite de costas, braços acima da cabeça, pernas estendidas.\n'
        '2. Suba braços e pernas ao mesmo tempo e toque os pés.\n'
        '3. Desça devagar.',
      'hollow_hold':
        '1. Deite de costas e pressione a lombar no chão.\n'
        '2. Tire um pouco do chão os ombros e as pernas estendidas.\n'
        '3. Segure pelo tempo definido sem arquear a lombar.',
      'pallof_press':
        '1. De lado para um cabo na altura do peito, alça junto ao peito.\n'
        '2. Empurre a alça reto para frente sem deixar o corpo girar.\n'
        '3. Volte ao peito. Faça os dois lados.',
      'cable_woodchopper':
        '1. De lado para a polia alta, segure a alça com as duas mãos.\n'
        '2. Puxe na diagonal para baixo cruzando o corpo e girando o tronco.\n'
        '3. Volte devagar. Faça os dois lados.',
      'plank_shoulder_tap':
        '1. Fique em prancha alta, pés levemente afastados.\n'
        '2. Toque o ombro oposto com uma mão sem mexer o quadril.\n'
        '3. Troque de mão.',
      'bird_dog':
        '1. Fique de quatro, coluna reta.\n'
        '2. Estenda um braço à frente e a perna oposta para trás.\n'
        '3. Segure um instante, volte e troque de lado.',
      'power_clean':
        '1. Fique sobre a barra, pegada logo por fora dos joelhos, coluna reta.\n'
        '2. Puxe a barra de forma explosiva junto ao corpo e receba na frente dos ombros.\n'
        '3. Fique em pé e desça a barra. Aprenda a técnica com pouco peso.',
      'thruster':
        '1. Segure a barra na frente dos ombros.\n'
        '2. Agache e, ao subir, empurre a barra acima da cabeça em um só movimento.\n'
        '3. Volte a barra aos ombros e emende o próximo agachamento.',
      'turkish_get_up':
        '1. Deite de costas segurando um kettlebell para cima com um braço.\n'
        '2. Levante passo a passo olhando para o kettlebell, braço estendido.\n'
        '3. Volte ao chão pelo mesmo caminho. Faça os dois lados.',
      'bear_crawl':
        '1. Apoie mãos e pés, joelhos logo acima do chão, coluna reta.\n'
        '2. Avance movendo ao mesmo tempo mão e pé opostos.\n'
        '3. Mantenha o quadril baixo pelo tempo definido.',
      'high_knees':
        '1. Corra no lugar levando os joelhos à altura do quadril.\n'
        '2. Use os braços e fique na ponta dos pés.\n'
        '3. Mantenha ritmo rápido pelo tempo definido.',
      'jump_rope':
        '1. Segure os cabos na altura do quadril, cotovelos perto do corpo.\n'
        '2. Gire a corda com os punhos e pule só o necessário.\n'
        '3. Aterrisse suave na ponta dos pés pelo tempo definido.',
      'rowing_machine':
        '1. Prenda os pés e segure o puxador com os braços estendidos.\n'
        '2. Empurre com as pernas, incline um pouco para trás e puxe até as costelas baixas.\n'
        '3. Volte na ordem inversa: braços, tronco, pernas. Ritmo constante.',
      'stationary_bike':
        '1. Ajuste o banco para o joelho ficar levemente dobrado embaixo.\n'
        '2. Pedale em ritmo constante com a coluna reta.\n'
        '3. Ajuste a resistência ao seu objetivo pelo tempo definido.',
      'treadmill_run':
        '1. Comece caminhando e aumente a velocidade aos poucos.\n'
        '2. Corra com o tronco ereto e os ombros soltos, pisando sob o quadril.\n'
        '3. Reduza para caminhada antes de descer.',
      'elliptical':
        '1. Suba nos pedais e segure as alças móveis.\n'
        '2. Movimente-se de forma fluida empurrando e puxando também com os braços.\n'
        '3. Mantenha ritmo constante pelo tempo definido.',
      'stair_climber':
        '1. Suba e escolha uma velocidade que consiga manter.\n'
        '2. Suba com o tronco ereto, use o corrimão só para equilíbrio.\n'
        '3. Continue pelo tempo definido.',
      'air_bike':
        '1. Sente e segure as alças móveis.\n'
        '2. Pedale empurrando e puxando as alças ao mesmo tempo.\n'
        '3. Quanto mais forte, mais o ventilador freia. Pelo tempo definido.',
    },
    routineNames: {
      'home_upper': 'Membros superiores em 5 minutos',
      'home_lower': 'Membros inferiores em 5 minutos',
      'home_full': 'Corpo inteiro em 5 minutos',
    },
    programNames: {
      'full_body': 'Full body (iniciante)',
      'upper_lower': 'Superior / Inferior',
      'ppl': 'Push / Pull / Legs',
      'full_body_2x': 'Full body 2× por semana',
      'dumbbell_home': 'Halteres em casa',
      'strength_5x5': 'Força 5×5',
      'circuit': 'Treino em circuito (resistência)',
      'full_body_variation': 'Full body – variação',
      'bodyweight_home': 'Peso corporal em casa',
      'machines': 'Máquinas (iniciante)',
      'upper_lower_variation': 'Superior / Inferior – variação',
      'ppl_variation': 'Push / Pull / Legs – variação',
      'strength_dup': 'Força – ondas semanais',
      'conditioning_intervals': 'Condicionamento – intervalos',
      'phul': 'Força + volume (PHUL)',
      'strength_advanced': 'Força – 4 dias (avançado)',
      'ppl_6x': 'Push / Pull / Legs 6× por semana',
    },
    programDescriptions: {
      'full_body':
        '3× por semana, alternando os treinos A e B. Ideal para os primeiros meses.',
      'upper_lower':
        '4× por semana: superiores seg + qui, inferiores ter + sex.',
      'ppl': '3× por semana: push seg, pull qua, legs sex.',
      'full_body_2x':
        'Para semanas corridas: 2 treinos de cerca de uma hora, seg + qui. Cada músculo 2× por semana.',
      'dumbbell_home':
        '3× por semana com um par de halteres e um colchonete, alternando A e B. Sem academia.',
      'strength_5x5':
        '3× por semana, alternando A e B: 5 séries de 5 nos exercícios grandes. Quando você completa todas as séries de 5, a carga sobe.',
      'circuit':
        '3× por semana, alternando A e B: exercícios em circuito um após o outro, descansos curtos, muitas repetições. Para resistência e condicionamento.',
      'full_body_variation':
        '3× por semana, alternando C e D. A mesma estrutura do Full body (iniciante) com outros exercícios – troque a cada 6–8 semanas.',
      'bodyweight_home':
        '3× por semana, alternando A e B, sem equipamento – só um tapete (e uma mesa firme para as remadas). Para começar e para viagens.',
      'machines':
        '3× por semana, alternando A e B, nas máquinas da academia: fáceis de aprender e seguras mesmo sem parceiro. Um bom primeiro passo antes dos pesos livres.',
      'upper_lower_variation':
        '4× por semana como Superior / Inferior, com outros exercícios (supino inclinado, agachamento frontal, hip thrust). Troque a cada 6–8 semanas.',
      'ppl_variation':
        '3× por semana como Push / Pull / Legs, com outros exercícios (primeiro desenvolvimento, remada curvada, agachamento hack). Troque a cada 6–8 semanas.',
      'strength_dup':
        '3× por semana: dia pesado (séries de 3), dia de volume (6–8 repetições) e dia médio (séries de 5). Variar a carga dentro da semana mantém a força a crescer mesmo depois do primeiro ano.',
      'conditioning_intervals':
        '3× por semana, alternando A e B: pares de um exercício de força e um de cardio seguidos, e no fim um bloco de cardio contínuo. Para condicionamento, resistência e perda de gordura.',
      'phul':
        '4× por semana: dias pesados de superiores e inferiores para força (seg, ter) e dias com mais repetições para músculo (qui, sex). Cerca de 12–16 séries por músculo por semana.',
      'strength_advanced':
        '4× por semana, um exercício principal por dia (agachamento, supino, levantamento terra, desenvolvimento): séries pesadas de 3, uma variação relacionada e acessórios para os pontos fracos.',
      'ppl_6x':
        'Seg–sáb: Push, Pull, Legs, depois Push B, Pull B, Legs B. Cada músculo 2× por semana com volume alto – para quem tem experiência e boa recuperação.',
    },
    planNames: {
      'Full body A': 'Full body A',
      'Full body B': 'Full body B',
      'Upper body': 'Superiores',
      'Lower body': 'Inferiores',
      'Push': 'Push',
      'Pull': 'Pull',
      'Legs': 'Legs',
      'Full body 2× A': 'Full body 2× A',
      'Full body 2× B': 'Full body 2× B',
      'Dumbbells A': 'Halteres A',
      'Dumbbells B': 'Halteres B',
      '5×5 A': '5×5 A',
      '5×5 B': '5×5 B',
      'Circuit A': 'Circuito A',
      'Circuit B': 'Circuito B',
      'Full body C': 'Full body C',
      'Full body D': 'Full body D',
      'Bodyweight A': 'Peso corporal A',
      'Bodyweight B': 'Peso corporal B',
      'Machines A': 'Máquinas A',
      'Machines B': 'Máquinas B',
      'Upper body B': 'Superiores B',
      'Lower body B': 'Inferiores B',
      'Push B': 'Push B',
      'Pull B': 'Pull B',
      'Legs B': 'Legs B',
      'Strength: heavy day': 'Força: dia pesado',
      'Strength: volume day': 'Força: dia de volume',
      'Strength: medium day': 'Força: dia médio',
      'Intervals A': 'Intervalos A',
      'Intervals B': 'Intervalos B',
      'Upper power': 'Superiores – força',
      'Lower power': 'Inferiores – força',
      'Upper hypertrophy': 'Superiores – volume',
      'Lower hypertrophy': 'Inferiores – volume',
      'Strength: squat': 'Força: agachamento',
      'Strength: bench': 'Força: supino',
      'Strength: deadlift': 'Força: levantamento terra',
      'Strength: overhead press': 'Força: desenvolvimento',
    },
  ),
  'it': (
    exerciseNames: {
      'bench_press': 'Panca piana',
      'incline_dumbbell_press': 'Panca inclinata con manubri',
      'cable_fly': 'Croci ai cavi',
      'push_up': 'Flessioni',
      'deadlift': 'Stacco da terra',
      'barbell_row': 'Rematore con bilanciere',
      'lat_pulldown': 'Lat machine',
      'pull_up': 'Trazioni alla sbarra',
      'overhead_press': 'Military press',
      'lateral_raise': 'Alzate laterali',
      'pike_push_up': 'Pike push-up',
      'dumbbell_curl': 'Curl con manubri',
      'triceps_pushdown': 'Pushdown ai cavi',
      'dips': 'Dip alle parallele',
      'back_squat': 'Squat',
      'leg_press': 'Leg press',
      'romanian_deadlift': 'Stacco rumeno',
      'bodyweight_squat': 'Squat a corpo libero',
      'lunge': 'Affondi',
      'hip_thrust': 'Hip thrust',
      'glute_bridge': 'Ponte glutei',
      'plank': 'Plank',
      'crunch': 'Crunch',
      'mountain_climber': 'Mountain climber',
      'jumping_jack': 'Jumping jack',
      'dumbbell_bench_press': 'Panca piana con manubri',
      'incline_bench_press': 'Panca inclinata',
      'chest_press_machine': 'Chest press',
      'pec_deck': 'Pectoral machine',
      'seated_cable_row': 'Pulley basso',
      'one_arm_dumbbell_row': 'Rematore con manubrio a un braccio',
      'chin_up': 'Trazioni presa supina',
      'dumbbell_shoulder_press': 'Lento avanti con manubri',
      'rear_delt_fly': 'Alzate posteriori',
      'face_pull': 'Face pull',
      'barbell_curl': 'Curl con bilanciere',
      'hammer_curl': 'Hammer curl',
      'cable_curl': 'Curl ai cavi',
      'skull_crusher': 'French press',
      'overhead_triceps_extension': 'Estensioni tricipiti sopra la testa',
      'close_grip_bench_press': 'Panca presa stretta',
      'front_squat': 'Front squat',
      'goblet_squat': 'Goblet squat',
      'bulgarian_split_squat': 'Squat bulgaro',
      'leg_extension': 'Leg extension',
      'leg_curl': 'Leg curl',
      'calf_raise': 'Calf raise',
      'hanging_leg_raise': 'Sollevamento gambe alla sbarra',
      'cable_crunch': 'Crunch ai cavi',
      'dead_bug': 'Dead bug',
      'side_plank': 'Plank laterale',
      'burpee': 'Burpee',
      'kettlebell_swing': 'Swing con kettlebell',
      'weighted_pull_up': 'Trazioni zavorrate',
      'weighted_dips': 'Dip alle parallele zavorrati',
      'barbell_shrug': 'Scrollate con bilanciere',
      'dumbbell_shrug': 'Scrollate con manubri',
      'wrist_curl': 'Curl per i polsi',
      'reverse_curl': 'Curl inverso',
      'dead_hang': 'Sospensione alla sbarra',
      'back_extension': 'Iperestensioni',
      'good_morning': 'Good morning',
      'superman': 'Superman',
      'decline_bench_press': 'Panca declinata',
      'smith_bench_press': 'Panca piana al multipower',
      'dumbbell_fly': 'Croci con manubri',
      'incline_dumbbell_fly': 'Croci su panca inclinata',
      'low_to_high_cable_fly': 'Croci ai cavi dal basso verso l’alto',
      'incline_chest_press_machine': 'Chest press inclinata',
      'chest_dips': 'Dip per il petto',
      'incline_push_up': 'Flessioni inclinate',
      'decline_push_up': 'Flessioni declinate',
      'dumbbell_floor_press': 'Floor press con manubri',
      't_bar_row': 'Rematore T-bar',
      'pendlay_row': 'Rematore Pendlay',
      'machine_row': 'Rematore alla macchina',
      'chest_supported_row': 'Rematore con manubri su panca inclinata',
      'close_grip_lat_pulldown': 'Lat machine presa stretta',
      'straight_arm_pulldown': 'Pulldown a braccia tese',
      'band_assisted_pull_up': 'Trazioni assistite con elastico',
      'inverted_row': 'Rematore inverso',
      'neutral_grip_pull_up': 'Trazioni presa neutra',
      'rack_pull': 'Rack pull',
      'trap_bar_deadlift': 'Stacco con trap bar',
      'single_arm_cable_row': 'Rematore al cavo a un braccio',
      'dumbbell_pullover': 'Pullover con manubrio',
      'renegade_row': 'Renegade row',
      'arnold_press': 'Arnold press',
      'shoulder_press_machine': 'Shoulder press alla macchina',
      'push_press': 'Push press',
      'cable_lateral_raise': 'Alzate laterali al cavo',
      'machine_lateral_raise': 'Alzate laterali alla macchina',
      'front_raise': 'Alzate frontali con manubri',
      'upright_row': 'Tirate al mento',
      'reverse_pec_deck': 'Pec deck inversa',
      'band_pull_apart': 'Band pull-apart',
      'handstand_push_up': 'Flessioni in verticale',
      'landmine_press': 'Landmine press',
      'preacher_curl': 'Curl alla panca Scott',
      'concentration_curl': 'Curl di concentrazione',
      'incline_dumbbell_curl': 'Curl su panca inclinata',
      'ez_bar_curl': 'Curl con bilanciere EZ',
      'rope_hammer_curl': 'Hammer curl alla corda',
      'machine_biceps_curl': 'Curl bicipiti alla macchina',
      'band_curl': 'Curl con elastico',
      'rope_pushdown': 'Pushdown alla corda',
      'overhead_cable_extension': 'Estensioni tricipiti sopra la testa al cavo',
      'triceps_kickback': 'Kickback per tricipiti',
      'bench_dips': 'Dip su panca',
      'machine_triceps_dip': 'Dip alla macchina',
      'single_arm_pushdown': 'Pushdown al cavo a un braccio',
      'diamond_push_up': 'Flessioni a diamante',
      'reverse_wrist_curl': 'Curl inverso per i polsi',
      'hack_squat': 'Hack squat',
      'smith_squat': 'Squat al multipower',
      'walking_lunge': 'Affondi camminati',
      'reverse_lunge': 'Affondi all’indietro',
      'step_up': 'Step-up',
      'split_squat': 'Split squat',
      'sumo_squat': 'Squat sumo con manubrio',
      'pistol_squat': 'Pistol squat',
      'single_leg_press': 'Leg press a una gamba',
      'hip_adduction_machine': 'Macchina adduttori',
      'wall_sit': 'Sedia al muro',
      'jump_squat': 'Squat jump',
      'box_jump': 'Box jump',
      'seated_leg_curl': 'Leg curl da seduto',
      'nordic_curl': 'Nordic curl',
      'single_leg_rdl': 'Stacco rumeno a una gamba',
      'dumbbell_romanian_deadlift': 'Stacco rumeno con manubri',
      'stiff_leg_deadlift': 'Stacco a gambe tese',
      'stability_ball_leg_curl': 'Leg curl con fitball',
      'sumo_deadlift': 'Stacco sumo',
      'cable_glute_kickback': 'Kickback glutei al cavo',
      'hip_abduction_machine': 'Macchina abduttori',
      'machine_hip_thrust': 'Hip thrust alla macchina',
      'single_leg_glute_bridge': 'Ponte glutei a una gamba',
      'donkey_kick': 'Donkey kick',
      'fire_hydrant': 'Fire hydrant',
      'banded_lateral_walk': 'Passi laterali con elastico',
      'cable_pull_through': 'Pull-through al cavo',
      'seated_calf_raise': 'Calf raise da seduto',
      'single_leg_calf_raise': 'Calf raise a una gamba',
      'leg_press_calf_raise': 'Calf raise alla leg press',
      'sit_up': 'Sit-up',
      'decline_sit_up': 'Sit-up su panca declinata',
      'bicycle_crunch': 'Crunch bicicletta',
      'reverse_crunch': 'Crunch inverso',
      'lying_leg_raise': 'Sollevamento gambe da sdraiato',
      'captains_chair_knee_raise': 'Knee raise alla sedia romana',
      'ab_wheel_rollout': 'Ruota per addominali',
      'russian_twist': 'Russian twist',
      'v_up': 'V-up',
      'hollow_hold': 'Hollow hold',
      'pallof_press': 'Pallof press',
      'cable_woodchopper': 'Woodchopper al cavo',
      'plank_shoulder_tap': 'Plank con tocco delle spalle',
      'bird_dog': 'Bird dog',
      'power_clean': 'Girata al petto (power clean)',
      'thruster': 'Thruster',
      'turkish_get_up': 'Turkish get-up',
      'bear_crawl': 'Camminata dell’orso',
      'high_knees': 'Skip a ginocchia alte',
      'jump_rope': 'Salto con la corda',
      'rowing_machine': 'Vogatore',
      'stationary_bike': 'Cyclette',
      'treadmill_run': 'Corsa sul tapis roulant',
      'elliptical': 'Ellittica',
      'stair_climber': 'Stepper a gradini',
      'air_bike': 'Air bike',
    },
    exerciseInstructions: {
      'bench_press':
        '1. Sdraiati sulla panca con gli occhi sotto il bilanciere e i piedi ben appoggiati a terra.\n'
        '2. Impugna il bilanciere poco più largo delle spalle e stringi le scapole.\n'
        '3. Scendi con controllo a metà petto, gomiti a circa 45° dal busto.\n'
        '4. Spingi fino a braccia tese senza sollevare i glutei.',
      'incline_dumbbell_press':
        '1. Inclina la panca a 30–45°, manubri all’altezza del petto.\n'
        '2. Tieni le scapole indietro e i piedi a terra.\n'
        '3. Spingi in alto avvicinando leggermente i manubri, poi scendi lentamente fino al petto.',
      'cable_fly':
        '1. Mettiti in piedi tra i cavi, gomiti leggermente piegati.\n'
        '2. Porta le maniglie una verso l’altra con un movimento ad arco davanti al petto.\n'
        '3. Torna lentamente fino a sentire l’allungamento, gomiti fissi.',
      'push_up':
        '1. Mani poco più larghe delle spalle, corpo in linea retta.\n'
        '2. Scendi con il petto vicino al pavimento, gomiti a circa 45° dal busto.\n'
        '3. Risali spingendo, tieni addome e glutei contratti.',
      'deadlift':
        '1. Bilanciere sopra il centro del piede, piedi alla larghezza delle anche.\n'
        '2. Piegati alle anche, afferra il bilanciere, schiena neutra.\n'
        '3. Spingi il pavimento e alzati tenendo il bilanciere vicino alle gambe.\n'
        '4. Scendi con controllo portando le anche indietro.',
      'barbell_row':
        '1. Piegati in avanti a circa 45°, schiena dritta, ginocchia leggermente flesse.\n'
        '2. Tira il bilanciere verso la parte bassa del petto o l’addome.\n'
        '3. Stringi le scapole, poi scendi lentamente.',
      'lat_pulldown':
        '1. Impugna la barra poco più larga delle spalle, cosce sotto i rulli.\n'
        '2. Tira la barra verso la parte alta del petto, gomiti in basso e indietro.\n'
        '3. Torna lentamente a braccia tese senza dondolare.',
      'pull_up':
        '1. Appenditi alla sbarra con presa prona, spalle attive.\n'
        '2. Tirati su finché il mento supera la sbarra.\n'
        '3. Scendi con controllo fino a braccia completamente distese.',
      'overhead_press':
        '1. Bilanciere appoggiato sulla parte anteriore delle spalle, presa appena fuori dalle spalle.\n'
        '2. Contrai glutei e addome, spingi il bilanciere dritto verso l’alto.\n'
        '3. Sposta leggermente indietro la testa al passaggio del bilanciere, blocca sopra la testa.',
      'lateral_raise':
        '1. In piedi, schiena dritta, manubri lungo i fianchi, gomiti leggermente piegati.\n'
        '2. Solleva lateralmente fino all’altezza delle spalle.\n'
        '3. Scendi lentamente, senza slanci.',
      'pike_push_up':
        '1. Parti in posizione da flessioni e solleva le anche formando una V rovesciata.\n'
        '2. Abbassa la testa verso il pavimento tra le mani.\n'
        '3. Risali spingendo con le spalle.',
      'dumbbell_curl':
        '1. In piedi, schiena dritta, gomiti lungo i fianchi.\n'
        '2. Fletti i manubri verso l’alto senza muovere i gomiti.\n'
        '3. Scendi lentamente fino a braccia tese.',
      'triceps_pushdown':
        '1. In piedi davanti al cavo, gomiti bloccati lungo i fianchi.\n'
        '2. Spingi la maniglia verso il basso fino a braccia tese.\n'
        '3. Torna lentamente, gomiti fermi.',
      'dips':
        '1. Sostieniti sulle parallele a braccia tese.\n'
        '2. Scendi finché le braccia sono circa parallele al pavimento.\n'
        '3. Risali spingendo, senza far cadere le spalle in avanti.',
      'back_squat':
        '1. Bilanciere sulla parte alta della schiena, piedi alla larghezza delle spalle, punte leggermente in fuori.\n'
        '2. Contrai l’addome e scendi sedendoti tra i talloni.\n'
        '3. Le ginocchia seguono le punte, la schiena resta neutra.\n'
        '4. Risali spingendo con tutto il piede.',
      'leg_press':
        '1. Piedi alla larghezza delle spalle al centro della pedana.\n'
        '2. Scendi finché le ginocchia sono a circa 90°, zona lombare appoggiata allo schienale.\n'
        '3. Spingi senza bloccare con forza le ginocchia.',
      'romanian_deadlift':
        '1. In piedi con il bilanciere, ginocchia leggermente flesse.\n'
        '2. Porta le anche indietro e fai scendere il bilanciere lungo le gambe.\n'
        '3. Fermati quando senti l’allungamento dei femorali, schiena dritta.\n'
        '4. Risali spingendo le anche in avanti.',
      'bodyweight_squat':
        '1. Piedi alla larghezza delle spalle, braccia in avanti per l’equilibrio.\n'
        '2. Scendi più in basso che puoi con la schiena dritta.\n'
        '3. Risali spingendo sui talloni.',
      'lunge':
        '1. Fai un passo avanti e scendi finché entrambe le ginocchia sono a circa 90°.\n'
        '2. Il ginocchio anteriore resta sopra il piede, busto eretto.\n'
        '3. Torna alla posizione iniziale spingendo e cambia gamba.',
      'hip_thrust':
        '1. Parte alta della schiena sulla panca, bilanciere sulle anche.\n'
        '2. Spingi sui talloni e solleva le anche finché il corpo è in linea.\n'
        '3. Stringi i glutei in alto, scendi con controllo.',
      'glute_bridge':
        '1. Sdraiati sulla schiena, ginocchia piegate, piedi a terra.\n'
        '2. Solleva le anche contraendo i glutei.\n'
        '3. Mantieni un attimo in alto e scendi lentamente.',
      'plank':
        '1. Avambracci sotto le spalle, corpo in linea retta.\n'
        '2. Contrai addome e glutei, non lasciar cadere le anche.\n'
        '3. Respira regolarmente e mantieni la posizione.',
      'crunch':
        '1. Sdraiati sulla schiena, ginocchia piegate, mani vicino alla testa.\n'
        '2. Solleva le spalle da terra usando gli addominali.\n'
        '3. Scendi lentamente, non tirare il collo.',
      'mountain_climber':
        '1. Parti in posizione da flessioni.\n'
        '2. Porta le ginocchia verso il petto, una dopo l’altra.\n'
        '3. Tieni le anche basse e il ritmo costante.',
      'jumping_jack':
        '1. In piedi, piedi uniti, braccia lungo i fianchi.\n'
        '2. Salta aprendo le gambe e porta le braccia sopra la testa.\n'
        '3. Torna con un salto e ripeti a ritmo costante.',
      'dumbbell_bench_press':
        '1. Sdraiati su una panca piana con i manubri all’altezza del petto.\n'
        '2. Spingi in alto avvicinando leggermente i manubri.\n'
        '3. Scendi lentamente finché senti l’allungamento del petto.',
      'incline_bench_press':
        '1. Panca a 30–45°, presa poco più larga delle spalle.\n'
        '2. Porta il bilanciere verso la parte alta del petto.\n'
        '3. Spingi in alto, scapole indietro.',
      'chest_press_machine':
        '1. Regola il sedile in modo che le maniglie siano a metà petto.\n'
        '2. Spingi in avanti fino a braccia quasi tese.\n'
        '3. Torna lentamente, schiena appoggiata allo schienale.',
      'pec_deck':
        '1. Siediti con la schiena sullo schienale, gomiti leggermente piegati.\n'
        '2. Porta le maniglie una verso l’altra davanti al petto.\n'
        '3. Torna lentamente fino a un allungamento confortevole.',
      'seated_cable_row':
        '1. Siediti con il busto eretto, piedi sulla pedana, ginocchia leggermente flesse.\n'
        '2. Tira la maniglia verso l’addome, gomiti vicini al corpo.\n'
        '3. Stringi le scapole, torna lentamente senza curvare la schiena.',
      'one_arm_dumbbell_row':
        '1. Un ginocchio e una mano sulla panca, schiena piatta.\n'
        '2. Tira il manubrio verso l’anca.\n'
        '3. Scendi lentamente fino al completo allungamento.',
      'chin_up':
        '1. Appenditi alla sbarra con presa supina alla larghezza delle spalle.\n'
        '2. Tirati su finché il mento supera la sbarra.\n'
        '3. Scendi con controllo fino a braccia completamente distese.',
      'dumbbell_shoulder_press':
        '1. Su una panca o in piedi, manubri all’altezza delle spalle.\n'
        '2. Spingi sopra la testa senza inarcare la zona lombare.\n'
        '3. Scendi lentamente fino alle spalle.',
      'rear_delt_fly':
        '1. Piegati in avanti con la schiena piatta, manubri verso il basso.\n'
        '2. Apri le braccia lateralmente con i gomiti leggermente piegati.\n'
        '3. Scendi lentamente, senza slanci.',
      'face_pull':
        '1. Corda all’altezza della testa, impugnala con i pollici verso di te.\n'
        '2. Tira verso il viso, gomiti alti e larghi.\n'
        '3. Stringi la parte alta della schiena, torna lentamente.',
      'barbell_curl':
        '1. In piedi, schiena dritta, presa supina alla larghezza delle spalle.\n'
        '2. Fletti il bilanciere verso l’alto senza dondolare con il corpo.\n'
        '3. Scendi lentamente fino a braccia tese.',
      'hammer_curl':
        '1. Impugna i manubri con i palmi rivolti uno verso l’altro.\n'
        '2. Fletti verso l’alto, gomiti lungo i fianchi.\n'
        '3. Scendi lentamente.',
      'cable_curl':
        '1. In piedi di fronte al cavo basso, gomiti lungo i fianchi.\n'
        '2. Fletti la maniglia fino alle spalle.\n'
        '3. Scendi lentamente, mantieni la tensione costante.',
      'skull_crusher':
        '1. Sdraiati sulla panca, bilanciere sopra il petto a braccia tese.\n'
        '2. Piega solo i gomiti e porta il bilanciere verso la fronte.\n'
        '3. Torna a braccia tese, gomiti rivolti verso l’alto.',
      'overhead_triceps_extension':
        '1. Tieni un manubrio sopra la testa con entrambe le mani.\n'
        '2. Abbassalo dietro la testa piegando i gomiti.\n'
        '3. Torna a braccia tese, gomiti vicini alla testa.',
      'close_grip_bench_press':
        '1. Sdraiati sulla panca, presa circa alla larghezza delle spalle.\n'
        '2. Porta il bilanciere verso la parte bassa del petto, gomiti vicini al corpo.\n'
        '3. Spingi in alto estendendo i gomiti.',
      'front_squat':
        '1. Bilanciere sulla parte anteriore delle spalle, gomiti alti.\n'
        '2. Scendi in squat con il busto eretto.\n'
        '3. Risali spingendo, tieni i gomiti alti per tutto il tempo.',
      'goblet_squat':
        '1. Tieni un kettlebell o un manubrio al petto.\n'
        '2. Scendi in squat tra le ginocchia con la schiena dritta.\n'
        '3. Risali spingendo sui talloni.',
      'bulgarian_split_squat':
        '1. Piede posteriore sulla panca, piede anteriore un passo avanti.\n'
        '2. Scendi finché la coscia anteriore è circa parallela al pavimento.\n'
        '3. Risali spingendo con il piede anteriore, poi cambia gamba.',
      'leg_extension':
        '1. Regola il rullo appena sopra le caviglie.\n'
        '2. Estendi le gambe fino a tenderle.\n'
        '3. Scendi lentamente con controllo.',
      'leg_curl':
        '1. Regola il rullo appena sopra i talloni.\n'
        '2. Fletti i talloni verso i glutei.\n'
        '3. Torna lentamente, non lasciar cadere il peso.',
      'calf_raise':
        '1. Avampiedi sul bordo, talloni liberi.\n'
        '2. Sali il più in alto possibile sulle punte.\n'
        '3. Scendi lentamente fino all’allungamento.',
      'hanging_leg_raise':
        '1. Appenditi alla sbarra, spalle attive.\n'
        '2. Solleva le gambe o le ginocchia usando gli addominali, evita di dondolare.\n'
        '3. Scendi lentamente.',
      'cable_crunch':
        '1. In ginocchio di fronte al cavo, corda all’altezza della testa.\n'
        '2. Fletti il busto verso il basso arrotondando la colonna, anche ferme.\n'
        '3. Torna lentamente.',
      'dead_bug':
        '1. Sdraiati sulla schiena, braccia in alto, ginocchia a 90°.\n'
        '2. Abbassa braccio e gamba opposti, zona lombare a terra.\n'
        '3. Torna e cambia lato.',
      'side_plank':
        '1. Sdraiati su un fianco, gomito sotto la spalla.\n'
        '2. Solleva le anche in modo che il corpo formi una linea retta.\n'
        '3. Mantieni, poi cambia lato.',
      'burpee':
        '1. Da in piedi, accosciati e appoggia le mani a terra.\n'
        '2. Porta i piedi indietro con un salto in posizione di plank, se vuoi fai una flessione.\n'
        '3. Riporta i piedi in avanti con un salto e salta verso l’alto.',
      'kettlebell_swing':
        '1. Kettlebell davanti a te, piedi poco più larghi delle anche.\n'
        '2. Portalo indietro tra le gambe piegandoti alle anche.\n'
        '3. Spingi le anche in avanti con decisione e fai oscillare il kettlebell fino all’altezza del petto, braccia rilassate.',
      'weighted_pull_up':
        '1. Aggancia un disco a una cintura da zavorra o stringi un manubrio tra i piedi.\n'
        '2. Appenditi alla sbarra con presa prona, spalle attive.\n'
        '3. Tirati su senza slancio finché il mento supera la sbarra.\n'
        '4. Scendi con controllo fino a braccia completamente distese. Registra solo il peso aggiunto.',
      'weighted_dips':
        '1. Aggancia un disco a una cintura da zavorra o stringi un manubrio tra i piedi.\n'
        '2. Sostieniti sulle parallele a braccia tese.\n'
        '3. Scendi finché le braccia sono circa parallele al pavimento.\n'
        '4. Risali spingendo, senza far cadere le spalle in avanti. Registra solo il peso aggiunto.',
      'barbell_shrug':
        '1. In piedi, tieni il bilanciere a braccia tese, presa alla larghezza delle spalle.\n'
        '2. Solleva le spalle in verticale verso le orecchie, braccia tese.\n'
        '3. Fermati in alto e scendi lentamente. Non ruotare le spalle.',
      'dumbbell_shrug':
        '1. In piedi, un manubrio per mano lungo i fianchi, palmi verso il corpo.\n'
        '2. Solleva le spalle in verticale il più in alto possibile.\n'
        '3. Tieni un attimo e scendi con controllo.',
      'wrist_curl':
        '1. Siediti con gli avambracci sulle cosce o su una panca, palmi in su, polsi oltre il bordo.\n'
        '2. Lascia rotolare i manubri verso la punta delle dita.\n'
        '3. Fletti i polsi il più in alto possibile, avambracci fermi.',
      'reverse_curl':
        '1. In piedi, impugna il bilanciere in presa prona alla larghezza delle spalle.\n'
        '2. Fletti verso l’alto con i gomiti lungo i fianchi e i polsi dritti.\n'
        '3. Scendi lentamente fino a braccia tese.',
      'dead_hang':
        '1. Afferra la sbarra in presa prona alla larghezza delle spalle.\n'
        '2. Appenditi a braccia tese, piedi sollevati, corpo fermo.\n'
        '3. Tieni per il tempo previsto con le spalle leggermente attive.',
      'back_extension':
        '1. Regola il cuscino appena sotto le anche e blocca i talloni.\n'
        '2. Scendi con il busto a schiena dritta finché senti l’allungamento dei femorali.\n'
        '3. Risali fino all’allineamento con le gambe, senza inarcarti. Tieni un disco per più carico.',
      'good_morning':
        '1. Bilanciere sulla parte alta della schiena come nello squat, piedi alla larghezza delle anche, ginocchia morbide.\n'
        '2. Porta le anche indietro e piegati a schiena dritta finché il busto è quasi orizzontale.\n'
        '3. Spingi le anche in avanti per tornare su. Inizia con poco peso.',
      'superman':
        '1. Sdraiati a pancia in giù con le braccia tese oltre la testa.\n'
        '2. Solleva insieme braccia, petto e gambe da terra.\n'
        '3. Tieni un secondo in alto e scendi lentamente.',
      'decline_bench_press':
        '1. Blocca le gambe sulla panca declinata, presa poco più larga delle spalle.\n'
        '2. Scendi con il bilanciere in controllo verso la parte bassa del petto.\n'
        '3. Spingi fino a braccia tese, scapole addotte.',
      'smith_bench_press':
        '1. Posiziona la panca in modo che il bilanciere arrivi a metà petto.\n'
        '2. Sgancia il bilanciere e scendi in controllo al petto.\n'
        '3. Spingi senza bloccare di colpo i gomiti e alla fine riaggancia.',
      'dumbbell_fly':
        '1. Sdraiati su una panca piana, manubri sopra il petto, gomiti leggermente piegati.\n'
        '2. Apri le braccia in un ampio arco fino a sentire l’allungamento del petto.\n'
        '3. Richiudi i manubri senza cambiare l’angolo dei gomiti.',
      'incline_dumbbell_fly':
        '1. Panca a 30°, manubri sopra il petto, gomiti morbidi.\n'
        '2. Scendi con un ampio arco fino a sentire l’allungamento del petto alto.\n'
        '3. Richiudili sopra il petto.',
      'low_to_high_cable_fly':
        '1. Imposta i cavi in basso e mettiti in mezzo, busto leggermente inclinato.\n'
        '2. Porta le maniglie in alto e unite davanti al petto alto.\n'
        '3. Torna lentamente in allungamento, gomiti leggermente piegati.',
      'incline_chest_press_machine':
        '1. Regola il sedile in modo che le maniglie siano all’altezza del petto alto.\n'
        '2. Spingi in avanti e in alto fino a braccia quasi tese.\n'
        '3. Torna lentamente fino a sentire l’allungamento.',
      'chest_dips':
        '1. In appoggio sulle parallele, inclina il busto in avanti.\n'
        '2. Scendi con i gomiti leggermente aperti fino a sentire l’allungamento del petto.\n'
        '3. Risali mantenendo l’inclinazione.',
      'incline_push_up':
        '1. Mani su una panca o un box, corpo in linea.\n'
        '2. Porta il petto verso il bordo, gomiti a circa 45° dal corpo.\n'
        '3. Risali. Più alto è l’appoggio, più è facile.',
      'decline_push_up':
        '1. Piedi su una panca, mani a terra sotto le spalle.\n'
        '2. Scendi con il petto verso terra, addome contratto.\n'
        '3. Risali senza far cedere il bacino.',
      'dumbbell_floor_press':
        '1. Sdraiati a terra, ginocchia piegate, manubri sopra il petto.\n'
        '2. Scendi finché le braccia toccano terra, breve pausa.\n'
        '3. Spingi fino a braccia tese.',
      't_bar_row':
        '1. Mettiti sopra il bilanciere, piegati a schiena dritta e afferra la maniglia.\n'
        '2. Tira il peso al petto stringendo le scapole.\n'
        '3. Scendi in controllo senza curvare la schiena.',
      'pendlay_row':
        '1. Bilanciere a terra, busto quasi orizzontale, schiena dritta.\n'
        '2. Tira il bilanciere in modo esplosivo verso il petto basso.\n'
        '3. Appoggialo a terra a ogni ripetizione e ritrova la posizione.',
      'machine_row':
        '1. Siediti con il petto contro il cuscino e afferra le maniglie.\n'
        '2. Tira verso il corpo, gomiti stretti, scapole addotte.\n'
        '3. Torna lentamente a braccia tese.',
      'chest_supported_row':
        '1. Sdraiati a pancia in giù su una panca a 30–45°, manubri in basso.\n'
        '2. Tirali verso i fianchi stringendo le scapole.\n'
        '3. Scendi lentamente fino al pieno allungamento.',
      'close_grip_lat_pulldown':
        '1. Siediti alla lat machine con presa stretta o a V, cosce bloccate.\n'
        '2. Tira la maniglia al petto alto, gomiti in basso e indietro.\n'
        '3. Lasciala risalire lentamente fino a braccia tese.',
      'straight_arm_pulldown':
        '1. In piedi davanti al cavo alto, braccia quasi tese, leggera inclinazione.\n'
        '2. Porta la barra in arco fino alle cosce usando i dorsali.\n'
        '3. Lascia risalire lentamente, gomiti quasi tesi.',
      'band_assisted_pull_up':
        '1. Aggancia un elastico alla sbarra e appoggia un piede o un ginocchio.\n'
        '2. Sali finché il mento supera la sbarra.\n'
        '3. Scendi in controllo fino alla sospensione. Elastico più sottile = meno aiuto.',
      'inverted_row':
        '1. Appenditi sotto una sbarra bassa o agli anelli, corpo dritto, talloni a terra.\n'
        '2. Porta il petto alla sbarra stringendo le scapole.\n'
        '3. Scendi in controllo. Più il corpo è verticale, più è facile.',
      'neutral_grip_pull_up':
        '1. Appenditi a maniglie parallele, palmi uno verso l’altro.\n'
        '2. Sali finché il mento supera le maniglie.\n'
        '3. Scendi in controllo fino alla sospensione completa.',
      'rack_pull':
        '1. Appoggia il bilanciere sui fermi appena sotto o sopra le ginocchia.\n'
        '2. Afferralo, contrai il core e sali spingendo le anche in avanti.\n'
        '3. Riportalo sui fermi a schiena dritta.',
      'trap_bar_deadlift':
        '1. Mettiti dentro la trap bar, piedi alla larghezza delle anche, afferra le maniglie.\n'
        '2. Contrai, spingi il pavimento e torna in piedi.\n'
        '3. Riporta giù la barra a schiena dritta.',
      'single_arm_cable_row':
        '1. Afferra una maniglia al cavo a metà altezza, braccio teso.\n'
        '2. Tirala verso il fianco, gomito vicino al corpo.\n'
        '3. Torna lentamente lasciando avanzare un po’ la spalla.',
      'dumbbell_pullover':
        '1. Sdraiati su una panca con un manubrio sopra il petto, tenuto a due mani.\n'
        '2. Portalo ad arco dietro la testa, gomiti leggermente piegati.\n'
        '3. Riportalo sopra il petto.',
      'renegade_row':
        '1. In posizione da flessioni sui manubri, piedi larghi.\n'
        '2. Tira un manubrio al fianco senza ruotare il bacino.\n'
        '3. Appoggialo e ripeti con l’altro braccio.',
      'arnold_press':
        '1. Siediti con i manubri davanti alle spalle, palmi verso di te.\n'
        '2. Spingi in alto ruotando i palmi in avanti.\n'
        '3. Scendi ruotando di nuovo alla posizione iniziale.',
      'shoulder_press_machine':
        '1. Regola il sedile in modo che le maniglie partano all’altezza delle spalle.\n'
        '2. Spingi fino a braccia quasi tese.\n'
        '3. Scendi lentamente all’altezza delle spalle.',
      'push_press':
        '1. Bilanciere sulla parte anteriore delle spalle, piedi alla larghezza delle anche.\n'
        '2. Piega leggermente le ginocchia e con la spinta delle gambe porta il bilanciere sopra la testa.\n'
        '3. Riportalo sulle spalle in controllo.',
      'cable_lateral_raise':
        '1. Di fianco al cavo basso, maniglia nella mano più lontana.\n'
        '2. Alza il braccio lateralmente fino all’altezza della spalla.\n'
        '3. Scendi lentamente mantenendo la tensione.',
      'machine_lateral_raise':
        '1. Siediti con i cuscini all’esterno delle braccia.\n'
        '2. Alza le braccia fino all’altezza delle spalle.\n'
        '3. Scendi lentamente senza appoggiare il peso.',
      'front_raise':
        '1. In piedi, manubri davanti alle cosce.\n'
        '2. Alzali davanti fino all’altezza delle spalle, braccia quasi tese.\n'
        '3. Scendi lentamente senza slancio.',
      'upright_row':
        '1. Tieni il bilanciere davanti alle cosce, presa circa alla larghezza delle spalle.\n'
        '2. Tiralo lungo il corpo fino al petto, guidano i gomiti.\n'
        '3. Scendi lentamente. Se le spalle danno fastidio, sali meno.',
      'reverse_pec_deck':
        '1. Siediti di fronte alla macchina, petto sul cuscino, afferra le maniglie.\n'
        '2. Apri le braccia indietro ad arco fino a essere in linea con il corpo.\n'
        '3. Torna lentamente.',
      'band_pull_apart':
        '1. Tieni un elastico davanti a te all’altezza delle spalle, braccia tese.\n'
        '2. Allargalo fino al petto stringendo le scapole.\n'
        '3. Torna lentamente.',
      'handstand_push_up':
        '1. Sali in verticale contro il muro, mani alla larghezza delle spalle.\n'
        '2. Scendi con la testa verso terra in controllo.\n'
        '3. Spingi fino a braccia tese. Metti un tappetino sotto la testa.',
      'landmine_press':
        '1. Tieni l’estremità del bilanciere landmine alla spalla, piedi sfalsati.\n'
        '2. Spingi in alto e in avanti fino a braccio teso.\n'
        '3. Riportalo alla spalla in controllo.',
      'preacher_curl':
        '1. Siediti alla panca Scott, braccia appoggiate, bilanciere EZ in mano.\n'
        '2. Solleva il bilanciere senza staccare i gomiti.\n'
        '3. Scendi lentamente quasi a braccia tese.',
      'concentration_curl':
        '1. Siediti su una panca, gomito appoggiato all’interno della coscia.\n'
        '2. Porta il manubrio verso la spalla.\n'
        '3. Scendi lentamente fino al pieno allungamento.',
      'incline_dumbbell_curl':
        '1. Appoggiati a una panca a 45–60°, braccia distese verso il basso.\n'
        '2. Solleva i manubri senza muovere le braccia.\n'
        '3. Scendi lentamente fino al pieno allungamento.',
      'ez_bar_curl':
        '1. In piedi, impugna il bilanciere EZ nei punti angolati, braccia tese.\n'
        '2. Sollevalo senza dondolare il corpo.\n'
        '3. Scendi lentamente a braccia tese.',
      'rope_hammer_curl':
        '1. Aggancia una corda al cavo basso, palmi uno verso l’altro.\n'
        '2. Solleva la corda, gomiti lungo i fianchi.\n'
        '3. Scendi lentamente mantenendo la tensione.',
      'machine_biceps_curl':
        '1. Siediti con le braccia sul cuscino e afferra le maniglie.\n'
        '2. Porta le maniglie verso le spalle.\n'
        '3. Scendi lentamente quasi a braccia tese.',
      'band_curl':
        '1. In piedi al centro dell’elastico, estremità in mano.\n'
        '2. Porta le mani alle spalle, gomiti lungo i fianchi.\n'
        '3. Scendi lentamente.',
      'rope_pushdown':
        '1. Afferra la corda al cavo alto, gomiti lungo i fianchi.\n'
        '2. Spingi in basso e apri le estremità alla fine.\n'
        '3. Lascia risalire lentamente fino a circa 90° al gomito.',
      'overhead_cable_extension':
        '1. Di spalle al cavo, corda dietro la testa, gomiti in alto.\n'
        '2. Distendi le braccia in avanti e in alto.\n'
        '3. Piega lentamente i gomiti dietro la testa.',
      'triceps_kickback':
        '1. Busto inclinato, braccio parallelo al corpo, gomito piegato.\n'
        '2. Distendi completamente il braccio all’indietro.\n'
        '3. Piega lentamente senza muovere il braccio.',
      'bench_dips':
        '1. Mani sul bordo di una panca dietro di te, gambe in avanti.\n'
        '2. Scendi piegando i gomiti a circa 90°.\n'
        '3. Risali fino a braccia tese.',
      'machine_triceps_dip':
        '1. Siediti nella macchina e afferra le maniglie laterali.\n'
        '2. Spingi in basso fino a braccia tese.\n'
        '3. Lascia risalire lentamente fino a circa 90° al gomito.',
      'single_arm_pushdown':
        '1. Afferra una maniglia al cavo alto, gomito lungo il fianco.\n'
        '2. Spingi in basso fino a braccio teso.\n'
        '3. Lascia risalire lentamente, il gomito resta fermo.',
      'diamond_push_up':
        '1. Posizione da flessioni con le mani unite sotto il petto a formare un rombo.\n'
        '2. Porta il petto alle mani, gomiti stretti.\n'
        '3. Risali con il corpo dritto.',
      'reverse_wrist_curl':
        '1. Siediti con gli avambracci sulle cosce, palmi in giù, polsi oltre le ginocchia.\n'
        '2. Solleva il dorso delle mani il più in alto possibile.\n'
        '3. Scendi lentamente.',
      'hack_squat':
        '1. Sali sulla pedana, schiena sullo schienale, spalle sotto i cuscini.\n'
        '2. Scendi finché le cosce sono almeno parallele alla pedana.\n'
        '3. Risali spingendo con tutto il piede.',
      'smith_squat':
        '1. Bilanciere sulla parte alta della schiena, piedi un po’ avanti rispetto al bilanciere.\n'
        '2. Scendi a schiena dritta almeno fino al parallelo.\n'
        '3. Risali e alla fine riaggancia il bilanciere.',
      'walking_lunge':
        '1. Manubri lungo i fianchi, fai un passo lungo in avanti.\n'
        '2. Porta il ginocchio posteriore quasi a terra.\n'
        '3. Spingi con il piede anteriore e prosegui con l’affondo successivo.',
      'reverse_lunge':
        '1. In piedi, manubri lungo i fianchi.\n'
        '2. Fai un passo indietro e porta il ginocchio posteriore quasi a terra.\n'
        '3. Spingi con il piede anteriore per tornare. Alterna le gambe.',
      'step_up':
        '1. Mettiti davanti a una panca o un box con i manubri.\n'
        '2. Appoggia un piede sopra e sali spingendo con quella gamba.\n'
        '3. Scendi lentamente. Alterna o fai un lato alla volta.',
      'split_squat':
        '1. Mettiti in affondo lungo con i manubri in mano.\n'
        '2. Scendi in verticale finché il ginocchio posteriore quasi tocca terra.\n'
        '3. Risali. Finisci le ripetizioni e cambia gamba.',
      'sumo_squat':
        '1. Piedi larghi, punte in fuori, un manubrio tra le gambe.\n'
        '2. Scendi con il busto eretto, ginocchia nella direzione delle punte.\n'
        '3. Risali e contrai i glutei.',
      'pistol_squat':
        '1. In piedi su una gamba, l’altra tesa in avanti.\n'
        '2. Scendi in controllo il più in basso possibile, braccia avanti per l’equilibrio.\n'
        '3. Risali. All’inizio puoi tenerti a qualcosa.',
      'single_leg_press':
        '1. Siediti alla leg press con un piede al centro della pedana.\n'
        '2. Scendi finché il ginocchio è a circa 90°.\n'
        '3. Spingi senza bloccare il ginocchio. Cambia gamba.',
      'hip_adduction_machine':
        '1. Siediti con i cuscini all’interno delle ginocchia.\n'
        '2. Chiudi le gambe.\n'
        '3. Riaprile lentamente.',
      'wall_sit':
        '1. Appoggia la schiena al muro e scivola in basso.\n'
        '2. Fermati con le ginocchia a circa 90°, piedi sotto le ginocchia.\n'
        '3. Tieni per il tempo previsto, schiena aderente al muro.',
      'jump_squat':
        '1. In piedi, piedi alla larghezza delle spalle.\n'
        '2. Scendi in squat e salta in modo esplosivo.\n'
        '3. Atterra morbido e passa subito allo squat successivo.',
      'box_jump':
        '1. Mettiti davanti a un box stabile.\n'
        '2. Slancia le braccia e salta sul box atterrando morbido.\n'
        '3. Raddrizzati completamente e scendi camminando.',
      'seated_leg_curl':
        '1. Siediti nella macchina, cuscino sopra i talloni, cosce bloccate.\n'
        '2. Porta i talloni in basso e indietro il più possibile.\n'
        '3. Torna lentamente.',
      'nordic_curl':
        '1. In ginocchio con i talloni bloccati sotto qualcosa di stabile.\n'
        '2. Lascia cadere il busto in avanti il più lentamente possibile, anche distese.\n'
        '3. Frena con le mani e risali con i femorali.',
      'single_leg_rdl':
        '1. In piedi su una gamba con un manubrio, ginocchio leggermente piegato.\n'
        '2. Piegati in avanti mentre la gamba libera va indietro, schiena dritta.\n'
        '3. Torna su spingendo le anche in avanti.',
      'dumbbell_romanian_deadlift':
        '1. In piedi con i manubri davanti alle cosce, ginocchia morbide.\n'
        '2. Porta le anche indietro e fai scorrere i manubri lungo le gambe.\n'
        '3. Fermati all’allungamento dei femorali e risali.',
      'stiff_leg_deadlift':
        '1. In piedi con il bilanciere, gambe quasi tese.\n'
        '2. Piegati a schiena dritta facendo scendere il bilanciere lungo le gambe.\n'
        '3. Risali contraendo femorali e glutei.',
      'stability_ball_leg_curl':
        '1. Sdraiati sulla schiena, talloni sulla fitball, bacino sollevato.\n'
        '2. Avvicina la palla piegando le ginocchia.\n'
        '3. Allontanala lentamente, il bacino resta su.',
      'sumo_deadlift':
        '1. Piedi molto larghi, punte in fuori, afferra il bilanciere tra le gambe.\n'
        '2. Contrai, spingi le ginocchia in fuori e sali con il bilanciere vicino al corpo.\n'
        '3. Riportalo a terra a schiena dritta.',
      'cable_glute_kickback':
        '1. Aggancia una cavigliera al cavo basso e tieniti alla macchina.\n'
        '2. Spingi la gamba indietro e in alto contraendo il gluteo.\n'
        '3. Torna lentamente senza inarcare la zona lombare.',
      'hip_abduction_machine':
        '1. Siediti con i cuscini all’esterno delle ginocchia.\n'
        '2. Apri le gambe il più possibile.\n'
        '3. Richiudile lentamente.',
      'machine_hip_thrust':
        '1. Appoggia la parte alta della schiena allo schienale e la cintura sulle anche.\n'
        '2. Spingi in alto il bacino fino all’allineamento ginocchia-spalle.\n'
        '3. Contrai i glutei in alto e scendi lentamente.',
      'single_leg_glute_bridge':
        '1. Sdraiati sulla schiena, un piede a terra e l’altra gamba tesa verso l’alto.\n'
        '2. Solleva il bacino spingendo con il tallone a terra.\n'
        '3. Scendi lentamente. Finisci e cambia gamba.',
      'donkey_kick':
        '1. In quadrupedia, mani sotto le spalle.\n'
        '2. Solleva indietro una gamba piegata, pianta del piede verso il soffitto.\n'
        '3. Scendi lentamente senza inarcare la schiena.',
      'fire_hydrant':
        '1. In quadrupedia, schiena piatta.\n'
        '2. Solleva lateralmente una gamba piegata fino all’altezza dell’anca.\n'
        '3. Scendi lentamente, bacino fermo.',
      'banded_lateral_walk':
        '1. Metti una mini band sopra le ginocchia o alle caviglie e piega leggermente le ginocchia.\n'
        '2. Cammina di lato mantenendo l’elastico teso.\n'
        '3. Conta i passi da un lato e poi torna indietro.',
      'cable_pull_through':
        '1. Di spalle al cavo basso, corda tra le gambe.\n'
        '2. Piegati a schiena dritta lasciando andare indietro la corda.\n'
        '3. Spingi le anche in avanti per tornare su e contrai i glutei.',
      'seated_calf_raise':
        '1. Siediti con il cuscino sulle cosce, avampiedi sul gradino.\n'
        '2. Solleva i talloni il più in alto possibile.\n'
        '3. Scendi lentamente fino al pieno allungamento.',
      'single_leg_calf_raise':
        '1. Un piede sul bordo di un gradino, tieniti.\n'
        '2. Sali sulla punta il più in alto possibile.\n'
        '3. Scendi con il tallone sotto il gradino per allungare.',
      'leg_press_calf_raise':
        '1. Siediti alla leg press con gli avampiedi sul bordo basso della pedana.\n'
        '2. Spingi la pedana distendendo i piedi.\n'
        '3. Lasciala tornare lentamente in allungamento. Ginocchia tese.',
      'sit_up':
        '1. Sdraiati sulla schiena, ginocchia piegate, piedi a terra.\n'
        '2. Arrotolati fino alla posizione seduta.\n'
        '3. Scendi lentamente.',
      'decline_sit_up':
        '1. Blocca i piedi sulla panca declinata e sdraiati.\n'
        '2. Sali finché il busto è verticale.\n'
        '3. Scendi lentamente. Tieni un disco per più carico.',
      'bicycle_crunch':
        '1. Sdraiati sulla schiena, mani vicino alla testa, gambe sollevate.\n'
        '2. Porta un gomito verso il ginocchio opposto mentre distendi l’altra gamba.\n'
        '3. Alterna i lati come se pedalassi.',
      'reverse_crunch':
        '1. Sdraiati sulla schiena, ginocchia a 90°, braccia a terra.\n'
        '2. Solleva il bacino e porta le ginocchia al petto.\n'
        '3. Scendi lentamente senza slancio.',
      'lying_leg_raise':
        '1. Sdraiati sulla schiena, gambe tese, zona lombare a terra.\n'
        '2. Solleva le gambe finché puntano al soffitto.\n'
        '3. Scendi lentamente senza inarcare la schiena.',
      'captains_chair_knee_raise':
        '1. Appoggia gli avambracci ai cuscini e la schiena allo schienale.\n'
        '2. Porta le ginocchia verso il petto.\n'
        '3. Scendi lentamente senza dondolare.',
      'ab_wheel_rollout':
        '1. In ginocchio, tieni la ruota sotto le spalle.\n'
        '2. Rotola in avanti il più possibile senza far cedere la zona lombare.\n'
        '3. Torna indietro tirando con gli addominali.',
      'russian_twist':
        '1. Siediti con il busto leggermente inclinato indietro, piedi sollevati o a terra.\n'
        '2. Ruota il busto e tocca terra accanto al fianco.\n'
        '3. Ruota dall’altra parte. Tieni un peso per più carico.',
      'v_up':
        '1. Sdraiati sulla schiena, braccia sopra la testa, gambe tese.\n'
        '2. Solleva insieme braccia e gambe e tocca i piedi.\n'
        '3. Scendi lentamente.',
      'hollow_hold':
        '1. Sdraiati sulla schiena e premi la zona lombare a terra.\n'
        '2. Solleva leggermente spalle e gambe tese.\n'
        '3. Tieni per il tempo previsto senza inarcare la schiena.',
      'pallof_press':
        '1. Di fianco a un cavo all’altezza del petto, maniglia al petto.\n'
        '2. Spingi la maniglia dritta davanti senza far ruotare il corpo.\n'
        '3. Riportala al petto. Lavora entrambi i lati.',
      'cable_woodchopper':
        '1. Di fianco al cavo alto, maniglia con entrambe le mani.\n'
        '2. Tira in diagonale verso il basso attraverso il corpo ruotando il busto.\n'
        '3. Torna lentamente. Lavora entrambi i lati.',
      'plank_shoulder_tap':
        '1. In plank alto, piedi leggermente divaricati.\n'
        '2. Tocca la spalla opposta con una mano senza muovere il bacino.\n'
        '3. Cambia mano.',
      'bird_dog':
        '1. In quadrupedia, schiena piatta.\n'
        '2. Distendi un braccio in avanti e la gamba opposta indietro.\n'
        '3. Tieni un attimo, torna e cambia lato.',
      'power_clean':
        '1. Sopra il bilanciere, presa appena fuori dalle ginocchia, schiena dritta.\n'
        '2. Tira il bilanciere in modo esplosivo lungo il corpo e ricevilo sulla parte anteriore delle spalle.\n'
        '3. Raddrizzati e riappoggia il bilanciere. Impara la tecnica con poco peso.',
      'thruster':
        '1. Tieni il bilanciere sulla parte anteriore delle spalle.\n'
        '2. Scendi in squat e risalendo spingi il bilanciere sopra la testa in un solo movimento.\n'
        '3. Riportalo sulle spalle e passa subito allo squat successivo.',
      'turkish_get_up':
        '1. Sdraiati sulla schiena e tieni un kettlebell in alto con un braccio teso.\n'
        '2. Alzati passo dopo passo guardando il kettlebell, braccio teso.\n'
        '3. Torna a terra con gli stessi passaggi. Lavora entrambi i lati.',
      'bear_crawl':
        '1. In appoggio su mani e piedi, ginocchia appena sollevate, schiena piatta.\n'
        '2. Avanza muovendo insieme mano e piede opposti.\n'
        '3. Tieni il bacino basso per il tempo previsto.',
      'high_knees':
        '1. Corri sul posto portando le ginocchia all’altezza delle anche.\n'
        '2. Usa le braccia e resta sugli avampiedi.\n'
        '3. Mantieni un ritmo veloce per il tempo previsto.',
      'jump_rope':
        '1. Tieni le maniglie all’altezza dei fianchi, gomiti vicini al corpo.\n'
        '2. Fai girare la corda con i polsi e salta quanto basta.\n'
        '3. Atterra morbido sugli avampiedi per il tempo previsto.',
      'rowing_machine':
        '1. Fissa i piedi e afferra la maniglia a braccia tese.\n'
        '2. Spingi con le gambe, inclinati un po’ indietro e tira la maniglia verso le costole basse.\n'
        '3. Torna in ordine inverso: braccia, busto, gambe. Ritmo costante.',
      'stationary_bike':
        '1. Regola la sella in modo che il ginocchio resti leggermente piegato in basso.\n'
        '2. Pedala a ritmo costante con la schiena dritta.\n'
        '3. Regola la resistenza in base all’obiettivo per il tempo previsto.',
      'treadmill_run':
        '1. Inizia camminando e aumenta la velocità gradualmente.\n'
        '2. Corri con il busto eretto e le spalle rilassate, appoggio sotto le anche.\n'
        '3. Rallenta camminando prima di scendere.',
      'elliptical':
        '1. Sali sui pedali e afferra le maniglie mobili.\n'
        '2. Muoviti in modo fluido spingendo e tirando anche con le braccia.\n'
        '3. Mantieni un ritmo costante per il tempo previsto.',
      'stair_climber':
        '1. Sali e scegli una velocità che riesci a mantenere.\n'
        '2. Sali con il busto eretto, usa i corrimano solo per l’equilibrio.\n'
        '3. Continua per il tempo previsto.',
      'air_bike':
        '1. Siediti e afferra le maniglie mobili.\n'
        '2. Pedala spingendo e tirando le maniglie insieme.\n'
        '3. Più spingi, più la ventola frena. Per il tempo previsto.',
    },
    routineNames: {
      'home_upper': 'Parte superiore in 5 minuti',
      'home_lower': 'Parte inferiore in 5 minuti',
      'home_full': 'Total body in 5 minuti',
    },
    programNames: {
      'full_body': 'Total body (principianti)',
      'upper_lower': 'Upper / Lower',
      'ppl': 'Push / Pull / Legs',
      'full_body_2x': 'Total body 2 volte a settimana',
      'dumbbell_home': 'Manubri a casa',
      'strength_5x5': 'Forza 5×5',
      'circuit': 'Circuito (resistenza)',
      'full_body_variation': 'Total body – variante',
      'bodyweight_home': 'Corpo libero a casa',
      'machines': 'Macchine (principianti)',
      'upper_lower_variation': 'Upper / Lower – variante',
      'ppl_variation': 'Push / Pull / Legs – variante',
      'strength_dup': 'Forza – onde settimanali',
      'conditioning_intervals': 'Condizionamento – intervalli',
      'phul': 'Forza + volume (PHUL)',
      'strength_advanced': 'Forza – 4 giorni (avanzati)',
      'ppl_6x': 'Push / Pull / Legs 6 volte a settimana',
    },
    programDescriptions: {
      'full_body':
        '3 volte a settimana, alternando gli allenamenti A e B. Ideale per i primi mesi.',
      'upper_lower':
        '4 volte a settimana: parte superiore lun + gio, parte inferiore mar + ven.',
      'ppl': '3 volte a settimana: push lun, pull mer, gambe ven.',
      'full_body_2x':
        'Per le settimane piene: 2 allenamenti di circa un’ora, lun + gio. Ogni muscolo 2 volte a settimana.',
      'dumbbell_home':
        '3 volte a settimana con un paio di manubri e un tappetino, alternando A e B. Senza palestra.',
      'strength_5x5':
        '3 volte a settimana, alternando A e B: 5 serie da 5 negli esercizi principali. Quando completi tutte le serie da 5, il peso sale.',
      'circuit':
        '3 volte a settimana, alternando A e B: esercizi in circuito uno dopo l’altro, recuperi brevi, tante ripetizioni. Per resistenza e forma fisica.',
      'full_body_variation':
        '3 volte a settimana, alternando C e D. Stessa struttura di Total body (principianti) con esercizi diversi – cambia ogni 6–8 settimane.',
      'bodyweight_home':
        '3 volte a settimana, alternando A e B, senza attrezzi – basta un tappetino (e un tavolo robusto per le trazioni). Per iniziare e in viaggio.',
      'machines':
        '3 volte a settimana, alternando A e B, sulle macchine della palestra: facili da imparare, sicure anche senza assistenza. Un buon primo passo prima dei pesi liberi.',
      'upper_lower_variation':
        '4 volte a settimana come Upper / Lower, con esercizi diversi (panca inclinata, front squat, hip thrust). Cambia ogni 6–8 settimane.',
      'ppl_variation':
        '3 volte a settimana come Push / Pull / Legs, con esercizi diversi (prima la military press, rematore con bilanciere, hack squat). Cambia ogni 6–8 settimane.',
      'strength_dup':
        '3 volte a settimana: giorno pesante (serie da 3), giorno di volume (6–8 ripetizioni) e giorno medio (serie da 5). Variare il carico nella settimana fa crescere la forza anche dopo il primo anno.',
      'conditioning_intervals':
        '3 volte a settimana, alternando A e B: coppie di un esercizio di forza e uno cardio uno dopo l’altro, alla fine un blocco di cardio continuo. Per forma fisica, resistenza e dimagrimento.',
      'phul':
        '4 volte a settimana: giorni pesanti per parte superiore e inferiore per la forza (lun, mar), giorni con più ripetizioni per i muscoli (gio, ven). Circa 12–16 serie per muscolo a settimana.',
      'strength_advanced':
        '4 volte a settimana, un grande esercizio al giorno (squat, panca piana, stacco da terra, military press): serie pesanti da 3, una variante affine e complementari per i punti deboli.',
      'ppl_6x':
        'Lun–sab: Push, Pull, Gambe, poi Push B, Pull B, Gambe B. Ogni muscolo 2 volte a settimana con volume alto – per chi ha esperienza e recupera bene.',
    },
    planNames: {
      'Full body A': 'Total body A',
      'Full body B': 'Total body B',
      'Upper body': 'Parte superiore',
      'Lower body': 'Parte inferiore',
      'Push': 'Push',
      'Pull': 'Pull',
      'Legs': 'Gambe',
      'Full body 2× A': 'Total body 2× A',
      'Full body 2× B': 'Total body 2× B',
      'Dumbbells A': 'Manubri A',
      'Dumbbells B': 'Manubri B',
      '5×5 A': '5×5 A',
      '5×5 B': '5×5 B',
      'Circuit A': 'Circuito A',
      'Circuit B': 'Circuito B',
      'Full body C': 'Total body C',
      'Full body D': 'Total body D',
      'Bodyweight A': 'Corpo libero A',
      'Bodyweight B': 'Corpo libero B',
      'Machines A': 'Macchine A',
      'Machines B': 'Macchine B',
      'Upper body B': 'Parte superiore B',
      'Lower body B': 'Parte inferiore B',
      'Push B': 'Push B',
      'Pull B': 'Pull B',
      'Legs B': 'Gambe B',
      'Strength: heavy day': 'Forza: giorno pesante',
      'Strength: volume day': 'Forza: giorno di volume',
      'Strength: medium day': 'Forza: giorno medio',
      'Intervals A': 'Intervalli A',
      'Intervals B': 'Intervalli B',
      'Upper power': 'Superiore – forza',
      'Lower power': 'Inferiore – forza',
      'Upper hypertrophy': 'Superiore – volume',
      'Lower hypertrophy': 'Inferiore – volume',
      'Strength: squat': 'Forza: squat',
      'Strength: bench': 'Forza: panca piana',
      'Strength: deadlift': 'Forza: stacco da terra',
      'Strength: overhead press': 'Forza: military press',
    },
  ),
  'sk': (
    exerciseNames: {
      'bench_press': 'Bench press',
      'incline_dumbbell_press': 'Tlaky s jednoručkami na šikmej lavičke',
      'cable_fly': 'Rozpažovanie na kladke',
      'push_up': 'Kľuk',
      'deadlift': 'Mŕtvy ťah',
      'barbell_row': 'Príťahy veľkej činky v predklone',
      'lat_pulldown': 'Sťahovanie hornej kladky',
      'pull_up': 'Zhyb',
      'overhead_press': 'Tlaky nad hlavu',
      'lateral_raise': 'Upažovanie s jednoručkami',
      'pike_push_up': 'Kľuk v pozícii V',
      'dumbbell_curl': 'Bicepsový zdvih s jednoručkami',
      'triceps_pushdown': 'Sťahovanie kladky na triceps',
      'dips': 'Kľuky na bradlách',
      'back_squat': 'Drep s činkou na chrbte',
      'leg_press': 'Legpress',
      'romanian_deadlift': 'Rumunský mŕtvy ťah',
      'bodyweight_squat': 'Drep bez záťaže',
      'lunge': 'Výpad',
      'hip_thrust': 'Hip thrust',
      'glute_bridge': 'Sedací mostík',
      'plank': 'Plank',
      'crunch': 'Skracovačky',
      'mountain_climber': 'Horolezec',
      'jumping_jack': 'Panáky (jumping jacks)',
      'dumbbell_bench_press': 'Tlaky s jednoručkami na rovnej lavičke',
      'incline_bench_press': 'Bench press na šikmej lavičke',
      'chest_press_machine': 'Tlaky na hrudníkovom stroji',
      'pec_deck': 'Butterfly na stroji',
      'seated_cable_row': 'Príťahy spodnej kladky v sede',
      'one_arm_dumbbell_row': 'Príťahy jednoručky v opore',
      'chin_up': 'Zhyb podhmatom',
      'dumbbell_shoulder_press': 'Tlaky s jednoručkami nad hlavu',
      'rear_delt_fly': 'Zapažovanie v predklone',
      'face_pull': 'Príťahy lana k tvári',
      'barbell_curl': 'Bicepsový zdvih s veľkou činkou',
      'hammer_curl': 'Kladivové zdvihy',
      'cable_curl': 'Bicepsový zdvih na kladke',
      'skull_crusher': 'Francúzsky tlak v ľahu',
      'overhead_triceps_extension': 'Tricepsové tlaky za hlavou',
      'close_grip_bench_press': 'Bench press úzkym úchopom',
      'front_squat': 'Predný drep',
      'goblet_squat': 'Goblet drep',
      'bulgarian_split_squat': 'Bulharský drep',
      'leg_extension': 'Predkopávanie na stroji',
      'leg_curl': 'Zakopávanie na stroji',
      'calf_raise': 'Výpony na lýtka',
      'hanging_leg_raise': 'Dvíhanie nôh vo vise',
      'cable_crunch': 'Skracovačky na kladke',
      'dead_bug': 'Dead bug',
      'side_plank': 'Bočný plank',
      'burpee': 'Angličák',
      'kettlebell_swing': 'Švihy s kettlebellom',
      'weighted_pull_up': 'Zhyby so záťažou',
      'weighted_dips': 'Kľuky na bradlách so záťažou',
      'barbell_shrug': 'Krčenie ramien s veľkou činkou',
      'dumbbell_shrug': 'Krčenie ramien s jednoručkami',
      'wrist_curl': 'Zápästné zdvihy',
      'reverse_curl': 'Bicepsový zdvih nadhmatom',
      'dead_hang': 'Vis na hrazde',
      'back_extension': 'Hyperextenzie',
      'good_morning': 'Predklony s osou (good morning)',
      'superman': 'Superman',
      'decline_bench_press': 'Bench press na negatívnej lavičke',
      'smith_bench_press': 'Bench press na Smithovom stroji',
      'dumbbell_fly': 'Rozpažovanie s jednoručkami',
      'incline_dumbbell_fly': 'Rozpažovanie s jednoručkami na šikmej lavičke',
      'low_to_high_cable_fly': 'Rozpažovanie na kladke zdola nahor',
      'incline_chest_press_machine': 'Tlaky na šikmom hrudnom stroji',
      'chest_dips': 'Kľuky na bradlách na hrudník',
      'incline_push_up': 'Kľuk s rukami na vyvýšení',
      'decline_push_up': 'Kľuk s nohami na vyvýšení',
      'dumbbell_floor_press': 'Tlaky s jednoručkami v ľahu na zemi',
      't_bar_row': 'Príťahy T-osi',
      'pendlay_row': 'Pendlay príťahy',
      'machine_row': 'Príťahy na stroji v sede',
      'chest_supported_row': 'Príťahy jednoručiek v ľahu na šikmej lavičke',
      'close_grip_lat_pulldown': 'Sťahovanie hornej kladky úzkym úchopom',
      'straight_arm_pulldown': 'Sťahovanie kladky s natiahnutými pažami',
      'band_assisted_pull_up': 'Zhyby s gumou',
      'inverted_row': 'Austrálske zhyby',
      'neutral_grip_pull_up': 'Zhyby neutrálnym úchopom',
      'rack_pull': 'Mŕtvy ťah zo stojana',
      'trap_bar_deadlift': 'Mŕtvy ťah s trap barom',
      'single_arm_cable_row': 'Príťahy kladky jednorúč',
      'dumbbell_pullover': 'Preťahovanie jednoručky v ľahu',
      'renegade_row': 'Príťahy v planku',
      'arnold_press': 'Arnoldove tlaky',
      'shoulder_press_machine': 'Tlaky na ramená na stroji',
      'push_press': 'Push press',
      'cable_lateral_raise': 'Upažovanie na kladke',
      'machine_lateral_raise': 'Upažovanie na stroji',
      'front_raise': 'Predpažovanie s jednoručkami',
      'upright_row': 'Príťahy k brade',
      'reverse_pec_deck': 'Zapažovanie na stroji (reverse butterfly)',
      'band_pull_apart': 'Rozťahovanie gumy',
      'handstand_push_up': 'Kľuk v stojke',
      'landmine_press': 'Landmine tlak',
      'preacher_curl': 'Bicepsový zdvih na Scottovej lavičke',
      'concentration_curl': 'Koncentrovaný bicepsový zdvih',
      'incline_dumbbell_curl': 'Bicepsový zdvih v ľahu na šikmej lavičke',
      'ez_bar_curl': 'Bicepsový zdvih s EZ osou',
      'rope_hammer_curl': 'Kladivový zdvih na kladke s lanom',
      'machine_biceps_curl': 'Bicepsový zdvih na stroji',
      'band_curl': 'Bicepsový zdvih s gumou',
      'rope_pushdown': 'Sťahovanie lana na triceps',
      'overhead_cable_extension': 'Tricepsové tlaky za hlavou na kladke',
      'triceps_kickback': 'Zanožovanie predlaktia s jednoručkou (kickback)',
      'bench_dips': 'Kľuky vzad o lavičku',
      'machine_triceps_dip': 'Tricepsové tlaky na stroji (dipy)',
      'single_arm_pushdown': 'Sťahovanie kladky jednorúč',
      'diamond_push_up': 'Diamantový kľuk',
      'reverse_wrist_curl': 'Zápästné zdvihy nadhmatom',
      'hack_squat': 'Hack drep na stroji',
      'smith_squat': 'Drep na Smithovom stroji',
      'walking_lunge': 'Výpady v chôdzi',
      'reverse_lunge': 'Výpady vzad',
      'step_up': 'Výstupy na lavičku',
      'split_squat': 'Drep vo výpade',
      'sumo_squat': 'Sumo drep s jednoručkou',
      'pistol_squat': 'Drep na jednej nohe (pistol)',
      'single_leg_press': 'Legpress jednonož',
      'hip_adduction_machine': 'Prinožovanie na stroji',
      'wall_sit': 'Sed pri stene',
      'jump_squat': 'Drep s výskokom',
      'box_jump': 'Výskoky na debnu',
      'seated_leg_curl': 'Zakopávanie v sede na stroji',
      'nordic_curl': 'Severské zakopávanie (nordic curl)',
      'single_leg_rdl': 'Rumunský mŕtvy ťah na jednej nohe',
      'dumbbell_romanian_deadlift': 'Rumunský mŕtvy ťah s jednoručkami',
      'stiff_leg_deadlift': 'Mŕtvy ťah s natiahnutými nohami',
      'stability_ball_leg_curl': 'Zakopávanie na gymnastickej lopte',
      'sumo_deadlift': 'Mŕtvy ťah sumo',
      'cable_glute_kickback': 'Zanožovanie na kladke',
      'hip_abduction_machine': 'Unožovanie na stroji',
      'machine_hip_thrust': 'Hip thrust na stroji',
      'single_leg_glute_bridge': 'Sedací mostík na jednej nohe',
      'donkey_kick': 'Zanožovanie v kľaku',
      'fire_hydrant': 'Unožovanie v kľaku',
      'banded_lateral_walk': 'Chôdza do strany s gumou',
      'cable_pull_through': 'Priťahovanie kladky pomedzi nohy (pull-through)',
      'seated_calf_raise': 'Výpony na lýtka v sede',
      'single_leg_calf_raise': 'Výpony na jednej nohe',
      'leg_press_calf_raise': 'Výpony na legpresse',
      'sit_up': 'Sed-ľahy',
      'decline_sit_up': 'Sed-ľahy na šikmej lavičke',
      'bicycle_crunch': 'Bicyklové skracovačky',
      'reverse_crunch': 'Spätné skracovačky',
      'lying_leg_raise': 'Dvíhanie nôh v ľahu',
      'captains_chair_knee_raise': 'Priťahovanie kolien v opore na bradlách',
      'ab_wheel_rollout': 'Koliesko na brucho',
      'russian_twist': 'Ruský twist',
      'v_up': 'Loďka (V-up)',
      'hollow_hold': 'Hollow hold (výdrž v loďke)',
      'pallof_press': 'Pallof press',
      'cable_woodchopper': 'Drevorubač na kladke',
      'plank_shoulder_tap': 'Plank s dotykom ramien',
      'bird_dog': 'Bird dog (dvíhanie ruky a nohy v kľaku)',
      'power_clean': 'Power clean (nadhod na hrudník)',
      'thruster': 'Thruster (drep s tlakom nad hlavu)',
      'turkish_get_up': 'Turecký vztyk',
      'bear_crawl': 'Medvedia chôdza',
      'high_knees': 'Skipovanie (vysoké kolená)',
      'jump_rope': 'Švihadlo',
      'rowing_machine': 'Veslársky trenažér',
      'stationary_bike': 'Rotoped',
      'treadmill_run': 'Beh na páse',
      'elliptical': 'Eliptický trenažér',
      'stair_climber': 'Schodový trenažér',
      'air_bike': 'Vzduchový rotoped (air bike)',
    },
    exerciseInstructions: {
      'bench_press':
        '1. Ľahni si na lavičku, oči pod osou, chodidlá pevne na zemi.\n'
        '2. Úchop o niečo širší ako ramená, lopatky stiahni k sebe.\n'
        '3. Kontrolovane spúšťaj osu k stredu hrudníka, lakte asi 45° od tela.\n'
        '4. Vytlač do vystretých rúk, panvu nedvíhaj z lavičky.',
      'incline_dumbbell_press':
        '1. Lavičku nastav na 30–45°, jednoručky drž pri hrudníku.\n'
        '2. Lopatky stiahnuté dozadu, chodidlá na zemi.\n'
        '3. Tlač hore a mierne k sebe, potom pomaly spúšťaj k hrudníku.',
      'cable_fly':
        '1. Postav sa medzi kladky, lakte mierne pokrčené.\n'
        '2. Veď rukoväte oblúkom k sebe pred hrudník.\n'
        '3. Pomaly sa vráť do natiahnutia, uhol v lakťoch nemeň.',
      'push_up':
        '1. Dlane o niečo širšie ako ramená, telo v jednej línii.\n'
        '2. Spusti hrudník tesne k zemi, lakte asi 45° od tela.\n'
        '3. Vytlač späť hore, drž spevnený stred tela a zadok.',
      'deadlift':
        '1. Os nad stredom chodidla, chodidlá na šírku panvy.\n'
        '2. Predkloň sa v bedrách, chyť osu, chrbát drž rovný.\n'
        '3. Odtlač sa od zeme a postav sa, os ide tesne pozdĺž nôh.\n'
        '4. Kontrolovane spúšťaj, panvu tlač dozadu.',
      'barbell_row':
        '1. Predkloň sa zhruba na 45°, chrbát rovný, kolená mierne pokrčené.\n'
        '2. Pritiahni osu k spodnej časti hrudníka alebo k bruchu.\n'
        '3. Stiahni lopatky a pomaly spúšťaj.',
      'lat_pulldown':
        '1. Úchop o niečo širší ako ramená, stehná pod opierkami.\n'
        '2. Stiahni osu k hornej časti hrudníka, lakte dole a dozadu.\n'
        '3. Pomaly vráť do vystretých rúk, nehojdaj sa.',
      'pull_up':
        '1. Vis na hrazde nadhmatom, ramená aktívne stiahnuté.\n'
        '2. Pritiahni sa, až je brada nad hrazdou.\n'
        '3. Kontrolovane sa spusti do plného visu.',
      'overhead_press':
        '1. Os na prednej strane ramien, úchop tesne mimo ramien.\n'
        '2. Spevni zadok a stred tela, tlač osu kolmo hore.\n'
        '3. Hlavu mierne uhni, keď os míňa tvár, a zamkni nad hlavou.',
      'lateral_raise':
        '1. Stoj vzpriamene, jednoručky pozdĺž tela, lakte mierne pokrčené.\n'
        '2. Upažuj do výšky ramien.\n'
        '3. Pomaly spúšťaj, nehojdaj sa.',
      'pike_push_up':
        '1. Z pozície kľuku zdvihni panvu do obráteného V.\n'
        '2. Spúšťaj hlavu k zemi medzi dlane.\n'
        '3. Vytlač späť silou ramien.',
      'dumbbell_curl':
        '1. Stoj vzpriamene, lakte pri tele.\n'
        '2. Dvíhaj jednoručky, lakte sa nehýbu.\n'
        '3. Pomaly spúšťaj do vystretia.',
      'triceps_pushdown':
        '1. Postav sa ku kladke, lakte pritlačené k telu.\n'
        '2. Tlač rukoväť dole do vystretých rúk.\n'
        '3. Pomaly vráť, lakte zostávajú na mieste.',
      'dips':
        '1. Opri sa na bradlách vo vystretých rukách.\n'
        '2. Spúšťaj sa, až sú ramená zhruba vodorovne.\n'
        '3. Vytlač späť, ramená nepadajú dopredu.',
      'back_squat':
        '1. Os na hornej časti chrbta, chodidlá na šírku ramien, špičky mierne von.\n'
        '2. Spevni stred tela a sadaj medzi päty.\n'
        '3. Kolená idú v smere špičiek, chrbát zostáva rovný.\n'
        '4. Vstávaj tlakom cez celé chodidlo.',
      'leg_press':
        '1. Chodidlá na šírku ramien doprostred plošiny.\n'
        '2. Spúšťaj zhruba do 90° v kolenách, driek zostáva na opierke.\n'
        '3. Vytlač hore, kolená prudko nezamykaj.',
      'romanian_deadlift':
        '1. Stoj s osou, kolená mierne pokrčené.\n'
        '2. Tlač panvu dozadu a spúšťaj osu pozdĺž nôh.\n'
        '3. Zastav v natiahnutí zadnej strany stehien, chrbát rovný.\n'
        '4. Vráť sa tlakom panvy dopredu.',
      'bodyweight_squat':
        '1. Chodidlá na šírku ramien, ruky pred telom pre rovnováhu.\n'
        '2. Sadaj čo najnižšie s rovným chrbtom.\n'
        '3. Vstávaj tlakom cez päty.',
      'lunge':
        '1. Vykroč dopredu a klesni, až sú obe kolená zhruba v 90°.\n'
        '2. Predné koleno nad chodidlom, trup vzpriamený.\n'
        '3. Odraz sa späť a vystriedaj nohy.',
      'hip_thrust':
        '1. Horná časť chrbta opretá o lavičku, os cez panvu.\n'
        '2. Tlakom cez päty zdvihni panvu, až je telo v rovine.\n'
        '3. Hore stiahni zadok a kontrolovane spúšťaj.',
      'glute_bridge':
        '1. Ľahni si na chrbát, kolená pokrčené, chodidlá na zemi.\n'
        '2. Zdvihni panvu stiahnutím sedacích svalov.\n'
        '3. Hore chvíľu vydrž a pomaly spúšťaj.',
      'plank':
        '1. Predlaktia pod ramenami, telo v jednej línii.\n'
        '2. Spevni stred tela a zadok, panva neklesá.\n'
        '3. Pokojne dýchaj a vydrž.',
      'crunch':
        '1. Ľahni si na chrbát, kolená pokrčené, ruky pri hlave.\n'
        '2. Silou brucha odlep ramená od zeme.\n'
        '3. Pomaly spúšťaj, neťahaj za krk.',
      'mountain_climber':
        '1. Začni v pozícii kľuku.\n'
        '2. Striedavo priťahuj kolená k hrudníku.\n'
        '3. Panvu drž nízko a tempo plynulé.',
      'jumping_jack':
        '1. Stoj znožmo, ruky pozdĺž tela.\n'
        '2. Výskokom roznož a ruky daj nad hlavu.\n'
        '3. Výskokom späť a opakuj plynulým tempom.',
      'dumbbell_bench_press':
        '1. Ľahni si na rovnú lavičku, jednoručky pri hrudníku.\n'
        '2. Tlač hore a mierne k sebe.\n'
        '3. Pomaly spúšťaj do natiahnutia hrudníka.',
      'incline_bench_press':
        '1. Lavička na 30–45°, úchop o niečo širší ako ramená.\n'
        '2. Spúšťaj osu k hornej časti hrudníka.\n'
        '3. Vytlač hore, lopatky drž stiahnuté.',
      'chest_press_machine':
        '1. Sedadlo nastav tak, aby boli rukoväte vo výške stredu hrudníka.\n'
        '2. Tlač vpred do takmer vystretých rúk.\n'
        '3. Pomaly vráť, chrbát zostáva na opierke.',
      'pec_deck':
        '1. Seď chrbtom na opierke, lakte mierne pokrčené.\n'
        '2. Spoj rukoväte pred hrudníkom.\n'
        '3. Pomaly sa vráť do príjemného natiahnutia.',
      'seated_cable_row':
        '1. Seď vzpriamene, chodidlá na opierke, kolená mierne pokrčené.\n'
        '2. Pritiahni rukoväť k bruchu, lakte pri tele.\n'
        '3. Stiahni lopatky a pomaly vráť, chrbát nehrb.',
      'one_arm_dumbbell_row':
        '1. Jedno koleno a ruku opri o lavičku, chrbát rovný.\n'
        '2. Priťahuj jednoručku k boku.\n'
        '3. Pomaly spúšťaj do plného natiahnutia.',
      'chin_up':
        '1. Vis na hrazde podhmatom na šírku ramien.\n'
        '2. Pritiahni sa, až je brada nad hrazdou.\n'
        '3. Kontrolovane sa spusti do plného visu.',
      'dumbbell_shoulder_press':
        '1. V sede alebo v stoji, jednoručky vo výške ramien.\n'
        '2. Tlač nad hlavu, neprehýbaj sa v drieku.\n'
        '3. Pomaly spúšťaj späť k ramenám.',
      'rear_delt_fly':
        '1. Predkloň sa s rovným chrbtom, jednoručky visia dole.\n'
        '2. Upažuj do strán s mierne pokrčenými lakťami.\n'
        '3. Pomaly spúšťaj, bez švihu.',
      'face_pull':
        '1. Lano vo výške hlavy, palce smerujú k tebe.\n'
        '2. Priťahuj k tvári, lakte vysoko a do strán.\n'
        '3. Stiahni hornú časť chrbta a pomaly vráť.',
      'barbell_curl':
        '1. Stoj vzpriamene, podhmat na šírku ramien.\n'
        '2. Dvíhaj osu bez švihu trupom.\n'
        '3. Pomaly spúšťaj do vystretia.',
      'hammer_curl':
        '1. Drž jednoručky dlaňami k sebe.\n'
        '2. Dvíhaj hore, lakte zostávajú pri tele.\n'
        '3. Pomaly spúšťaj.',
      'cable_curl':
        '1. Stoj čelom k spodnej kladke, lakte pri tele.\n'
        '2. Zdvihni rukoväť k ramenám.\n'
        '3. Pomaly spúšťaj, udržuj stále napätie.',
      'skull_crusher':
        '1. Ľahni si na lavičku, os nad hrudníkom vo vystretých rukách.\n'
        '2. Ohýbaj len lakte a spúšťaj osu k čelu.\n'
        '3. Vystri späť, lakte mieria stále hore.',
      'overhead_triceps_extension':
        '1. Drž jednu jednoručku oboma rukami nad hlavou.\n'
        '2. Pokrčením lakťov ju spúšťaj za hlavu.\n'
        '3. Vystri späť, lakte drž pri hlave.',
      'close_grip_bench_press':
        '1. Ľahni si na lavičku, úchop zhruba na šírku ramien.\n'
        '2. Spúšťaj osu k spodnej časti hrudníka, lakte pri tele.\n'
        '3. Vytlač hore vystretím lakťov.',
      'front_squat':
        '1. Os na prednej strane ramien, lakte vysoko.\n'
        '2. Drepni so vzpriameným trupom.\n'
        '3. Vstávaj, lakte drž celý čas hore.',
      'goblet_squat':
        '1. Drž kettlebell alebo jednoručku pri hrudníku.\n'
        '2. Drepni medzi kolená s rovným chrbtom.\n'
        '3. Vstávaj tlakom cez päty.',
      'bulgarian_split_squat':
        '1. Zadnú nohu opri o lavičku, prednú krok vpredu.\n'
        '2. Klesni, až je predné stehno zhruba vodorovne.\n'
        '3. Vytlač sa cez prednú nohu, potom vystriedaj.',
      'leg_extension':
        '1. Opierku nastav tesne nad členky.\n'
        '2. Vystri nohy do rovnej polohy.\n'
        '3. Pomaly a kontrolovane spúšťaj.',
      'leg_curl':
        '1. Opierku nastav tesne nad päty.\n'
        '2. Priťahuj päty k zadku.\n'
        '3. Pomaly vráť, závažie nepúšťaj.',
      'calf_raise':
        '1. Špičky na hrane, päty voľne.\n'
        '2. Vystúp čo najvyššie na špičky.\n'
        '3. Pomaly spúšťaj do natiahnutia.',
      'hanging_leg_raise':
        '1. Vis na hrazde, ramená aktívne.\n'
        '2. Silou brucha zdvihni nohy alebo kolená, nehojdaj sa.\n'
        '3. Pomaly spúšťaj.',
      'cable_crunch':
        '1. Kľakni si čelom ku kladke, lano pri hlave.\n'
        '2. Stáčaj trup dole, panva zostáva na mieste.\n'
        '3. Pomaly sa vráť.',
      'dead_bug':
        '1. Ľahni si na chrbát, ruky hore, kolená v 90°.\n'
        '2. Spúšťaj opačnú ruku a nohu, driek zostáva na zemi.\n'
        '3. Vráť sa a vystriedaj strany.',
      'side_plank':
        '1. Ľahni si na bok, lakeť pod ramenom.\n'
        '2. Zdvihni panvu, aby telo tvorilo rovnú líniu.\n'
        '3. Vydrž a potom vystriedaj strany.',
      'burpee':
        '1. Zo stoja drepni a opri dlane o zem.\n'
        '2. Výskokom daj nohy do planku, prípadne urob kľuk.\n'
        '3. Priskoč nohami k rukám a vyskoč.',
      'kettlebell_swing':
        '1. Kettlebell pred tebou, chodidlá o niečo širšie ako panva.\n'
        '2. Predklonom v bedrách ho pošli dozadu medzi nohy.\n'
        '3. Prudkým vystretím bedier ho vyšvihni do výšky hrudníka, ruky uvoľnené.',
      'weighted_pull_up':
        '1. Pripni si kotúč na opasok s reťazou alebo zovri jednoručku medzi chodidlami.\n'
        '2. Vis na hrazde nadhmatom, ramená aktívne stiahnuté.\n'
        '3. Bez švihu sa pritiahni, až je brada nad hrazdou.\n'
        '4. Kontrolovane sa spusti do plného visu. Zapisuj len pridanú záťaž.',
      'weighted_dips':
        '1. Pripni si kotúč na opasok s reťazou alebo zovri jednoručku medzi chodidlami.\n'
        '2. Opri sa na bradlách vo vystretých rukách.\n'
        '3. Spúšťaj sa, až sú ramená zhruba vodorovne.\n'
        '4. Vytlač späť, ramená nepadajú dopredu. Zapisuj len pridanú záťaž.',
      'barbell_shrug':
        '1. Stoj vzpriamene, os drž v natiahnutých pažiach, úchop na šírku ramien.\n'
        '2. Vytiahni ramená kolmo hore k ušiam, paže zostávajú natiahnuté.\n'
        '3. Hore krátko vydrž a pomaly spusti. Ramenami nekrúž.',
      'dumbbell_shrug':
        '1. Stoj s jednoručkami pozdĺž tela, dlane smerujú k telu.\n'
        '2. Vytiahni ramená kolmo hore čo najvyššie.\n'
        '3. Krátko vydrž a kontrolovane spusti.',
      'wrist_curl':
        '1. Sadni si, predlaktia opri o stehná alebo lavičku dlaňami hore, zápästia presahujú okraj.\n'
        '2. Nechaj jednoručky skĺznuť ku končekom prstov.\n'
        '3. Zápästím ich vytoč čo najvyššie, predlaktia sa nehýbu.',
      'reverse_curl':
        '1. Stoj a drž os nadhmatom na šírku ramien.\n'
        '2. Zdvihni os k ramenám, lakte pri tele, zápästia rovné.\n'
        '3. Pomaly spusti do natiahnutých paží.',
      'dead_hang':
        '1. Chyť hrazdu nadhmatom na šírku ramien.\n'
        '2. Vis v natiahnutých pažiach, nohy nad zemou, telo v pokoji.\n'
        '3. Vydrž stanovený čas, ramená mierne aktívne.',
      'back_extension':
        '1. Podložku nastav tesne pod bedrá a zapri päty.\n'
        '2. S rovným chrbtom spusti trup, kým necítiš natiahnutie zadných stehien.\n'
        '3. Zdvihni sa do roviny s nohami, nezakláňaj sa. Pre väčšiu záťaž drž kotúč.',
      'good_morning':
        '1. Os polož na hornú časť chrbta ako pri drepe, chodidlá na šírku panvy, kolená mierne pokrčené.\n'
        '2. Posuň panvu dozadu a s rovným chrbtom sa predkloň, kým nie je trup takmer vodorovne.\n'
        '3. Tlakom panvy dopredu sa vzpriam. Začni s menšou váhou.',
      'superman':
        '1. Ľahni si na brucho, paže natiahnuté pred hlavou.\n'
        '2. Súčasne zdvihni paže, hrudník a nohy nad zem.\n'
        '3. Hore sekundu vydrž a pomaly spusti.',
      'decline_bench_press':
        '1. Zapri nohy na negatívnej lavičke, úchop o niečo širší ako ramená.\n'
        '2. Kontrolovane spusti os k spodnej časti hrudníka.\n'
        '3. Vytlač do natiahnutých paží, lopatky drž stiahnuté.',
      'smith_bench_press':
        '1. Lavičku postav tak, aby os mierila na stred hrudníka.\n'
        '2. Odisti os a kontrolovane ju spusti k hrudníku.\n'
        '3. Vytlač hore bez prudkého zamknutia lakťov, na konci os zaisti.',
      'dumbbell_fly':
        '1. Ľahni si na rovnú lavičku, jednoručky nad hrudníkom, lakte mierne pokrčené.\n'
        '2. Rozpaž širokým oblúkom, kým necítiš natiahnutie hrudníka.\n'
        '3. Vráť jednoručky k sebe, uhol v lakťoch nemeň.',
      'incline_dumbbell_fly':
        '1. Lavičku nastav na 30°, jednoručky nad hrudníkom, lakte povolené.\n'
        '2. Spúšťaj ich širokým oblúkom, kým necítiš natiahnutie hornej časti hrudníka.\n'
        '3. Stiahni ich späť k sebe nad hrudník.',
      'low_to_high_cable_fly':
        '1. Obe kladky nastav dole, postav sa medzi ne v miernom predklone.\n'
        '2. Veď rukoväte hore a k sebe pred hornú časť hrudníka.\n'
        '3. Pomaly sa vráť do natiahnutia, lakte mierne pokrčené.',
      'incline_chest_press_machine':
        '1. Sedadlo nastav tak, aby rukoväte boli vo výške hornej časti hrudníka.\n'
        '2. Tlač rukoväte dopredu a hore do takmer natiahnutých paží.\n'
        '3. Pomaly sa vráť, kým necítiš natiahnutie hrudníka.',
      'chest_dips':
        '1. Opri sa na bradlách a nakloň trup dopredu.\n'
        '2. Spúšťaj sa s lakťami mierne od tela, kým necítiš natiahnutie hrudníka.\n'
        '3. Vytlač späť hore, predklon udrž.',
      'incline_push_up':
        '1. Opri ruky o lavičku alebo debnu, telo v jednej línii.\n'
        '2. Spusti hrudník k hrane, lakte asi 45° od tela.\n'
        '3. Vytlač sa späť. Čím vyššia opora, tým ľahší kľuk.',
      'decline_push_up':
        '1. Nohy opri o lavičku, dlane na zemi pod ramenami.\n'
        '2. So spevneným stredom spusti hrudník k zemi.\n'
        '3. Vytlač sa späť, panva nepadá.',
      'dumbbell_floor_press':
        '1. Ľahni si na zem, kolená pokrčené, jednoručky nad hrudníkom.\n'
        '2. Spúšťaj, kým sa paže nedotknú zeme, krátko vydrž.\n'
        '3. Vytlač späť do natiahnutých paží.',
      't_bar_row':
        '1. Postav sa nad os, s rovným chrbtom sa predkloň a chyť rukoväť.\n'
        '2. Pritiahni záťaž k hrudníku a stiahni lopatky.\n'
        '3. Kontrolovane spusti, chrbát nehrb.',
      'pendlay_row':
        '1. Os na zemi, trup takmer vodorovne, chrbát rovný.\n'
        '2. Výbušne pritiahni os k spodnej časti hrudníka.\n'
        '3. Po každom opakovaní ju polož na zem a uprav polohu.',
      'machine_row':
        '1. Sadni si hrudníkom k opierke a chyť rukoväte.\n'
        '2. Pritiahni rukoväte k telu, lakte pri tele, lopatky k sebe.\n'
        '3. Pomaly sa vráť do natiahnutých paží.',
      'chest_supported_row':
        '1. Ľahni si na brucho na lavičku nastavenú na 30–45°, jednoručky visia dole.\n'
        '2. Pritiahni ich k bokom a stiahni lopatky.\n'
        '3. Pomaly spusti do plného natiahnutia.',
      'close_grip_lat_pulldown':
        '1. Sadni si ku kladke s úzkou alebo V rukoväťou, stehná pod opierkami.\n'
        '2. Stiahni rukoväť k hornej časti hrudníka, lakte dole a dozadu.\n'
        '3. Pomaly ju pusti hore do natiahnutých paží.',
      'straight_arm_pulldown':
        '1. Stoj čelom k hornej kladke, paže takmer natiahnuté, mierny predklon.\n'
        '2. Chrbtom stiahni os oblúkom až k stehnám.\n'
        '3. Pomaly ju pusti späť, lakte zostávajú takmer natiahnuté.',
      'band_assisted_pull_up':
        '1. Prehoď odporovú gumu cez hrazdu a opri do nej chodidlo alebo koleno.\n'
        '2. Pritiahni sa, kým nie je brada nad hrazdou.\n'
        '3. Kontrolovane sa spusti do visu. Tenšia guma = menšia dopomoc.',
      'inverted_row':
        '1. Zaves sa pod nízku hrazdu alebo kruhy, telo rovné, päty na zemi.\n'
        '2. Pritiahni hrudník k hrazde a stiahni lopatky.\n'
        '3. Kontrolovane sa spusti. Čím viac v stoji, tým ľahšie.',
      'neutral_grip_pull_up':
        '1. Zaves sa na rovnobežné madlá, dlane oproti sebe.\n'
        '2. Pritiahni sa, kým nie je brada nad madlami.\n'
        '3. Kontrolovane sa spusti do plného visu.',
      'rack_pull':
        '1. Os polož na zarážky stojana tesne pod alebo nad kolená.\n'
        '2. Chyť ju, spevni stred a vstaň tlakom panvy dopredu.\n'
        '3. S rovným chrbtom ju vráť na zarážky.',
      'trap_bar_deadlift':
        '1. Postav sa dovnútra trap baru, chodidlá na šírku panvy, chyť madlá.\n'
        '2. Spevni sa, odtlač podlahu a vstaň do vzpriamenej polohy.\n'
        '3. S rovným chrbtom os vráť na zem.',
      'single_arm_cable_row':
        '1. Chyť jednu rukoväť na kladke vo výške pása, paža natiahnutá.\n'
        '2. Pritiahni ju k boku, lakeť pri tele.\n'
        '3. Pomaly sa vráť a nechaj rameno mierne vysunúť dopredu.',
      'dumbbell_pullover':
        '1. Ľahni si na lavičku a drž jednu jednoručku oboma rukami nad hrudníkom.\n'
        '2. Oblúkom ju spusti za hlavu, lakte mierne pokrčené.\n'
        '3. Pretiahni ju späť nad hrudník.',
      'renegade_row':
        '1. Zaujmi pozíciu kľuku s rukami na jednoručkách, nohy široko.\n'
        '2. Pritiahni jednu jednoručku k boku, panvu nevytáčaj.\n'
        '3. Polož ju a opakuj druhou rukou.',
      'arnold_press':
        '1. Sadni si, jednoručky drž pred ramenami dlaňami k sebe.\n'
        '2. Tlač hore a cestou otáčaj dlane dopredu.\n'
        '3. Spúšťaj a vracaj dlane do východiskovej polohy.',
      'shoulder_press_machine':
        '1. Sedadlo nastav tak, aby rukoväte začínali vo výške ramien.\n'
        '2. Tlač hore do takmer natiahnutých paží.\n'
        '3. Pomaly sa vráť do výšky ramien.',
      'push_press':
        '1. Os vpredu na ramenách, chodidlá na šírku panvy.\n'
        '2. Mierne podrepni a švihom nôh vytlač os nad hlavu.\n'
        '3. Kontrolovane ju vráť na ramená.',
      'cable_lateral_raise':
        '1. Stoj bokom k spodnej kladke, rukoväť drž vzdialenejšou rukou.\n'
        '2. Upaž do výšky ramien.\n'
        '3. Pomaly spusti, kladku nenechaj povoliť.',
      'machine_lateral_raise':
        '1. Sadni si, opierky ti ležia z vonkajšej strany paží.\n'
        '2. Upaž do výšky ramien.\n'
        '3. Pomaly spusti, záťaž neodkladaj.',
      'front_raise':
        '1. Stoj s jednoručkami pred stehnami.\n'
        '2. Predpaž do výšky ramien, paže takmer natiahnuté.\n'
        '3. Pomaly spusti, nešvihaj.',
      'upright_row':
        '1. Drž os pred stehnami, úchop zhruba na šírku ramien.\n'
        '2. Ťahaj ju pozdĺž tela do výšky hrudníka, vedú lakte.\n'
        '3. Pomaly spusti. Keď tlačia ramená, nechoď tak vysoko.',
      'reverse_pec_deck':
        '1. Sadni si čelom k stroju, hrudník na opierke, chyť rukoväte.\n'
        '2. Oblúkom rozpaž dozadu do roviny s telom.\n'
        '3. Pomaly sa vráť.',
      'band_pull_apart':
        '1. Drž gumu pred sebou vo výške ramien v natiahnutých pažiach.\n'
        '2. Roztiahni ju až k hrudníku a stiahni lopatky.\n'
        '3. Pomaly sa vráť.',
      'handstand_push_up':
        '1. Vyšvihni sa do stojky pri stene, ruky na šírku ramien.\n'
        '2. Kontrolovane spúšťaj hlavu k zemi.\n'
        '3. Vytlač sa do natiahnutých paží. Pod hlavu daj podložku.',
      'landmine_press':
        '1. Drž koniec landmine osi pri ramene, nohy v miernom výkroku.\n'
        '2. Tlač ju hore a dopredu do natiahnutej paže.\n'
        '3. Kontrolovane ju vráť k ramenu.',
      'preacher_curl':
        '1. Sadni si k Scottovej lavičke, paže celou plochou na opierke, EZ os v rukách.\n'
        '2. Zdvihni os, lakte z opierky nedvíhaj.\n'
        '3. Pomaly spusti takmer do natiahnutia.',
      'concentration_curl':
        '1. Sadni si na lavičku, lakeť opri o vnútornú stranu stehna.\n'
        '2. Zdvihni jednoručku k ramenu.\n'
        '3. Pomaly spusti do plného natiahnutia.',
      'incline_dumbbell_curl':
        '1. Opri sa o lavičku nastavenú na 45–60°, paže visia dole.\n'
        '2. Zdvihni jednoručky, ramená sa nehýbu.\n'
        '3. Pomaly spusti do plného natiahnutia.',
      'ez_bar_curl':
        '1. Stoj a drž EZ os za zalomené miesta, paže natiahnuté.\n'
        '2. Zdvihni ju bez švihu telom.\n'
        '3. Pomaly spusti do natiahnutých paží.',
      'rope_hammer_curl':
        '1. Na spodnú kladku pripni lano, dlane oproti sebe.\n'
        '2. Zdvihni lano, lakte pri tele.\n'
        '3. Pomaly spusti, kladku nenechaj povoliť.',
      'machine_biceps_curl':
        '1. Sadni si, paže opri o opierku a chyť rukoväte.\n'
        '2. Zdvihni rukoväte k ramenám.\n'
        '3. Pomaly spusti takmer do natiahnutia.',
      'band_curl':
        '1. Postav sa na stred gumy, konce drž v rukách.\n'
        '2. Zdvihni ruky k ramenám, lakte pri tele.\n'
        '3. Pomaly spusti.',
      'rope_pushdown':
        '1. Chyť lano na hornej kladke, lakte pri tele.\n'
        '2. Stiahni lano dole a dole roztiahni konce od seba.\n'
        '3. Pomaly ho pusti hore zhruba do pravého uhla v lakti.',
      'overhead_cable_extension':
        '1. Stoj chrbtom ku kladke, lano za hlavou, lakte hore.\n'
        '2. Natiahni paže dopredu a hore.\n'
        '3. Pomaly pokrč lakte späť za hlavu.',
      'triceps_kickback':
        '1. Predkloň sa, rameno rovnobežne s telom, lakeť pokrčený.\n'
        '2. Natiahni pažu dozadu.\n'
        '3. Pomaly ju pokrč späť, rameno sa nehýbe.',
      'bench_dips':
        '1. Opri dlane o hranu lavičky za sebou, nohy natiahnuté vpred.\n'
        '2. Pokrčením lakťov do pravého uhla sa spusti.\n'
        '3. Vytlač sa späť do natiahnutých paží.',
      'machine_triceps_dip':
        '1. Sadni si do stroja a chyť rukoväte po stranách.\n'
        '2. Stlač rukoväte dole do natiahnutých paží.\n'
        '3. Pomaly ich pusti hore zhruba do pravého uhla v lakti.',
      'single_arm_pushdown':
        '1. Chyť jednu rukoväť na hornej kladke, lakeť pri tele.\n'
        '2. Stlač ju dole do natiahnutej paže.\n'
        '3. Pomaly ju pusti hore, lakeť zostáva na mieste.',
      'diamond_push_up':
        '1. Pozícia kľuku, dlane pri sebe pod hrudníkom, prsty tvoria kosoštvorec.\n'
        '2. Spusti hrudník k dlaniam, lakte pri tele.\n'
        '3. Vytlač sa späť, telo rovné.',
      'reverse_wrist_curl':
        '1. Sadni si, predlaktia opri o stehná dlaňami dole, zápästia presahujú kolená.\n'
        '2. Zdvihni chrbty rúk čo najvyššie.\n'
        '3. Pomaly spusti.',
      'hack_squat':
        '1. Postav sa na plošinu, chrbát na opierke, ramená pod vankúšmi.\n'
        '2. Drepni, kým nie sú stehná aspoň rovnobežne s plošinou.\n'
        '3. Vytlač sa späť celým chodidlom.',
      'smith_squat':
        '1. Os na hornej časti chrbta, chodidlá mierne pred osou.\n'
        '2. S rovným chrbtom drepni aspoň do vodorovnej polohy stehien.\n'
        '3. Vstaň a na konci os zaisti.',
      'walking_lunge':
        '1. Drž jednoručky pozdĺž tela a urob dlhý krok vpred.\n'
        '2. Spusti zadné koleno takmer k zemi.\n'
        '3. Odraz sa prednou nohou a hneď pokračuj ďalším výpadom.',
      'reverse_lunge':
        '1. Stoj vzpriamene s jednoručkami pozdĺž tela.\n'
        '2. Ukroč dozadu a spusti zadné koleno takmer k zemi.\n'
        '3. Tlakom prednej nohy sa vráť. Striedaj nohy.',
      'step_up':
        '1. Postav sa pred lavičku alebo debnu s jednoručkami v rukách.\n'
        '2. Polož jednu nohu hore a vystúp tlakom tejto nohy.\n'
        '3. Pomaly zostúp. Striedaj nohy alebo cvič jednu stranu po druhej.',
      'split_squat':
        '1. Postav sa do dlhého výkroku s jednoručkami v rukách.\n'
        '2. Spúšťaj sa zvislo dole, kým sa zadné koleno takmer nedotkne zeme.\n'
        '3. Vytlač sa späť. Dokonči opakovania a vymeň nohy.',
      'sumo_squat':
        '1. Široký postoj, špičky von, jednu jednoručku drž medzi nohami.\n'
        '2. Drepni so vzpriameným trupom, kolená mieria v smere špičiek.\n'
        '3. Vstaň a zatni zadok.',
      'pistol_squat':
        '1. Postav sa na jednu nohu, druhú natiahni pred seba.\n'
        '2. Kontrolovane drepni čo najhlbšie, ruky vpredu pre rovnováhu.\n'
        '3. Vstaň. Na začiatku sa môžeš niečoho pridržať.',
      'single_leg_press':
        '1. Sadni si do legpressu, jednu nohu daj doprostred plošiny.\n'
        '2. Spúšťaj plošinu, kým nie je koleno zhruba v pravom uhle.\n'
        '3. Vytlač späť bez zamknutia kolena. Vymeň nohy.',
      'hip_adduction_machine':
        '1. Sadni si do stroja, vankúše máš z vnútornej strany kolien.\n'
        '2. Stiahni nohy k sebe.\n'
        '3. Pomaly ich roztiahni späť.',
      'wall_sit':
        '1. Opri sa chrbtom o stenu a zíď dole.\n'
        '2. Zastav, keď sú kolená zhruba v pravom uhle, chodidlá pod kolenami.\n'
        '3. Vydrž stanovený čas, chrbát celou plochou pri stene.',
      'jump_squat':
        '1. Postav sa, chodidlá na šírku ramien.\n'
        '2. Drepni a výbušne vyskoč.\n'
        '3. Mäkko dopadni a hneď pokračuj ďalším drepom.',
      'box_jump':
        '1. Postav sa pred stabilnú debnu.\n'
        '2. Švihni pažami a vyskoč na debnu, dopadni mäkko.\n'
        '3. Vzpriam sa a zostúp dole.',
      'seated_leg_curl':
        '1. Sadni si do stroja, vankúš nad pätami, stehná zaistené zhora.\n'
        '2. Pritiahni päty čo najviac dole a dozadu.\n'
        '3. Pomaly sa vráť.',
      'nordic_curl':
        '1. Kľakni si a zapri päty pod niečo pevné.\n'
        '2. Čo najpomalšie padaj trupom dopredu, bedrá rovné.\n'
        '3. Zachyť sa rukami a zadnými stehnami sa pritiahni späť.',
      'single_leg_rdl':
        '1. Stoj na jednej nohe s jednoručkou v ruke, koleno mierne pokrčené.\n'
        '2. Predkloň sa a voľnú nohu natiahni dozadu, chrbát rovný.\n'
        '3. Tlakom panvy dopredu sa vzpriam.',
      'dumbbell_romanian_deadlift':
        '1. Stoj s jednoručkami pred stehnami, kolená povolené.\n'
        '2. Posuň panvu dozadu a jednoručky veď pozdĺž nôh dole.\n'
        '3. Pri natiahnutí zadných stehien sa zastav a vzpriam sa.',
      'stiff_leg_deadlift':
        '1. Stoj s osou v rukách, nohy takmer natiahnuté.\n'
        '2. S rovným chrbtom sa predkloň a spúšťaj os pozdĺž nôh.\n'
        '3. Zatnutím zadných stehien a zadku sa vzpriam.',
      'stability_ball_leg_curl':
        '1. Ľahni si na chrbát, päty na gymnastickej lopte, panva zdvihnutá.\n'
        '2. Pokrčením kolien pritiahni loptu k sebe.\n'
        '3. Pomaly ju odkotúľaj späť, panva zostáva hore.',
      'sumo_deadlift':
        '1. Široký postoj, špičky von, os chyť medzi nohami.\n'
        '2. Spevni sa, tlač kolená von a vstaň s osou tesne pri tele.\n'
        '3. S rovným chrbtom ju vráť na zem.',
      'cable_glute_kickback':
        '1. Na spodnú kladku pripni manžetu na členok a pridrž sa stroja.\n'
        '2. Zatnutím zadku zanož nohu dozadu a hore.\n'
        '3. Pomaly sa vráť, v krížoch sa neprehýbaj.',
      'hip_abduction_machine':
        '1. Sadni si do stroja, vankúše máš z vonkajšej strany kolien.\n'
        '2. Roztiahni nohy od seba čo najviac.\n'
        '3. Pomaly ich vráť k sebe.',
      'machine_hip_thrust':
        '1. Opri hornú časť chrbta o opierku a pás si daj cez panvu.\n'
        '2. Vytlač panvu hore do roviny od kolien k ramenám.\n'
        '3. Hore zatni zadok a pomaly spusti.',
      'single_leg_glute_bridge':
        '1. Ľahni si na chrbát, jedno chodidlo na zemi, druhú nohu natiahni hore.\n'
        '2. Tlakom päty opretej nohy zdvihni panvu.\n'
        '3. Pomaly spusti. Dokonči opakovania a vymeň nohy.',
      'donkey_kick':
        '1. Kľakni si na všetky štyri, dlane pod ramenami.\n'
        '2. Pokrčenú nohu zdvihni dozadu, chodidlo mieri k stropu.\n'
        '3. Pomaly spusti, v chrbte sa neprehýbaj.',
      'fire_hydrant':
        '1. Kľakni si na všetky štyri, chrbát rovný.\n'
        '2. Pokrčenú nohu zdvihni do strany do výšky panvy.\n'
        '3. Pomaly spusti, panva zostáva rovno.',
      'banded_lateral_walk':
        '1. Natiahni si mini gumu nad kolená alebo členky a mierne pokrč kolená.\n'
        '2. Kráčaj do strany, guma zostáva napnutá.\n'
        '3. Počítaj kroky jedným smerom a potom sa vráť.',
      'cable_pull_through':
        '1. Stoj chrbtom k spodnej kladke, lano medzi nohami.\n'
        '2. S rovným chrbtom sa predkloň a nechaj lano odísť dozadu.\n'
        '3. Tlakom panvy dopredu sa vzpriam a zatni zadok.',
      'seated_calf_raise':
        '1. Sadni si, vankúš na stehnách, predná časť chodidiel na nášľapnej ploche.\n'
        '2. Zdvihni päty čo najvyššie.\n'
        '3. Pomaly spusti do plného natiahnutia.',
      'single_leg_calf_raise':
        '1. Postav sa jednou nohou na hranu schodu a pridrž sa.\n'
        '2. Vytiahni sa na špičku čo najvyššie.\n'
        '3. Spusti pätu pod úroveň schodu do plného natiahnutia.',
      'leg_press_calf_raise':
        '1. Sadni si do legpressu, predná časť chodidiel na spodnej hrane plošiny.\n'
        '2. Natiahnutím špičiek odtlač plošinu.\n'
        '3. Pomaly ju pusti späť do natiahnutia. Kolená drž natiahnuté.',
      'sit_up':
        '1. Ľahni si na chrbát, kolená pokrčené, chodidlá na zemi.\n'
        '2. Postupne sa zdvihni až do sedu.\n'
        '3. Pomaly sa vráť do ľahu.',
      'decline_sit_up':
        '1. Zapri nohy na negatívnej lavičke a ľahni si.\n'
        '2. Zdvihni sa, kým nie je trup zvislo.\n'
        '3. Pomaly sa vráť. Pre väčšiu záťaž drž kotúč.',
      'bicycle_crunch':
        '1. Ľahni si na chrbát, ruky pri hlave, nohy zdvihnuté.\n'
        '2. Pritiahni lakeť k opačnému kolenu, druhú nohu natiahni.\n'
        '3. Striedaj strany ako pri šliapaní na bicykli.',
      'reverse_crunch':
        '1. Ľahni si na chrbát, kolená v pravom uhle, ruky na zemi.\n'
        '2. Zdvihni panvu a pritiahni kolená k hrudníku.\n'
        '3. Pomaly spusti, nešvihaj.',
      'lying_leg_raise':
        '1. Ľahni si na chrbát, nohy natiahnuté, kríže pritlačené k zemi.\n'
        '2. Zdvihni nohy, kým nemieria k stropu.\n'
        '3. Pomaly spusti, kríže sa neprehýbajú.',
      'captains_chair_knee_raise':
        '1. Opri sa predlaktiami o opierky, chrbát o operadlo.\n'
        '2. Pritiahni kolená k hrudníku.\n'
        '3. Pomaly spusti, nešvihaj.',
      'ab_wheel_rollout':
        '1. Kľakni si a drž koliesko pod ramenami.\n'
        '2. Choď s kolieskom dopredu čo najďalej, kríže sa neprehýbajú.\n'
        '3. Bruchom sa pritiahni späť.',
      'russian_twist':
        '1. Sadni si s miernym záklonom, nohy zdvihnuté alebo na zemi.\n'
        '2. Otoč trup a dotkni sa zeme vedľa boku.\n'
        '3. Otoč sa na druhú stranu. Pre väčšiu záťaž drž závažie.',
      'v_up':
        '1. Ľahni si na chrbát, paže za hlavou, nohy natiahnuté.\n'
        '2. Súčasne zdvihni paže aj nohy a dotkni sa špičiek.\n'
        '3. Pomaly sa vráť do ľahu.',
      'hollow_hold':
        '1. Ľahni si na chrbát a pritlač kríže k zemi.\n'
        '2. Zdvihni ramená a natiahnuté nohy kúsok nad zem.\n'
        '3. Vydrž stanovený čas, kríže sa neprehýbajú.',
      'pallof_press':
        '1. Stoj bokom ku kladke vo výške hrudníka, rukoväť pri hrudníku.\n'
        '2. Vytlač rukoväť rovno pred seba a nedovoľ telu sa otočiť.\n'
        '3. Vráť ju k hrudníku. Cvič obe strany.',
      'cable_woodchopper':
        '1. Stoj bokom k hornej kladke, rukoväť drž oboma rukami.\n'
        '2. Ťahaj ju šikmo dole cez telo a otáčaj trup.\n'
        '3. Pomaly sa vráť. Cvič obe strany.',
      'plank_shoulder_tap':
        '1. Zaujmi pozíciu vysokého planku, nohy mierne od seba.\n'
        '2. Jednou rukou sa dotkni opačného ramena, panva sa nehojdá.\n'
        '3. Vymeň ruky.',
      'bird_dog':
        '1. Kľakni si na všetky štyri, chrbát rovný.\n'
        '2. Natiahni jednu ruku dopredu a opačnú nohu dozadu.\n'
        '3. Chvíľu vydrž, vráť sa a vymeň strany.',
      'power_clean':
        '1. Stoj nad osou, úchop tesne zvonka kolien, chrbát rovný.\n'
        '2. Výbušne ťahaj os pozdĺž tela hore a zachyť ju vpredu na ramenách.\n'
        '3. Vzpriam sa a os spusti. Techniku sa uč s ľahkou osou.',
      'thruster':
        '1. Os drž vpredu na ramenách.\n'
        '2. Drepni a pri vstávaní ju jedným pohybom vytlač nad hlavu.\n'
        '3. Vráť os na ramená a hneď pokračuj ďalším drepom.',
      'turkish_get_up':
        '1. Ľahni si na chrbát a drž kettlebell v jednej ruke nad sebou.\n'
        '2. Krok za krokom sa postav, kettlebell sleduj očami a pažu drž natiahnutú.\n'
        '3. Rovnakou cestou sa vráť do ľahu. Cvič obe strany.',
      'bear_crawl':
        '1. Opri sa o ruky a chodidlá, kolená kúsok nad zemou, chrbát rovný.\n'
        '2. Lez dopredu, súčasne posúvaj opačnú ruku a nohu.\n'
        '3. Panvu drž nízko stanovený čas.',
      'high_knees':
        '1. Bež na mieste a dvíhaj kolená do výšky panvy.\n'
        '2. Pracuj pažami a zostaň na prednej časti chodidiel.\n'
        '3. Drž rýchle tempo stanovený čas.',
      'jump_rope':
        '1. Drž rukoväte pri bokoch, lakte blízko tela.\n'
        '2. Toč švihadlom zápästím a skáč len tak vysoko, aby prešlo.\n'
        '3. Mäkko dopadaj na prednú časť chodidiel stanovený čas.',
      'rowing_machine':
        '1. Pripni si nohy a chyť madlo v natiahnutých pažiach.\n'
        '2. Odraz sa nohami, mierne sa zakloň a pritiahni madlo k spodným rebrám.\n'
        '3. Vracaj sa v opačnom poradí: paže, trup, nohy. Drž stále tempo.',
      'stationary_bike':
        '1. Sedlo nastav tak, aby bolo koleno v spodnej polohe pedálu mierne pokrčené.\n'
        '2. Šliapaj stálym tempom s rovným chrbtom.\n'
        '3. Odpor nastav podľa cieľa a jazdi stanovený čas.',
      'treadmill_run':
        '1. Začni chôdzou a postupne zvyšuj rýchlosť.\n'
        '2. Bež vzpriamene s uvoľnenými ramenami, dopadaj pod panvu.\n'
        '3. Pred zostúpením spomaľ do chôdze.',
      'elliptical':
        '1. Postav sa na pedále a chyť pohyblivé madlá.\n'
        '2. Pohybuj sa plynulo a zapoj aj paže tlakom a ťahom.\n'
        '3. Drž stále tempo stanovený čas.',
      'stair_climber':
        '1. Postav sa na schody a zvoľ rýchlosť, ktorú udržíš.\n'
        '2. Stúpaj vzpriamene, zábradlie používaj len zľahka na rovnováhu.\n'
        '3. Pokračuj stanovený čas.',
      'air_bike':
        '1. Sadni si na bicykel a chyť pohyblivé madlá.\n'
        '2. Šliapaj a zároveň tlač a ťahaj madlá.\n'
        '3. Čím viac pridáš, tým viac ventilátor brzdí. Jazdi stanovený čas.',
    },
    routineNames: {
      'home_upper': 'Horná polovica tela za 5 minút',
      'home_lower': 'Nohy za 5 minút',
      'home_full': 'Celé telo za 5 minút',
    },
    programNames: {
      'full_body': 'Celé telo (začiatočník)',
      'upper_lower': 'Horná / dolná polovica',
      'ppl': 'Push / Pull / Nohy',
      'full_body_2x': 'Celé telo 2× týždenne',
      'dumbbell_home': 'Jednoručky doma',
      'strength_5x5': 'Sila 5×5',
      'circuit': 'Kruhový tréning (výdrž)',
      'full_body_variation': 'Celé telo – obmena',
      'bodyweight_home': 'Vlastná váha doma',
      'machines': 'Stroje (začiatočník)',
      'upper_lower_variation': 'Horná / dolná – obmena',
      'ppl_variation': 'Push / Pull / Nohy – obmena',
      'strength_dup': 'Sila – týždenné vlny',
      'conditioning_intervals': 'Kondícia – intervaly',
      'phul': 'Sila + objem (PHUL)',
      'strength_advanced': 'Sila – 4 dni (pokročilý)',
      'ppl_6x': 'Push / Pull / Nohy 6× týždenne',
    },
    programDescriptions: {
      'full_body':
        '3× týždenne, striedanie tréningov A a B. Ideálne na prvé mesiace.',
      'upper_lower': '4× týždenne: horná polovica Po + Št, dolná Ut + Pi.',
      'ppl': '3× týždenne: tlaky Po, príťahy St, nohy Pi.',
      'full_body_2x':
        'Na nabité týždne: 2 tréningy zhruba na hodinu, Po + Št. Každá partia 2× týždenne.',
      'dumbbell_home':
        '3× týždenne s párom jednoručiek a podložkou, striedanie A a B. Bez posilňovne.',
      'strength_5x5':
        '3× týždenne, striedanie A a B: 5 sérií po 5 pri veľkých cvikoch. Keď dáš všetky série po 5, váha ide hore.',
      'circuit':
        '3× týždenne, striedanie A a B: cviky v kruhu za sebou, krátke pauzy, veľa opakovaní. Na výdrž a kondíciu.',
      'full_body_variation':
        '3× týždenne, striedanie C a D. Rovnaká stavba ako Celé telo (začiatočník), iné cviky – striedaj po 6–8 týždňoch.',
      'bodyweight_home':
        '3× týždenne, striedanie A a B, bez vybavenia – stačí podložka (a pevný stôl na príťahy). Na začiatok aj na cesty.',
      'machines':
        '3× týždenne, striedanie A a B, na strojoch v posilňovni: ľahko sa naučíš, bezpečné aj bez istenia. Dobrý prvý krok pred voľnými váhami.',
      'upper_lower_variation':
        '4× týždenne ako Horná / dolná polovica, s inými cvikmi (šikmý bench, predný drep, hip thrust). Striedaj po 6–8 týždňoch.',
      'ppl_variation':
        '3× týždenne ako Push / Pull / Nohy, s inými cvikmi (najprv tlaky nad hlavu, príťahy v predklone, hack drep). Striedaj po 6–8 týždňoch.',
      'strength_dup':
        '3× týždenne: ťažký deň (série po 3), objemový deň (6–8 opakovaní) a stredný deň (série po 5). Striedanie záťaže v týždni udrží rast sily aj po prvom roku.',
      'conditioning_intervals':
        '3× týždenne, striedanie A a B: dvojice silového a kardio cviku hneď po sebe, na konci súvislé kardio. Na kondíciu, výdrž a chudnutie.',
      'phul':
        '4× týždenne: ťažké dni hornej a dolnej polovice na silu (Po, Ut), dni s viac opakovaniami na svaly (Št, Pi). Zhruba 12–16 sérií na partiu týždenne.',
      'strength_advanced':
        '4× týždenne, každý deň jeden veľký cvik (drep, bench, mŕtvy ťah, tlak nad hlavu): ťažké série po 3, príbuzná varianta a doplnky na slabé miesta.',
      'ppl_6x':
        'Po–So: Push, Pull, Nohy, potom Push B, Pull B, Nohy B. Každá partia 2× týždenne s vysokým objemom – pre skúsených s dobrou regeneráciou.',
    },
    planNames: {
      'Full body A': 'Celé telo A',
      'Full body B': 'Celé telo B',
      'Upper body': 'Horná polovica',
      'Lower body': 'Dolná polovica',
      'Push': 'Push (tlaky)',
      'Pull': 'Pull (príťahy)',
      'Legs': 'Nohy',
      'Full body 2× A': 'Celé telo 2× A',
      'Full body 2× B': 'Celé telo 2× B',
      'Dumbbells A': 'Jednoručky A',
      'Dumbbells B': 'Jednoručky B',
      '5×5 A': '5×5 A',
      '5×5 B': '5×5 B',
      'Circuit A': 'Kruh A',
      'Circuit B': 'Kruh B',
      'Full body C': 'Celé telo C',
      'Full body D': 'Celé telo D',
      'Bodyweight A': 'Vlastná váha A',
      'Bodyweight B': 'Vlastná váha B',
      'Machines A': 'Stroje A',
      'Machines B': 'Stroje B',
      'Upper body B': 'Horná polovica B',
      'Lower body B': 'Dolná polovica B',
      'Push B': 'Push B (tlaky)',
      'Pull B': 'Pull B (príťahy)',
      'Legs B': 'Nohy B',
      'Strength: heavy day': 'Sila: ťažký deň',
      'Strength: volume day': 'Sila: objemový deň',
      'Strength: medium day': 'Sila: stredný deň',
      'Intervals A': 'Intervaly A',
      'Intervals B': 'Intervaly B',
      'Upper power': 'Horná – sila',
      'Lower power': 'Dolná – sila',
      'Upper hypertrophy': 'Horná – objem',
      'Lower hypertrophy': 'Dolná – objem',
      'Strength: squat': 'Sila: drep',
      'Strength: bench': 'Sila: bench',
      'Strength: deadlift': 'Sila: mŕtvy ťah',
      'Strength: overhead press': 'Sila: tlak nad hlavu',
    },
  ),
  'nl': (
    exerciseNames: {
      'bench_press': 'Bench press',
      'incline_dumbbell_press': 'Incline dumbbell press',
      'cable_fly': 'Cable fly',
      'push_up': 'Opdrukken',
      'deadlift': 'Deadlift',
      'barbell_row': 'Barbell row',
      'lat_pulldown': 'Lat pulldown',
      'pull_up': 'Optrekken',
      'overhead_press': 'Overhead press',
      'lateral_raise': 'Lateral raise',
      'pike_push_up': 'Pike push-up',
      'dumbbell_curl': 'Dumbbell curl',
      'triceps_pushdown': 'Triceps pushdown',
      'dips': 'Dips',
      'back_squat': 'Squat',
      'leg_press': 'Leg press',
      'romanian_deadlift': 'Roemeense deadlift',
      'bodyweight_squat': 'Squat met eigen gewicht',
      'lunge': 'Lunge',
      'hip_thrust': 'Hip thrust',
      'glute_bridge': 'Glute bridge',
      'plank': 'Plank',
      'crunch': 'Crunch',
      'mountain_climber': 'Mountain climber',
      'jumping_jack': 'Jumping jack',
      'dumbbell_bench_press': 'Dumbbell bench press',
      'incline_bench_press': 'Incline bench press',
      'chest_press_machine': 'Chest press (machine)',
      'pec_deck': 'Pec deck',
      'seated_cable_row': 'Seated cable row',
      'one_arm_dumbbell_row': 'Eenarmige dumbbell row',
      'chin_up': 'Chin-up',
      'dumbbell_shoulder_press': 'Dumbbell shoulder press',
      'rear_delt_fly': 'Rear delt fly',
      'face_pull': 'Face pull',
      'barbell_curl': 'Barbell curl',
      'hammer_curl': 'Hammer curl',
      'cable_curl': 'Cable curl',
      'skull_crusher': 'Skull crusher',
      'overhead_triceps_extension': 'Overhead triceps extension',
      'close_grip_bench_press': 'Close-grip bench press',
      'front_squat': 'Front squat',
      'goblet_squat': 'Goblet squat',
      'bulgarian_split_squat': 'Bulgarian split squat',
      'leg_extension': 'Leg extension',
      'leg_curl': 'Leg curl',
      'calf_raise': 'Calf raise',
      'hanging_leg_raise': 'Hanging leg raise',
      'cable_crunch': 'Cable crunch',
      'dead_bug': 'Dead bug',
      'side_plank': 'Zijplank',
      'burpee': 'Burpee',
      'kettlebell_swing': 'Kettlebell swing',
      'weighted_pull_up': 'Optrekken met extra gewicht',
      'weighted_dips': 'Dips met extra gewicht',
      'barbell_shrug': 'Barbell shrugs',
      'dumbbell_shrug': 'Dumbbell shrugs',
      'wrist_curl': 'Polscurls',
      'reverse_curl': 'Reverse curls',
      'dead_hang': 'Hangen aan de stang',
      'back_extension': 'Rugextensies (hyperextensions)',
      'good_morning': 'Good mornings',
      'superman': 'Superman',
      'decline_bench_press': 'Decline bench press',
      'smith_bench_press': 'Bench press in de Smith machine',
      'dumbbell_fly': 'Dumbbell flyes',
      'incline_dumbbell_fly': 'Incline dumbbell flyes',
      'low_to_high_cable_fly': 'Cable flyes van laag naar hoog',
      'incline_chest_press_machine': 'Incline chest press machine',
      'chest_dips': 'Dips voor de borst',
      'incline_push_up': 'Incline push-ups',
      'decline_push_up': 'Decline push-ups',
      'dumbbell_floor_press': 'Floor press met dumbbells',
      't_bar_row': 'T-bar row',
      'pendlay_row': 'Pendlay row',
      'machine_row': 'Roeien op de machine',
      'chest_supported_row': 'Dumbbell row op de incline bank',
      'close_grip_lat_pulldown': 'Lat pulldown met smalle greep',
      'straight_arm_pulldown': 'Straight-arm pulldown',
      'band_assisted_pull_up': 'Pull-ups met weerstandsband',
      'inverted_row': 'Inverted row',
      'neutral_grip_pull_up': 'Pull-ups met neutrale greep',
      'rack_pull': 'Rack pull',
      'trap_bar_deadlift': 'Trap bar deadlift',
      'single_arm_cable_row': 'Eenarmig kabelroeien',
      'dumbbell_pullover': 'Dumbbell pullover',
      'renegade_row': 'Renegade row',
      'arnold_press': 'Arnold press',
      'shoulder_press_machine': 'Shoulder press machine',
      'push_press': 'Push press',
      'cable_lateral_raise': 'Lateral raise aan de kabel',
      'machine_lateral_raise': 'Lateral raise op de machine',
      'front_raise': 'Front raise met dumbbells',
      'upright_row': 'Upright row',
      'reverse_pec_deck': 'Reverse pec deck',
      'band_pull_apart': 'Band pull-aparts',
      'handstand_push_up': 'Handstand push-ups',
      'landmine_press': 'Landmine press',
      'preacher_curl': 'Preacher curl',
      'concentration_curl': 'Concentratiecurl',
      'incline_dumbbell_curl': 'Incline dumbbell curl',
      'ez_bar_curl': 'EZ-bar curl',
      'rope_hammer_curl': 'Hammer curl met touw',
      'machine_biceps_curl': 'Bicepscurl op de machine',
      'band_curl': 'Bicepscurl met band',
      'rope_pushdown': 'Triceps pushdown met touw',
      'overhead_cable_extension': 'Overhead triceps extensie aan de kabel',
      'triceps_kickback': 'Triceps kickback',
      'bench_dips': 'Bench dips',
      'machine_triceps_dip': 'Dipmachine',
      'single_arm_pushdown': 'Eenarmige triceps pushdown',
      'diamond_push_up': 'Diamond push-ups',
      'reverse_wrist_curl': 'Reverse polscurls',
      'hack_squat': 'Hack squat',
      'smith_squat': 'Squat in de Smith machine',
      'walking_lunge': 'Walking lunges',
      'reverse_lunge': 'Reverse lunges',
      'step_up': 'Step-ups',
      'split_squat': 'Split squat',
      'sumo_squat': 'Sumo squat met dumbbell',
      'pistol_squat': 'Pistol squat',
      'single_leg_press': 'Eenbenige leg press',
      'hip_adduction_machine': 'Adductormachine',
      'wall_sit': 'Wall sit',
      'jump_squat': 'Jump squats',
      'box_jump': 'Box jumps',
      'seated_leg_curl': 'Zittende leg curl',
      'nordic_curl': 'Nordic hamstring curl',
      'single_leg_rdl': 'Eenbenige Roemeense deadlift',
      'dumbbell_romanian_deadlift': 'Roemeense deadlift met dumbbells',
      'stiff_leg_deadlift': 'Stiff-leg deadlift',
      'stability_ball_leg_curl': 'Leg curl op de fitnessbal',
      'sumo_deadlift': 'Sumo deadlift',
      'cable_glute_kickback': 'Glute kickback aan de kabel',
      'hip_abduction_machine': 'Abductormachine',
      'machine_hip_thrust': 'Hip thrust machine',
      'single_leg_glute_bridge': 'Eenbenige glute bridge',
      'donkey_kick': 'Donkey kicks',
      'fire_hydrant': 'Fire hydrants',
      'banded_lateral_walk': 'Zijwaarts lopen met band',
      'cable_pull_through': 'Cable pull-through',
      'seated_calf_raise': 'Zittende kuitheffing',
      'single_leg_calf_raise': 'Eenbenige kuitheffing',
      'leg_press_calf_raise': 'Kuitheffing in de leg press',
      'sit_up': 'Sit-ups',
      'decline_sit_up': 'Sit-ups op de declinebank',
      'bicycle_crunch': 'Bicycle crunches',
      'reverse_crunch': 'Reverse crunches',
      'lying_leg_raise': 'Liggend benen heffen',
      'captains_chair_knee_raise': 'Knieheffen in de captain’s chair',
      'ab_wheel_rollout': 'Ab wheel rollout',
      'russian_twist': 'Russian twist',
      'v_up': 'V-ups',
      'hollow_hold': 'Hollow body hold',
      'pallof_press': 'Pallof press',
      'cable_woodchopper': 'Woodchopper aan de kabel',
      'plank_shoulder_tap': 'Plank met schoudertik',
      'bird_dog': 'Bird dog',
      'power_clean': 'Power clean',
      'thruster': 'Thruster',
      'turkish_get_up': 'Turkish get-up',
      'bear_crawl': 'Bear crawl',
      'high_knees': 'High knees',
      'jump_rope': 'Touwtjespringen',
      'rowing_machine': 'Roeimachine',
      'stationary_bike': 'Hometrainer',
      'treadmill_run': 'Hardlopen op de loopband',
      'elliptical': 'Crosstrainer',
      'stair_climber': 'Traploper',
      'air_bike': 'Air bike',
    },
    exerciseInstructions: {
      'bench_press':
        '1. Ga op de bank liggen met je ogen onder de stang en je voeten plat op de grond.\n'
        '2. Pak de stang iets breder dan schouderbreedte en knijp je schouderbladen samen.\n'
        '3. Laat de stang gecontroleerd zakken naar het midden van je borst, ellebogen ongeveer 45° van je lichaam.\n'
        '4. Druk omhoog tot gestrekte armen zonder je heupen op te tillen.',
      'incline_dumbbell_press':
        '1. Zet de bank op 30–45°, dumbbells ter hoogte van je borst.\n'
        '2. Houd je schouderbladen naar achteren en je voeten op de grond.\n'
        '3. Druk omhoog en iets naar elkaar toe, laat dan langzaam zakken tot borsthoogte.',
      'cable_fly':
        '1. Ga tussen de katrollen staan, ellebogen licht gebogen.\n'
        '2. Breng de handgrepen in een boog voor je borst samen.\n'
        '3. Ga langzaam terug tot je rek voelt, houd je ellebogen in dezelfde hoek.',
      'push_up':
        '1. Handen iets breder dan je schouders, lichaam in een rechte lijn.\n'
        '2. Laat je borst tot vlak boven de grond zakken, ellebogen ongeveer 45° van je lichaam.\n'
        '3. Duw jezelf weer omhoog, houd je core en billen aangespannen.',
      'deadlift':
        '1. Stang boven het midden van je voet, voeten op heupbreedte.\n'
        '2. Buig vanuit je heupen, pak de stang en houd je rug neutraal.\n'
        '3. Duw de vloer van je af en kom omhoog met de stang dicht langs je benen.\n'
        '4. Laat gecontroleerd zakken door je heupen naar achteren te duwen.',
      'barbell_row':
        '1. Buig voorover tot ongeveer 45°, rug recht, knieën licht gebogen.\n'
        '2. Trek de stang naar je onderborst of buik.\n'
        '3. Knijp je schouderbladen samen en laat dan langzaam zakken.',
      'lat_pulldown':
        '1. Pak de stang iets breder dan schouderbreedte, dijen onder de kussens.\n'
        '2. Trek de stang naar je bovenborst, ellebogen omlaag en naar achteren.\n'
        '3. Ga langzaam terug tot gestrekte armen zonder te zwaaien.',
      'pull_up':
        '1. Hang aan de stang met een bovenhandse greep, schouders actief.\n'
        '2. Trek jezelf op tot je kin boven de stang is.\n'
        '3. Laat gecontroleerd zakken tot je volledig hangt.',
      'overhead_press':
        '1. Stang op de voorkant van je schouders, greep net buiten schouderbreedte.\n'
        '2. Span je billen en core aan en druk de stang recht omhoog.\n'
        '3. Beweeg je hoofd iets naar achteren als de stang langskomt en strek boven je hoofd volledig uit.',
      'lateral_raise':
        '1. Sta rechtop, dumbbells langs je zij, ellebogen licht gebogen.\n'
        '2. Hef zijwaarts op tot schouderhoogte.\n'
        '3. Laat langzaam zakken, niet zwaaien.',
      'pike_push_up':
        '1. Begin in opdrukpositie en til je heupen op tot een omgekeerde V.\n'
        '2. Laat je hoofd tussen je handen richting de grond zakken.\n'
        '3. Duw jezelf vanuit je schouders weer omhoog.',
      'dumbbell_curl':
        '1. Sta rechtop, ellebogen langs je zij.\n'
        '2. Krul de dumbbells omhoog zonder je ellebogen te bewegen.\n'
        '3. Laat langzaam zakken tot gestrekte armen.',
      'triceps_pushdown':
        '1. Ga bij de kabel staan, ellebogen tegen je zij.\n'
        '2. Duw de handgreep omlaag tot je armen gestrekt zijn.\n'
        '3. Ga langzaam terug en houd je ellebogen stil.',
      'dips':
        '1. Steun op de leggers met gestrekte armen.\n'
        '2. Zak tot je bovenarmen ongeveer parallel aan de grond zijn.\n'
        '3. Duw jezelf weer omhoog en laat je schouders niet naar voren vallen.',
      'back_squat':
        '1. Stang op je bovenrug, voeten op schouderbreedte, tenen iets naar buiten.\n'
        '2. Span je core aan en zak tussen je hielen naar beneden.\n'
        '3. Knieën volgen je tenen, je rug blijft neutraal.\n'
        '4. Kom omhoog door met je hele voet te duwen.',
      'leg_press':
        '1. Voeten op schouderbreedte in het midden van het platform.\n'
        '2. Zak tot je knieën ongeveer 90° zijn, je onderrug blijft tegen het kussen.\n'
        '3. Druk omhoog zonder je knieën hard op slot te zetten.',
      'romanian_deadlift':
        '1. Sta met de stang in je handen, knieën licht gebogen.\n'
        '2. Duw je heupen naar achteren en laat de stang langs je benen zakken.\n'
        '3. Stop als je rek voelt in je hamstrings, rug recht.\n'
        '4. Kom terug door je heupen naar voren te duwen.',
      'bodyweight_squat':
        '1. Voeten op schouderbreedte, armen naar voren voor je balans.\n'
        '2. Zak zo diep als je kunt met een rechte rug.\n'
        '3. Kom omhoog door je hielen.',
      'lunge':
        '1. Stap naar voren en zak tot beide knieën ongeveer 90° zijn.\n'
        '2. Je voorste knie blijft boven je voet, bovenlichaam rechtop.\n'
        '3. Duw terug naar het begin en wissel van been.',
      'hip_thrust':
        '1. Bovenrug tegen de bank, stang over je heupen.\n'
        '2. Duw door je hielen en til je heupen op tot je lichaam recht is.\n'
        '3. Knijp bovenaan je billen samen en laat gecontroleerd zakken.',
      'glute_bridge':
        '1. Ga op je rug liggen, knieën gebogen, voeten op de grond.\n'
        '2. Til je heupen op door je billen aan te spannen.\n'
        '3. Houd bovenaan even vast en laat langzaam zakken.',
      'plank':
        '1. Onderarmen onder je schouders, lichaam in een rechte lijn.\n'
        '2. Span je core en billen aan en laat je heupen niet doorzakken.\n'
        '3. Adem rustig door en houd vast.',
      'crunch':
        '1. Ga op je rug liggen, knieën gebogen, handen bij je hoofd.\n'
        '2. Krul je schouders van de grond met je buikspieren.\n'
        '3. Laat langzaam zakken en trek niet aan je nek.',
      'mountain_climber':
        '1. Begin in opdrukpositie.\n'
        '2. Breng je knieën om en om naar je borst.\n'
        '3. Houd je heupen laag en het tempo gelijkmatig.',
      'jumping_jack':
        '1. Sta met je voeten tegen elkaar, armen langs je zij.\n'
        '2. Spring je voeten uit elkaar en breng je armen boven je hoofd.\n'
        '3. Spring terug en herhaal in een gelijkmatig tempo.',
      'dumbbell_bench_press':
        '1. Ga op een vlakke bank liggen met de dumbbells ter hoogte van je borst.\n'
        '2. Druk omhoog en iets naar elkaar toe.\n'
        '3. Laat langzaam zakken tot je rek voelt in je borst.',
      'incline_bench_press':
        '1. Bank op 30–45°, greep iets breder dan schouderbreedte.\n'
        '2. Laat de stang zakken naar je bovenborst.\n'
        '3. Druk omhoog en houd je schouderbladen naar achteren.',
      'chest_press_machine':
        '1. Stel de zitting zo in dat de handgrepen ter hoogte van het midden van je borst zijn.\n'
        '2. Druk naar voren tot je armen bijna gestrekt zijn.\n'
        '3. Ga langzaam terug en houd je rug tegen het kussen.',
      'pec_deck':
        '1. Zit met je rug tegen het kussen, ellebogen licht gebogen.\n'
        '2. Breng de handgrepen voor je borst samen.\n'
        '3. Ga langzaam terug tot een comfortabele rek.',
      'seated_cable_row':
        '1. Zit rechtop, voeten op het platform, knieën licht gebogen.\n'
        '2. Trek de handgreep naar je buik, ellebogen dicht bij je lichaam.\n'
        '3. Knijp je schouderbladen samen en ga langzaam terug zonder je rug bol te maken.',
      'one_arm_dumbbell_row':
        '1. Eén knie en hand op de bank, rug plat.\n'
        '2. Trek de dumbbell richting je heup.\n'
        '3. Laat langzaam zakken tot volledige rek.',
      'chin_up':
        '1. Hang aan de stang met een onderhandse greep op schouderbreedte.\n'
        '2. Trek jezelf op tot je kin boven de stang is.\n'
        '3. Laat gecontroleerd zakken tot je volledig hangt.',
      'dumbbell_shoulder_press':
        '1. Zit of sta, dumbbells op schouderhoogte.\n'
        '2. Druk boven je hoofd zonder je onderrug hol te trekken.\n'
        '3. Laat langzaam terug naar je schouders zakken.',
      'rear_delt_fly':
        '1. Buig voorover met een vlakke rug, dumbbells hangend naar beneden.\n'
        '2. Hef je armen zijwaarts op met licht gebogen ellebogen.\n'
        '3. Laat langzaam zakken en gebruik geen zwaai.',
      'face_pull':
        '1. Touw op hoofdhoogte, vasthouden met je duimen naar je toe.\n'
        '2. Trek richting je gezicht, ellebogen hoog en wijd.\n'
        '3. Knijp je bovenrug samen en ga langzaam terug.',
      'barbell_curl':
        '1. Sta rechtop, onderhandse greep op schouderbreedte.\n'
        '2. Krul de stang omhoog zonder met je lichaam te zwaaien.\n'
        '3. Laat langzaam zakken tot gestrekte armen.',
      'hammer_curl':
        '1. Houd de dumbbells vast met je handpalmen naar elkaar toe.\n'
        '2. Krul omhoog, ellebogen blijven langs je zij.\n'
        '3. Laat langzaam zakken.',
      'cable_curl':
        '1. Sta met je gezicht naar de lage katrol, ellebogen langs je zij.\n'
        '2. Krul de handgreep omhoog naar je schouders.\n'
        '3. Laat langzaam zakken en houd constante spanning.',
      'skull_crusher':
        '1. Ga op een bank liggen, stang boven je borst met gestrekte armen.\n'
        '2. Buig alleen je ellebogen en laat de stang richting je voorhoofd zakken.\n'
        '3. Strek weer uit en houd je ellebogen naar boven gericht.',
      'overhead_triceps_extension':
        '1. Houd één dumbbell met beide handen boven je hoofd.\n'
        '2. Laat hem achter je hoofd zakken door je ellebogen te buigen.\n'
        '3. Strek weer uit en houd je ellebogen dicht bij je hoofd.',
      'close_grip_bench_press':
        '1. Ga op de bank liggen, greep ongeveer op schouderbreedte.\n'
        '2. Laat de stang zakken naar je onderborst, ellebogen dicht bij je lichaam.\n'
        '3. Druk omhoog door je ellebogen te strekken.',
      'front_squat':
        '1. Stang op de voorkant van je schouders, ellebogen hoog.\n'
        '2. Zak naar beneden met een rechtop bovenlichaam.\n'
        '3. Kom omhoog en houd je ellebogen de hele tijd hoog.',
      'goblet_squat':
        '1. Houd een kettlebell of dumbbell voor je borst.\n'
        '2. Zak tussen je knieën naar beneden met een rechte rug.\n'
        '3. Kom omhoog door je hielen.',
      'bulgarian_split_squat':
        '1. Achterste voet op een bank, voorste voet een pas naar voren.\n'
        '2. Zak tot je voorste dijbeen ongeveer parallel is.\n'
        '3. Duw omhoog via je voorste voet en wissel dan van been.',
      'leg_extension':
        '1. Stel het kussen in net boven je enkels.\n'
        '2. Strek je benen helemaal.\n'
        '3. Laat langzaam en gecontroleerd zakken.',
      'leg_curl':
        '1. Stel het kussen in net boven je hielen.\n'
        '2. Krul je hielen richting je billen.\n'
        '3. Ga langzaam terug en laat het gewicht niet vallen.',
      'calf_raise':
        '1. Voorvoeten op de rand, hielen vrij.\n'
        '2. Kom zo hoog mogelijk op je tenen.\n'
        '3. Laat langzaam zakken tot je rek voelt.',
      'hanging_leg_raise':
        '1. Hang aan de stang, schouders actief.\n'
        '2. Breng je benen of knieën omhoog met je buikspieren, zonder te zwaaien.\n'
        '3. Laat langzaam zakken.',
      'cable_crunch':
        '1. Kniel met je gezicht naar de kabel, touw bij je hoofd.\n'
        '2. Crunch naar beneden door je rug bol te maken, heupen blijven stil.\n'
        '3. Ga langzaam terug.',
      'dead_bug':
        '1. Ga op je rug liggen, armen omhoog, knieën op 90°.\n'
        '2. Laat de tegenovergestelde arm en het tegenovergestelde been zakken, je onderrug blijft op de grond.\n'
        '3. Ga terug en wissel van kant.',
      'side_plank':
        '1. Ga op je zij liggen, elleboog onder je schouder.\n'
        '2. Til je heupen op zodat je lichaam een rechte lijn vormt.\n'
        '3. Houd vast en wissel dan van kant.',
      'burpee':
        '1. Zak vanuit stand door je knieën en zet je handen op de grond.\n'
        '2. Spring met je voeten naar achteren in een plank, doe eventueel een opdrukker.\n'
        '3. Spring je voeten weer naar voren en spring omhoog.',
      'kettlebell_swing':
        '1. Kettlebell voor je, voeten iets breder dan heupbreedte.\n'
        '2. Zwaai hem tussen je benen naar achteren met een heupscharnier.\n'
        '3. Stuw je heupen krachtig naar voren om hem tot borsthoogte te zwaaien, armen ontspannen.',
      'weighted_pull_up':
        '1. Hang een halterschijf aan een dipriem of klem een dumbbell tussen je voeten.\n'
        '2. Hang aan de stang met een bovenhandse greep, schouders actief.\n'
        '3. Trek jezelf zonder zwaaien op tot je kin boven de stang is.\n'
        '4. Laat gecontroleerd zakken tot je volledig hangt. Noteer alleen het extra gewicht.',
      'weighted_dips':
        '1. Hang een halterschijf aan een dipriem of klem een dumbbell tussen je voeten.\n'
        '2. Steun op de leggers met gestrekte armen.\n'
        '3. Zak tot je bovenarmen ongeveer parallel aan de grond zijn.\n'
        '4. Duw jezelf weer omhoog en laat je schouders niet naar voren vallen. Noteer alleen het extra gewicht.',
      'barbell_shrug':
        '1. Sta rechtop met de stang in gestrekte armen, greep op schouderbreedte.\n'
        '2. Trek je schouders recht omhoog richting je oren, armen blijven gestrekt.\n'
        '3. Houd even vast bovenin en laat langzaam zakken. Rol niet met je schouders.',
      'dumbbell_shrug':
        '1. Sta met een dumbbell in elke hand langs je lichaam, handpalmen naar binnen.\n'
        '2. Trek je schouders zo hoog mogelijk recht omhoog.\n'
        '3. Houd even vast en laat gecontroleerd zakken.',
      'wrist_curl':
        '1. Zit met je onderarmen op je dijen of een bank, handpalmen omhoog, polsen over de rand.\n'
        '2. Laat de dumbbells naar je vingertoppen rollen.\n'
        '3. Krul je polsen zo hoog mogelijk op, onderarmen blijven stil.',
      'reverse_curl':
        '1. Sta rechtop en houd de stang in bovenhandse greep op schouderbreedte.\n'
        '2. Krul de stang omhoog, ellebogen langs je zij, polsen recht.\n'
        '3. Laat langzaam zakken tot gestrekte armen.',
      'dead_hang':
        '1. Pak de stang in bovenhandse greep op schouderbreedte.\n'
        '2. Hang met gestrekte armen, voeten van de grond, lichaam stil.\n'
        '3. Houd de ingestelde tijd vol met licht actieve schouders.',
      'back_extension':
        '1. Zet het kussen net onder je heupen en zet je hielen vast.\n'
        '2. Laat je bovenlichaam met rechte rug zakken tot je je hamstrings voelt rekken.\n'
        '3. Kom omhoog tot je in lijn bent met je benen, niet overstrekken. Houd een schijf vast voor extra gewicht.',
      'good_morning':
        '1. Stang op je bovenrug zoals bij de squat, voeten op heupbreedte, knieën licht gebogen.\n'
        '2. Duw je heupen naar achteren en buig met rechte rug voorover tot je romp bijna horizontaal is.\n'
        '3. Duw je heupen naar voren om rechtop te komen. Begin licht.',
      'superman':
        '1. Ga op je buik liggen met je armen gestrekt boven je hoofd.\n'
        '2. Til armen, borst en benen tegelijk van de grond.\n'
        '3. Houd een seconde vast en laat langzaam zakken.',
      'decline_bench_press':
        '1. Zet je benen vast op de declinebank, greep iets breder dan je schouders.\n'
        '2. Laat de stang gecontroleerd zakken naar je onderste borst.\n'
        '3. Druk omhoog tot gestrekte armen, schouderbladen blijven samen.',
      'smith_bench_press':
        '1. Zet de bank zo dat de stang boven het midden van je borst komt.\n'
        '2. Haal de stang los en laat hem gecontroleerd naar je borst zakken.\n'
        '3. Druk omhoog zonder je ellebogen hard op slot te zetten en haak de stang aan het eind weer in.',
      'dumbbell_fly':
        '1. Lig op een vlakke bank, dumbbells boven je borst, ellebogen licht gebogen.\n'
        '2. Open je armen in een brede boog tot je je borst voelt rekken.\n'
        '3. Breng de dumbbells weer samen zonder de hoek in je ellebogen te veranderen.',
      'incline_dumbbell_fly':
        '1. Zet de bank op 30°, dumbbells boven je borst, ellebogen soepel.\n'
        '2. Laat ze in een brede boog zakken tot je je bovenste borst voelt rekken.\n'
        '3. Breng ze weer samen boven je borst.',
      'low_to_high_cable_fly':
        '1. Zet beide kabels laag en sta ertussen, licht voorovergebogen.\n'
        '2. Breng de handvatten omhoog en samen voor je bovenste borst.\n'
        '3. Ga langzaam terug naar de rek, ellebogen licht gebogen.',
      'incline_chest_press_machine':
        '1. Stel de zitting zo in dat de handvatten op hoogte van je bovenste borst zitten.\n'
        '2. Duw naar voren en omhoog tot je armen bijna gestrekt zijn.\n'
        '3. Ga langzaam terug tot je je borst voelt rekken.',
      'chest_dips':
        '1. Steun op de brug en buig je bovenlichaam naar voren.\n'
        '2. Zak met je ellebogen iets naar buiten tot je je borst voelt rekken.\n'
        '3. Duw je weer omhoog en blijf licht voorovergebogen.',
      'incline_push_up':
        '1. Zet je handen op een bank of box, lichaam in één lijn.\n'
        '2. Laat je borst naar de rand zakken, ellebogen ongeveer 45° van je lichaam.\n'
        '3. Duw je weer omhoog. Hoe hoger de steun, hoe makkelijker.',
      'decline_push_up':
        '1. Voeten op een bank, handen op de grond onder je schouders.\n'
        '2. Laat je borst met een strakke romp naar de grond zakken.\n'
        '3. Duw je omhoog zonder dat je heupen doorzakken.',
      'dumbbell_floor_press':
        '1. Lig op de grond, knieën gebogen, dumbbells boven je borst.\n'
        '2. Laat zakken tot je bovenarmen de grond raken en pauzeer kort.\n'
        '3. Druk weer omhoog tot gestrekte armen.',
      't_bar_row':
        '1. Ga boven de stang staan, buig voorover met een rechte rug en pak het handvat.\n'
        '2. Trek het gewicht naar je borst en knijp je schouderbladen samen.\n'
        '3. Laat gecontroleerd zakken zonder je rug bol te maken.',
      'pendlay_row':
        '1. Stang op de grond, bovenlichaam bijna horizontaal, rug recht.\n'
        '2. Trek de stang explosief naar je onderste borst.\n'
        '3. Leg hem na elke herhaling neer en zet je opnieuw klaar.',
      'machine_row':
        '1. Ga zitten met je borst tegen het kussen en pak de handvatten.\n'
        '2. Trek naar je lichaam, ellebogen dicht bij je, schouderbladen samen.\n'
        '3. Ga langzaam terug tot je armen gestrekt zijn.',
      'chest_supported_row':
        '1. Lig op je buik op een bank van 30–45°, dumbbells hangen omlaag.\n'
        '2. Trek ze naar je zij en knijp je schouderbladen samen.\n'
        '3. Laat langzaam zakken tot volledige rek.',
      'close_grip_lat_pulldown':
        '1. Ga aan de lat pulldown zitten met een smalle of V-greep, dijen onder de kussens.\n'
        '2. Trek de greep naar je bovenste borst, ellebogen omlaag en naar achteren.\n'
        '3. Laat hem langzaam omhoog tot je armen gestrekt zijn.',
      'straight_arm_pulldown':
        '1. Sta voor de hoge kabel, armen bijna gestrekt, licht voorover.\n'
        '2. Duw de stang met je lats in een boog naar je dijen.\n'
        '3. Laat langzaam terugkomen, ellebogen bijna gestrekt.',
      'band_assisted_pull_up':
        '1. Hang een weerstandsband over de stang en zet een voet of knie erin.\n'
        '2. Trek je op tot je kin boven de stang is.\n'
        '3. Laat je gecontroleerd zakken tot je volledig hangt. Dunnere band = minder hulp.',
      'inverted_row':
        '1. Hang onder een lage stang of ringen, lichaam recht, hielen op de grond.\n'
        '2. Trek je borst naar de stang en knijp je schouderbladen samen.\n'
        '3. Laat gecontroleerd zakken. Hoe rechter je staat, hoe makkelijker.',
      'neutral_grip_pull_up':
        '1. Hang aan parallelle handvatten, handpalmen naar elkaar toe.\n'
        '2. Trek je op tot je kin boven de handvatten is.\n'
        '3. Laat je gecontroleerd zakken tot je volledig hangt.',
      'rack_pull':
        '1. Leg de stang op de steunen net onder of boven je knieën.\n'
        '2. Pak hem vast, span je romp aan en kom omhoog door je heupen naar voren te duwen.\n'
        '3. Laat hem met een rechte rug terug op de steunen zakken.',
      'trap_bar_deadlift':
        '1. Ga in de trap bar staan, voeten op heupbreedte, pak de handvatten.\n'
        '2. Span aan, duw de vloer weg en kom rechtop.\n'
        '3. Laat de stang met een rechte rug weer zakken.',
      'single_arm_cable_row':
        '1. Pak een enkel handvat aan de kabel op heuphoogte, arm gestrekt.\n'
        '2. Trek het naar je zij, elleboog dicht bij je lichaam.\n'
        '3. Ga langzaam terug en laat je schouder iets naar voren komen.',
      'dumbbell_pullover':
        '1. Lig op een bank en houd één dumbbell met twee handen boven je borst.\n'
        '2. Laat hem in een boog achter je hoofd zakken, ellebogen licht gebogen.\n'
        '3. Trek hem terug boven je borst.',
      'renegade_row':
        '1. Ga in push-uppositie op twee dumbbells staan, voeten breed.\n'
        '2. Trek één dumbbell naar je heup zonder je heupen te draaien.\n'
        '3. Zet hem neer en herhaal met de andere arm.',
      'arnold_press':
        '1. Zit met de dumbbells voor je schouders, handpalmen naar je toe.\n'
        '2. Druk omhoog en draai je handpalmen onderweg naar voren.\n'
        '3. Laat zakken en draai terug naar de beginhouding.',
      'shoulder_press_machine':
        '1. Stel de zitting zo in dat de handvatten op schouderhoogte beginnen.\n'
        '2. Druk omhoog tot je armen bijna gestrekt zijn.\n'
        '3. Laat langzaam terug zakken naar schouderhoogte.',
      'push_press':
        '1. Stang voor op je schouders, voeten op heupbreedte.\n'
        '2. Zak kort door je knieën en druk de stang met beenkracht boven je hoofd.\n'
        '3. Laat hem gecontroleerd terug op je schouders zakken.',
      'cable_lateral_raise':
        '1. Sta zijwaarts naast de lage kabel, handvat in de verste hand.\n'
        '2. Breng je arm zijwaarts omhoog tot schouderhoogte.\n'
        '3. Laat langzaam zakken en houd spanning op de kabel.',
      'machine_lateral_raise':
        '1. Ga zitten met de kussens tegen de buitenkant van je armen.\n'
        '2. Breng je armen omhoog tot schouderhoogte.\n'
        '3. Laat langzaam zakken zonder het gewicht neer te zetten.',
      'front_raise':
        '1. Sta met dumbbells voor je dijen.\n'
        '2. Breng ze naar voren omhoog tot schouderhoogte, armen bijna gestrekt.\n'
        '3. Laat langzaam zakken zonder te zwaaien.',
      'upright_row':
        '1. Houd de stang voor je dijen, greep ongeveer op schouderbreedte.\n'
        '2. Trek hem langs je lichaam omhoog tot borsthoogte, ellebogen gaan voorop.\n'
        '3. Laat langzaam zakken. Ga minder hoog als je schouders knellen.',
      'reverse_pec_deck':
        '1. Ga met je gezicht naar de machine zitten, borst tegen het kussen, pak de handvatten.\n'
        '2. Open je armen in een boog naar achteren tot ze in lijn met je lichaam zijn.\n'
        '3. Ga langzaam terug.',
      'band_pull_apart':
        '1. Houd een band voor je op schouderhoogte, armen gestrekt.\n'
        '2. Trek hem uit elkaar tot je borst en knijp je schouderbladen samen.\n'
        '3. Ga langzaam terug.',
      'handstand_push_up':
        '1. Zwaai op in een handstand tegen de muur, handen op schouderbreedte.\n'
        '2. Laat je hoofd gecontroleerd naar de grond zakken.\n'
        '3. Druk je omhoog tot gestrekte armen. Leg een mat onder je hoofd.',
      'landmine_press':
        '1. Houd het uiteinde van een landmine-stang bij je schouder, voeten in spreidstand.\n'
        '2. Druk hem omhoog en naar voren tot je arm gestrekt is.\n'
        '3. Laat hem gecontroleerd terug naar je schouder komen.',
      'preacher_curl':
        '1. Zit aan de preacherbank, bovenarmen plat op het kussen, EZ-stang in je handen.\n'
        '2. Krul de stang omhoog zonder je ellebogen op te tillen.\n'
        '3. Laat langzaam zakken tot bijna gestrekt.',
      'concentration_curl':
        '1. Zit op een bank, elleboog tegen de binnenkant van je dij.\n'
        '2. Krul de dumbbell naar je schouder.\n'
        '3. Laat langzaam zakken tot volledige rek.',
      'incline_dumbbell_curl':
        '1. Leun tegen een bank van 45–60°, armen hangen recht omlaag.\n'
        '2. Krul de dumbbells omhoog, je bovenarmen blijven stil.\n'
        '3. Laat langzaam zakken tot volledige rek.',
      'ez_bar_curl':
        '1. Sta met de EZ-stang aan de gebogen delen, armen gestrekt.\n'
        '2. Krul hem omhoog zonder met je lichaam te zwaaien.\n'
        '3. Laat langzaam zakken tot gestrekte armen.',
      'rope_hammer_curl':
        '1. Bevestig een touw aan de lage kabel, handpalmen naar elkaar toe.\n'
        '2. Krul het touw omhoog, ellebogen langs je zij.\n'
        '3. Laat langzaam zakken en houd spanning.',
      'machine_biceps_curl':
        '1. Ga zitten met je bovenarmen op het kussen en pak de handvatten.\n'
        '2. Krul de handvatten naar je schouders.\n'
        '3. Laat langzaam zakken tot bijna gestrekt.',
      'band_curl':
        '1. Sta op het midden van de band, uiteinden in je handen.\n'
        '2. Krul je handen naar je schouders, ellebogen langs je zij.\n'
        '3. Laat langzaam zakken.',
      'rope_pushdown':
        '1. Pak het touw aan de hoge kabel, ellebogen langs je zij.\n'
        '2. Duw het touw omlaag en trek onderaan de uiteinden uit elkaar.\n'
        '3. Laat het langzaam omhoog tot ongeveer 90° in je elleboog.',
      'overhead_cable_extension':
        '1. Sta met je rug naar de kabel, touw achter je hoofd, ellebogen omhoog.\n'
        '2. Strek je armen naar voren en omhoog.\n'
        '3. Buig je ellebogen langzaam terug achter je hoofd.',
      'triceps_kickback':
        '1. Buig voorover, bovenarm parallel aan je lichaam, elleboog gebogen.\n'
        '2. Strek je arm volledig naar achteren.\n'
        '3. Buig langzaam terug, je bovenarm blijft stil.',
      'bench_dips':
        '1. Zet je handen achter je op de rand van een bank, benen naar voren.\n'
        '2. Laat je zakken door je ellebogen tot ongeveer 90° te buigen.\n'
        '3. Duw je weer omhoog tot gestrekte armen.',
      'machine_triceps_dip':
        '1. Ga in de machine zitten en pak de handvatten aan de zijkant.\n'
        '2. Duw de handvatten omlaag tot je armen gestrekt zijn.\n'
        '3. Laat ze langzaam omhoog tot ongeveer 90° in je elleboog.',
      'single_arm_pushdown':
        '1. Pak een enkel handvat aan de hoge kabel, elleboog langs je zij.\n'
        '2. Duw het omlaag tot je arm gestrekt is.\n'
        '3. Laat het langzaam omhoog, je elleboog blijft op zijn plek.',
      'diamond_push_up':
        '1. Push-uppositie met je handen samen onder je borst, vingers vormen een ruit.\n'
        '2. Laat je borst naar je handen zakken, ellebogen dicht bij je lichaam.\n'
        '3. Duw je omhoog met een recht lichaam.',
      'reverse_wrist_curl':
        '1. Zit met je onderarmen op je dijen, handpalmen omlaag, polsen voorbij je knieën.\n'
        '2. Til de rug van je handen zo hoog mogelijk op.\n'
        '3. Laat langzaam zakken.',
      'hack_squat':
        '1. Sta op het platform met je rug tegen het kussen, schouders onder de kussens.\n'
        '2. Zak tot je dijen minstens parallel aan het platform zijn.\n'
        '3. Duw je omhoog via je hele voet.',
      'smith_squat':
        '1. Stang op je bovenrug, voeten iets voor de stang.\n'
        '2. Zak met een rechte rug minstens tot parallel.\n'
        '3. Kom omhoog en haak de stang aan het eind weer in.',
      'walking_lunge':
        '1. Houd dumbbells langs je zij en zet een lange stap naar voren.\n'
        '2. Laat je achterste knie bijna tot de grond zakken.\n'
        '3. Duw af met je voorste voet en ga direct door met de volgende lunge.',
      'reverse_lunge':
        '1. Sta rechtop met dumbbells langs je zij.\n'
        '2. Stap naar achteren en laat je achterste knie bijna tot de grond zakken.\n'
        '3. Duw via je voorste voet terug. Wissel van been.',
      'step_up':
        '1. Sta voor een bank of box met dumbbells in je handen.\n'
        '2. Zet één voet erop en stap op door met dat been te duwen.\n'
        '3. Stap langzaam af. Wissel of doe eerst één kant.',
      'split_squat':
        '1. Ga in een lange spreidstand staan met dumbbells in je handen.\n'
        '2. Zak recht omlaag tot je achterste knie bijna de grond raakt.\n'
        '3. Duw je omhoog. Maak alle herhalingen en wissel dan van been.',
      'sumo_squat':
        '1. Brede stand, tenen naar buiten, één dumbbell tussen je benen.\n'
        '2. Zak met een rechtop bovenlichaam, knieën in de richting van je tenen.\n'
        '3. Kom omhoog en span je billen aan.',
      'pistol_squat':
        '1. Sta op één been, het andere gestrekt voor je.\n'
        '2. Zak gecontroleerd zo diep mogelijk, armen naar voren voor balans.\n'
        '3. Kom weer omhoog. In het begin mag je je ergens aan vasthouden.',
      'single_leg_press':
        '1. Ga in de leg press zitten met één voet midden op het platform.\n'
        '2. Laat het platform zakken tot je knie ongeveer 90° gebogen is.\n'
        '3. Duw terug zonder je knie op slot te zetten. Wissel van been.',
      'hip_adduction_machine':
        '1. Ga zitten met de kussens tegen de binnenkant van je knieën.\n'
        '2. Knijp je benen samen.\n'
        '3. Open ze langzaam weer.',
      'wall_sit':
        '1. Leun met je rug tegen een muur en glijd omlaag.\n'
        '2. Stop als je knieën ongeveer 90° gebogen zijn, voeten onder je knieën.\n'
        '3. Houd de ingestelde tijd vol, rug plat tegen de muur.',
      'jump_squat':
        '1. Sta met je voeten op schouderbreedte.\n'
        '2. Zak in een squat en spring explosief omhoog.\n'
        '3. Land zacht en ga direct door met de volgende squat.',
      'box_jump':
        '1. Ga voor een stevige box staan.\n'
        '2. Zwaai je armen en spring op de box, land zacht.\n'
        '3. Kom helemaal rechtop en stap dan af.',
      'seated_leg_curl':
        '1. Ga in de machine zitten, kussen boven je hielen, dijen vast.\n'
        '2. Trek je hielen zo ver mogelijk omlaag en naar achteren.\n'
        '3. Ga langzaam terug.',
      'nordic_curl':
        '1. Kniel met je hielen vast onder iets stevigs.\n'
        '2. Laat je lichaam zo langzaam mogelijk naar voren zakken, heupen gestrekt.\n'
        '3. Vang je op met je handen en trek je met je hamstrings terug.',
      'single_leg_rdl':
        '1. Sta op één been met een dumbbell, knie licht gebogen.\n'
        '2. Buig voorover terwijl je vrije been naar achteren gaat, rug recht.\n'
        '3. Kom omhoog door je heupen naar voren te duwen.',
      'dumbbell_romanian_deadlift':
        '1. Sta met dumbbells voor je dijen, knieën soepel.\n'
        '2. Duw je heupen naar achteren en laat de dumbbells langs je benen zakken.\n'
        '3. Stop als je je hamstrings voelt rekken en kom omhoog.',
      'stiff_leg_deadlift':
        '1. Sta met de stang in je handen, benen bijna gestrekt.\n'
        '2. Buig met een rechte rug voorover en laat de stang langs je benen zakken.\n'
        '3. Kom omhoog door je hamstrings en billen aan te spannen.',
      'stability_ball_leg_curl':
        '1. Lig op je rug, hielen op de bal, heupen omhoog.\n'
        '2. Rol de bal naar je toe door je knieën te buigen.\n'
        '3. Rol hem langzaam terug, je heupen blijven omhoog.',
      'sumo_deadlift':
        '1. Brede stand, tenen naar buiten, pak de stang tussen je benen.\n'
        '2. Span aan, duw je knieën naar buiten en kom omhoog met de stang dicht bij je lichaam.\n'
        '3. Laat hem met een rechte rug weer zakken.',
      'cable_glute_kickback':
        '1. Bevestig een enkelband aan de lage kabel en houd je vast aan de machine.\n'
        '2. Schop je been naar achteren en omhoog door je bil aan te spannen.\n'
        '3. Ga langzaam terug zonder je onderrug hol te maken.',
      'hip_abduction_machine':
        '1. Ga zitten met de kussens tegen de buitenkant van je knieën.\n'
        '2. Duw je benen zo ver mogelijk uit elkaar.\n'
        '3. Breng ze langzaam weer samen.',
      'machine_hip_thrust':
        '1. Leg je bovenrug tegen het kussen en de riem over je heupen.\n'
        '2. Duw je heupen omhoog tot je lichaam recht is van knieën tot schouders.\n'
        '3. Span bovenin je billen aan en laat langzaam zakken.',
      'single_leg_glute_bridge':
        '1. Lig op je rug, één voet op de grond, het andere been recht omhoog.\n'
        '2. Duw je heupen omhoog via de hiel van het standbeen.\n'
        '3. Laat langzaam zakken. Maak alle herhalingen en wissel dan.',
      'donkey_kick':
        '1. Ga op handen en knieën zitten, handen onder je schouders.\n'
        '2. Til één gebogen been naar achteren op, voetzool naar het plafond.\n'
        '3. Laat langzaam zakken zonder je rug hol te maken.',
      'fire_hydrant':
        '1. Ga op handen en knieën zitten, rug recht.\n'
        '2. Til één gebogen been zijwaarts op tot heuphoogte.\n'
        '3. Laat langzaam zakken, je heupen blijven recht.',
      'banded_lateral_walk':
        '1. Doe een miniband boven je knieën of om je enkels en buig je knieën licht.\n'
        '2. Stap zijwaarts en houd de band op spanning.\n'
        '3. Tel je stappen naar één kant en loop dan terug.',
      'cable_pull_through':
        '1. Sta met je rug naar de lage kabel, touw tussen je benen.\n'
        '2. Buig met een rechte rug voorover en laat het touw naar achteren gaan.\n'
        '3. Duw je heupen naar voren om rechtop te komen en span je billen aan.',
      'seated_calf_raise':
        '1. Ga zitten met het kussen op je dijen, voorvoeten op de trede.\n'
        '2. Til je hielen zo hoog mogelijk op.\n'
        '3. Laat langzaam zakken tot volledige rek.',
      'single_leg_calf_raise':
        '1. Sta met één voet op de rand van een trede en houd je vast.\n'
        '2. Kom zo hoog mogelijk op je tenen.\n'
        '3. Laat je hiel onder de trede zakken voor een volledige rek.',
      'leg_press_calf_raise':
        '1. Ga in de leg press zitten, voorvoeten op de onderrand van het platform.\n'
        '2. Duw het platform weg door je voeten te strekken.\n'
        '3. Laat het langzaam terugkomen voor een volledige rek. Houd je knieën gestrekt.',
      'sit_up':
        '1. Lig op je rug, knieën gebogen, voeten op de grond.\n'
        '2. Rol helemaal op tot zit.\n'
        '3. Laat je langzaam terug zakken.',
      'decline_sit_up':
        '1. Zet je voeten vast op de declinebank en ga liggen.\n'
        '2. Kom omhoog tot je bovenlichaam rechtop is.\n'
        '3. Ga langzaam terug. Houd een schijf vast voor extra gewicht.',
      'bicycle_crunch':
        '1. Lig op je rug, handen bij je hoofd, benen opgetild.\n'
        '2. Breng een elleboog naar de tegenovergestelde knie terwijl je het andere been strekt.\n'
        '3. Wissel van kant alsof je fietst.',
      'reverse_crunch':
        '1. Lig op je rug, knieën 90° gebogen, armen op de grond.\n'
        '2. Til je heupen op en breng je knieën naar je borst.\n'
        '3. Laat langzaam zakken zonder te zwaaien.',
      'lying_leg_raise':
        '1. Lig op je rug, benen gestrekt, onderrug tegen de grond.\n'
        '2. Til je benen op tot ze naar het plafond wijzen.\n'
        '3. Laat langzaam zakken zonder je rug hol te maken.',
      'captains_chair_knee_raise':
        '1. Steun met je onderarmen op de kussens, rug tegen de leuning.\n'
        '2. Trek je knieën naar je borst.\n'
        '3. Laat langzaam zakken zonder te zwaaien.',
      'ab_wheel_rollout':
        '1. Kniel en houd het buikwiel onder je schouders.\n'
        '2. Rol zo ver mogelijk naar voren zonder dat je onderrug doorzakt.\n'
        '3. Trek je met je buikspieren terug.',
      'russian_twist':
        '1. Zit licht achterover geleund, voeten opgetild of op de grond.\n'
        '2. Draai je bovenlichaam en tik de grond naast je heup aan.\n'
        '3. Draai naar de andere kant. Houd een gewicht vast voor extra belasting.',
      'v_up':
        '1. Lig op je rug, armen boven je hoofd, benen gestrekt.\n'
        '2. Til tegelijk je armen en benen op en raak je tenen aan.\n'
        '3. Laat je langzaam terug zakken.',
      'hollow_hold':
        '1. Lig op je rug en druk je onderrug in de grond.\n'
        '2. Til je schouders en gestrekte benen een stukje van de grond.\n'
        '3. Houd de ingestelde tijd vol zonder je rug hol te maken.',
      'pallof_press':
        '1. Sta zijwaarts naast een kabel op borsthoogte, handvat bij je borst.\n'
        '2. Duw het handvat recht naar voren zonder dat je lichaam draait.\n'
        '3. Breng het terug naar je borst. Train beide kanten.',
      'cable_woodchopper':
        '1. Sta zijwaarts naast de hoge kabel, handvat met twee handen.\n'
        '2. Trek het diagonaal omlaag over je lichaam en draai je bovenlichaam mee.\n'
        '3. Ga langzaam terug. Train beide kanten.',
      'plank_shoulder_tap':
        '1. Ga in een hoge plank, voeten iets uit elkaar.\n'
        '2. Tik met één hand de tegenovergestelde schouder aan zonder je heupen te bewegen.\n'
        '3. Wissel van hand.',
      'bird_dog':
        '1. Ga op handen en knieën zitten, rug recht.\n'
        '2. Strek één arm naar voren en het tegenovergestelde been naar achteren.\n'
        '3. Houd even vast, ga terug en wissel van kant.',
      'power_clean':
        '1. Sta boven de stang, greep net buiten je knieën, rug recht.\n'
        '2. Trek de stang explosief langs je lichaam omhoog en vang hem voor op je schouders.\n'
        '3. Kom rechtop en laat de stang zakken. Leer de techniek met een lichte stang.',
      'thruster':
        '1. Houd de stang voor op je schouders.\n'
        '2. Zak in een squat en druk de stang bij het opstaan in één beweging boven je hoofd.\n'
        '3. Breng hem terug naar je schouders en ga direct door met de volgende squat.',
      'turkish_get_up':
        '1. Lig op je rug en houd een kettlebell met één hand recht omhoog.\n'
        '2. Kom stap voor stap overeind, blik op de kettlebell, arm gestrekt.\n'
        '3. Ga via dezelfde stappen terug naar liggen. Train beide kanten.',
      'bear_crawl':
        '1. Steun op handen en voeten, knieën net boven de grond, rug recht.\n'
        '2. Kruip naar voren en beweeg tegelijk tegenovergestelde hand en voet.\n'
        '3. Houd je heupen laag gedurende de ingestelde tijd.',
      'high_knees':
        '1. Ren op de plaats en breng je knieën tot heuphoogte.\n'
        '2. Gebruik je armen en blijf op je voorvoeten.\n'
        '3. Houd een hoog tempo vol gedurende de ingestelde tijd.',
      'jump_rope':
        '1. Houd de handvatten op heuphoogte, ellebogen dicht bij je lichaam.\n'
        '2. Draai het touw vanuit je polsen en spring net hoog genoeg.\n'
        '3. Land zacht op je voorvoeten gedurende de ingestelde tijd.',
      'rowing_machine':
        '1. Zet je voeten vast en pak de handgreep met gestrekte armen.\n'
        '2. Duw af met je benen, leun iets achterover en trek de greep naar je onderste ribben.\n'
        '3. Ga in omgekeerde volgorde terug: armen, romp, benen. Houd een gelijkmatig tempo.',
      'stationary_bike':
        '1. Stel het zadel zo in dat je knie onderaan licht gebogen is.\n'
        '2. Fiets in een gelijkmatig tempo met een rechte rug.\n'
        '3. Stel de weerstand af op je doel gedurende de ingestelde tijd.',
      'treadmill_run':
        '1. Begin met wandelen en verhoog de snelheid geleidelijk.\n'
        '2. Loop rechtop met ontspannen schouders, landen onder je heupen.\n'
        '3. Vertraag naar wandelen voordat je eraf stapt.',
      'elliptical':
        '1. Stap op de pedalen en pak de bewegende handgrepen.\n'
        '2. Beweeg soepel en duw en trek ook met je armen.\n'
        '3. Houd een gelijkmatig tempo gedurende de ingestelde tijd.',
      'stair_climber':
        '1. Stap op en kies een tempo dat je kunt volhouden.\n'
        '2. Klim rechtop en gebruik de leuningen alleen licht voor balans.\n'
        '3. Ga door gedurende de ingestelde tijd.',
      'air_bike':
        '1. Ga zitten en pak de bewegende handgrepen.\n'
        '2. Trap en duw en trek tegelijk aan de handgrepen.\n'
        '3. Hoe harder je gaat, hoe meer de ventilator remt. Gedurende de ingestelde tijd.',
    },
    routineNames: {
      'home_upper': 'Bovenlichaam in 5 minuten',
      'home_lower': 'Onderlichaam in 5 minuten',
      'home_full': 'Hele lichaam in 5 minuten',
    },
    programNames: {
      'full_body': 'Full body (beginner)',
      'upper_lower': 'Upper / Lower',
      'ppl': 'Push / Pull / Legs',
      'full_body_2x': 'Full body 2× per week',
      'dumbbell_home': 'Dumbbells thuis',
      'strength_5x5': 'Kracht 5×5',
      'circuit': 'Circuittraining (uithouding)',
      'full_body_variation': 'Full body – variant',
      'bodyweight_home': 'Lichaamsgewicht thuis',
      'machines': 'Machines (beginner)',
      'upper_lower_variation': 'Upper / Lower – variant',
      'ppl_variation': 'Push / Pull / Legs – variant',
      'strength_dup': 'Kracht – weekgolven',
      'conditioning_intervals': 'Conditie – intervallen',
      'phul': 'Kracht + volume (PHUL)',
      'strength_advanced': 'Kracht – 4 dagen (gevorderd)',
      'ppl_6x': 'Push / Pull / Legs 6× per week',
    },
    programDescriptions: {
      'full_body':
        '3× per week, afwisselend training A en B. Ideaal voor de eerste maanden.',
      'upper_lower': '4× per week: bovenlichaam ma + do, onderlichaam di + vr.',
      'ppl': '3× per week: push ma, pull wo, benen vr.',
      'full_body_2x':
        'Voor drukke weken: 2 trainingen van ongeveer een uur, ma + do. Elke spiergroep 2× per week.',
      'dumbbell_home':
        '3× per week met een paar dumbbells en een mat, afwisselend A en B. Zonder sportschool.',
      'strength_5x5':
        '3× per week, afwisselend A en B: 5 sets van 5 bij de grote oefeningen. Haal je alle sets van 5, dan gaat het gewicht omhoog.',
      'circuit':
        '3× per week, afwisselend A en B: oefeningen in een circuit achter elkaar, korte rust, veel herhalingen. Voor uithouding en conditie.',
      'full_body_variation':
        '3× per week, afwisselend C en D. Dezelfde opbouw als Full body (beginner) met andere oefeningen – wissel elke 6–8 weken.',
      'bodyweight_home':
        '3× per week, afwisselend A en B, zonder materiaal – alleen een mat (en een stevige tafel om te roeien). Om te beginnen en op reis.',
      'machines':
        '3× per week, afwisselend A en B, op machines in de sportschool: makkelijk te leren, veilig ook zonder spotter. Een goede eerste stap vóór vrije gewichten.',
      'upper_lower_variation':
        '4× per week zoals Upper / Lower, met andere oefeningen (schuine bankdruk, front squat, hip thrust). Wissel elke 6–8 weken.',
      'ppl_variation':
        '3× per week zoals Push / Pull / Legs, met andere oefeningen (eerst overhead press, barbell row, hack squat). Wissel elke 6–8 weken.',
      'strength_dup':
        '3× per week: zware dag (sets van 3), volumedag (6–8 herhalingen) en middeldag (sets van 5). Door de belasting binnen de week te variëren blijft je kracht ook na het eerste jaar groeien.',
      'conditioning_intervals':
        '3× per week, afwisselend A en B: telkens een kracht- en een cardio-oefening direct na elkaar, tot slot een blok doorlopende cardio. Voor conditie, uithouding en vetverlies.',
      'phul':
        '4× per week: zware boven- en onderlichaamdagen voor kracht (ma, di), dagen met meer herhalingen voor spiermassa (do, vr). Ongeveer 12–16 sets per spiergroep per week.',
      'strength_advanced':
        '4× per week, elke dag één grote oefening (squat, bankdrukken, deadlift, overhead press): zware sets van 3, een verwante variant en hulpoefeningen voor zwakke punten.',
      'ppl_6x':
        'Ma–za: Push, Pull, Legs, daarna Push B, Pull B, Legs B. Elke spiergroep 2× per week met veel volume – voor ervaren sporters die goed herstellen.',
    },
    planNames: {
      'Full body A': 'Full body A',
      'Full body B': 'Full body B',
      'Upper body': 'Bovenlichaam',
      'Lower body': 'Onderlichaam',
      'Push': 'Push',
      'Pull': 'Pull',
      'Legs': 'Benen',
      'Full body 2× A': 'Full body 2× A',
      'Full body 2× B': 'Full body 2× B',
      'Dumbbells A': 'Dumbbells A',
      'Dumbbells B': 'Dumbbells B',
      '5×5 A': '5×5 A',
      '5×5 B': '5×5 B',
      'Circuit A': 'Circuit A',
      'Circuit B': 'Circuit B',
      'Full body C': 'Full body C',
      'Full body D': 'Full body D',
      'Bodyweight A': 'Lichaamsgewicht A',
      'Bodyweight B': 'Lichaamsgewicht B',
      'Machines A': 'Machines A',
      'Machines B': 'Machines B',
      'Upper body B': 'Bovenlichaam B',
      'Lower body B': 'Onderlichaam B',
      'Push B': 'Push B',
      'Pull B': 'Pull B',
      'Legs B': 'Benen B',
      'Strength: heavy day': 'Kracht: zware dag',
      'Strength: volume day': 'Kracht: volumedag',
      'Strength: medium day': 'Kracht: middeldag',
      'Intervals A': 'Intervallen A',
      'Intervals B': 'Intervallen B',
      'Upper power': 'Boven – kracht',
      'Lower power': 'Onder – kracht',
      'Upper hypertrophy': 'Boven – volume',
      'Lower hypertrophy': 'Onder – volume',
      'Strength: squat': 'Kracht: squat',
      'Strength: bench': 'Kracht: bankdrukken',
      'Strength: deadlift': 'Kracht: deadlift',
      'Strength: overhead press': 'Kracht: overhead press',
    },
  ),
};
