// Texty push notifikací v 10 jazycích aplikace. Vychází z textů novinek
// v aplikaci (lib/l10n, socialFeed*) a nezávisí na rodu příjemce ani
// odesílatele. Názvy cviků jsou v exerciseNames.ts (generuje
// tool/push_exercises.dart).
import { EXERCISE_NAMES } from "./exerciseNames.js";
import { isGymCategory, isLift } from "./plausibility.js";

/// Jazyky v pořadí sloupců EXERCISE_NAMES.
export const PUSH_LANGS = ["en", "cs", "de", "es", "fr", "it", "nl", "pl", "pt", "sk"] as const;
export type PushLang = (typeof PUSH_LANGS)[number];

export interface PushMessage {
  title: string;
  body: string;
}

/// Jazyk příjemce z localeName aplikace („de“, „pt_BR“…); jinak angličtina.
export function pushLang(raw: string): PushLang {
  const l = raw.slice(0, 2).toLowerCase();
  return (PUSH_LANGS as readonly string[]).includes(l) ? (l as PushLang) : "en";
}

// [titulek, text]; {name}, {exercise}… se dosadí přes fill().
type Template = readonly [string, string];

interface FeedTexts {
  friend: Template;
  pr: Template;
  invite: Template;
  inviteAccepted: Template;
  inviteDeclined: Template;
  challenge: Template;
  tookOn: Template;
  challengeDone: Template;
  gymOvertaken: Template;
  workouts: string;
  perDumbbell: string;
  addedWeight: string;
}

interface SessionTexts {
  invite: Template;
  updated: Template;
  cancelled: Template;
  accepted: Template;
  declined: Template;
  weekly: string;
}

