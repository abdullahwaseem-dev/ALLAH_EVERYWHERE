import '../prophetic_content.dart';
import '../seerah_data.dart';
import '../tib_e_nabwi_data.dart';

/// French translation of the Seerah and Tib-e-Nabwi content.
const propheticFr = PropheticContent(
  text: PropheticScreenText(
    seeratTitle: 'LA SÎRA DU PROPHÈTE',
    seeratHeader: 'سیرتِ نبوی',
    seeratSubtitle: 'La vie du Prophète Muhammad (ﷺ), de sa naissance à sa mort',
    tibTitle: 'Médecine prophétique (ﷺ)',
    tibHeader: 'طبِ نبوی',
    tibSubtitle: 'Les enseignements du Prophète sur la santé et les remèdes naturels (Tibb Nabawi)',
    tibDisclaimer:
        'Il s\'agit d\'enseignements traditionnels issus de hadiths authentiques. Ils ne remplacent pas un traitement médical - consultez un médecin pour tout problème de santé.',
  ),
  seerah: [
    SeerahChapter(
      period: 'Avant 570',
      title: 'L\'Arabie avant l\'islam',
      paragraphs: [
        'L\'Arabie préislamique (la « Jâhiliyya », ou âge de l\'ignorance) était une société tribale, fondée sur la loyauté clanique et l\'honneur plutôt que sur un gouvernement établi. La Mecque se trouvait au carrefour de grandes routes commerciales et abritait la Kaaba, un sanctuaire cubique bâti - selon la tradition islamique - par Ibrahim (Abraham) et son fils Ismaël comme maison d\'adoration du Dieu unique. Au VIe siècle, elle était entourée de quelque 360 idoles, et des pèlerins venaient de toute l\'Arabie pour les vénérer.',
        'Les Quraych, gardiens de la Kaaba, jouissaient d\'un prestige à la fois religieux et commercial. Mais l\'époque était aussi marquée par les guerres tribales, l\'infanticide des filles, une exploitation économique brutale des faibles et une idolâtrie généralisée - précisément les maux que le Coran présentera plus tard la prière et la révélation comme venant corriger (Coran 29:45).',
      ],
    ),
    SeerahChapter(
      period: '570',
      title: 'Naissance et petite enfance',
      paragraphs: [
        'Muhammad ibn Abdallah (paix et bénédictions sur lui) naquit à La Mecque durant « l\'année de l\'Éléphant », ainsi nommée d\'après l\'année où une armée abyssine accompagnée d\'éléphants de guerre tenta de détruire la Kaaba et fut repoussée, événement évoqué dans la sourate Al-Fîl (Coran 105). Son père, Abdallah, était mort avant sa naissance ; sa mère, Âmina, mourut quand il avait six ans. Orphelin, il fut élevé d\'abord par son grand-père Abd al-Muttalib, puis, après la mort de celui-ci, par son oncle Abû Tâlib.',
        'Selon la coutume arabe, le nourrisson fut confié dans le désert à une nourrice, Halîma as-Sa\'diyya de la tribu des Banû Sa\'d ; il y passa ses premières années, loin de l\'entassement et des maladies de la ville - une période que la tradition islamique associe à la purification de son cœur en préparation de la prophétie.',
      ],
    ),
    SeerahChapter(
      period: '576-595',
      title: 'Jeunesse à La Mecque',
      paragraphs: [
        'Élevé dans la maison de son oncle Abû Tâlib, le jeune Muhammad fut berger, puis rejoignit des caravanes commerciales vers la Syrie. Il acquit dans toute La Mecque une telle réputation d\'honnêteté et de fiabilité qu\'on l\'appela « Al-Amîn », le Digne de confiance. Il ne prit aucune part à l\'idolâtrie, à l\'ivresse ou à la corruption morale courantes chez ses contemporains, et était connu pour régler équitablement les différends ; vers trente-cinq ans, il fut choisi pour arbitrer une querelle dangereuse entre les clans de Quraych : qui replacerait la Pierre noire dans la Kaaba reconstruite ? Il la plaça sur un manteau que les représentants de chaque clan soulevèrent ensemble.',
      ],
    ),
    SeerahChapter(
      period: '595',
      title: 'Mariage avec Khadîja',
      paragraphs: [
        'À vingt-cinq ans, Muhammad fut engagé par Khadîja bint Khuwaylid, une commerçante mecquoise respectée et prospère, pour conduire une caravane vers la Syrie. Impressionnée par son honnêteté et par les bénéfices qu\'il lui rapporta, Khadîja - alors âgée de quarante ans - lui proposa le mariage, et il accepta. Leur union fut un profond partenariat : Khadîja fut la première à croire en sa mission prophétique, et il ne prit aucune autre épouse de son vivant. Ils eurent plusieurs enfants, dont leur fille Fâtima, qui occupera une place centrale dans l\'histoire islamique.',
      ],
    ),
    SeerahChapter(
      period: '610',
      title: 'La première révélation',
      paragraphs: [
        'À l\'approche de ses quarante ans, Muhammad avait pris l\'habitude de se retirer pour méditer dans la grotte de Hirâ, sur le mont Jabal an-Nûr près de La Mecque. Lors d\'une de ces retraites, pendant le mois de Ramadan, l\'ange Jibrîl (Gabriel) lui apparut et lui ordonna : « Lis » (Iqra). Muhammad répondit qu\'il ne savait pas lire ; l\'ange le serra fortement contre lui trois fois, puis lui révéla les premiers versets du Coran : « Lis, au nom de ton Seigneur qui a créé, qui a créé l\'homme d\'une adhérence. Lis ! Ton Seigneur est le Très Noble » (Coran 96:1-3).',
        'Bouleversé, il rentra auprès de Khadîja, qui l\'enveloppa d\'un manteau et, après avoir entendu son récit, le rassura : « Allah ne t\'humiliera jamais. Tu entretiens les liens de parenté, tu aides le faible, tu nourris le pauvre et tu secours ceux qui sont dans l\'épreuve. » Elle l\'emmena chez son cousin Waraqa ibn Nawfal, un savant chrétien, qui reconnut dans cette rencontre la même révélation qu\'avait reçue Moïse, et lui annonça qu\'il serait chassé de sa ville à cause du message qu\'il porterait.',
      ],
      reference: 'Sahih al-Bukhari 3, Sahih Muslim 160',
    ),
    SeerahChapter(
      period: '613-619',
      title: 'Premières prédications et persécutions',
      paragraphs: [
        'Après une interruption de la révélation, Muhammad commença à prêcher en privé à sa famille et à ses proches - Khadîja, son cousin Ali, son affranchi Zayd ibn Hâritha et son ami intime Abû Bakr furent parmi les tout premiers à embrasser l\'islam. Trois ans plus tard, il reçut l\'ordre de prêcher publiquement (Coran 26:214), ce qui déclencha l\'hostilité ouverte de Quraych, qui voyait dans ce message une menace pour ses idoles, son commerce et son ordre social.',
        'La persécution s\'intensifia : des musulmans issus de familles sans protection, comme Bilâl ibn Rabâh, furent torturés ; certains émigrèrent en Abyssinie (l\'actuelle Éthiopie) auprès d\'un roi chrétien, le Négus, qui leur accorda sa protection après avoir entendu des versets du Coran sur Îsâ (Jésus) et Maryam (Marie). Quraych imposa un boycott au clan de Muhammad, les Banû Hâchim, les privant de commerce et d\'alliances matrimoniales pendant environ trois ans, jusqu\'à ce que ce boycott s\'effondre sous le poids de sa propre injustice.',
      ],
    ),
    SeerahChapter(
      period: '619-620',
      title: 'L\'année de la tristesse et le Voyage nocturne',
      paragraphs: [
        'La dixième année de la prophétie, Muhammad perdit en peu de temps son épouse Khadîja et son oncle et protecteur Abû Tâlib, une période appelée « \'Âm al-Huzn », l\'année de la tristesse. Privé de la protection d\'Abû Tâlib, il subit une hostilité accrue de Quraych, et sa tentative de prêcher dans la ville voisine de Tâ\'if se solda par son expulsion sous les jets de pierres de ses habitants.',
        'Peu après, selon la tradition islamique, Muhammad vécut al-Isrâ\' wal-Mi\'râj, le Voyage nocturne : un voyage miraculeux de La Mecque à Jérusalem, puis de là une ascension à travers les cieux, au cours de laquelle les cinq prières quotidiennes furent prescrites aux musulmans (Coran 17:1).',
      ],
    ),
    SeerahChapter(
      period: '620-622',
      title: 'Les serments d\'Aqaba et l\'Hégire',
      paragraphs: [
        'Pendant la saison annuelle du pèlerinage, Muhammad rencontra des pèlerins de Yathrib (plus tard renommée Médine), une ville minée par un long conflit tribal entre les Aws et les Khazraj. Lors de deux rencontres secrètes à Aqaba, des groupes d\'habitants de Yathrib embrassèrent l\'islam et invitèrent Muhammad dans leur ville comme arbitre et chef, s\'engageant à le protéger comme leurs propres familles.',
        'Lorsque l\'hostilité de Quraych alla jusqu\'à un complot d\'assassinat, Muhammad ordonna à ses compagnons d\'émigrer à Médine par petits groupes, tandis que lui-même et Abû Bakr partirent les derniers, se cachant trois jours dans la grotte de Thawr avant d\'entreprendre le voyage. Cette migration - l\'Hégire, en 622 - marque le début du calendrier islamique (hégirien) et transforma une minorité persécutée en fondement d\'une société nouvelle.',
      ],
    ),
    SeerahChapter(
      period: '622-624',
      title: 'Bâtir la communauté à Médine',
      paragraphs: [
        'À Médine, Muhammad fonda une mosquée qui servait aussi de centre de la vie communautaire, unit officiellement les émigrés mecquois (Muhâjirûn) à leurs hôtes médinois (Ansâr) par des liens de fraternité et d\'entraide, et fit rédiger la Constitution de Médine - un pacte entre les musulmans et les tribus juives de la ville établissant la défense mutuelle, la liberté religieuse et la coopération juridique, considéré par les historiens comme l\'une des plus anciennes constitutions écrites.',
      ],
    ),
    SeerahChapter(
      period: '624',
      title: 'La bataille de Badr',
      paragraphs: [
        'Le conflit avec La Mecque se poursuivit, Quraych cherchant à écraser la jeune communauté. À Badr, en 624, une petite troupe musulmane mal équipée d\'environ 313 hommes affronta une armée mecquoise près de trois fois plus nombreuse et remporta une victoire décisive, que le Coran attribue au secours divin (Coran 3:123, 8:9). La bataille prouva la résilience de la nouvelle communauté et accrut considérablement son prestige dans toute l\'Arabie.',
      ],
    ),
    SeerahChapter(
      period: '625-627',
      title: 'Uhud et la bataille du Fossé',
      paragraphs: [
        'Quraych revint l\'année suivante à Uhud, où une erreur tactique - un groupe d\'archers musulmans quittant son poste - transforma un avantage initial en un revers coûteux, sans que l\'armée musulmane soit anéantie ; le Prophète lui-même fut blessé. En 627, une coalition de Mecquois et de tribus alliées assiégea Médine même ; sur le conseil du compagnon perse Salmân al-Fârisî, les musulmans creusèrent un fossé défensif sur le flanc exposé de la ville - une tactique inconnue en Arabie - qui bloqua le siège jusqu\'à ce que la coalition, usée par les intempéries et la désunion, se retire sans bataille décisive.',
      ],
    ),
    SeerahChapter(
      period: '628',
      title: 'Le traité d\'al-Hudaybiya',
      paragraphs: [
        'En 628, Muhammad partit sans armes avec 1 400 compagnons pour accomplir le pèlerinage, mais Quraych l\'arrêta à al-Hudaybiya, aux portes de La Mecque. Plutôt que de combattre, il négocia une trêve de dix ans, à des conditions qui semblaient d\'abord défavorables aux musulmans, dont le report du pèlerinage de cette année-là. Le Coran qualifia ensuite ce traité de « victoire éclatante » (Coran 48:1) : la trêve mit fin à des années de guerre ouverte et, en permettant la libre circulation et les échanges, entraîna plus de conversions à l\'islam durant les deux années suivantes que pendant toute la période précédente.',
      ],
    ),
    SeerahChapter(
      period: '630',
      title: 'La conquête de La Mecque',
      paragraphs: [
        'Lorsque les alliés de Quraych rompirent la trêve d\'al-Hudaybiya, Muhammad marcha sur La Mecque avec quelque 10 000 hommes en 630. La ville se rendit presque sans effusion de sang. Muhammad y entra avec humilité, proclama une amnistie générale, même pour ceux qui avaient persécuté les musulmans pendant vingt ans, et détruisit lui-même les idoles entourant la Kaaba en récitant : « La Vérité est venue et l\'erreur a disparu ; l\'erreur est destinée à disparaître » (Coran 17:81). En deux ans, la majeure partie de l\'Arabie avait embrassé l\'islam.',
      ],
    ),
    SeerahChapter(
      period: '632',
      title: 'Le pèlerinage d\'adieu',
      paragraphs: [
        'Au cours de la dernière année de sa vie, Muhammad conduisit quelque 100 000 à 120 000 musulmans lors de ce qu\'on appela le pèlerinage d\'adieu (Hajjat al-Wadâ\'). À Arafat, il prononça son sermon d\'adieu, énonçant des principes qui demeurent au fondement de l\'éthique islamique : le caractère sacré de la vie et des biens, l\'abolition des vendettas préislamiques et de l\'usure, les droits des femmes, l\'égalité de tous les êtres humains quelle que soit leur race ou leur tribu (« un Arabe n\'a aucune supériorité sur un non-Arabe, ni un Blanc sur un Noir, si ce n\'est par la piété »), et l\'exhortation à s\'attacher fermement au Coran. C\'est durant ce pèlerinage que fut révélé le verset : « Aujourd\'hui, J\'ai parachevé pour vous votre religion » (Coran 5:3).',
      ],
    ),
    SeerahChapter(
      period: '632',
      title: 'Sa mort à Médine',
      paragraphs: [
        'Muhammad tomba malade peu après son retour à Médine et s\'éteignit le 12 Rabî\' al-Awwal de l\'an 11 de l\'Hégire (8 juin 632), dans l\'appartement de son épouse Aïcha, la tête reposant sur ses genoux. Il fut enterré là où il mourut, dans ce qui fait aujourd\'hui partie de la Mosquée du Prophète à Médine. Il laissa le Coran et sa Sunna (son exemple) comme guide, et la petite communauté qu\'il avait dirigée s\'étendit en un siècle sur trois continents - un héritage que les musulmans considèrent non comme l\'œuvre d\'un seul homme, mais comme une miséricorde pour l\'univers (Coran 21:107).',
      ],
    ),
  ],
  tib: [
    TibCategory(
      title: 'Principes généraux de la médecine prophétique',
      intro:
          'Le Prophète (ﷺ) a enseigné que se soigner ne contredit pas la confiance (tawakkul) en Allah - pour chaque maladie qu\'Allah crée, Il crée aussi un remède, excepté la vieillesse et la mort elle-même.',
      items: [
        TibRemedy(
          title: 'Se soigner',
          description:
              'Le Prophète (ﷺ) a dit : « Soignez-vous, car Allah n\'a pas créé de maladie sans lui assigner un remède, à l\'exception d\'une seule maladie : la vieillesse. »',
          reference: 'Sunan Abu Dawood 3855',
        ),
        TibRemedy(
          title: 'Un remède pour chaque maladie',
          description: 'Le Prophète (ﷺ) a dit : « Allah n\'a fait descendre aucune maladie sans faire descendre aussi son remède. »',
          reference: 'Sahih al-Bukhari 5678',
        ),
        TibRemedy(
          title: 'Se soigner et s\'en remettre à Allah',
          description:
              'Des Bédouins demandèrent au Prophète (ﷺ) s\'ils devaient se soigner. Il répondit : « Oui, ô serviteurs d\'Allah, soignez-vous, car Allah n\'a pas créé de maladie sans lui créer un remède, excepté une seule : la vieillesse. »',
          reference: "Jami' at-Tirmidhi 2038",
        ),
      ],
    ),
    TibCategory(
      title: 'Aliments et boissons',
      intro:
          'Plusieurs aliments sont cités dans le Coran et les hadiths authentiques pour leurs bienfaits - ce sont des remèdes traditionnels, pas un substitut à un traitement médical.',
      items: [
        TibRemedy(
          title: 'Le miel',
          description:
              'Le Coran décrit le miel comme contenant une guérison pour les gens. Le Prophète (ﷺ) conseilla à un homme dont le frère souffrait du ventre de lui faire boire du miel.',
          reference: 'Quran 16:69, Sahih al-Bukhari 5684',
        ),
        TibRemedy(
          title: 'La nigelle (graine noire)',
          description: 'Le Prophète (ﷺ) a dit que la graine noire est un remède à toute maladie, sauf la mort.',
          reference: 'Sahih al-Bukhari 5688, Sahih Muslim 2215',
        ),
        TibRemedy(
          title: 'Les dattes, surtout les Ajwa',
          description:
              'Le Prophète (ﷺ) a dit que celui qui mange chaque matin sept dattes Ajwa ne sera atteint ce jour-là ni par le poison ni par la sorcellerie.',
          reference: 'Sahih al-Bukhari 5445, Sahih Muslim 2047',
        ),
        TibRemedy(
          title: 'La talbîna',
          description:
              'Un plat à base d\'orge dont le Prophète (ﷺ) a dit qu\'il apaise le cœur du malade et allège la tristesse ; il encourageait à l\'offrir à une famille endeuillée.',
          reference: 'Sahih al-Bukhari 5417, Sahih Muslim 2216',
        ),
        TibRemedy(
          title: 'L\'eau de Zamzam',
          description: 'Le Prophète (ﷺ) a dit que l\'eau de Zamzam sert à ce pour quoi on la boit.',
          reference: 'Sunan Ibn Majah 3062',
        ),
        TibRemedy(
          title: 'L\'huile d\'olive',
          description:
              'Le Prophète (ﷺ) recommandait de consommer l\'huile d\'olive et de s\'en oindre, la décrivant comme issue d\'un arbre béni.',
          reference: "Jami' at-Tirmidhi 1851",
        ),
        TibRemedy(
          title: 'Le lait',
          description:
              'Le Prophète (ﷺ) a enseigné une invocation de bénédiction après avoir bu du lait : « Ô Allah, bénis-le pour nous et accorde-nous-en davantage. »',
          reference: "Jami' at-Tirmidhi 3455, Sunan Abu Dawood 3730",
        ),
        TibRemedy(
          title: 'Le vinaigre',
          description: 'Le Prophète (ﷺ) a dit : « Quel excellent condiment que le vinaigre. »',
          reference: 'Sahih Muslim 2051',
        ),
      ],
    ),
    TibCategory(
      title: 'Ventouses (hijâma) et thérapies physiques',
      intro: 'Les ventouses sont l\'une des thérapies physiques les plus souvent mentionnées dans les hadiths.',
      items: [
        TibRemedy(
          title: 'La hijâma, un remède de premier ordre',
          description: 'Le Prophète (ﷺ) a dit : « Le meilleur remède que vous utilisiez est la hijâma (ventouses). »',
          reference: 'Sahih al-Bukhari 5696, Sahih Muslim 2205',
        ),
        TibRemedy(
          title: 'Le Prophète (ﷺ) a lui-même reçu la hijâma',
          description:
              'Il est rapporté que le Prophète (ﷺ) s\'est fait poser des ventouses sur la nuque et entre les épaules, et qu\'il a rémunéré celui qui les lui a posées.',
          reference: 'Sahih al-Bukhari 2277, 5691',
        ),
      ],
    ),
    TibCategory(
      title: 'Médecine préventive et hygiène',
      intro: 'Plusieurs enseignements visent à prévenir la maladie avant qu\'elle ne survienne.',
      items: [
        TibRemedy(
          title: 'Le siwâk (bâtonnet dentaire)',
          description:
              'Le Prophète (ﷺ) a dit : « Si je ne craignais pas d\'imposer une charge trop lourde à ma communauté, je lui aurais ordonné d\'utiliser le siwâk à chaque prière. »',
          reference: 'Sahih al-Bukhari 887, Sahih Muslim 252',
        ),
        TibRemedy(
          title: 'La propreté',
          description: 'Le Prophète (ﷺ) a dit : « La purification est la moitié de la foi. »',
          reference: 'Sahih Muslim 223',
        ),
        TibRemedy(
          title: 'La modération dans l\'alimentation',
          description:
              'Le Prophète (ﷺ) a dit que le fils d\'Adam ne remplit pas de récipient pire que son ventre ; quelques bouchées suffisent pour lui tenir le dos droit - et s\'il doit manger davantage, qu\'il réserve un tiers à la nourriture, un tiers à la boisson et un tiers à la respiration.',
          reference: "Jami' at-Tirmidhi 2380, Sunan Ibn Majah 3349",
        ),
        TibRemedy(
          title: 'Couvrir la nourriture et la boisson',
          description:
              'Le Prophète (ﷺ) ordonna de couvrir les récipients et de fermer les outres, surtout la nuit, disant qu\'il y a dans l\'année une nuit où descend une épidémie qui ne passe près d\'aucun récipient découvert sans qu\'il en tombe quelque chose dedans.',
          reference: 'Sahih Muslim 2012, Sahih al-Bukhari 5624',
        ),
        TibRemedy(
          title: 'Le principe de la quarantaine',
          description:
              'Le Prophète (ﷺ) a dit : « Si vous apprenez qu\'une épidémie de peste sévit dans une contrée, n\'y entrez pas ; et si elle se déclare là où vous vous trouvez, n\'en sortez pas. »',
          reference: 'Sahih al-Bukhari 5728, Sahih Muslim 2218',
        ),
      ],
    ),
    TibCategory(
      title: 'La roqya - guérison spirituelle',
      intro: 'Réciter le Coran et invoquer Allah pour le malade font eux-mêmes partie de la médecine prophétique.',
      items: [
        TibRemedy(
          title: 'Al-Fâtiha comme roqya',
          description:
              'Un compagnon récita la sourate Al-Fâtiha sur un homme piqué par un scorpion, qui guérit ; lorsqu\'on le lui rapporta, le Prophète (ﷺ) dit : « Et comment as-tu su que c\'était une roqya ? »',
          reference: 'Sahih al-Bukhari 5749, Sahih Muslim 2201',
        ),
        TibRemedy(
          title: 'Les deux sourates protectrices avant le sommeil',
          description:
              'Durant sa dernière maladie, le Prophète (ﷺ) récitait les sourates Al-Falaq et An-Nâs avec Al-Ikhlâs, soufflait dans ses mains et les passait sur son corps.',
          reference: 'Sahih al-Bukhari 5017, 5748',
        ),
        TibRemedy(
          title: 'Invocation pour le malade',
          description:
              'Le Prophète (ﷺ) disait auprès du malade : « Adh-hib al-ba\'s, Rabb an-nâs, wachfi anta ach-Châfî, lâ chifâ\'a illâ chifâ\'uka, chifâ\'an lâ yughâdiru saqamâ » - « Ôte le mal, Seigneur des hommes, et guéris, Tu es Celui qui guérit ; il n\'y a de guérison que Ta guérison, une guérison qui ne laisse aucune maladie. »',
          reference: 'Sahih al-Bukhari 5675, Sahih Muslim 2191',
        ),
      ],
    ),
    TibCategory(
      title: 'Sommeil et rythme quotidien',
      intro: 'La Sunna recommande quelques habitudes simples pour le sommeil.',
      items: [
        TibRemedy(
          title: 'Dormir sur le côté droit',
          description: 'Le Prophète (ﷺ) se couchait sur le côté droit pour dormir et l\'enseignait comme faisant partie des usages du coucher.',
          reference: 'Sahih al-Bukhari 247, Sahih Muslim 2710',
        ),
        TibRemedy(
          title: 'Éviter de dormir sur le ventre',
          description: 'Le Prophète (ﷺ) vit un homme allongé sur le ventre et dit qu\'Allah n\'aime pas cette position.',
          reference: 'Sunan Abu Dawood 5040, Sunan Ibn Majah 3723',
        ),
      ],
    ),
    TibCategory(
      title: 'Maladie, patience et récompense',
      intro: 'Les hadiths présentent la maladie comme une épreuve qui, vécue avec patience, apporte un bienfait spirituel.',
      items: [
        TibRemedy(
          title: 'La maladie efface les péchés',
          description:
              'Le Prophète (ﷺ) a dit : « Aucune fatigue, aucune maladie, aucun souci, aucune tristesse, aucun mal ni aucune détresse n\'atteint le musulman, fût-ce une épine qui le pique, sans qu\'Allah n\'efface par cela une partie de ses péchés. »',
          reference: 'Sahih al-Bukhari 5641, Sahih Muslim 2573',
        ),
        TibRemedy(
          title: 'Rendre visite au malade',
          description:
              'Le Prophète (ﷺ) encourageait à rendre visite aux malades, un droit que les musulmans se doivent mutuellement et une source de récompense pour le visiteur.',
          reference: 'Sahih Muslim 2568',
        ),
      ],
    ),
  ],
);
