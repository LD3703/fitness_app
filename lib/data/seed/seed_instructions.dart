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
  'barbell_shrug': (
    '1. Stand tall holding the bar at arm’s length, shoulder-width grip.\n'
        '2. Shrug your shoulders straight up toward your ears, arms stay straight.\n'
        '3. Pause at the top, then lower slowly. Do not roll the shoulders.',
    '1. Stůj vzpřímeně, osu drž v propnutých pažích, úchop na šířku ramen.\n'
        '2. Vytáhni ramena kolmo nahoru k uším, paže zůstávají propnuté.\n'
        '3. Nahoře krátce vydrž a pomalu spusť. Rameny nekrouž.',
  ),
  'dumbbell_shrug': (
    '1. Stand with a dumbbell in each hand at your sides, palms facing in.\n'
        '2. Shrug your shoulders straight up as high as you can.\n'
        '3. Hold briefly and lower slowly with control.',
    '1. Stůj s jednoručkami podél těla, dlaně směřují k tělu.\n'
        '2. Vytáhni ramena kolmo nahoru co nejvýš.\n'
        '3. Krátce vydrž a kontrolovaně spusť.',
  ),
  'wrist_curl': (
    '1. Sit with your forearms on your thighs or a bench, palms up, wrists past the edge.\n'
        '2. Let the dumbbells roll down toward your fingertips.\n'
        '3. Curl your wrists up as high as you can, forearms stay still.',
    '1. Sedni si, předloktí opři o stehna nebo lavici dlaněmi nahoru, zápěstí přesahují okraj.\n'
        '2. Nech jednoručky sjet ke konečkům prstů.\n'
        '3. Zápěstím je vytoč co nejvýš, předloktí se nehýbou.',
  ),
  'reverse_curl': (
    '1. Stand holding the bar with an overhand grip, shoulder-width.\n'
        '2. Curl the bar up with your elbows at your sides and wrists straight.\n'
        '3. Lower slowly to straight arms.',
    '1. Stůj a drž osu nadhmatem na šířku ramen.\n'
        '2. Zvedni osu k ramenům, lokty u těla, zápěstí rovná.\n'
        '3. Pomalu spusť do propnutých paží.',
  ),
  'dead_hang': (
    '1. Grab the bar with an overhand grip, shoulder-width.\n'
        '2. Hang with straight arms, feet off the floor, body still.\n'
        '3. Hold for the set time with your shoulders slightly engaged.',
    '1. Chyť hrazdu nadhmatem na šířku ramen.\n'
        '2. Vis v propnutých pažích, nohy nad zemí, tělo v klidu.\n'
        '3. Vydrž po stanovený čas, ramena lehce aktivní.',
  ),
  'back_extension': (
    '1. Set the pad just below your hips and lock your heels in.\n'
        '2. Lower your torso with a straight back until you feel a stretch in your hamstrings.\n'
        '3. Rise until your body is in line with your legs, do not overarch. Hold a plate for extra load.',
    '1. Polštář nastav těsně pod kyčle a zapři paty.\n'
        '2. S rovnými zády spusť trup, až ucítíš protažení zadních stehen.\n'
        '3. Zvedni se do roviny s nohama, nezaklánej se. Pro větší zátěž drž kotouč.',
  ),
  'good_morning': (
    '1. Bar on your upper back as for a squat, feet hip-width, knees soft.\n'
        '2. Push your hips back and hinge forward with a straight back until your torso is almost parallel to the floor.\n'
        '3. Drive your hips forward to stand up. Start with a light weight.',
    '1. Osu polož na horní část zad jako u dřepu, chodidla na šířku pánve, kolena lehce povolená.\n'
        '2. Posuň pánev dozadu a s rovnými zády se předkloň, až je trup skoro vodorovně.\n'
        '3. Tlakem pánve dopředu se narovnej. Začni s menší vahou.',
  ),
  'superman': (
    '1. Lie face down with your arms extended overhead.\n'
        '2. Lift your arms, chest and legs off the floor at the same time.\n'
        '3. Hold for a second at the top, then lower slowly.',
    '1. Lehni si na břicho, paže natažené před hlavou.\n'
        '2. Současně zvedni paže, hrudník a nohy nad zem.\n'
        '3. Nahoře vteřinu vydrž a pomalu spusť.',
  ),
  'decline_bench_press': (
    '1. Lock your legs in on a decline bench, grip slightly wider than shoulders.\n'
        '2. Lower the bar to your lower chest with control.\n'
        '3. Press up to straight arms, shoulder blades stay pulled back.',
    '1. Zapři nohy na negativní lavici, úchop o něco širší než ramena.\n'
        '2. Kontrolovaně spusť osu ke spodní části hrudníku.\n'
        '3. Vytlač do propnutých paží, lopatky drž stažené.',
  ),
  'smith_bench_press': (
    '1. Set the bench so the bar lines up with your mid-chest.\n'
        '2. Unhook the bar and lower it to your chest with control.\n'
        '3. Press up without locking your elbows hard, then rehook the bar.',
    '1. Lavici postav tak, aby osa mířila na střed hrudníku.\n'
        '2. Odjisti osu a kontrolovaně ji spusť k hrudníku.\n'
        '3. Vytlač nahoru bez prudkého zamknutí loktů, na konci osu zajisti.',
  ),
  'dumbbell_fly': (
    '1. Lie on a flat bench, dumbbells above your chest, elbows slightly bent.\n'
        '2. Open your arms in a wide arc until you feel a stretch in your chest.\n'
        '3. Bring the dumbbells back together, keeping the elbow angle fixed.',
    '1. Lehni si na rovnou lavici, jednoručky nad hrudníkem, lokty lehce pokrčené.\n'
        '2. Rozpaž širokým obloukem, až ucítíš protažení hrudníku.\n'
        '3. Vrať jednoručky k sobě, úhel v loktech neměň.',
  ),
  'incline_dumbbell_fly': (
    '1. Set the bench to 30°, dumbbells above your chest, elbows soft.\n'
        '2. Lower them in a wide arc until you feel a stretch in your upper chest.\n'
        '3. Squeeze them back up together over your chest.',
    '1. Lavici nastav na 30°, jednoručky nad hrudníkem, lokty povolené.\n'
        '2. Spouštěj je širokým obloukem, až ucítíš protažení horní části hrudníku.\n'
        '3. Stáhni je zpět k sobě nad hrudník.',
  ),
  'low_to_high_cable_fly': (
    '1. Set both pulleys low and stand between them with a slight forward lean.\n'
        '2. Bring the handles up and together in front of your upper chest.\n'
        '3. Lower slowly back to the stretch, elbows slightly bent.',
    '1. Obě kladky nastav dolů, postav se mezi ně v mírném předklonu.\n'
        '2. Veď rukojeti nahoru a k sobě před horní část hrudníku.\n'
        '3. Pomalu se vrať do protažení, lokty lehce pokrčené.',
  ),
  'incline_chest_press_machine': (
    '1. Adjust the seat so the handles are at upper-chest height.\n'
        '2. Press the handles forward and up until your arms are almost straight.\n'
        '3. Return slowly until you feel a stretch in your chest.',
    '1. Sedačku nastav tak, aby rukojeti byly ve výšce horní části hrudníku.\n'
        '2. Tlač rukojeti dopředu a nahoru do téměř propnutých paží.\n'
        '3. Pomalu se vrať, až ucítíš protažení hrudníku.',
  ),
  'chest_dips': (
    '1. Support yourself on the bars, lean your torso forward.\n'
        '2. Lower yourself with elbows slightly out until you feel a stretch in your chest.\n'
        '3. Push back up, keep the forward lean.',
    '1. Opři se na bradlech a nakloň trup dopředu.\n'
        '2. Spouštěj se s lokty mírně od těla, až ucítíš protažení hrudníku.\n'
        '3. Vytlač zpět nahoru, předklon udrž.',
  ),
  'incline_push_up': (
    '1. Put your hands on a bench or box, body in a straight line.\n'
        '2. Lower your chest to the edge, elbows about 45° from the body.\n'
        '3. Push back up. The higher the support, the easier the push-up.',
    '1. Opři ruce o lavici nebo bednu, tělo v jedné linii.\n'
        '2. Spusť hrudník k hraně, lokty asi 45° od těla.\n'
        '3. Vytlač se zpět. Čím vyšší opora, tím lehčí klik.',
  ),
  'decline_push_up': (
    '1. Put your feet on a bench, hands on the floor under your shoulders.\n'
        '2. Lower your chest to the floor with a tight core.\n'
        '3. Push back up without sagging your hips.',
    '1. Nohy opři o lavici, dlaně na zemi pod rameny.\n'
        '2. Se zpevněným středem spusť hrudník k zemi.\n'
        '3. Vytlač se zpět, pánev nepropadá.',
  ),
  'dumbbell_floor_press': (
    '1. Lie on the floor, knees bent, dumbbells above your chest.\n'
        '2. Lower until your upper arms touch the floor, pause briefly.\n'
        '3. Press back up to straight arms.',
    '1. Lehni si na zem, kolena pokrčená, jednoručky nad hrudníkem.\n'
        '2. Spouštěj, až se paže dotknou země, krátce vydrž.\n'
        '3. Vytlač zpět do propnutých paží.',
  ),
  't_bar_row': (
    '1. Straddle the bar, hinge forward with a straight back, grip the handle.\n'
        '2. Pull the weight to your chest, squeezing your shoulder blades.\n'
        '3. Lower with control without rounding your back.',
    '1. Postav se nad osu, s rovnými zády se předkloň a chyť rukojeť.\n'
        '2. Přitáhni závaží k hrudníku a stáhni lopatky.\n'
        '3. Kontrolovaně spusť, záda nekulať.',
  ),
  'pendlay_row': (
    '1. Bar on the floor, torso almost parallel to the floor, back straight.\n'
        '2. Pull the bar explosively to your lower chest.\n'
        '3. Set it back on the floor each rep and reset your position.',
    '1. Osa na zemi, trup skoro vodorovně, záda rovná.\n'
        '2. Výbušně přitáhni osu ke spodní části hrudníku.\n'
        '3. Po každém opakování ji polož na zem a srovnej polohu.',
  ),
  'machine_row': (
    '1. Sit with your chest against the pad and grab the handles.\n'
        '2. Pull the handles to your body, elbows close, shoulder blades together.\n'
        '3. Return slowly until your arms are straight.',
    '1. Sedni si hrudníkem k opěrce a chyť rukojeti.\n'
        '2. Přitáhni rukojeti k tělu, lokty u těla, lopatky k sobě.\n'
        '3. Pomalu se vrať do propnutých paží.',
  ),
  'chest_supported_row': (
    '1. Lie face down on a 30–45° bench, dumbbells hanging down.\n'
        '2. Row them up to your sides, squeezing your shoulder blades.\n'
        '3. Lower slowly to a full stretch.',
    '1. Lehni si na břicho na lavici nastavenou na 30–45°, jednoručky visí dolů.\n'
        '2. Přitáhni je k bokům a stáhni lopatky.\n'
        '3. Pomalu spusť do plného protažení.',
  ),
  'close_grip_lat_pulldown': (
    '1. Sit at the pulldown with a narrow or V-handle, thighs under the pads.\n'
        '2. Pull the handle to your upper chest, elbows down and back.\n'
        '3. Let it rise slowly until your arms are straight.',
    '1. Sedni si ke kladce s úzkou nebo V rukojetí, stehna pod opěrkami.\n'
        '2. Stáhni rukojeť k horní části hrudníku, lokty dolů a dozadu.\n'
        '3. Pomalu ji pusť nahoru do propnutých paží.',
  ),
  'straight_arm_pulldown': (
    '1. Stand facing a high pulley, arms almost straight, slight forward lean.\n'
        '2. Push the bar down in an arc to your thighs using your lats.\n'
        '3. Let it rise slowly, elbows stay almost straight.',
    '1. Stůj čelem k horní kladce, paže téměř propnuté, mírný předklon.\n'
        '2. Zády stáhni osu obloukem až ke stehnům.\n'
        '3. Pomalu ji pusť zpět, lokty zůstávají téměř propnuté.',
  ),
  'band_assisted_pull_up': (
    '1. Loop a resistance band over the bar and put a foot or knee in it.\n'
        '2. Pull up until your chin is over the bar.\n'
        '3. Lower with control to a full hang. A thinner band means less help.',
    '1. Přehoď odporovou gumu přes hrazdu a opři do ní chodidlo nebo koleno.\n'
        '2. Přitáhni se, až je brada nad hrazdou.\n'
        '3. Kontrolovaně se spusť do visu. Tenčí guma = menší dopomoc.',
  ),
  'inverted_row': (
    '1. Hang under a low bar or rings, body straight, heels on the floor.\n'
        '2. Pull your chest to the bar, squeezing your shoulder blades.\n'
        '3. Lower with control. The more upright, the easier.',
    '1. Zavěs se pod nízkou hrazdu nebo kruhy, tělo rovné, paty na zemi.\n'
        '2. Přitáhni hrudník k hrazdě a stáhni lopatky.\n'
        '3. Kontrolovaně se spusť. Čím víc vestoje, tím lehčí.',
  ),
  'neutral_grip_pull_up': (
    '1. Hang from parallel handles, palms facing each other.\n'
        '2. Pull up until your chin is over the handles.\n'
        '3. Lower with control to a full hang.',
    '1. Zavěs se na rovnoběžná madla, dlaně proti sobě.\n'
        '2. Přitáhni se, až je brada nad madly.\n'
        '3. Kontrolovaně se spusť do plného visu.',
  ),
  'rack_pull': (
    '1. Set the bar on the rack pins just below or above your knees.\n'
        '2. Grip it, brace your core and stand up by driving your hips forward.\n'
        '3. Lower it back to the pins with a straight back.',
    '1. Osu polož na zarážky stojanu těsně pod nebo nad kolena.\n'
        '2. Chyť ji, zpevni střed a vstaň tlakem pánve dopředu.\n'
        '3. S rovnými zády ji vrať na zarážky.',
  ),
  'trap_bar_deadlift': (
    '1. Stand inside the trap bar, feet hip-width, grip the handles.\n'
        '2. Brace, push the floor away and stand up tall.\n'
        '3. Lower the bar back down with a straight back.',
    '1. Stoupni si dovnitř trap bar, chodidla na šířku pánve, chyť madla.\n'
        '2. Zpevni se, odtlač podlahu a vstaň do vzpřímené polohy.\n'
        '3. S rovnými zády osu vrať na zem.',
  ),
  'single_arm_cable_row': (
    '1. Hold a single handle on a mid-height pulley, arm straight.\n'
        '2. Row it to your side, elbow close to the body.\n'
        '3. Return slowly and let your shoulder reach forward.',
    '1. Chyť jednu rukojeť na kladce ve výšce pasu, paže propnutá.\n'
        '2. Přitáhni ji k boku, loket u těla.\n'
        '3. Pomalu se vrať a nech rameno lehce vyjet dopředu.',
  ),
  'dumbbell_pullover': (
    '1. Lie on a bench holding one dumbbell above your chest with both hands.\n'
        '2. Lower it behind your head in an arc, elbows slightly bent.\n'
        '3. Pull it back over your chest.',
    '1. Lehni si na lavici a drž jednu jednoručku oběma rukama nad hrudníkem.\n'
        '2. Obloukem ji spusť za hlavu, lokty lehce pokrčené.\n'
        '3. Přetáhni ji zpět nad hrudník.',
  ),
  'renegade_row': (
    '1. Get into a push-up position holding two dumbbells, feet wide.\n'
        '2. Row one dumbbell to your hip without twisting your hips.\n'
        '3. Put it down and repeat with the other arm.',
    '1. Zaujmi pozici kliku s rukama na jednoručkách, nohy široko.\n'
        '2. Přitáhni jednu jednoručku k boku, pánev neprotáčej.\n'
        '3. Polož ji a opakuj druhou rukou.',
  ),
  'arnold_press': (
    '1. Sit holding dumbbells in front of your shoulders, palms facing you.\n'
        '2. Press up while rotating your palms to face forward.\n'
        '3. Lower while rotating back to the start.',
    '1. Sedni si, jednoručky drž před rameny dlaněmi k sobě.\n'
        '2. Tlač nahoru a cestou otáčej dlaně dopředu.\n'
        '3. Spouštěj a vracej dlaně do výchozí polohy.',
  ),
  'shoulder_press_machine': (
    '1. Adjust the seat so the handles start at shoulder height.\n'
        '2. Press up until your arms are almost straight.\n'
        '3. Lower slowly back to shoulder height.',
    '1. Sedačku nastav tak, aby rukojeti začínaly ve výšce ramen.\n'
        '2. Tlač nahoru do téměř propnutých paží.\n'
        '3. Pomalu se vrať do výšky ramen.',
  ),
  'push_press': (
    '1. Bar on the front of your shoulders, feet hip-width.\n'
        '2. Dip slightly at the knees, then drive up and press the bar overhead.\n'
        '3. Lower it back to your shoulders with control.',
    '1. Osa vpředu na ramenou, chodidla na šířku pánve.\n'
        '2. Lehce podřep a švihem nohou vytlač osu nad hlavu.\n'
        '3. Kontrolovaně ji vrať na ramena.',
  ),
  'cable_lateral_raise': (
    '1. Stand side-on to a low pulley, hold the handle with the far hand.\n'
        '2. Raise your arm out to the side to shoulder height.\n'
        '3. Lower slowly, keep tension on the cable.',
    '1. Stůj bokem ke spodní kladce, rukojeť drž vzdálenější rukou.\n'
        '2. Upaž do výšky ramen.\n'
        '3. Pomalu spusť, kladku nenech povolit.',
  ),
  'machine_lateral_raise': (
    '1. Sit with the pads against the outside of your arms.\n'
        '2. Raise your arms out to shoulder height.\n'
        '3. Lower slowly without letting the weight rest.',
    '1. Sedni si, opěrky ti leží z vnější strany paží.\n'
        '2. Upaž do výšky ramen.\n'
        '3. Pomalu spusť, závaží neodkládej.',
  ),
  'front_raise': (
    '1. Stand holding dumbbells in front of your thighs.\n'
        '2. Raise them forward to shoulder height, arms almost straight.\n'
        '3. Lower slowly without swinging.',
    '1. Stůj s jednoručkami před stehny.\n'
        '2. Předpaž do výšky ramen, paže téměř propnuté.\n'
        '3. Pomalu spusť, nešvihej.',
  ),
  'upright_row': (
    '1. Hold the bar in front of your thighs, grip about shoulder-width.\n'
        '2. Pull it up along your body to chest height, elbows lead.\n'
        '3. Lower slowly. Stop lower if your shoulders feel pinched.',
    '1. Drž osu před stehny, úchop zhruba na šířku ramen.\n'
        '2. Táhni ji podél těla do výšky hrudníku, vedou lokty.\n'
        '3. Pomalu spusť. Když tlačí ramena, nechoď tak vysoko.',
  ),
  'reverse_pec_deck': (
    '1. Sit facing the machine, chest on the pad, grab the handles.\n'
        '2. Open your arms back in an arc until they are in line with your body.\n'
        '3. Return slowly.',
    '1. Sedni si čelem ke stroji, hrudník na opěrce, chyť rukojeti.\n'
        '2. Obloukem rozpaž dozadu do roviny s tělem.\n'
        '3. Pomalu se vrať.',
  ),
  'band_pull_apart': (
    '1. Hold a band in front of you at shoulder height, arms straight.\n'
        '2. Pull it apart until it touches your chest, squeezing your shoulder blades.\n'
        '3. Return slowly.',
    '1. Drž gumu před sebou ve výšce ramen v propnutých pažích.\n'
        '2. Roztáhni ji až k hrudníku a stáhni lopatky.\n'
        '3. Pomalu se vrať.',
  ),
  'handstand_push_up': (
    '1. Kick up into a handstand against a wall, hands shoulder-width.\n'
        '2. Lower your head toward the floor with control.\n'
        '3. Press back up to straight arms. Use a pad under your head.',
    '1. Vyšvihni se do stojky u zdi, ruce na šířku ramen.\n'
        '2. Kontrolovaně spouštěj hlavu k zemi.\n'
        '3. Vytlač se do propnutých paží. Pod hlavu dej podložku.',
  ),
  'landmine_press': (
    '1. Hold the end of a landmine bar at your shoulder, staggered stance.\n'
        '2. Press it up and forward until your arm is straight.\n'
        '3. Lower it back to your shoulder with control.',
    '1. Drž konec landmine osy u ramene, nohy v mírném výkroku.\n'
        '2. Tlač ji nahoru a dopředu do propnuté paže.\n'
        '3. Kontrolovaně ji vrať k rameni.',
  ),
  'preacher_curl': (
    '1. Sit at the preacher bench, upper arms flat on the pad, EZ bar in hands.\n'
        '2. Curl the bar up without lifting your elbows.\n'
        '3. Lower slowly almost to straight arms.',
    '1. Sedni si ke Scottově lavici, paže celou plochou na opěrce, EZ osa v rukou.\n'
        '2. Zvedni osu, lokty z opěrky nezvedej.\n'
        '3. Pomalu spusť skoro do propnutí.',
  ),
  'concentration_curl': (
    '1. Sit on a bench, elbow braced against the inside of your thigh.\n'
        '2. Curl the dumbbell up toward your shoulder.\n'
        '3. Lower slowly to a full stretch.',
    '1. Sedni si na lavici, loket opři o vnitřní stranu stehna.\n'
        '2. Zvedni jednoručku k rameni.\n'
        '3. Pomalu spusť do plného protažení.',
  ),
  'incline_dumbbell_curl': (
    '1. Lie back on a 45–60° bench, arms hanging straight down.\n'
        '2. Curl the dumbbells up, upper arms stay still.\n'
        '3. Lower slowly to a full stretch.',
    '1. Opři se o lavici nastavenou na 45–60°, paže visí dolů.\n'
        '2. Zvedni jednoručky, paže od ramene k lokti se nehýbou.\n'
        '3. Pomalu spusť do plného protažení.',
  ),
  'ez_bar_curl': (
    '1. Stand holding an EZ bar on the angled grips, arms straight.\n'
        '2. Curl it up without swinging your body.\n'
        '3. Lower slowly to straight arms.',
    '1. Stůj a drž EZ osu za zalomená místa, paže propnuté.\n'
        '2. Zvedni ji bez švihu tělem.\n'
        '3. Pomalu spusť do propnutých paží.',
  ),
  'rope_hammer_curl': (
    '1. Attach a rope to a low pulley, palms facing each other.\n'
        '2. Curl the rope up, elbows at your sides.\n'
        '3. Lower slowly, keep tension on the cable.',
    '1. Na spodní kladku připni lano, dlaně proti sobě.\n'
        '2. Zvedni lano, lokty u těla.\n'
        '3. Pomalu spusť, kladku nenech povolit.',
  ),
  'machine_biceps_curl': (
    '1. Sit with your upper arms on the pad, grab the handles.\n'
        '2. Curl the handles up toward your shoulders.\n'
        '3. Lower slowly almost to straight arms.',
    '1. Sedni si, paže opři o opěrku a chyť rukojeti.\n'
        '2. Zvedni rukojeti k ramenům.\n'
        '3. Pomalu spusť skoro do propnutí.',
  ),
  'band_curl': (
    '1. Stand on the middle of a band, ends in your hands.\n'
        '2. Curl your hands up to your shoulders, elbows at your sides.\n'
        '3. Lower slowly.',
    '1. Stoupni si na střed gumy, konce drž v rukou.\n'
        '2. Zvedni ruce k ramenům, lokty u těla.\n'
        '3. Pomalu spusť.',
  ),
  'rope_pushdown': (
    '1. Hold a rope on a high pulley, elbows at your sides.\n'
        '2. Push the rope down and spread the ends at the bottom.\n'
        '3. Let it rise slowly to about 90° at the elbow.',
    '1. Chyť lano na horní kladce, lokty u těla.\n'
        '2. Stáhni lano dolů a dole roztáhni konce od sebe.\n'
        '3. Pomalu ho pusť nahoru zhruba do pravého úhlu v lokti.',
  ),
  'overhead_cable_extension': (
    '1. Face away from the pulley, rope behind your head, elbows up.\n'
        '2. Extend your arms forward and up until straight.\n'
        '3. Bend your elbows slowly back behind your head.',
    '1. Stůj zády ke kladce, lano za hlavou, lokty nahoru.\n'
        '2. Propni paže dopředu a nahoru.\n'
        '3. Pomalu pokrč lokty zpět za hlavu.',
  ),
  'triceps_kickback': (
    '1. Hinge forward, upper arm parallel to your body, elbow bent.\n'
        '2. Straighten your arm back until fully extended.\n'
        '3. Bend it slowly back, upper arm stays still.',
    '1. Předkloň se, paže od ramene k lokti rovnoběžně s tělem, loket pokrčený.\n'
        '2. Propni paži dozadu.\n'
        '3. Pomalu ji pokrč zpět, paže u těla se nehýbe.',
  ),
  'bench_dips': (
    '1. Put your hands on the edge of a bench behind you, legs forward.\n'
        '2. Lower your body by bending your elbows to about 90°.\n'
        '3. Push back up to straight arms.',
    '1. Opři dlaně o hranu lavice za sebou, nohy natažené vpřed.\n'
        '2. Pokrčením loktů do pravého úhlu se spusť.\n'
        '3. Vytlač se zpět do propnutých paží.',
  ),
  'machine_triceps_dip': (
    '1. Sit in the machine and grab the handles at your sides.\n'
        '2. Push the handles down until your arms are straight.\n'
        '3. Let them rise slowly to about 90° at the elbow.',
    '1. Sedni si do stroje a chyť rukojeti po stranách.\n'
        '2. Stlač rukojeti dolů do propnutých paží.\n'
        '3. Pomalu je pusť nahoru zhruba do pravého úhlu v lokti.',
  ),
  'single_arm_pushdown': (
    '1. Hold a single handle on a high pulley, elbow at your side.\n'
        '2. Push it down until your arm is straight.\n'
        '3. Let it rise slowly, elbow stays in place.',
    '1. Chyť jednu rukojeť na horní kladce, loket u těla.\n'
        '2. Stlač ji dolů do propnuté paže.\n'
        '3. Pomalu ji pusť nahoru, loket zůstává na místě.',
  ),
  'diamond_push_up': (
    '1. Push-up position with hands together under your chest, fingers forming a diamond.\n'
        '2. Lower your chest to your hands, elbows close to the body.\n'
        '3. Push back up with a straight body.',
    '1. Pozice kliku, dlaně u sebe pod hrudníkem, prsty tvoří kosočtverec.\n'
        '2. Spusť hrudník k dlaním, lokty u těla.\n'
        '3. Vytlač se zpět, tělo rovné.',
  ),
  'reverse_wrist_curl': (
    '1. Sit with forearms on your thighs, palms down, wrists past your knees.\n'
        '2. Lift the back of your hands up as high as you can.\n'
        '3. Lower slowly.',
    '1. Sedni si, předloktí opři o stehna dlaněmi dolů, zápěstí přesahují kolena.\n'
        '2. Zvedni hřbety rukou co nejvýš.\n'
        '3. Pomalu spusť.',
  ),
  'hack_squat': (
    '1. Stand on the platform with your back on the pad, shoulders under the pads.\n'
        '2. Squat down until your thighs are at least parallel to the platform.\n'
        '3. Push back up through your whole foot.',
    '1. Stoupni si na plošinu, záda na opěrce, ramena pod polštáři.\n'
        '2. Dřepni, až jsou stehna aspoň rovnoběžně s plošinou.\n'
        '3. Vytlač se zpět celým chodidlem.',
  ),
  'smith_squat': (
    '1. Bar on your upper back, feet slightly in front of the bar.\n'
        '2. Squat down with a straight back to at least parallel.\n'
        '3. Stand back up and rehook the bar at the end.',
    '1. Osa na horní části zad, chodidla mírně před osou.\n'
        '2. S rovnými zády dřepni aspoň do vodorovné polohy stehen.\n'
        '3. Vstaň a na konci osu zajisti.',
  ),
  'walking_lunge': (
    '1. Hold dumbbells at your sides and take a long step forward.\n'
        '2. Lower your back knee almost to the floor.\n'
        '3. Push through the front foot and step straight into the next lunge.',
    '1. Drž jednoručky podél těla a udělej dlouhý krok vpřed.\n'
        '2. Spusť zadní koleno skoro k zemi.\n'
        '3. Odraz se přední nohou a rovnou pokračuj dalším výpadem.',
  ),
  'reverse_lunge': (
    '1. Stand tall holding dumbbells at your sides.\n'
        '2. Step back and lower your back knee almost to the floor.\n'
        '3. Push through the front foot to return. Alternate legs.',
    '1. Stůj vzpřímeně s jednoručkami podél těla.\n'
        '2. Ukroč dozadu a spusť zadní koleno skoro k zemi.\n'
        '3. Tlakem přední nohy se vrať. Střídej nohy.',
  ),
  'step_up': (
    '1. Stand in front of a bench or box holding dumbbells.\n'
        '2. Put one foot on top and step up by pushing through that leg.\n'
        '3. Step down slowly. Alternate legs or do one side at a time.',
    '1. Postav se před lavici nebo bednu s jednoručkami v rukou.\n'
        '2. Polož jednu nohu nahoru a vystup tlakem této nohy.\n'
        '3. Pomalu sestup. Střídej nohy nebo cvič jednu stranu po druhé.',
  ),
  'split_squat': (
    '1. Stand in a long staggered stance holding dumbbells.\n'
        '2. Lower straight down until your back knee almost touches the floor.\n'
        '3. Push back up. Finish all reps, then switch legs.',
    '1. Postav se do dlouhého výkroku s jednoručkami v rukou.\n'
        '2. Spouštěj se svisle dolů, až se zadní koleno skoro dotkne země.\n'
        '3. Vytlač se zpět. Dokonči opakování a vyměň nohy.',
  ),
  'sumo_squat': (
    '1. Wide stance, toes pointing out, hold one dumbbell between your legs.\n'
        '2. Squat down with an upright torso, knees follow your toes.\n'
        '3. Stand back up and squeeze your glutes.',
    '1. Široký postoj, špičky ven, jednu jednoručku drž mezi nohama.\n'
        '2. Dřepni se vzpřímeným trupem, kolena míří ve směru špiček.\n'
        '3. Vstaň a zatni hýždě.',
  ),
  'pistol_squat': (
    '1. Stand on one leg, the other leg straight out in front.\n'
        '2. Squat down as deep as you can with control, arms forward for balance.\n'
        '3. Stand back up. Hold onto something if you need help.',
    '1. Stoupni si na jednu nohu, druhou natáhni před sebe.\n'
        '2. Kontrolovaně dřepni co nejhlouběji, ruce vpředu pro rovnováhu.\n'
        '3. Vstaň. Na začátku se můžeš něčeho přidržet.',
  ),
  'single_leg_press': (
    '1. Sit in the leg press with one foot in the middle of the platform.\n'
        '2. Lower the platform until your knee is bent to about 90°.\n'
        '3. Press back up without locking the knee. Switch legs.',
    '1. Sedni si do legpressu, jednu nohu dej doprostřed plošiny.\n'
        '2. Spouštěj plošinu, až je koleno zhruba v pravém úhlu.\n'
        '3. Vytlač zpět bez zamknutí kolena. Vyměň nohy.',
  ),
  'hip_adduction_machine': (
    '1. Sit in the machine with the pads on the inside of your knees.\n'
        '2. Squeeze your legs together.\n'
        '3. Open them slowly back to the start.',
    '1. Sedni si do stroje, polštáře máš z vnitřní strany kolen.\n'
        '2. Stáhni nohy k sobě.\n'
        '3. Pomalu je roztáhni zpět.',
  ),
  'wall_sit': (
    '1. Lean your back against a wall and slide down.\n'
        '2. Stop when your knees are at about 90°, feet under your knees.\n'
        '3. Hold for the set time, back flat against the wall.',
    '1. Opři se zády o zeď a sjeď dolů.\n'
        '2. Zastav, když jsou kolena zhruba v pravém úhlu, chodidla pod koleny.\n'
        '3. Vydrž po stanovený čas, záda celou plochou u zdi.',
  ),
  'jump_squat': (
    '1. Stand with feet shoulder-width apart.\n'
        '2. Squat down and jump up explosively.\n'
        '3. Land softly and go straight into the next squat.',
    '1. Stoupni si, chodidla na šířku ramen.\n'
        '2. Dřepni a výbušně vyskoč.\n'
        '3. Měkce dopadni a rovnou pokračuj dalším dřepem.',
  ),
  'box_jump': (
    '1. Stand in front of a sturdy box.\n'
        '2. Swing your arms and jump onto the box, landing softly.\n'
        '3. Stand up fully, then step down.',
    '1. Postav se před stabilní bednu.\n'
        '2. Švihni pažemi a vyskoč na bednu, dopadni měkce.\n'
        '3. Narovnej se a sestup dolů.',
  ),
  'seated_leg_curl': (
    '1. Sit in the machine, pad above your heels, thigh pad locked down.\n'
        '2. Curl your heels down and back as far as you can.\n'
        '3. Return slowly.',
    '1. Sedni si do stroje, polštář nad patami, stehna zajištěná shora.\n'
        '2. Přitáhni paty co nejvíc dolů a dozadu.\n'
        '3. Pomalu se vrať.',
  ),
  'nordic_curl': (
    '1. Kneel with your heels anchored under something stable.\n'
        '2. Lower your body forward as slowly as you can, hips straight.\n'
        '3. Catch yourself with your hands and pull back up with your hamstrings.',
    '1. Klekni si a zapři paty pod něco pevného.\n'
        '2. Co nejpomaleji padej trupem dopředu, kyčle rovné.\n'
        '3. Zachyť se rukama a zadními stehny se přitáhni zpět.',
  ),
  'single_leg_rdl': (
    '1. Stand on one leg holding a dumbbell, knee slightly bent.\n'
        '2. Hinge forward while the free leg goes back, back straight.\n'
        '3. Return upright by driving your hips forward.',
    '1. Stůj na jedné noze s jednoručkou v ruce, koleno lehce pokrčené.\n'
        '2. Předkloň se a volnou nohu natáhni dozadu, záda rovná.\n'
        '3. Tlakem pánve dopředu se narovnej.',
  ),
  'dumbbell_romanian_deadlift': (
    '1. Stand holding dumbbells in front of your thighs, knees soft.\n'
        '2. Push your hips back and slide the dumbbells down your legs.\n'
        '3. Stop when you feel a hamstring stretch and stand back up.',
    '1. Stůj s jednoručkami před stehny, kolena povolená.\n'
        '2. Posuň pánev dozadu a jednoručky veď podél nohou dolů.\n'
        '3. Při protažení zadních stehen se zastav a narovnej se.',
  ),
  'stiff_leg_deadlift': (
    '1. Stand holding the bar, legs almost straight.\n'
        '2. Hinge forward with a straight back and lower the bar along your legs.\n'
        '3. Stand back up by squeezing your hamstrings and glutes.',
    '1. Stůj s osou v rukou, nohy téměř propnuté.\n'
        '2. S rovnými zády se předkloň a spouštěj osu podél nohou.\n'
        '3. Zatnutím zadních stehen a hýždí se narovnej.',
  ),
  'stability_ball_leg_curl': (
    '1. Lie on your back with your heels on a gym ball, hips lifted.\n'
        '2. Roll the ball toward you by bending your knees.\n'
        '3. Roll it back out slowly, hips stay up.',
    '1. Lehni si na záda, paty na gymnastickém míči, pánev zvednutá.\n'
        '2. Pokrčením kolen přitáhni míč k sobě.\n'
        '3. Pomalu ho odvaľ zpět, pánev zůstává nahoře.',
  ),
  'sumo_deadlift': (
    '1. Wide stance, toes out, grip the bar between your legs.\n'
        '2. Brace, push your knees out and stand up with the bar close to you.\n'
        '3. Lower it back down with a straight back.',
    '1. Široký postoj, špičky ven, osu chyť mezi nohama.\n'
        '2. Zpevni se, tlač kolena ven a vstaň s osou těsně u těla.\n'
        '3. S rovnými zády ji vrať na zem.',
  ),
  'cable_glute_kickback': (
    '1. Attach an ankle strap to a low pulley, hold the machine for support.\n'
        '2. Kick your leg back and up by squeezing your glute.\n'
        '3. Return slowly without arching your lower back.',
    '1. Na spodní kladku připni manžetu na kotník a přidrž se stroje.\n'
        '2. Zatnutím hýždě zanož nohu dozadu a nahoru.\n'
        '3. Pomalu se vrať, v bedrech se neprohýbej.',
  ),
  'hip_abduction_machine': (
    '1. Sit in the machine with the pads on the outside of your knees.\n'
        '2. Push your legs apart as far as you can.\n'
        '3. Bring them back together slowly.',
    '1. Sedni si do stroje, polštáře máš z vnější strany kolen.\n'
        '2. Roztáhni nohy od sebe co nejvíc.\n'
        '3. Pomalu je vrať k sobě.',
  ),
  'machine_hip_thrust': (
    '1. Sit with your upper back on the pad and the belt over your hips.\n'
        '2. Drive your hips up until your body is straight from knees to shoulders.\n'
        '3. Squeeze your glutes at the top and lower slowly.',
    '1. Opři horní část zad o opěrku a pás si dej přes pánev.\n'
        '2. Vytlač pánev nahoru do roviny od kolen k ramenům.\n'
        '3. Nahoře zatni hýždě a pomalu spusť.',
  ),
  'single_leg_glute_bridge': (
    '1. Lie on your back, one foot on the floor, the other leg straight up.\n'
        '2. Push your hips up through the planted heel.\n'
        '3. Lower slowly. Finish all reps, then switch legs.',
    '1. Lehni si na záda, jedno chodidlo na zemi, druhou nohu natáhni nahoru.\n'
        '2. Tlakem paty opřené nohy zvedni pánev.\n'
        '3. Pomalu spusť. Dokonči opakování a vyměň nohy.',
  ),
  'donkey_kick': (
    '1. Kneel on all fours, hands under your shoulders.\n'
        '2. Kick one leg up behind you with the knee bent, sole toward the ceiling.\n'
        '3. Lower slowly without arching your back.',
    '1. Klekni si na všechny čtyři, dlaně pod rameny.\n'
        '2. Pokrčenou nohu zvedni dozadu, chodidlo míří ke stropu.\n'
        '3. Pomalu spusť, v zádech se neprohýbej.',
  ),
  'fire_hydrant': (
    '1. Kneel on all fours, back flat.\n'
        '2. Lift one bent leg out to the side up to hip height.\n'
        '3. Lower slowly, hips stay level.',
    '1. Klekni si na všechny čtyři, záda rovná.\n'
        '2. Pokrčenou nohu zvedni do strany do výšky pánve.\n'
        '3. Pomalu spusť, pánev zůstává rovně.',
  ),
  'banded_lateral_walk': (
    '1. Put a mini band above your knees or ankles and bend your knees slightly.\n'
        '2. Step sideways, keeping tension on the band.\n'
        '3. Count steps to one side, then walk back.',
    '1. Natáhni si mini gumu nad kolena nebo kotníky a lehce pokrč kolena.\n'
        '2. Kráčej do strany, guma zůstává napnutá.\n'
        '3. Počítej kroky jedním směrem a pak se vrať.',
  ),
  'cable_pull_through': (
    '1. Face away from a low pulley, rope between your legs.\n'
        '2. Hinge forward with a straight back, letting the rope go back.\n'
        '3. Drive your hips forward to stand up and squeeze your glutes.',
    '1. Stůj zády ke spodní kladce, lano mezi nohama.\n'
        '2. S rovnými zády se předkloň a nech lano odjet dozadu.\n'
        '3. Tlakem pánve dopředu se narovnej a zatni hýždě.',
  ),
  'seated_calf_raise': (
    '1. Sit with the pad on your thighs, balls of your feet on the step.\n'
        '2. Raise your heels as high as you can.\n'
        '3. Lower slowly to a full stretch.',
    '1. Sedni si, polštář na stehnech, přední část chodidel na nášlapu.\n'
        '2. Zvedni paty co nejvýš.\n'
        '3. Pomalu spusť do plného protažení.',
  ),
  'single_leg_calf_raise': (
    '1. Stand on one foot on the edge of a step, hold on for balance.\n'
        '2. Rise up onto your toes as high as you can.\n'
        '3. Lower your heel below the step for a full stretch.',
    '1. Stoupni si jednou nohou na hranu schodu a přidrž se.\n'
        '2. Vytáhni se na špičku co nejvýš.\n'
        '3. Spusť patu pod úroveň schodu do plného protažení.',
  ),
  'leg_press_calf_raise': (
    '1. Sit in the leg press, balls of your feet on the bottom edge of the platform.\n'
        '2. Push the platform away by pointing your toes.\n'
        '3. Let it come back slowly for a full stretch. Keep your knees straight.',
    '1. Sedni si do legpressu, přední část chodidel na spodní hraně plošiny.\n'
        '2. Natažením špiček odtlač plošinu.\n'
        '3. Pomalu ji pusť zpět do protažení. Kolena drž propnutá.',
  ),
  'sit_up': (
    '1. Lie on your back, knees bent, feet on the floor.\n'
        '2. Curl up all the way to sitting.\n'
        '3. Lower slowly back down.',
    '1. Lehni si na záda, kolena pokrčená, chodidla na zemi.\n'
        '2. Postupně se zvedni až do sedu.\n'
        '3. Pomalu se vrať do lehu.',
  ),
  'decline_sit_up': (
    '1. Lock your feet in on a decline bench and lie back.\n'
        '2. Curl up until your torso is upright.\n'
        '3. Lower slowly. Hold a plate for extra load.',
    '1. Zapři nohy na negativní lavici a lehni si.\n'
        '2. Zvedni se, až je trup svisle.\n'
        '3. Pomalu se vrať. Pro větší zátěž drž kotouč.',
  ),
  'bicycle_crunch': (
    '1. Lie on your back, hands by your head, legs lifted.\n'
        '2. Bring one elbow toward the opposite knee while the other leg straightens.\n'
        '3. Switch sides in a pedalling motion.',
    '1. Lehni si na záda, ruce u hlavy, nohy zvednuté.\n'
        '2. Přitáhni loket k opačnému kolenu, druhou nohu natáhni.\n'
        '3. Střídej strany jako při šlapání na kole.',
  ),
  'reverse_crunch': (
    '1. Lie on your back, knees bent at 90°, arms on the floor.\n'
        '2. Curl your hips off the floor, bringing your knees to your chest.\n'
        '3. Lower slowly without swinging.',
    '1. Lehni si na záda, kolena v pravém úhlu, ruce na zemi.\n'
        '2. Zvedni pánev a přitáhni kolena k hrudníku.\n'
        '3. Pomalu spusť, nešvihej.',
  ),
  'lying_leg_raise': (
    '1. Lie on your back, legs straight, lower back pressed to the floor.\n'
        '2. Raise your legs until they point to the ceiling.\n'
        '3. Lower slowly without arching your back.',
    '1. Lehni si na záda, nohy natažené, bedra přitisknutá k zemi.\n'
        '2. Zvedni nohy, až míří ke stropu.\n'
        '3. Pomalu spusť, bedra se neprohýbají.',
  ),
  'captains_chair_knee_raise': (
    '1. Support yourself on the forearm pads, back against the backrest.\n'
        '2. Pull your knees up toward your chest.\n'
        '3. Lower slowly without swinging.',
    '1. Opři se předloktími o opěrky, záda o opěradlo.\n'
        '2. Přitáhni kolena k hrudníku.\n'
        '3. Pomalu spusť, nešvihej.',
  ),
  'ab_wheel_rollout': (
    '1. Kneel holding the ab wheel under your shoulders.\n'
        '2. Roll forward as far as you can without sagging your lower back.\n'
        '3. Pull back to the start using your abs.',
    '1. Klekni si a drž kolečko pod rameny.\n'
        '2. Vyjeď dopředu co nejdál, bedra se neprohýbají.\n'
        '3. Břichem se přitáhni zpět.',
  ),
  'russian_twist': (
    '1. Sit leaning back slightly, feet lifted or on the floor.\n'
        '2. Rotate your torso and touch the floor beside your hip.\n'
        '3. Rotate to the other side. Hold a weight for extra load.',
    '1. Sedni si s mírným záklonem, nohy zvednuté nebo na zemi.\n'
        '2. Otoč trup a dotkni se země vedle boku.\n'
        '3. Otoč se na druhou stranu. Pro větší zátěž drž závaží.',
  ),
  'v_up': (
    '1. Lie on your back, arms overhead, legs straight.\n'
        '2. Lift your arms and legs at the same time and touch your toes.\n'
        '3. Lower slowly back down.',
    '1. Lehni si na záda, paže za hlavou, nohy natažené.\n'
        '2. Současně zvedni paže i nohy a dotkni se špiček.\n'
        '3. Pomalu se vrať do lehu.',
  ),
  'hollow_hold': (
    '1. Lie on your back and press your lower back into the floor.\n'
        '2. Lift your shoulders and straight legs a little off the floor.\n'
        '3. Hold for the set time without arching your back.',
    '1. Lehni si na záda a přitiskni bedra k zemi.\n'
        '2. Zvedni ramena a natažené nohy kousek nad zem.\n'
        '3. Vydrž po stanovený čas, bedra se neprohýbají.',
  ),
  'pallof_press': (
    '1. Stand side-on to a pulley at chest height, handle at your chest.\n'
        '2. Press the handle straight forward without letting your body rotate.\n'
        '3. Bring it back to your chest. Do both sides.',
    '1. Stůj bokem ke kladce ve výšce hrudníku, rukojeť u hrudníku.\n'
        '2. Vytlač rukojeť rovně před sebe a nedovol tělu se otočit.\n'
        '3. Vrať ji k hrudníku. Cvič obě strany.',
  ),
  'cable_woodchopper': (
    '1. Stand side-on to a high pulley, hold the handle with both hands.\n'
        '2. Pull it diagonally down across your body, rotating your torso.\n'
        '3. Return slowly. Do both sides.',
    '1. Stůj bokem k horní kladce, rukojeť drž oběma rukama.\n'
        '2. Táhni ji šikmo dolů přes tělo a otáčej trup.\n'
        '3. Pomalu se vrať. Cvič obě strany.',
  ),
  'plank_shoulder_tap': (
    '1. Get into a high plank, feet slightly apart.\n'
        '2. Touch your opposite shoulder with one hand without rocking your hips.\n'
        '3. Switch hands.',
    '1. Zaujmi pozici vysokého planku, nohy mírně od sebe.\n'
        '2. Jednou rukou se dotkni opačného ramene, pánev se nehoupe.\n'
        '3. Vyměň ruce.',
  ),
  'bird_dog': (
    '1. Kneel on all fours, back flat.\n'
        '2. Extend one arm forward and the opposite leg back.\n'
        '3. Hold for a moment, return and switch sides.',
    '1. Klekni si na všechny čtyři, záda rovná.\n'
        '2. Natáhni jednu ruku dopředu a opačnou nohu dozadu.\n'
        '3. Chvíli vydrž, vrať se a vyměň strany.',
  ),
  'power_clean': (
    '1. Stand over the bar, grip just outside your knees, back straight.\n'
        '2. Pull the bar explosively up your body and catch it on the front of your shoulders.\n'
        '3. Stand up and lower the bar. Learn the technique with a light bar.',
    '1. Stůj nad osou, úchop těsně vně kolen, záda rovná.\n'
        '2. Výbušně táhni osu podél těla nahoru a zachyť ji vpředu na ramenou.\n'
        '3. Narovnej se a osu spusť. Techniku se uč s lehkou osou.',
  ),
  'thruster': (
    '1. Hold the bar on the front of your shoulders.\n'
        '2. Squat down, then drive up and press the bar overhead in one motion.\n'
        '3. Lower the bar to your shoulders and go straight into the next squat.',
    '1. Osu drž vpředu na ramenou.\n'
        '2. Dřepni a při vstávání ji jedním pohybem vytlač nad hlavu.\n'
        '3. Vrať osu na ramena a rovnou pokračuj dalším dřepem.',
  ),
  'turkish_get_up': (
    '1. Lie on your back holding a kettlebell straight up in one hand.\n'
        '2. Stand up step by step, keeping your eyes on the kettlebell and your arm straight.\n'
        '3. Reverse the steps back to lying. Do both sides.',
    '1. Lehni si na záda a drž kettlebell v jedné ruce nad sebou.\n'
        '2. Krok za krokem se postav, kettlebell sleduj očima a paži drž propnutou.\n'
        '3. Stejnou cestou se vrať do lehu. Cvič obě strany.',
  ),
  'bear_crawl': (
    '1. On hands and feet, knees just off the floor, back flat.\n'
        '2. Crawl forward moving the opposite hand and foot together.\n'
        '3. Keep your hips low for the set time.',
    '1. Opři se o ruce a chodidla, kolena kousek nad zemí, záda rovná.\n'
        '2. Lez dopředu, současně posouvej opačnou ruku a nohu.\n'
        '3. Pánev drž nízko po stanovený čas.',
  ),
  'high_knees': (
    '1. Run on the spot, driving your knees up to hip height.\n'
        '2. Pump your arms and stay on the balls of your feet.\n'
        '3. Keep a fast pace for the set time.',
    '1. Běž na místě a zvedej kolena do výšky pánve.\n'
        '2. Pracuj pažemi a zůstaň na přední části chodidel.\n'
        '3. Drž rychlé tempo po stanovený čas.',
  ),
  'jump_rope': (
    '1. Hold the handles at hip height, elbows close to your body.\n'
        '2. Turn the rope with your wrists and jump just high enough to clear it.\n'
        '3. Land softly on the balls of your feet for the set time.',
    '1. Drž rukojeti u boků, lokty blízko těla.\n'
        '2. Toč švihadlem zápěstím a skákej jen tak vysoko, aby prošlo.\n'
        '3. Měkce dopadej na přední část chodidel po stanovený čas.',
  ),
  'rowing_machine': (
    '1. Strap your feet in and grab the handle with straight arms.\n'
        '2. Push with your legs, then lean back slightly and pull the handle to your lower ribs.\n'
        '3. Return in reverse order: arms, body, legs. Keep a steady pace.',
    '1. Upni si nohy a chyť madlo v propnutých pažích.\n'
        '2. Odraz se nohama, mírně se zakloň a přitáhni madlo ke spodním žebrům.\n'
        '3. Vracej se v opačném pořadí: paže, trup, nohy. Drž stálé tempo.',
  ),
  'stationary_bike': (
    '1. Set the saddle so your knee is slightly bent at the bottom of the pedal stroke.\n'
        '2. Pedal at a steady pace with your back straight.\n'
        '3. Adjust the resistance to your goal for the set time.',
    '1. Sedlo nastav tak, aby bylo koleno ve spodní poloze pedálu lehce pokrčené.\n'
        '2. Šlapej stálým tempem s rovnými zády.\n'
        '3. Odpor nastav podle cíle a jeď po stanovený čas.',
  ),
  'treadmill_run': (
    '1. Start walking and gradually raise the speed.\n'
        '2. Run upright with relaxed shoulders, land under your hips.\n'
        '3. Slow down to a walk before you step off.',
    '1. Začni chůzí a postupně zvyšuj rychlost.\n'
        '2. Běž vzpřímeně s uvolněnými rameny, dopadej pod pánev.\n'
        '3. Před sestoupením zpomal do chůze.',
  ),
  'elliptical': (
    '1. Step on the pedals and hold the moving handles.\n'
        '2. Move smoothly, pushing and pulling with your arms as well.\n'
        '3. Keep a steady pace for the set time.',
    '1. Stoupni si na pedály a chyť pohyblivá madla.\n'
        '2. Pohybuj se plynule a zapoj i paže tlakem a tahem.\n'
        '3. Drž stálé tempo po stanovený čas.',
  ),
  'stair_climber': (
    '1. Step on and pick a speed you can keep.\n'
        '2. Climb upright, use the rails only lightly for balance.\n'
        '3. Keep going for the set time.',
    '1. Stoupni si na schody a zvol rychlost, kterou udržíš.\n'
        '2. Stoupej vzpřímeně, zábradlí používej jen lehce pro rovnováhu.\n'
        '3. Pokračuj po stanovený čas.',
  ),
  'air_bike': (
    '1. Sit on the bike and grab the moving handles.\n'
        '2. Pedal and push and pull the handles at the same time.\n'
        '3. The harder you go, the more the fan resists. Go for the set time.',
    '1. Sedni si na kolo a chyť pohyblivá madla.\n'
        '2. Šlapej a zároveň tlač a táhni madla.\n'
        '3. Čím víc přidáš, tím víc větrák brzdí. Jeď po stanovený čas.',
  ),
};