const FEED: Record<PushLang, FeedTexts> = {
  en: {
    friend: ["New friend", "{name} added you as a friend."],
    pr: ["New record", "{name} set a new {exercise} record: {value}"],
    invite: ["Workout invitation", "{name} invites you to a workout: {plan}"],
    inviteAccepted: ["Invitation accepted", "{name} is joining your workout: {plan}"],
    inviteDeclined: ["Invitation declined", "{name} can't make it this time."],
    challenge: ["New challenge", "{name} challenges you. Are you in?"],
    tookOn: ["Challenge accepted", "{name} is going for your record."],
    challengeDone: ["Challenge completed", "{name} completed your challenge!"],
    gymOvertaken: ["You lost 1st place", "{name} overtook you at {gym}: {what}"],
    workouts: "Workouts",
    perDumbbell: "per dumbbell",
    addedWeight: "added weight",
  },
  cs: {
    friend: ["Nové přátelství", "{name} tě přidává do přátel."],
    pr: ["Nový rekord", "{name} má nový rekord ve cviku {exercise}: {value}"],
    invite: ["Pozvánka na trénink", "{name} tě zve na trénink: {plan}"],
    inviteAccepted: ["Pozvánka přijata", "{name} jde s tebou na trénink: {plan}"],
    inviteDeclined: ["Pozvánka odmítnuta", "{name} tentokrát nemůže."],
    challenge: ["Nová výzva", "{name} tě vyzývá. Přijmeš?"],
    tookOn: ["Výzva přijata", "{name} se pokusí překonat tvůj rekord."],
    challengeDone: ["Výzva splněna", "{name}: tvoje výzva je splněná!"],
    gymOvertaken: ["Už nejsi první", "{name} tě v posilovně {gym} předbíhá: {what}"],
    workouts: "Tréninky",
    perDumbbell: "na jednoručku",
    addedWeight: "přidané zátěže",
  },
  de: {
    friend: ["Neue Freundschaft", "{name} hat dich zu den Freunden hinzugefügt."],
    pr: ["Neuer Rekord", "{name} hat einen neuen Rekord bei {exercise} aufgestellt: {value}"],
    invite: ["Trainingseinladung", "{name} lädt dich zum Training ein: {plan}"],
    inviteAccepted: ["Einladung angenommen", "{name} trainiert mit dir: {plan}"],
    inviteDeclined: ["Einladung abgelehnt", "{name} kann diesmal nicht."],
    challenge: ["Neue Challenge", "{name} fordert dich heraus. Bist du dabei?"],
    tookOn: ["Challenge angenommen", "{name} will deinen Rekord knacken."],
    challengeDone: ["Challenge geschafft", "{name} hat deine Challenge geschafft!"],
    gymOvertaken: ["Platz 1 ist weg", "{name} hat dich bei {gym} überholt: {what}"],
    workouts: "Trainings",
    perDumbbell: "pro Kurzhantel",
    addedWeight: "Zusatzgewicht",
  },
  es: {
    friend: ["Nueva amistad", "{name} te añadió a sus amigos."],
    pr: ["Nuevo récord", "{name} tiene un nuevo récord en {exercise}: {value}"],
    invite: ["Invitación a entrenar", "{name} te invita a entrenar: {plan}"],
    inviteAccepted: ["Invitación aceptada", "{name} entrena contigo: {plan}"],
    inviteDeclined: ["Invitación rechazada", "{name} no puede esta vez."],
    challenge: ["Nuevo reto", "{name} te reta. ¿Te animas?"],
    tookOn: ["Reto aceptado", "{name} intentará superar tu récord."],
    challengeDone: ["Reto completado", "¡{name} completó tu reto!"],
    gymOvertaken: ["Perdiste el 1.er puesto", "{name} te superó en {gym}: {what}"],
    workouts: "Entrenamientos",
    perDumbbell: "por mancuerna",
    addedWeight: "de peso añadido",
  },
  fr: {
    friend: ["Nouvelle amitié", "{name} fait maintenant partie de tes amis."],
    pr: ["Nouveau record", "{name} a battu son record en {exercise} : {value}"],
    invite: ["Invitation à une séance", "{name} t’invite à une séance : {plan}"],
    inviteAccepted: ["Invitation acceptée", "{name} s’entraîne avec toi : {plan}"],
    inviteDeclined: ["Invitation refusée", "{name} ne peut pas cette fois."],
    challenge: ["Nouveau défi", "{name} te lance un défi. Tu relèves ?"],
    tookOn: ["Défi accepté", "{name} va tenter de battre ton record."],
    challengeDone: ["Défi réussi", "{name} a réussi ton défi !"],
    gymOvertaken: ["1re place perdue", "{name} passe devant toi à {gym} : {what}"],
    workouts: "Séances",
    perDumbbell: "par haltère",
    addedWeight: "de lest",
  },
  it: {
    friend: ["Nuova amicizia", "{name} ora è tra i tuoi amici."],
    pr: ["Nuovo record", "{name} ha fatto un nuovo record in {exercise}: {value}"],
    invite: ["Invito ad allenarsi", "{name} ti invita ad allenarvi insieme: {plan}"],
    inviteAccepted: ["Invito accettato", "{name} si allena con te: {plan}"],
    inviteDeclined: ["Invito rifiutato", "{name} stavolta non può."],
    challenge: ["Nuova sfida", "{name} ti sfida. Ci stai?"],
    tookOn: ["Sfida accettata", "{name} proverà a battere il tuo record."],
    challengeDone: ["Sfida completata", "{name} ha completato la tua sfida!"],
    gymOvertaken: ["Hai perso il 1° posto", "{name} ti ha soffiato il 1° posto in {gym}: {what}"],
    workouts: "Allenamenti",
    perDumbbell: "per manubrio",
    addedWeight: "di zavorra",
  },
  nl: {
    friend: ["Nieuwe vriendschap", "{name} en jij zijn nu vrienden."],
    pr: ["Nieuw record", "{name} zette een nieuw record bij {exercise}: {value}"],
    invite: ["Trainingsuitnodiging", "{name} nodigt je uit voor een training: {plan}"],
    inviteAccepted: ["Uitnodiging geaccepteerd", "{name} traint met je mee: {plan}"],
    inviteDeclined: ["Uitnodiging afgewezen", "{name} kan deze keer niet."],
    challenge: ["Nieuwe uitdaging", "{name} daagt je uit. Doe je mee?"],
    tookOn: ["Uitdaging aangenomen", "{name} gaat voor jouw record."],
    challengeDone: ["Uitdaging voltooid", "{name} heeft je uitdaging voltooid!"],
    gymOvertaken: ["1e plaats kwijt", "{name} heeft je ingehaald bij {gym}: {what}"],
    workouts: "Trainingen",
    perDumbbell: "per dumbbell",
    addedWeight: "extra gewicht",
  },
  pl: {
    friend: ["Nowa znajomość", "{name} dodaje Cię do znajomych."],
    pr: ["Nowy rekord", "{name} ma nowy rekord – {exercise}: {value}"],
    invite: ["Zaproszenie na trening", "{name} zaprasza Cię na trening: {plan}"],
    inviteAccepted: ["Zaproszenie przyjęte", "{name} trenuje z Tobą: {plan}"],
    inviteDeclined: ["Zaproszenie odrzucone", "{name} tym razem nie da rady."],
    challenge: ["Nowe wyzwanie", "{name} rzuca Ci wyzwanie. Wchodzisz?"],
    tookOn: ["Wyzwanie przyjęte", "{name} spróbuje pobić Twój rekord."],
    challengeDone: ["Wyzwanie ukończone", "{name}: Twoje wyzwanie ukończone!"],
    gymOvertaken: ["Nie jesteś już na 1. miejscu", "{name} wyprzedza Cię w siłowni {gym}: {what}"],
    workouts: "Treningi",
    perDumbbell: "na hantlę",
    addedWeight: "dodatkowego obciążenia",
  },
  pt: {
    friend: ["Nova amizade", "{name} agora está na sua lista de amigos."],
    pr: ["Novo recorde", "{name} bateu um novo recorde em {exercise}: {value}"],
    invite: ["Convite para treinar", "{name} te convidou para treinar: {plan}"],
    inviteAccepted: ["Convite aceito", "{name} vai treinar com você: {plan}"],
    inviteDeclined: ["Convite recusado", "{name} não vai poder desta vez."],
    challenge: ["Novo desafio", "{name} te desafiou. Topa?"],
    tookOn: ["Desafio aceito", "{name} vai tentar bater seu recorde."],
    challengeDone: ["Desafio concluído", "{name} concluiu seu desafio!"],
    gymOvertaken: ["Você perdeu o 1º lugar", "{name} tirou seu 1º lugar em {gym}: {what}"],
    workouts: "Treinos",
    perDumbbell: "por halter",
    addedWeight: "de carga adicional",
  },
  sk: {
    friend: ["Nové priateľstvo", "{name} ťa pridáva medzi kamarátov."],
    pr: ["Nový rekord", "{name} má nový rekord v cviku {exercise}: {value}"],
    invite: ["Pozvánka na tréning", "{name} ťa pozýva na tréning: {plan}"],
    inviteAccepted: ["Pozvánka prijatá", "{name} ide s tebou na tréning: {plan}"],
    inviteDeclined: ["Pozvánka odmietnutá", "{name} tentoraz nemôže."],
    challenge: ["Nová výzva", "{name} ťa vyzýva. Prijmeš?"],
    tookOn: ["Výzva prijatá", "{name} sa pokúsi prekonať tvoj rekord."],
    challengeDone: ["Výzva splnená", "{name}: tvoja výzva je splnená!"],
    gymOvertaken: ["Zmena na 1. mieste", "{name} ťa predbieha v posilňovni {gym}: {what}"],
    workouts: "Tréningy",
    perDumbbell: "na jednoručku",
    addedWeight: "pridanej záťaže",
  },
};

