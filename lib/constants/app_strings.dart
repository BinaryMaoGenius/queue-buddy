class AppStrings {
  // General UI
  static const String appName = "Queue-Buddy";

  static String homeTitle(String locale) => locale == 'en' ? "HOME" : "ACCUEIL";
  static const String siraTitle = "SIRA";

  static String proximityAgencies(String locale) =>
      locale == 'en' ? "Agencies nearby" : "Agences à proximité";

  static String minWaiting(num min, String locale) =>
      locale == 'en' ? "$min min wait" : "$min min d'attente";

  static String tagline(String locale) =>
      locale == 'en' ? "Smart waiting, zero stress" : "L'attente devient intelligente";

  static String takeTicket(String locale) =>
      locale == 'en' ? "GET A TICKET" : "PRENDRE UN TICKET";

  static String history(String locale) =>
      locale == 'en' ? "HISTORY" : "HISTORIQUE";

  static String estimatedTime(String locale) =>
      locale == 'en' ? "ESTIMATED TIME" : "TEMPS ESTIMÉ";

  static const String live = "Live";

  static String peopleWaitingSuffix(String locale) =>
      locale == 'en' ? "people waiting" : "personnes dans l'attente";

  static String availableServices(String locale) =>
      locale == 'en' ? "Available services" : "Services disponibles";

  static String chooseVisitObject(String locale) =>
      locale == 'en' ? "Choose the object of your visit" : "Choisissez l'objet de votre visite";

  static String yourInfo(String locale) =>
      locale == 'en' ? "Your Information" : "Vos informations";

  static String fullName(String locale) =>
      locale == 'en' ? "Full Name" : "Nom complet";

  static String phone(String locale) =>
      locale == 'en' ? "Phone" : "Téléphone";

  static String enterNameError(String locale) =>
      locale == 'en' ? "Please enter your name" : "Veuillez entrer votre nom";

  static String enterPhoneError(String locale) =>
      locale == 'en' ? "Please enter your number" : "Veuillez entrer votre numéro";

  // Ticket Page
  static String yourTicket(String locale) =>
      locale == 'en' ? "YOUR TICKET" : "VOTRE TICKET";

  static String pleaseWait(String locale) =>
      locale == 'en' ? "Please wait..." : "Veuillez patienter...";

  static String notificationSoon(String locale) =>
      locale == 'en' ? "We will notify you when it's your turn" : "Nous vous notifierons dès que c'est votre tour";

  static String returnHome(String locale) =>
      locale == 'en' ? "RETURN HOME" : "RETOUR À L'ACCUEIL";

  static String itsYourTurn(String locale) =>
      locale == 'en' ? "It's your turn!" : "C'est votre tour !";

  static String presentAtCounter(String locale) =>
      locale == 'en' ? "Please present yourself at the counter" : "Veuillez vous présenter au guichet";

  static String positionInQueue(String locale) =>
      locale == 'en' ? "Position in queue" : "Position dans la file";

  static String peopleInFront(String locale) =>
      locale == 'en' ? "people in front of you" : "personnes devant vous";

  // Assistant
  static String assistantBtn(String locale) =>
      locale == 'en' ? "ENGLISH ASSISTANT" : "ASSISTANT SOLOBA";

  static String analyzing(String locale) =>
      locale == 'en' ? "Analyzing..." : "Analyse en cours...";

  static String solobaListening(String locale) =>
      locale == 'en' ? "I'm listening..." : "Je vous écoute...";

  static String solobaListeningDesc(String locale) =>
      locale == 'en' ? "Speak to Sira in English or French" : "Parlez à Sira en Français ou Bambara";

  static String stop(String locale) => locale == 'en' ? "STOP" : "ARRÊTER";
  static String cancel(String locale) => locale == 'en' ? "CANCEL" : "ANNULER";

  static String aiUnderstood(String locale) =>
      locale == 'en' ? "SIRA AI UNDERSTOOD:" : "L'IA SOLOBA V3 A COMPRIS :";

  static String retry(String locale) => locale == 'en' ? "RETRY" : "REPRÉCISER";
  static String continueBtn(String locale) => locale == 'en' ? "CONTINUE" : "CONTINUER";

  // QR Code & Download
  static String downloadTicket(String locale) =>
      locale == 'en' ? "DOWNLOAD TICKET" : "TÉLÉCHARGER LE TICKET";

  static String ticketSaved(String locale) =>
      locale == 'en' ? "Ticket saved!" : "Ticket sauvegardé !";

  static String scanAtArrival(String locale) =>
      locale == 'en' ? "Present this QR code at arrival" : "Présentez ce QR code à l'arrivée";

  // --- Static legacy constants for components not yet migrated ---
  static const String appNameLegacy = "Queue-Buddy";
  static const String homeTitleLegacy = "SIRA";
  static const String proximityAgenciesLegacy = "Agences à proximité";
  static String minWaitingLegacy(num min) => "$min min d'attente";
  static const String taglineLegacy = "L'attente devient intelligente";
  static const String takeTicketLegacy = "PRENDRE UN TICKET";
  static const String takeMyTicket = "PRENDRE MON TICKET";
  static const String historyLegacy = "HISTORIQUE";
  static const String estimatedTimeLegacy = "TEMPS ESTIMÉ";

  static const String peopleWaitingSuffixLegacy = "personnes dans l'attente";
  static const String availableServicesLegacy = "Services disponibles";
  static const String chooseVisitObjectLegacy = "Choisissez l'objet de votre visite";
  static const String quickServiceDesc = "Service rapide et efficace";
  static const String yourInfoLegacy = "Vos informations";
  static const String fullNameLegacy = "Nom complet";
  static const String phoneLegacy = "Téléphone";
  static const String enterNameErrorLegacy = "Veuillez entrer votre nom";
  static const String enterPhoneErrorLegacy = "Veuillez entrer votre numéro";
  static const String phoneMinLengthError = "Le numéro doit contenir au moins 8 chiffres";
  static const String errorPrefix = "Erreur: ";
  static const String yourTicketLegacy = "VOTRE TICKET";
  static const String pleaseWaitLegacy = "Veuillez patienter...";
  static const String notificationSoonLegacy = "Nous vous notifierons dès que c'est votre tour";
  static const String returnHomeLegacy = "RETOUR À L'ACCUEIL";
  static const String itsYourTurnLegacy = "C'est votre tour !";
  static const String presentAtCounterLegacy = "Veuillez vous présenter au guichet";
  static const String positionInQueueLegacy = "Position dans la file";
  static const String peopleInFrontLegacy = "personnes devant vous";
  static const String historyTitle = "HISTORIQUE";
  static const String noTickets = "Aucun ticket récent";
  static const String futureTicketsPrompt = "Vos futurs tickets apparaîtront ici.";
  static const String yourReview = "VOTRE AVIS";
  static const String howWasWait = "Comment s'est passée votre attente ?";
  static const String optionalComment = "Un commentaire ? (Optionnel)";
  static const String send = "ENVOYER";
  static const String thanksFeedback = "Merci pour votre retour !";
  static const String versement = "Versement";
  static const String retrait = "Retrait";
  static const String ouvertureCompte = "Ouverture de compte";
  static const String reclamation = "Réclamation";
  static const String backOfficeTitle = "DASHBOARD SUPERVISEUR";
  static const String callNext = "APPELER LE SUIVANT";
  static const String validateCurrent = "VALIDER LE TICKET ACTUEL";
  static const String serveDone = "SERVICE TERMINÉ";
  static const String noTicketsToCall = "Aucun ticket à appeler";
  static const String assistantBtnLegacy = "ASSISTANT SOLOBA";
  static const String analyzingLegacy = "Analyse en cours...";
  static const String solobaListeningBambara = "Soloba bɛ i lamɛnna...";
  static const String solobaListeningDescLegacy = "Soloba vous écoute en Bambara";
  static const String stopLegacy = "ARRÊTER";
  static const String cancelLegacy = "ANNULER";
  static const String aiUnderstoodLegacy = "L'IA SOLOBA V3 A COMPRIS :";
  static const String retryLegacy = "REPRÉCISER";
  static const String continueBtnLegacy = "CONTINUER";
  static const String microphoneDenied = "Permission micro refusée.";
  static const String audioError = "Impossible de générer le fichier audio.";
  static const String solobaErrorPrefix = "Erreur Soloba: ";
  static const String peakHoursLabel = "AFFLUENCE :";
  static const String notifTicketTaken = "Ticket bien pris !";
  static const String notifTicketTakenBody = "Votre ticket a été pris avec succès. Vous recevrez des alertes.";
  static const String notif30min = "Rappel";
  static const String notif30minBody = "Il vous reste environ 30 minutes avant votre tour.";
  static const String notif10min = "Bientôt votre tour";
  static const String notif10minBody = "Votre tour arrive dans environ 10 minutes !";
  static const String notifYourTurn = "C'est votre tour !";
  static const String notifYourTurnBody = "Veuillez vous présenter au guichet maintenant.";
  static const String notifYourTurnBambaraSpeech = "I ka waati sera. I ka taa guichet la sisan.";
  static const String notifications = "Notifications";
  static const String noNotifications = "Aucune notification";
  static const String qrCodeLabelLegacy = "QR Code d'identification";
  static const String scanAtArrivalLegacy = "Présentez ce QR code à l'arrivée";
  static const String downloadTicketLegacy = "TÉLÉCHARGER LE TICKET";
  static const String ticketSavedLegacy = "Ticket sauvegardé !";
  static const String ticketShared = "Partage du ticket...";
  static const String gabLabel = "GAB (Distributeur)";
  static const String guichetLabel = "Guichet";
  static const String gabDescription = "Guichet automatique — Carte bancaire";
  static const String guichetDescription = "Guichet humain — Service personnalisé";
  static const String welcomeGreeting = "Aw ni ce! Ne ye SIRA ye. N bɛ i dɛmɛ ka i ka ticket ta ni hɛrɛ ye, i kana i ka waati bɔnya.";
  static const String welcomeGreetingFr = "Bonjour ! Je suis SIRA. Je vous aide à prendre votre ticket en toute tranquillité pour optimiser votre temps.";
  static const String homeVoiceGuideBm = "Nin yoro la, i bɛ se ka banque yoro sugandi. I bɛ se fana ka Soloba wele walasa ka i ka baara fɔ n ye Bambara kan na.";
  static const String takeTicketVoiceGuideBm = "Nin yoro la, sugandi baara min i b’a fe, sɔrɔ i ka tɔgɔ ni telefonu nimɛro, o kɔfɛ i bɛ se ka i ka ticket ta.";
  static const String ticketVoiceGuideBm = "Nin ye i ka ticket ye. I ka nimɛro bɛ yan. A lajɛ kosɛbɛ, ani i bɛ se k’a download walima ka bɔ ka taa ɲɛna.";
  static const String historyVoiceGuideBm = "Nin ye i ka ticket kɔfɛkow ye. I ka ticket kɔrɔw bɛɛ bɛ yan, walasa i bɛ se k’u lajɛ tuguni.";
  static const String dashboardVoiceGuideBm = "Nin ye dashboard ye. Yan i bɛ se ka ticketw lajɛ, ka se ka wele ka tuma bɔ, ani ka baara kɛli ɲɛnabɔ.";
  static const String analyticsVoiceGuideBm = "Nin ye statistiques yoro ye. Yan i bɛ se ka lɛrɛnni lajɛ, waati hakɛ, ani tile ka baara kɛcogo lajɛ ka yidɛsɛbɛn sɔrɔ.";
  static const String asrUnavailable = "Le serveur vocal est indisponible. Utilisez le mode démonstration.";
  static const String demoMode = "MODE DÉMO";
  static const String tryDemoVoice = "ESSAYER (DÉMO)";
  static const String kpiWaiting = "En Attente";
  static const String kpiAvgWait = "Attente Moyenne";
  static const String kpiServed = "Servis (Jour)";
  static const String kpiValidated = "Validés (Jour)";
  static const String guichetAnalysis = "Analyse des Guichets";
  static const String gabAnalysis = "Analyse des GAB";
  static const String statusFunctional = "fonctionnels";
}
