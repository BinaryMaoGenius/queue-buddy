class AppStrings {
  // General UI
  static const String appName = "Queue-Buddy";
  static const String homeTitle = "SIRA";
  static const String proximityAgencies = "Agences à proximité";
  static String minWaiting(num min) => "$min min d'attente";
  static const String tagline = "L'attente devient intelligente";
  static const String takeTicket = "PRENDRE UN TICKET";
  static const String takeMyTicket = "PRENDRE MON TICKET";
  static const String history = "HISTORIQUE";
  static const String estimatedTime = "TEMPS ESTIMÉ";
  static const String live = "Live";
  static const String peopleWaitingSuffix = "personnes dans l'attente";
  static const String availableServices = "Services disponibles";
  static const String chooseVisitObject = "Choisissez l'objet de votre visite";
  static const String quickServiceDesc = "Service rapide et efficace";
  static const String yourInfo = "Vos informations";
  static const String fullName = "Nom complet";
  static const String phone = "Téléphone";
  static const String enterNameError = "Veuillez entrer votre nom";
  static const String enterPhoneError = "Veuillez entrer votre numéro";
  static const String phoneMinLengthError =
      "Le numéro doit contenir au moins 8 chiffres";
  static const String errorPrefix = "Erreur: ";

  // Ticket Page
  static const String yourTicket = "VOTRE TICKET";
  static const String pleaseWait = "Veuillez patienter...";
  static const String notificationSoon =
      "Nous vous notifierons dès que c'est votre tour";
  static const String returnHome = "RETOUR À L'ACCUEIL";
  static const String itsYourTurn = "C'est votre tour !";
  static const String presentAtCounter = "Veuillez vous présenter au guichet";
  static const String positionInQueue = "Position dans la file";
  static const String peopleInFront = "personnes devant vous";

  // History Page
  static const String historyTitle = "HISTORIQUE";
  static const String noTickets = "Aucun ticket récent";
  static const String futureTicketsPrompt =
      "Vos futurs tickets apparaîtront ici.";

  // Review System
  static const String yourReview = "VOTRE AVIS";
  static const String howWasWait = "Comment s'est passée votre attente ?";
  static const String optionalComment = "Un commentaire ? (Optionnel)";
  static const String send = "ENVOYER";
  static const String thanksFeedback = "Merci pour votre retour !";

  // ASR Intents / Services (Bambara mapping)
  static const String versement = "Versement";
  static const String retrait = "Retrait";
  static const String ouvertureCompte = "Ouverture de compte";
  static const String reclamation = "Réclamation";

  // Back Office
  static const String backOfficeTitle = "DASHBOARD SUPERVISEUR";
  static const String callNext = "APPELER LE SUIVANT";
  static const String validateCurrent = "VALIDER LE TICKET ACTUEL";
  static const String serveDone = "SERVICE TERMINÉ";
  static const String noTicketsToCall = "Aucun ticket à appeler";

  // Assistant
  static const String assistantBtn = "ASSISTANT SOLOBA";
  static const String analyzing = "Analyse en cours...";
  static const String solobaListeningBambara = "Soloba bɛ i lamɛnna...";
  static const String solobaListeningDesc = "Soloba vous écoute en Bambara";
  static const String stop = "ARRÊTER";
  static const String cancel = "ANNULER";
  static const String aiUnderstood = "L'IA SOLOBA V3 A COMPRIS :";
  static const String retry = "REPRÉCISER";
  static const String continueBtn = "CONTINUER";
  static const String microphoneDenied = "Permission micro refusée.";
  static const String audioError = "Impossible de générer le fichier audio.";
  static const String solobaErrorPrefix = "Erreur Soloba: ";

  // New UI
  static const String peakHoursLabel = "AFFLUENCE :";

  // Notification Bell
  static const String notifTicketTaken = "Ticket bien pris !";
  static const String notifTicketTakenBody =
      "Votre ticket a été pris avec succès. Vous recevrez des alertes.";
  static const String notif30min = "Rappel";
  static const String notif30minBody =
      "Il vous reste environ 30 minutes avant votre tour.";
  static const String notif10min = "Bientôt votre tour";
  static const String notif10minBody =
      "Votre tour arrive dans environ 10 minutes !";
  static const String notifYourTurn = "C'est votre tour !";
  static const String notifYourTurnBody =
      "Veuillez vous présenter au guichet maintenant.";
  static const String notifications = "Notifications";
  static const String noNotifications = "Aucune notification";

  // QR Code & Download
  static const String qrCodeLabel = "QR Code d'identification";
  static const String scanAtArrival = "Présentez ce QR code à l'arrivée";
  static const String downloadTicket = "TÉLÉCHARGER LE TICKET";
  static const String ticketSaved = "Ticket sauvegardé !";
  static const String ticketShared = "Partage du ticket...";

  // GAB vs Guichet
  static const String gabLabel = "GAB (Distributeur)";
  static const String guichetLabel = "Guichet";
  static const String gabDescription = "Guichet automatique — Carte bancaire";
  static const String guichetDescription =
      "Guichet humain — Service personnalisé";

  // Welcome Greeting
  static const String welcomeGreeting =
      "Aw ni ce! Ne ye SIRA ye. N bɛ i dɛmɛ ka i ka ticket ta ni hɛrɛ ye, i kana i ka waati bɔnya.";
  static const String welcomeGreetingFr =
      "Bonjour ! Je suis SIRA. Je vous aide à prendre votre ticket en toute tranquillité pour optimiser votre temps.";

  // Bambara voice guides by screen
  static const String homeVoiceGuideBm =
      "Nin yoro la, i bɛ se ka banque yoro sugandi. I bɛ se fana ka Soloba wele walasa ka i ka baara fɔ n ye Bambara kan na.";
  static const String takeTicketVoiceGuideBm =
      "Nin yoro la, sugandi baara min i b’a fe, sɔrɔ i ka tɔgɔ ni telefonu nimɛro, o kɔfɛ i bɛ se ka i ka ticket ta.";
  static const String ticketVoiceGuideBm =
      "Nin ye i ka ticket ye. I ka nimɛro bɛ yan. A lajɛ kosɛbɛ, ani i bɛ se k’a download walima ka bɔ ka taa ɲɛna.";
  static const String historyVoiceGuideBm =
      "Nin ye i ka ticket kɔfɛkow ye. I ka ticket kɔrɔw bɛɛ bɛ yan, walasa i bɛ se k’u lajɛ tuguni.";
  static const String dashboardVoiceGuideBm =
      "Nin ye dashboard ye. Yan i bɛ se ka ticketw lajɛ, ka se ka wele ka tuma bɔ, ani ka baara kɛli ɲɛnabɔ.";
  static const String analyticsVoiceGuideBm =
      "Nin ye statistiques yoro ye. Yan i bɛ se ka lɛrɛnni lajɛ, waati hakɛ, ani tile ka baara kɛcogo lajɛ ka yidɛsɛbɛn sɔrɔ.";

  // Voice assistant not available
  static const String asrUnavailable =
      "Le serveur vocal est indisponible. Utilisez le mode démonstration.";
  static const String demoMode = "MODE DÉMO";
  static const String tryDemoVoice = "ESSAYER (DÉMO)";

  // Dashboard KPI
  static const String kpiWaiting = "En Attente";
  static const String kpiAvgWait = "Attente Moyenne";
  static const String kpiServed = "Servis (Jour)";
  static const String kpiValidated = "Validés (Jour)";
  static const String guichetAnalysis = "Analyse des Guichets";
  static const String gabAnalysis = "Analyse des GAB";
  static const String statusFunctional = "fonctionnels";
}