const SESSION: Record<PushLang, SessionTexts> = {
  en: {
    invite: ["Workout invitation", "{trainer} invites you to a workout: {what}"],
    updated: ["Workout changed", "{trainer} changed the workout {what}. Confirm it in the app."],
    cancelled: ["Workout cancelled", "{trainer} cancelled the workout: {what}"],
    accepted: ["Workout confirmed", "{client} accepted the workout: {what}"],
    declined: ["Workout declined", "{client} can't make the workout: {what}"],
    weekly: "{title} (weekly)",
  },
  cs: {
    invite: ["Pozvánka na trénink", "{trainer} tě zve na trénink: {what}"],
    updated: ["Změna tréninku", "{trainer} mění trénink {what}. Potvrď ho v aplikaci."],
    cancelled: ["Trénink zrušen", "{trainer} ruší trénink: {what}"],
    accepted: ["Trénink potvrzen", "{client} potvrzuje trénink: {what}"],
    declined: ["Trénink odmítnut", "{client} nemůže na trénink: {what}"],
    weekly: "{title} (každý týden)",
  },
  de: {
    invite: ["Trainingseinladung", "{trainer} lädt dich zum Training ein: {what}"],
    updated: ["Training geändert", "{trainer} hat das Training {what} geändert. Bestätige es in der App."],
    cancelled: ["Training abgesagt", "{trainer} hat das Training abgesagt: {what}"],
    accepted: ["Training bestätigt", "{client} hat das Training angenommen: {what}"],
    declined: ["Training abgelehnt", "{client} kann nicht zum Training: {what}"],
    weekly: "{title} (wöchentlich)",
  },
  es: {
    invite: ["Invitación a entrenar", "{trainer} te invita a entrenar: {what}"],
    updated: ["Entrenamiento modificado", "{trainer} cambió el entrenamiento {what}. Confírmalo en la app."],
    cancelled: ["Entrenamiento cancelado", "{trainer} canceló el entrenamiento: {what}"],
    accepted: ["Entrenamiento confirmado", "{client} aceptó el entrenamiento: {what}"],
    declined: ["Entrenamiento rechazado", "{client} no puede ir al entrenamiento: {what}"],
    weekly: "{title} (cada semana)",
  },
  fr: {
    invite: ["Invitation à une séance", "{trainer} t’invite à une séance : {what}"],
    updated: ["Séance modifiée", "{trainer} a modifié la séance {what}. Confirme-la dans l’app."],
    cancelled: ["Séance annulée", "{trainer} a annulé la séance : {what}"],
    accepted: ["Séance confirmée", "{client} a accepté la séance : {what}"],
    declined: ["Séance refusée", "{client} ne peut pas venir à la séance : {what}"],
    weekly: "{title} (chaque semaine)",
  },
  it: {
    invite: ["Invito ad allenarsi", "{trainer} ti invita ad allenarti: {what}"],
    updated: ["Allenamento modificato", "{trainer} ha modificato l’allenamento {what}. Confermalo nell’app."],
    cancelled: ["Allenamento annullato", "{trainer} ha annullato l’allenamento: {what}"],
    accepted: ["Allenamento confermato", "{client} ha accettato l’allenamento: {what}"],
    declined: ["Allenamento rifiutato", "{client} non può venire all’allenamento: {what}"],
    weekly: "{title} (ogni settimana)",
  },
  nl: {
    invite: ["Trainingsuitnodiging", "{trainer} nodigt je uit voor een training: {what}"],
    updated: ["Training gewijzigd", "{trainer} heeft de training {what} gewijzigd. Bevestig hem in de app."],
    cancelled: ["Training geannuleerd", "{trainer} heeft de training geannuleerd: {what}"],
    accepted: ["Training bevestigd", "{client} heeft de training geaccepteerd: {what}"],
    declined: ["Training afgewezen", "{client} kan niet naar de training: {what}"],
    weekly: "{title} (wekelijks)",
  },
  pl: {
    invite: ["Zaproszenie na trening", "{trainer} zaprasza Cię na trening: {what}"],
    updated: ["Zmiana treningu", "{trainer} zmienia trening {what}. Potwierdź go w aplikacji."],
    cancelled: ["Trening odwołany", "{trainer} odwołuje trening: {what}"],
    accepted: ["Trening potwierdzony", "{client} potwierdza trening: {what}"],
    declined: ["Trening odrzucony", "{client} nie da rady przyjść na trening: {what}"],
    weekly: "{title} (co tydzień)",
  },
  pt: {
    invite: ["Convite para treinar", "{trainer} te convidou para um treino: {what}"],
    updated: ["Treino alterado", "{trainer} alterou o treino {what}. Confirme no app."],
    cancelled: ["Treino cancelado", "{trainer} cancelou o treino: {what}"],
    accepted: ["Treino confirmado", "{client} aceitou o treino: {what}"],
    declined: ["Treino recusado", "{client} não vai poder ir ao treino: {what}"],
    weekly: "{title} (toda semana)",
  },
  sk: {
    invite: ["Pozvánka na tréning", "{trainer} ťa pozýva na tréning: {what}"],
    updated: ["Zmena tréningu", "{trainer} mení tréning {what}. Potvrď ho v aplikácii."],
    cancelled: ["Tréning zrušený", "{trainer} ruší tréning: {what}"],
    accepted: ["Tréning potvrdený", "{client} potvrdzuje tréning: {what}"],
    declined: ["Tréning odmietnutý", "{client} nemôže prísť na tréning: {what}"],
    weekly: "{title} (každý týždeň)",
  },
};

