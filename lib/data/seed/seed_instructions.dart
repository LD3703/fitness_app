/// Stručné návody k vestavěným cvikům: (angličtina, čeština).
/// Klíč = slug cviku. Texty jsou orientační body techniky.
const seedInstructions = <String, (String, String)>{
  'bench_press': (
    '1. Lie on the bench, eyes under the bar, feet flat on the floor.\n'
        '2. Grip slightly wider than shoulders, squeeze shoulder blades together.\n'
        '3. Lower the bar to mid-chest with control, elbows about 45° from the body.\n'
        '4. Press up to straight arms without lifting your hips.',
    '1. Lehni si na lavici, oči pod osou, chodidla pevně na zemi.\n'
        '2. Úchop o něco širší než ramena, lopatky stáhni k sobě.\n'
        '3. Kontrolovaně spouštěj osu ke středu hrudníku, lokty asi 45° od těla.\n'
        '4. Vytlač do propnutých paží, pánev nezvedej z lavice.',
  ),
  'incline_dumbbell_press': (
    '1. Set the bench to 30–45°, dumbbells at chest level.\n'
        '2. Keep shoulder blades back and feet on the floor.\n'
        '3. Press up and slightly together, then lower slowly to chest level.',
    '1. Lavici nastav na 30–45°, jednoručky drž u hrudníku.\n'
        '2. Lopatky stažené dozadu, chodidla na zemi.\n'
        '3. Tlač nahoru a mírně k sobě, pak pomalu spouštěj k hrudníku.',
  ),
  'cable_fly': (
    '1. Stand between the pulleys, slight bend in the elbows.\n'
        '2. Bring the handles together in an arc in front of your chest.\n'
        '3. Return slowly until you feel a stretch, keep elbows fixed.',
    '1. Postav se mezi kladky, lokty lehce pokrčené.\n'
        '2. Veď rukojeti obloukem k sobě před hrudník.\n'
        '3. Pomalu se vrať do protažení, úhel v loktech neměň.',
  ),
  'push_up': (
    '1. Hands slightly wider than shoulders, body in a straight line.\n'
        '2. Lower your chest close to the floor, elbows about 45° from the body.\n'
        '3. Push back up, keep your core and glutes tight.',
    '1. Dlaně o něco šíř než ramena, tělo v jedné linii.\n'
        '2. Spusť hrudník těsně k zemi, lokty asi 45° od těla.\n'
        '3. Vytlač zpět nahoru, drž zpevněný střed těla a hýždě.',
  ),
  'deadlift': (
    '1. Bar over mid-foot, feet hip-width apart.\n'
        '2. Hinge at the hips, grip the bar, keep your back neutral.\n'
        '3. Push the floor away and stand up with the bar close to your legs.\n'
        '4. Lower with control by pushing the hips back.',
    '1. Osa nad středem chodidla, chodidla na šířku pánve.\n'
        '2. Předkloň se v kyčlích, uchop osu, záda drž rovná.\n'
        '3. Odtlač se od země a postav se, osa jede těsně podél nohou.\n'
        '4. Kontrolovaně spouštěj, pánev tlač dozadu.',
  ),
  'barbell_row': (
    '1. Hinge forward to about 45°, back straight, knees slightly bent.\n'
        '2. Pull the bar to your lower chest or belly.\n'
        '3. Squeeze the shoulder blades, then lower slowly.',
    '1. Předkloň se zhruba na 45°, záda rovná, kolena lehce pokrčená.\n'
        '2. Přitáhni osu ke spodní části hrudníku nebo k břichu.\n'
        '3. Stáhni lopatky a pomalu spouštěj.',
  ),
  'lat_pulldown': (
    '1. Grip slightly wider than shoulders, thighs under the pads.\n'
        '2. Pull the bar to your upper chest, elbows down and back.\n'
        '3. Return slowly to straight arms without swinging.',
    '1. Úchop o něco šíř než ramena, stehna pod opěrkami.\n'
        '2. Stáhni osu k horní části hrudníku, lokty dolů a dozadu.\n'
        '3. Pomalu vrať do propnutých paží, nehoupej se.',
  ),
  'pull_up': (
    '1. Hang from the bar with an overhand grip, shoulders active.\n'
        '2. Pull up until your chin is over the bar.\n'
        '3. Lower with control to a full hang.',
    '1. Vis na hrazdě nadhmatem, ramena aktivně stažená.\n'
        '2. Přitáhni se, až je brada nad hrazdou.\n'
        '3. Kontrolovaně se spusť do plného visu.',
  ),
  'overhead_press': (
    '1. Bar on the front of your shoulders, grip just outside shoulders.\n'
        '2. Tighten glutes and core, press the bar straight up.\n'
        '3. Move your head back slightly as the bar passes, lock out overhead.',
    '1. Osa na přední straně ramen, úchop těsně vně ramen.\n'
        '2. Zpevni hýždě a střed těla, tlač osu kolmo nahoru.\n'
        '3. Hlavu lehce uhni, když osa míjí obličej, a zamkni nad hlavou.',
  ),
  'lateral_raise': (
    '1. Stand tall, dumbbells at your sides, slight bend in the elbows.\n'
        '2. Raise to the sides up to shoulder height.\n'
        '3. Lower slowly, do not swing.',
    '1. Stůj vzpřímeně, jednoručky podél těla, lokty lehce pokrčené.\n'
        '2. Upažuj do výše ramen.\n'
        '3. Pomalu spouštěj, nehoupej se.',
  ),
  'pike_push_up': (
    '1. Start in a push-up position and lift your hips into an inverted V.\n'
        '2. Lower your head towards the floor between your hands.\n'
        '3. Push back up through your shoulders.',
    '1. Z pozice kliku zvedni pánev do obráceného V.\n'
        '2. Spouštěj hlavu k zemi mezi dlaně.\n'
        '3. Vytlač zpět silou ramen.',
  ),
  'dumbbell_curl': (
    '1. Stand tall, elbows at your sides.\n'
        '2. Curl the dumbbells up without moving the elbows.\n'
        '3. Lower slowly to straight arms.',
    '1. Stůj vzpřímeně, lokty u těla.\n'
        '2. Zvedej jednoručky, lokty nehýbou.\n'
        '3. Pomalu spouštěj do propnutí.',
  ),
  'triceps_pushdown': (
    '1. Stand at the cable, elbows pinned to your sides.\n'
        '2. Push the handle down until your arms are straight.\n'
        '3. Return slowly, keep the elbows still.',
    '1. Postav se ke kladce, lokty přitisknuté k tělu.\n'
        '2. Tlač rukojeť dolů do propnutých paží.\n'
        '3. Pomalu vrať, lokty zůstávají na místě.',
  ),
  'dips': (
    '1. Support yourself on the bars with straight arms.\n'
        '2. Lower until your upper arms are about parallel to the floor.\n'
        '3. Push back up, do not drop your shoulders forward.',
    '1. Opři se na bradlech v propnutých pažích.\n'
        '2. Spouštěj se, až jsou paže zhruba vodorovně.\n'
        '3. Vytlač zpět, ramena nepropadej dopředu.',
  ),
  'back_squat': (
    '1. Bar on your upper back, feet shoulder-width, toes slightly out.\n'
        '2. Brace your core and sit down between your heels.\n'
        '3. Knees follow the toes, back stays neutral.\n'
        '4. Drive up through the whole foot.',
    '1. Osa na horní části zad, chodidla na šířku ramen, špičky mírně ven.\n'
        '2. Zpevni střed těla a sedej mezi paty.\n'
        '3. Kolena jdou ve směru špiček, záda zůstávají rovná.\n'
        '4. Vstávej tlakem přes celé chodidlo.',
  ),
  'leg_press': (
    '1. Feet shoulder-width in the middle of the platform.\n'
        '2. Lower until your knees are about 90°, lower back stays on the pad.\n'
        '3. Press up without locking the knees hard.',
    '1. Chodidla na šířku ramen doprostřed plošiny.\n'
        '2. Spouštěj zhruba do 90° v kolenou, bedra zůstávají na opěrce.\n'
        '3. Vytlač nahoru, kolena prudce nezamykej.',
  ),
  'romanian_deadlift': (
    '1. Stand with the bar, knees slightly bent.\n'
        '2. Push your hips back and lower the bar along your legs.\n'
        '3. Stop when you feel a stretch in the hamstrings, back straight.\n'
        '4. Return by pushing the hips forward.',
    '1. Stůj s osou, kolena lehce pokrčená.\n'
        '2. Tlač pánev dozadu a spouštěj osu podél nohou.\n'
        '3. Zastav v protažení zadní strany stehen, záda rovná.\n'
        '4. Vrať se tlakem pánve dopředu.',
  ),
  'bodyweight_squat': (
    '1. Feet shoulder-width, arms in front for balance.\n'
        '2. Sit down as low as you can with a straight back.\n'
        '3. Stand up through your heels.',
    '1. Chodidla na šířku ramen, paže před tělem pro rovnováhu.\n'
        '2. Sedej co nejníž s rovnými zády.\n'
        '3. Vstávej tlakem přes paty.',
  ),
  'lunge': (
    '1. Step forward and lower until both knees are about 90°.\n'
        '2. Front knee stays over the foot, torso upright.\n'
        '3. Push back to the start and switch legs.',
    '1. Vykroč dopředu a klesni, až jsou obě kolena zhruba v 90°.\n'
        '2. Přední koleno nad chodidlem, trup vzpřímený.\n'
        '3. Odraz se zpět a vystřídej nohy.',
  ),
  'hip_thrust': (
    '1. Upper back on the bench, bar over your hips.\n'
        '2. Drive through the heels and lift your hips until your body is straight.\n'
        '3. Squeeze the glutes at the top, lower with control.',
    '1. Horní část zad opřená o lavici, osa přes pánev.\n'
        '2. Tlakem přes paty zvedni pánev, až je tělo v rovině.\n'
        '3. Nahoře stáhni hýždě a kontrolovaně spouštěj.',
  ),
  'glute_bridge': (
    '1. Lie on your back, knees bent, feet on the floor.\n'
        '2. Lift your hips by squeezing the glutes.\n'
        '3. Hold briefly at the top and lower slowly.',
    '1. Lehni si na záda, kolena pokrčená, chodidla na zemi.\n'
        '2. Zvedni pánev stažením hýždí.\n'
        '3. Nahoře chvíli vydrž a pomalu spouštěj.',
  ),
  'plank': (
    '1. Forearms under the shoulders, body in a straight line.\n'
        '2. Tighten the core and glutes, do not let the hips sag.\n'
        '3. Breathe steadily and hold.',
    '1. Předloktí pod rameny, tělo v jedné linii.\n'
        '2. Zpevni střed těla a hýždě, pánev nepropadá.\n'
        '3. Klidně dýchej a vydrž.',
  ),
  'crunch': (
    '1. Lie on your back, knees bent, hands by your head.\n'
        '2. Curl your shoulders off the floor using the abs.\n'
        '3. Lower slowly, do not pull on your neck.',
    '1. Lehni si na záda, kolena pokrčená, ruce u hlavy.\n'
        '2. Silou břicha odlep ramena od země.\n'
        '3. Pomalu spouštěj, netahej za krk.',
  ),
  'mountain_climber': (
    '1. Start in a push-up position.\n'
        '2. Drive your knees towards your chest one after another.\n'
        '3. Keep your hips low and the pace steady.',
    '1. Začni v pozici kliku.\n'
        '2. Střídavě přitahuj kolena k hrudníku.\n'
        '3. Pánev drž nízko a tempo plynulé.',
  ),
  'jumping_jack': (
    '1. Stand with feet together, arms at your sides.\n'
        '2. Jump your feet apart and raise your arms overhead.\n'
        '3. Jump back and repeat at a steady pace.',
    '1. Stůj snožmo, paže podél těla.\n'
        '2. Výskokem roznož a paže dej nad hlavu.\n'
        '3. Výskokem zpět a opakuj plynulým tempem.',
  ),
  'dumbbell_bench_press': (
    '1. Lie on a flat bench with dumbbells at chest level.\n'
        '2. Press up and slightly together.\n'
        '3. Lower slowly until you feel a stretch in the chest.',
    '1. Lehni si na rovnou lavici, jednoručky u hrudníku.\n'
        '2. Tlač nahoru a mírně k sobě.\n'
        '3. Pomalu spouštěj do protažení hrudníku.',
  ),
  'incline_bench_press': (
    '1. Bench at 30–45°, grip slightly wider than shoulders.\n'
        '2. Lower the bar to your upper chest.\n'
        '3. Press up, keep shoulder blades back.',
    '1. Lavice na 30–45°, úchop o něco šíř než ramena.\n'
        '2. Spouštěj osu k horní části hrudníku.\n'
        '3. Vytlač nahoru, lopatky drž stažené.',
  ),
  'chest_press_machine': (
    '1. Adjust the seat so the handles are at mid-chest.\n'
        '2. Press forward to almost straight arms.\n'
        '3. Return slowly, keep your back on the pad.',
    '1. Sedák nastav tak, aby byly rukojeti ve výši středu hrudníku.\n'
        '2. Tlač vpřed do téměř propnutých paží.\n'
        '3. Pomalu vrať, záda zůstávají na opěrce.',
  ),
  'pec_deck': (
    '1. Sit with your back on the pad, slight bend in the elbows.\n'
        '2. Bring the handles together in front of your chest.\n'
        '3. Return slowly to a comfortable stretch.',
    '1. Seď zády na opěrce, lokty lehce pokrčené.\n'
        '2. Spoj rukojeti před hrudníkem.\n'
        '3. Pomalu se vrať do příjemného protažení.',
  ),
  'seated_cable_row': (
    '1. Sit tall, feet on the platform, knees slightly bent.\n'
        '2. Pull the handle to your belly, elbows close to the body.\n'
        '3. Squeeze the shoulder blades, return slowly without rounding your back.',
    '1. Seď vzpřímeně, chodidla na opěrce, kolena lehce pokrčená.\n'
        '2. Přitáhni rukojeť k břichu, lokty u těla.\n'
        '3. Stáhni lopatky a pomalu vrať, záda nekulať.',
  ),
  'one_arm_dumbbell_row': (
    '1. One knee and hand on the bench, back flat.\n'
        '2. Pull the dumbbell towards your hip.\n'
        '3. Lower slowly to a full stretch.',
    '1. Jedno koleno a ruku opři o lavici, záda rovná.\n'
        '2. Přitahuj jednoručku k boku.\n'
        '3. Pomalu spouštěj do plného protažení.',
  ),
  'chin_up': (
    '1. Hang from the bar with an underhand grip, shoulder-width.\n'
        '2. Pull up until your chin is over the bar.\n'
        '3. Lower with control to a full hang.',
    '1. Vis na hrazdě podhmatem na šířku ramen.\n'
        '2. Přitáhni se, až je brada nad hrazdou.\n'
        '3. Kontrolovaně se spusť do plného visu.',
  ),
  'dumbbell_shoulder_press': (
    '1. Sit or stand, dumbbells at shoulder height.\n'
        '2. Press overhead without arching your lower back.\n'
        '3. Lower slowly back to the shoulders.',
    '1. Sed nebo stoj, jednoručky ve výši ramen.\n'
        '2. Tlač nad hlavu, nepřehýbej se v bedrech.\n'
        '3. Pomalu spouštěj zpět k ramenům.',
  ),
  'rear_delt_fly': (
    '1. Hinge forward with a flat back, dumbbells hanging down.\n'
        '2. Raise the arms out to the sides with slightly bent elbows.\n'
        '3. Lower slowly, do not use momentum.',
    '1. Předkloň se s rovnými zády, jednoručky visí dolů.\n'
        '2. Zapažuj do stran s lehce pokrčenými lokty.\n'
        '3. Pomalu spouštěj, bez švihu.',
  ),
  'face_pull': (
    '1. Rope at head height, hold with thumbs towards you.\n'
        '2. Pull towards your face, elbows high and wide.\n'
        '3. Squeeze the upper back, return slowly.',
    '1. Lano ve výši hlavy, palce směřují k tobě.\n'
        '2. Přitahuj k obličeji, lokty vysoko a do stran.\n'
        '3. Stáhni horní část zad a pomalu vrať.',
  ),
  'barbell_curl': (
    '1. Stand tall, shoulder-width underhand grip.\n'
        '2. Curl the bar up without swinging the body.\n'
        '3. Lower slowly to straight arms.',
    '1. Stůj vzpřímeně, podhmat na šířku ramen.\n'
        '2. Zvedej osu bez švihu trupem.\n'
        '3. Pomalu spouštěj do propnutí.',
  ),
  'hammer_curl': (
    '1. Hold dumbbells with palms facing each other.\n'
        '2. Curl up, elbows stay at your sides.\n'
        '3. Lower slowly.',
    '1. Drž jednoručky dlaněmi k sobě.\n'
        '2. Zvedej nahoru, lokty zůstávají u těla.\n'
        '3. Pomalu spouštěj.',
  ),
  'cable_curl': (
    '1. Stand facing the low pulley, elbows at your sides.\n'
        '2. Curl the handle up to your shoulders.\n'
        '3. Lower slowly, keep constant tension.',
    '1. Stůj čelem ke spodní kladce, lokty u těla.\n'
        '2. Zvedni rukojeť k ramenům.\n'
        '3. Pomalu spouštěj, udržuj stálé napětí.',
  ),
  'skull_crusher': (
    '1. Lie on a bench, bar above your chest with straight arms.\n'
        '2. Bend only the elbows and lower the bar towards your forehead.\n'
        '3. Extend back up, keep the elbows pointing up.',
    '1. Lehni si na lavici, osa nad hrudníkem v propnutých pažích.\n'
        '2. Ohýbej jen lokty a spouštěj osu k čelu.\n'
        '3. Propni zpět, lokty míří stále nahoru.',
  ),
  'overhead_triceps_extension': (
    '1. Hold one dumbbell overhead with both hands.\n'
        '2. Lower it behind your head by bending the elbows.\n'
        '3. Extend back up, keep the elbows close to your head.',
    '1. Drž jednu jednoručku oběma rukama nad hlavou.\n'
        '2. Pokrčením loktů ji spouštěj za hlavu.\n'
        '3. Propni zpět, lokty drž u hlavy.',
  ),
  'close_grip_bench_press': (
    '1. Lie on the bench, grip about shoulder-width.\n'
        '2. Lower the bar to the lower chest, elbows close to the body.\n'
        '3. Press up by extending the elbows.',
    '1. Lehni si na lavici, úchop zhruba na šířku ramen.\n'
        '2. Spouštěj osu ke spodní části hrudníku, lokty u těla.\n'
        '3. Vytlač nahoru propnutím loktů.',
  ),
  'front_squat': (
    '1. Bar on the front of your shoulders, elbows high.\n'
        '2. Squat down with an upright torso.\n'
        '3. Drive up, keep the elbows up the whole time.',
    '1. Osa na přední straně ramen, lokty vysoko.\n'
        '2. Dřepni s vzpřímeným trupem.\n'
        '3. Vstávej, lokty drž celou dobu nahoře.',
  ),
  'goblet_squat': (
    '1. Hold a kettlebell or dumbbell at your chest.\n'
        '2. Squat down between your knees with a straight back.\n'
        '3. Stand up through your heels.',
    '1. Drž kettlebell nebo jednoručku u hrudníku.\n'
        '2. Dřepni mezi kolena s rovnými zády.\n'
        '3. Vstávej tlakem přes paty.',
  ),
  'bulgarian_split_squat': (
    '1. Rear foot on a bench, front foot a stride ahead.\n'
        '2. Lower until the front thigh is about parallel.\n'
        '3. Push up through the front foot, then switch legs.',
    '1. Zadní nohu opři o lavici, přední o krok vpředu.\n'
        '2. Klesni, až je přední stehno zhruba vodorovně.\n'
        '3. Vytlač se přes přední nohu, pak vystřídej.',
  ),
  'leg_extension': (
    '1. Adjust the pad just above your ankles.\n'
        '2. Extend the legs to straight.\n'
        '3. Lower slowly with control.',
    '1. Opěrku nastav těsně nad kotníky.\n'
        '2. Propni nohy do rovné polohy.\n'
        '3. Pomalu a kontrolovaně spouštěj.',
  ),
  'leg_curl': (
    '1. Adjust the pad just above your heels.\n'
        '2. Curl the heels towards your glutes.\n'
        '3. Return slowly, do not let the weight drop.',
    '1. Opěrku nastav těsně nad paty.\n'
        '2. Přitahuj paty k hýždím.\n'
        '3. Pomalu vrať, závaží nepouštěj.',
  ),
  'calf_raise': (
    '1. Balls of the feet on the edge, heels free.\n'
        '2. Rise as high as possible onto your toes.\n'
        '3. Lower slowly into a stretch.',
    '1. Špičky na hraně, paty volně.\n'
        '2. Vystoupej co nejvýš na špičky.\n'
        '3. Pomalu spouštěj do protažení.',
  ),
  'hanging_leg_raise': (
    '1. Hang from the bar, shoulders active.\n'
        '2. Raise your legs or knees up using the abs, avoid swinging.\n'
        '3. Lower slowly.',
    '1. Vis na hrazdě, ramena aktivní.\n'
        '2. Silou břicha zvedni nohy nebo kolena, nehoupej se.\n'
        '3. Pomalu spouštěj.',
  ),
  'cable_crunch': (
    '1. Kneel facing the cable, rope at your head.\n'
        '2. Crunch down by rounding the spine, hips stay still.\n'
        '3. Return slowly.',
    '1. Klekni čelem ke kladce, lano u hlavy.\n'
        '2. Stáčej trup dolů, pánev zůstává na místě.\n'
        '3. Pomalu se vrať.',
  ),
  'dead_bug': (
    '1. Lie on your back, arms up, knees at 90°.\n'
        '2. Lower the opposite arm and leg, lower back stays on the floor.\n'
        '3. Return and switch sides.',
    '1. Lehni si na záda, paže nahoru, kolena v 90°.\n'
        '2. Spouštěj opačnou ruku a nohu, bedra zůstávají na zemi.\n'
        '3. Vrať se a vystřídej strany.',
  ),
  'side_plank': (
    '1. Lie on your side, elbow under the shoulder.\n'
        '2. Lift your hips so the body forms a straight line.\n'
        '3. Hold, then switch sides.',
    '1. Lehni si na bok, loket pod ramenem.\n'
        '2. Zvedni pánev, aby tělo tvořilo rovnou linii.\n'
        '3. Vydrž a pak vystřídej strany.',
  ),
  'burpee': (
    '1. From standing, squat and place your hands on the floor.\n'
        '2. Jump your feet back into a plank, optionally do a push-up.\n'
        '3. Jump the feet forward and jump up.',
    '1. Ze stoje dřepni a opři dlaně o zem.\n'
        '2. Výskokem dej nohy do planku, případně udělej klik.\n'
        '3. Přiskoč nohama k rukám a vyskoč.',
  ),
  'kettlebell_swing': (
    '1. Kettlebell in front, feet slightly wider than hips.\n'
        '2. Hike it back between your legs with a hip hinge.\n'
        '3. Snap the hips forward to swing it to chest height, arms relaxed.',
    '1. Kettlebell před tebou, chodidla o něco šíř než pánev.\n'
        '2. Předklonem v kyčlích ho pošli dozadu mezi nohy.\n'
        '3. Prudkým propnutím kyčlí ho vyšvihni do výše hrudníku, paže uvolněné.',
  ),
  'weighted_pull_up': (
    '1. Attach a plate to a dip belt or hold a dumbbell between your feet.\n'
        '2. Hang from the bar with an overhand grip, shoulders active.\n'
        '3. Pull up without swinging until your chin is over the bar.\n'
        '4. Lower with control to a full hang. Log only the added weight.',
    '1. Připni si kotouč na opasek s řetězem, nebo sevři jednoručku mezi chodidly.\n'
        '2. Vis na hrazdě nadhmatem, ramena aktivně stažená.\n'
        '3. Bez švihu se přitáhni, až je brada nad hrazdou.\n'
        '4. Kontrolovaně se spusť do plného visu. Zapisuj jen přidanou zátěž.',
  ),
  'weighted_dips': (
    '1. Attach a plate to a dip belt or hold a dumbbell between your feet.\n'
        '2. Support yourself on the bars with straight arms.\n'
        '3. Lower until your upper arms are about parallel to the floor.\n'
        '4. Push back up, do not drop your shoulders forward. Log only the added weight.',
    '1. Připni si kotouč na opasek s řetězem, nebo sevři jednoručku mezi chodidly.\n'
        '2. Opři se na bradlech v propnutých pažích.\n'
        '3. Spouštěj se, až jsou paže zhruba vodorovně.\n'
        '4. Vytlač zpět, ramena nepropadej dopředu. Zapisuj jen přidanou zátěž.',
  ),
};
