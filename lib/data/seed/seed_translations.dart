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
};