// Dosazení v jednom průchodu: „{plan}“ ve jménu uživatele se už
// nenahradí a návratová hodnota funkce se nevykládá jako vzor („$&“).
function fill(template: string, vars: Record<string, string>): string {
  return template.replace(/\{(\w+)\}/g, (m, k: string) => vars[k] ?? m);
}

function message(t: Template, vars: Record<string, string>): PushMessage {
  return { title: fill(t[0], vars), body: fill(t[1], vars) };
}

// Číslo s jedním desetinným místem; desetinná čárka všude kromě angličtiny.
function num(v: unknown, lang: PushLang): string {
  if (typeof v !== "number") return "";
  const s = Number.isInteger(v) ? String(v) : v.toFixed(1);
  return lang === "en" ? s : s.replace(".", ",");
}

/// Název vestavěného cviku v jazyce [lang], jinak null (vlastní cvik).
export function exerciseName(slug: string, lang: PushLang): string | null {
  return EXERCISE_NAMES[slug]?.[PUSH_LANGS.indexOf(lang)] ?? null;
}

// Staré klíče kategorií žebříčku (před přechodem na slugy cviků).
const LEGACY_CATEGORY_KEYS: Record<string, string> = {
  bench: "bench_press",
  squat: "back_squat",
};

/// Hodnota z žebříčku posilovny pro text notifikace („Mrtvý tah 180 kg“).
export function gymValueText(categoryKey: string, value: unknown, lang: PushLang): string {
  const key = LEGACY_CATEGORY_KEYS[categoryKey] ?? categoryKey;
  if (!isGymCategory(key)) return num(value, lang);
  const t = FEED[lang];
  if (!isLift(key)) return `${t.workouts} ${num(value, lang)}`;
  const note = key.startsWith("dumbbell_")
    ? ` ${t.perDumbbell}`
    : key.startsWith("weighted_")
      ? ` ${t.addedWeight}`
      : "";
  return `${exerciseName(key, lang) ?? key} ${num(value, lang)} kg${note}`;
}

