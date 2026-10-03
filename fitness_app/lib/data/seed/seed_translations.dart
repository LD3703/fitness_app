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
    },
    programDescriptions: {
      'full_body':
        '3× pro Woche, abwechselnd Training A und B. Ideal für die ersten Monate.',
      'upper_lower': '4× pro Woche: Oberkörper Mo + Do, Unterkörper Di + Fr.',
      'ppl': '3× pro Woche: Push Mo, Pull Mi, Legs Fr.',
    },
    planNames: {
      'Full body A': 'Ganzkörper A',
      'Full body B': 'Ganzkörper B',
      'Upper body': 'Oberkörper',
      'Lower body': 'Unterkörper',
      'Push': 'Push',
      'Pull': 'Pull',
      'Legs': 'Legs',
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
    },
    exerciseInstructions: {
      'bench_press':
        '1. Túmbate en el banco con los ojos bajo la barra y los pies apoyados en el suelo.\n'
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
        '3. Baja con control hasta quedar colgado del todo.',
      'overhead_press':
        '1. Barra apoyada delante de los hombros, agarre justo por fuera de ellos.\n'
        '2. Aprieta glúteos y core y empuja la barra recta hacia arriba.\n'
        '3. Echa la cabeza un poco atrás al pasar la barra y bloquea arriba.',
      'lateral_raise':
        '1. De pie y erguido, mancuernas a los lados, codos ligeramente flexionados.\n'
        '2. Eleva los brazos hacia los lados hasta la altura de los hombros.\n'
        '3. Baja despacio, sin balancearte.',
      'pike_push_up':
        '1. Empieza en posición de flexión y sube la cadera formando una V invertida.\n'
        '2. Baja la cabeza hacia el suelo entre las manos.\n'
        '3. Empuja de vuelta arriba con los hombros.',
      'dumbbell_curl':
        '1. De pie y erguido, codos pegados al cuerpo.\n'
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
        '1. Túmbate boca arriba, rodillas flexionadas y pies en el suelo.\n'
        '2. Sube la cadera apretando los glúteos.\n'
        '3. Aguanta un momento arriba y baja despacio.',
      'plank':
        '1. Antebrazos bajo los hombros, cuerpo en línea recta.\n'
        '2. Aprieta el core y los glúteos, no dejes caer la cadera.\n'
        '3. Respira de forma constante y aguanta.',
      'crunch':
        '1. Túmbate boca arriba, rodillas flexionadas, manos junto a la cabeza.\n'
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
        '1. Túmbate en un banco plano con las mancuernas a la altura del pecho.\n'
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
        '1. Siéntate erguido, pies en la plataforma, rodillas un poco flexionadas.\n'
        '2. Tira del agarre hacia el abdomen, codos pegados al cuerpo.\n'
        '3. Junta las escápulas y vuelve despacio sin redondear la espalda.',
      'one_arm_dumbbell_row':
        '1. Una rodilla y una mano en el banco, espalda plana.\n'
        '2. Tira de la mancuerna hacia la cadera.\n'
        '3. Baja despacio hasta estirar del todo.',
      'chin_up':
        '1. Cuélgate de la barra con agarre supino a la anchura de los hombros.\n'
        '2. Sube hasta que la barbilla pase la barra.\n'
        '3. Baja con control hasta quedar colgado del todo.',
      'dumbbell_shoulder_press':
        '1. Sentado o de pie, mancuernas a la altura de los hombros.\n'
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
        '1. De pie y erguido, agarre supino a la anchura de los hombros.\n'
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
        '1. Túmbate en un banco con la barra sobre el pecho y los brazos estirados.\n'
        '2. Flexiona solo los codos y baja la barra hacia la frente.\n'
        '3. Vuelve a estirar manteniendo los codos apuntando hacia arriba.',
      'overhead_triceps_extension':
        '1. Sujeta una mancuerna por encima de la cabeza con ambas manos.\n'
        '2. Bájala por detrás de la cabeza flexionando los codos.\n'
        '3. Vuelve a estirar con los codos cerca de la cabeza.',
      'close_grip_bench_press':
        '1. Túmbate en el banco con un agarre a la anchura de los hombros aprox.\n'
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
        '1. Túmbate boca arriba, brazos hacia arriba y rodillas a 90°.\n'
        '2. Baja el brazo y la pierna contrarios, con la zona lumbar pegada al suelo.\n'
        '3. Vuelve y cambia de lado.',
      'side_plank':
        '1. Túmbate de lado con el codo bajo el hombro.\n'
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
        '4. Baja con control hasta quedar colgado del todo. Anota solo el peso añadido.',
      'weighted_dips':
        '1. Cuelga un disco de un cinturón de lastre o sujeta una mancuerna entre los pies.\n'
        '2. Apóyate en las paralelas con los brazos estirados.\n'
        '3. Baja hasta que los brazos queden más o menos paralelos al suelo.\n'
        '4. Empuja de vuelta arriba sin dejar caer los hombros hacia delante. Anota solo el peso añadido.',
    },
    routineNames: {
      'home_upper': 'Tren superior en 5 minutos',
      'home_lower': 'Tren inferior en 5 minutos',
      'home_full': 'Cuerpo completo en 5 minutos',
    },
    programNames: {
      'full_body': 'Cuerpo completo (principiante)',
      'upper_lower': 'Tren superior / inferior',
      'ppl': 'Empuje / Tirón / Pierna',
    },
    programDescriptions: {
      'full_body':
        '3× por semana, alternando los entrenos A y B. Ideal para los primeros meses.',
      'upper_lower':
        '4× por semana: tren superior lun + jue, tren inferior mar + vie.',
      'ppl': '3× por semana: empuje lun, tirón mié, pierna vie.',
    },
    planNames: {
      'Full body A': 'Cuerpo completo A',
      'Full body B': 'Cuerpo completo B',
      'Upper body': 'Tren superior',
      'Lower body': 'Tren inferior',
      'Push': 'Empuje',
      'Pull': 'Tirón',
      'Legs': 'Pierna',
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
        '1. Assis ou debout, haltères à hauteur d’épaules.\n'
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
    },
    programDescriptions: {
      'full_body':
        '3× par semaine, en alternant les séances A et B. Idéal pour les premiers mois.',
      'upper_lower':
        '4× par semaine : haut du corps lun. + jeu., bas du corps mar. + ven.',
      'ppl': '3× par semaine : push lun., pull mer., jambes ven.',
    },
    planNames: {
      'Full body A': 'Full body A',
      'Full body B': 'Full body B',
      'Upper body': 'Haut du corps',
      'Lower body': 'Bas du corps',
      'Push': 'Push',
      'Pull': 'Pull',
      'Legs': 'Jambes',
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
    },
    exerciseInstructions: {
      'bench_press':
        '1. Połóż się na ławce, oczy pod sztangą, stopy płasko na podłodze.\n'
        '2. Chwyć sztangę nieco szerzej niż barki, ściągnij łopatki.\n'
        '3. Opuszczaj sztangę kontrolowanie na środek klatki, łokcie ok. 45° od tułowia.\n'
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
        '4. Opuść kontrolowanie, cofając biodra.',
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
        '3. Opuść się kontrolowanie do pełnego zwisu.',
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
        '3. Na górze mocno napnij pośladki, opuść kontrolowanie.',
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
        '3. Opuść się kontrolowanie do pełnego zwisu.',
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
        '3. Opuszczaj powoli i kontrolowanie.',
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
        '4. Opuść się kontrolowanie do pełnego zwisu. Zapisuj tylko dodatkowy ciężar.',
      'weighted_dips':
        '1. Przypnij talerz do pasa z łańcuchem albo ściśnij hantlę między stopami.\n'
        '2. Oprzyj się na poręczach na wyprostowanych ramionach.\n'
        '3. Opuść się, aż ramiona będą mniej więcej równoległe do podłogi.\n'
        '4. Wypchnij się w górę, nie wysuwaj barków do przodu. Zapisuj tylko dodatkowy ciężar.',
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
    },
    programDescriptions: {
      'full_body':
        '3× w tygodniu, na zmianę trening A i B. Idealny na pierwsze miesiące.',
      'upper_lower':
        '4× w tygodniu: góra ciała pon. + czw., dół ciała wt. + pt.',
      'ppl': '3× w tygodniu: push pon., pull śr., nogi pt.',
    },
    planNames: {
      'Full body A': 'Full body A',
      'Full body B': 'Full body B',
      'Upper body': 'Góra ciała',
      'Lower body': 'Dół ciała',
      'Push': 'Push',
      'Pull': 'Pull',
      'Legs': 'Nogi',
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
        '3. Desça com controle até ficar totalmente pendurado.',
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
        '3. Desça com controle até ficar totalmente pendurado.',
      'dumbbell_shoulder_press':
        '1. Sentado ou em pé, halteres na altura dos ombros.\n'
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
        '4. Desça com controle até ficar totalmente pendurado. Registre só a carga adicional.',
      'weighted_dips':
        '1. Prenda uma anilha em um cinto de carga ou segure um halter entre os pés.\n'
        '2. Apoie-se nas barras com os braços estendidos.\n'
        '3. Desça até os braços ficarem mais ou menos paralelos ao chão.\n'
        '4. Empurre de volta, sem deixar os ombros caírem para a frente. Registre só a carga adicional.',
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
    },
    programDescriptions: {
      'full_body':
        '3× por semana, alternando os treinos A e B. Ideal para os primeiros meses.',
      'upper_lower':
        '4× por semana: superiores seg + qui, inferiores ter + sex.',
      'ppl': '3× por semana: push seg, pull qua, legs sex.',
    },
    planNames: {
      'Full body A': 'Full body A',
      'Full body B': 'Full body B',
      'Upper body': 'Superiores',
      'Lower body': 'Inferiores',
      'Push': 'Push',
      'Pull': 'Pull',
      'Legs': 'Legs',
    },
  ),
  'it': (
    exerciseNames: {
      'bench_press': 'Panca piana',
      'incline_dumbbell_press': 'Panca inclinata con manubri',
      'cable_fly': 'Croci ai cavi',
      'push_up': 'Piegamenti',
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
        '1. Parti in posizione di piegamento e solleva le anche formando una V rovesciata.\n'
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
        '1. Parti in posizione di piegamento.\n'
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
        '1. Da seduti o in piedi, manubri all’altezza delle spalle.\n'
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
        '2. Porta i piedi indietro con un salto in posizione di plank, se vuoi fai un piegamento.\n'
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
    },
    programDescriptions: {
      'full_body':
        '3 volte a settimana, alternando gli allenamenti A e B. Ideale per i primi mesi.',
      'upper_lower':
        '4 volte a settimana: parte superiore lun + gio, parte inferiore mar + ven.',
      'ppl': '3 volte a settimana: push lun, pull mer, gambe ven.',
    },
    planNames: {
      'Full body A': 'Total body A',
      'Full body B': 'Total body B',
      'Upper body': 'Parte superiore',
      'Lower body': 'Parte inferiore',
      'Push': 'Push',
      'Pull': 'Pull',
      'Legs': 'Gambe',
    },
  ),
  'sk': (
    exerciseNames: {
      'bench_press': 'Bench press',
      'incline_dumbbell_press': 'Tlaky s jednoručkami na šikmej lavičke',
      'cable_fly': 'Rozpažovanie na kladke',
      'push_up': 'Kľuk',
      'deadlift': 'Mŕtvy ťah',
      'barbell_row': 'Priťahovanie veľkej činky v predklone',
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
      'jumping_jack': 'Skákajúci panák',
      'dumbbell_bench_press': 'Tlaky s jednoručkami na rovnej lavičke',
      'incline_bench_press': 'Bench press na šikmej lavičke',
      'chest_press_machine': 'Tlaky na hrudníkovom stroji',
      'pec_deck': 'Butterfly na stroji',
      'seated_cable_row': 'Priťahovanie spodnej kladky v sede',
      'one_arm_dumbbell_row': 'Priťahovanie jednoručky v opore',
      'chin_up': 'Zhyb podhmatom',
      'dumbbell_shoulder_press': 'Tlaky s jednoručkami nad hlavu',
      'rear_delt_fly': 'Zapažovanie v predklone',
      'face_pull': 'Priťahovanie lana k tvári',
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
      'weighted_dips': 'Dipy so záťažou',
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
    },
    programDescriptions: {
      'full_body':
        '3× týždenne, striedanie tréningov A a B. Ideálne na prvé mesiace.',
      'upper_lower': '4× týždenne: horná polovica Po + Št, dolná Ut + Pi.',
      'ppl': '3× týždenne: tlaky Po, priťahy St, nohy Pi.',
    },
    planNames: {
      'Full body A': 'Celé telo A',
      'Full body B': 'Celé telo B',
      'Upper body': 'Horná polovica',
      'Lower body': 'Dolná polovica',
      'Push': 'Push (tlaky)',
      'Pull': 'Pull (priťahy)',
      'Legs': 'Nohy',
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
    },
    programDescriptions: {
      'full_body':
        '3× per week, afwisselend training A en B. Ideaal voor de eerste maanden.',
      'upper_lower': '4× per week: bovenlichaam ma + do, onderlichaam di + vr.',
      'ppl': '3× per week: push ma, pull wo, benen vr.',
    },
    planNames: {
      'Full body A': 'Full body A',
      'Full body B': 'Full body B',
      'Upper body': 'Bovenlichaam',
      'Lower body': 'Onderlichaam',
      'Push': 'Push',
      'Pull': 'Pull',
      'Legs': 'Benen',
    },
  ),
};