/// Položka novinek (users/{uid}/feed); textová pole jsou už zkrácená.
export interface FeedPushItem {
  type: string;
  name: string;
  data: Record<string, unknown>;
  exercise: { slug: string; nameCs: string; nameEn: string };
  planName: string;
  gymName: string;
}

/// Text notifikace k položce novinek, null = typ bez notifikace.
export function feedPushText(item: FeedPushItem, lang: PushLang): PushMessage | null {
  const t = FEED[lang];
  const d = item.data;
  const name = item.name;
  const plan = item.planName;
  switch (item.type) {
    case "friend":
      return message(t.friend, { name });
    case "pr": {
      const e = item.exercise;
      const exercise = exerciseName(e.slug, lang) ??
        ((lang === "cs" || lang === "sk" ? e.nameCs : "") || e.nameEn || e.nameCs || e.slug);
      return message(t.pr, { name, exercise, value: `${num(d.value, lang)} kg` });
    }
    case "invite":
      return message(t.invite, { name, plan });
    case "inviteReply":
      return message(d.accepted === true ? t.inviteAccepted : t.inviteDeclined, { name, plan });
    case "challenge":
      return message(d.role === "tookOn" ? t.tookOn : t.challenge, { name });
    case "challengeDone":
      return message(t.challengeDone, { name });
    case "gymOvertaken": {
      const what = gymValueText(typeof d.category === "string" ? d.category : "", d.value, lang);
      return message(t.gymOvertaken, { name, gym: item.gymName, what });
    }
    default:
      return null;
  }
}

export type SessionPushChange = keyof Omit<SessionTexts, "weekly">;

/// Text notifikace k pozvánce trenéra; jména a název jsou už zkrácené.
export function sessionText(
  change: SessionPushChange,
  lang: PushLang,
  p: { trainerName: string; clientName: string; title: string; weekly: boolean },
): PushMessage {
  const t = SESSION[lang];
  const what = p.weekly ? fill(t.weekly, { title: p.title }) : p.title;
  return message(t[change], { trainer: p.trainerName, client: p.clientName, what });
}
